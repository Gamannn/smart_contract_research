```solidity
pragma solidity ^0.4.24;

contract LuckyETH {
    event onEndTx(
        address playerAddress,
        uint256 playerId,
        uint256 incomingEther,
        address referredBy,
        uint256 airDropPot,
        uint256 airDropTracker,
        uint256 airDropAmount
    );
    event onWithdraw(
        uint256 indexed playerId,
        address playerAddress,
        uint256 earnings,
        uint256 timeStamp
    );
}

library EventData {
    struct EventReturns {
        address playerAddress;
        uint256 playerId;
        uint256 incomingEther;
        address referredBy;
        uint256 airDropPot;
        uint256 airDropTracker;
        uint256 airDropAmount;
    }
}

contract LuckyETHGame {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier isHuman() {
        address _addr = msg.sender;
        require(_addr == tx.origin);
        uint256 _codeLength;
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }

    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 1000000000, "pocket lint: not a valid currency");
        require(_eth <= 100000000000000000000000, "no vitalik, no");
        _;
    }

    function buy() isHuman() isWithinLimits(msg.value) public payable {
        address _referredBy = address(0);
        if (playerReferral[msg.sender] != address(0)) {
            _referredBy = playerReferral[msg.sender];
        }
        core(msg.sender, msg.value, _referredBy);
    }

    function buyFor(address _referredBy) isHuman() isWithinLimits(msg.value) public payable {
        if (_referredBy == address(0)) {
            _referredBy = playerReferral[msg.sender];
        } else {
            playerReferral[msg.sender] = _referredBy;
        }
        core(msg.sender, msg.value, _referredBy);
    }

    function withdraw() isHuman() public {
        withdrawEarnings(msg.sender);
    }

    function setAdmin(address _newAdmin) public {
        if (admin != address(0)) {
            withdrawEarnings(admin);
        }
        core(_newAdmin, 0, address(0));
        admin = _newAdmin;
    }

    function core(address _player, uint256 _eth, address _referredBy) private {
        EventData.EventReturns memory _eventData;
        _eventData.playerAddress = _player;
        uint256 _playerId = playerId[_player];
        if (_playerId == 0) {
            _playerId = playerCount;
            playerCount = playerCount.add(1);
            playerId[_player] = _playerId;
        }
        _eventData.playerId = _playerId;
        _eventData.incomingEther = _eth;

        if (_eth >= 100000000000000000) {
            airDropTracker++;
            if (airDrop()) {
                uint256 _airDropAmount = 0;
                if (_eth >= 10000000000000000000) {
                    _airDropAmount = (airDropPot.mul(75)) / 100;
                } else if (_eth >= 1000000000000000000 && _eth < 10000000000000000000) {
                    _airDropAmount = (airDropPot.mul(50)) / 100;
                } else if (_eth >= 100000000000000000 && _eth < 1000000000000000000) {
                    _airDropAmount = (airDropPot.mul(25)) / 100;
                }
                airDropPot = airDropPot.sub(_airDropAmount);
                _player.transfer(_airDropAmount);
                _eventData.airDropPot = airDropPot;
                _eventData.airDropAmount = _airDropAmount;
                airDropTracker = 0;
            }
        }

        uint256 _referralBonus = _eth / 5;
        uint256 _community = _eth.mul(30) / 100;
        uint256 _pot = _eth.sub(_referralBonus).sub(_community);

        uint256 _referredById = playerId[_referredBy];
        if (_referredById != 0 && _referredById != _playerId) {
            _referredBy.transfer(_referralBonus);
        } else {
            _pot = _pot.add(_referralBonus);
        }

        airDropPot = airDropPot.add(_pot);
        genPot = genPot.add(_community);

        _eventData.airDropPot = airDropPot;
        emit onEndTx(
            _eventData.playerAddress,
            _eventData.playerId,
            _eventData.incomingEther,
            _eventData.referredBy,
            _eventData.airDropPot,
            _eventData.airDropTracker,
            _eventData.airDropAmount
        );
    }

    function airDrop() private view returns(bool) {
        uint256 _seed = uint256(keccak256(abi.encodePacked(
            (block.timestamp).add
            (block.difficulty).add
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
            (block.gaslimit).add
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
            (block.number)
        )));
        if((_seed - ((_seed / 1000) * 1000)) <= airDropTracker) return(true);
        else return(false);
    }

    function withdrawEarnings(address _player) private {
        uint256 _now = now;
        uint256 _playerId = playerId[_player];
        require(_playerId != 0, "no, no, no...");
        delete(playerId[_player]);
        delete(playerReferral[_player]);
        playerId[_player] = 0;
        EventData.EventReturns memory _eventData;
        _eventData.playerAddress = _player;
        uint256 _earnings = playerEarnings[_player];
        uint256 _community = genPot;
        uint256 _pot = airDropPot;
        uint256 _earningsShare = _community.mul(_earnings) / 2;
        assert(_earningsShare < _community);
        _earningsShare = _pot.mul(_earningsShare) / _community;
        airDropPot = airDropPot.sub(_earningsShare);
        _player.transfer(_earningsShare);
        emit onWithdraw(_playerId, _player, _earningsShare, _now);
    }

    mapping(address => address) public playerReferral;
    mapping(address => uint256) public playerId;
    mapping(address => uint256) public playerEarnings;
    uint256 public playerCount;
    uint256 public airDropPot;
    uint256 public genPot;
    uint256 public airDropTracker;
    address public admin;
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y) {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }

    function sq(uint256 x) internal pure returns (uint256) {
        return (mul(x,x));
    }

    function pwr(uint256 x, uint256 y) internal pure returns (uint256) {
        if (x==0) return (0);
        else if (y==0) return (1);
        else {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }
}
```