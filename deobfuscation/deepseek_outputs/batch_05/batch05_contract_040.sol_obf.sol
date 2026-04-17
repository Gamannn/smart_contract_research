```solidity
pragma solidity ^0.4.24;

contract LuckyETH {
    event onEndTx(
        address playerAddress,
        uint256 playerID,
        uint256 ethIn,
        address referrerAddress,
        uint256 timestamp,
        uint256 compressedData,
        uint256 pot
    );
    
    event onWithdraw(
        uint256 indexed playerID,
        address playerAddress,
        uint256 ethOut,
        uint256 timestamp
    );
}

library LuckyData {
    struct EventReturns {
        address playerAddress;
        uint256 playerID;
        uint256 ethIn;
        address referrerAddress;
        uint256 timestamp;
        uint256 compressedData;
        uint256 pot;
    }
}

contract LuckyETHGame {
    using SafeMath for uint256;
    
    address public owner;
    address public lastWinner;
    
    uint256 public airDropTracker;
    uint256 public airDropPot;
    uint256 public genPot;
    uint256 public pIDCounter;
    
    string public name = "Lucky ETH";
    string public symbol = "L";
    
    mapping(address => uint256) public playerID;
    mapping(address => address) public referrer;
    
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;
        
        assembly { _codeLength := extcodesize(_addr) }
        require(_codeLength == 0, "sorry humans only");
        _;
    }
    
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 1000000000, "pocket lint: not a valid currency");
        require(_eth <= 100000000000000000000000, "no vitalik, no");
        _;
    }
    
    constructor() public {
        owner = msg.sender;
    }
    
    function buy() 
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
        address _referrer = address(0);
        if (referrer[msg.sender] != address(0)) {
            _referrer = referrer[msg.sender];
        }
        core(msg.sender, msg.value, _referrer);
    }
    
    function buyXaddr(address _referrer)
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
        if (_referrer == address(0)) {
            _referrer = referrer[msg.sender];
        } else {
            referrer[msg.sender] = _referrer;
        }
        core(msg.sender, msg.value, _referrer);
    }
    
    function withdraw()
        isHuman()
        public
    {
        withdrawPlayer(msg.sender);
    }
    
    function registerNameXaddr(address _playerAddress)
        onlyOwner()
        public
    {
        if (lastWinner != address(0)) {
            withdrawPlayer(lastWinner);
        }
        core(_playerAddress, 0, address(0));
        lastWinner = _playerAddress;
    }
    
    function core(address _playerAddress, uint256 _eth, address _referrer)
        private
    {
        LuckyData.EventReturns memory _eventData;
        _eventData.playerAddress = _playerAddress;
        
        uint256 _pID = playerID[_playerAddress];
        if (_pID == 0) {
            _pID = pIDCounter;
            pIDCounter = pIDCounter.add(1);
            playerID[_playerAddress] = _pID;
        }
        _eventData.playerID = _pID;
        _eventData.ethIn = _eth;
        
        if (_eth >= 100000000000000000) {
            airDropTracker++;
            
            if (airDrop() == true) {
                uint256 _prize = 0;
                
                if (_eth >= 10000000000000000000) {
                    _prize = airDropPot.mul(75).div(100);
                } else if (_eth >= 1000000000000000000 && _eth < 10000000000000000000) {
                    _prize = airDropPot.mul(50).div(100);
                } else if (_eth >= 100000000000000000 && _eth < 1000000000000000000) {
                    _prize = airDropPot.mul(25).div(100);
                }
                
                if (_prize > 0) {
                    airDropPot = airDropPot.sub(_prize);
                    _playerAddress.transfer(_prize);
                    
                    _eventData.compressedData = _prize;
                    airDropTracker = 0;
                }
            }
        }
        
        uint256 _referral = _eth.div(5);
        uint256 _gen = _eth.mul(30).div(100);
        uint256 _pot = _eth.sub(_referral).sub(_gen);
        
        uint256 _referrerID = playerID[_referrer];
        if (_referrerID != 0 && _referrerID != _pID) {
            _referrer.transfer(_referral);
        } else {
            _pot = _pot.add(_referral);
        }
        
        airDropPot = airDropPot.add(_pot);
        genPot = genPot.add(_gen);
        
        _eventData.pot = _pot;
        endTx(_eventData);
    }
    
    function airDrop()
        private
        view
        returns(bool)
    {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            (block.timestamp).add(block.difficulty).add(
            (uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add(
            block.gaslimit).add(
            (uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add(
            block.number)
        )));
        
        if((seed - ((seed / 1000) * 1000)) <= airDropTracker)
            return(true);
        else
            return(false);
    }
    
    function endTx(LuckyData.EventReturns memory _eventData)
        private
    {
        emit LuckyETH.onEndTx(
            _eventData.playerAddress,
            _eventData.playerID,
            _eventData.ethIn,
            _eventData.referrerAddress,
            now,
            _eventData.compressedData,
            _eventData.pot
        );
    }
    
    function withdrawPlayer(address _playerAddress)
        private
    {
        uint256 _now = now;
        uint256 _pID = playerID[_playerAddress];
        require(_pID != 0, "no, no, no...");
        
        delete playerID[_playerAddress];
        delete referrer[_playerAddress];
        
        LuckyData.EventReturns memory _eventData;
        _eventData.playerAddress = _playerAddress;
        
        uint256 _total = pIDCounter;
        uint256 _gen = genPot;
        uint256 _win = _total.mul(1).div(2);
        
        int256 _earnings = _total.mul(1).sub(_pID);
        require(_earnings < int256(_total));
        
        _earnings = _gen.mul(_win).div(_total);
        genPot = genPot.sub(uint256(_earnings));
        
        _playerAddress.transfer(uint256(_earnings));
        
        emit LuckyETH.onWithdraw(_pID, _playerAddress, uint256(_earnings), _now);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }
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