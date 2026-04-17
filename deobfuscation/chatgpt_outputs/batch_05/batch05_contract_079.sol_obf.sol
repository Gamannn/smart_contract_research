pragma solidity ^0.4.20;

contract GladiatorBattle {
    address public owner;
    address public partner;
    address public kingGladiator;
    address[] public gladiatorQueue;
    mapping(address => uint) public gladiatorBalance;
    mapping(address => uint) public gladiatorCooldown;
    mapping(address => uint) public gladiatorQueuePosition;
    mapping(address => bool) public authorizedAddresses;
    uint public ownerFees = 0;
    bool public started = false;

    event BattleEvent(
        address indexed challenger,
        address indexed opponent,
        uint randomValue,
        uint challengerPower,
        uint opponentPower
    );

    modifier onlyOwnerOrAuthorized() {
        require(msg.sender == owner || authorizedAddresses[msg.sender]);
        _;
    }

    function GladiatorBattle() public {
        owner = msg.sender;
    }

    function setPartner(address _partner) public onlyOwnerOrAuthorized {
        partner = _partner;
    }

    function setOracle(address _oracle) public onlyOwnerOrAuthorized {
        require(!started);
        partner = _oracle;
        started = true;
    }

    function joinBattle() public payable returns (bool) {
        require(msg.value >= 10 finney && gladiatorCooldown[msg.sender] < now);
        if (gladiatorQueue.length > gladiatorQueuePosition[msg.sender]) {
            if (gladiatorQueue[gladiatorQueuePosition[msg.sender]] == msg.sender) {
                gladiatorBalance[msg.sender] += msg.value;
                removeGladiator(msg.sender);
                return false;
            }
        }
        addGladiator(msg.sender);
        return true;
    }

    function addGladiator(address _gladiator) private {
        gladiatorCooldown[_gladiator] = now + 1 days;
        gladiatorQueue.push(_gladiator);
        gladiatorQueuePosition[_gladiator] = gladiatorQueue.length - 1;
        gladiatorBalance[_gladiator] += msg.value;
        checkKingGladiator(_gladiator);
    }

    function removeGladiator(address _gladiator) internal {
        if (gladiatorQueue.length > gladiatorQueuePosition[_gladiator]) {
            if (gladiatorQueue[gladiatorQueuePosition[_gladiator]] == _gladiator) {
                gladiatorQueue[gladiatorQueuePosition[_gladiator]] = gladiatorQueue[gladiatorQueue.length - 1];
                gladiatorQueuePosition[gladiatorQueue[gladiatorQueue.length - 1]] = gladiatorQueuePosition[_gladiator];
                gladiatorCooldown[_gladiator] = 9999999999999;
                delete gladiatorQueue[gladiatorQueue.length - 1];
                gladiatorQueue.length--;
            }
        }
    }

    function authorizeAddress(address _address, bool _status) public onlyOwnerOrAuthorized {
        require(msg.sender != _address);
        authorizedAddresses[_address] = _status;
    }

    function getGladiatorBalance(address _gladiator) public view returns (uint) {
        return gladiatorBalance[_gladiator];
    }

    function getQueueLength() public view returns (uint) {
        return gladiatorQueue.length;
    }

    function getGladiatorCooldown(address _gladiator) public view returns (uint) {
        return gladiatorCooldown[_gladiator];
    }

    function initiateBattle(address _challenger, string _seed) public {
        require(msg.sender == owner);
        if (gladiatorQueue.length == 0) {
            gladiatorCooldown[_challenger] = now + 1 days;
            addGladiator(_challenger);
            kingGladiator = _challenger;
        } else {
            uint randomIndex = uint(keccak256(_seed)) % gladiatorQueue.length;
            uint randomValue = uint(keccak256(_seed)) % 1000;
            address opponent = gladiatorQueue[randomIndex];
            require(gladiatorBalance[_challenger] >= 10 finney && _challenger != opponent);
            uint challengerPower = gladiatorBalance[_challenger];
            uint opponentPower = gladiatorBalance[opponent];
            uint chance = SafeMath.div(SafeMath.mul(challengerPower, 1000), opponentPower);
            if (chance <= 958) {
                chance = SafeMath.div(SafeMath.mul(chance, 40), 100);
            } else {
                chance = 998;
            }
            emit BattleEvent(_challenger, opponent, randomValue, challengerPower, opponentPower);
            uint reward;
            if (randomValue <= chance) {
                reward = SafeMath.div(SafeMath.mul(SafeMath.div(SafeMath.mul(gladiatorBalance[opponent], 5), 100), 100), 100);
                gladiatorBalance[_challenger] = SafeMath.add(gladiatorBalance[_challenger], reward);
                gladiatorQueue[gladiatorQueuePosition[opponent]] = _challenger;
                gladiatorQueuePosition[_challenger] = gladiatorQueuePosition[opponent];
                gladiatorQueuePosition[opponent] = 0;
                gladiatorCooldown[_challenger] = now + 1 days;
                if (gladiatorBalance[_challenger] > gladiatorBalance[kingGladiator]) {
                    kingGladiator = _challenger;
                }
            } else {
                reward = SafeMath.div(SafeMath.mul(SafeMath.div(SafeMath.mul(gladiatorBalance[_challenger], 5), 100), 100), 100);
                gladiatorBalance[opponent] = SafeMath.add(gladiatorBalance[opponent], reward);
                gladiatorQueuePosition[_challenger] = 0;
                gladiatorCooldown[_challenger] = 0;
                if (gladiatorBalance[opponent] > gladiatorBalance[kingGladiator]) {
                    kingGladiator = opponent;
                }
            }
            kingGladiator.transfer(SafeMath.div(SafeMath.mul(reward, 5), 100));
            ownerFees = SafeMath.add(ownerFees, SafeMath.div(SafeMath.mul(reward, 5), 100));
        }
    }

    function withdrawFees(uint _amount) public returns (bool) {
        address recipient;
        uint withdrawalAmount;
        if (msg.sender == owner || msg.sender == partner) {
            recipient = owner;
            withdrawalAmount = ownerFees;
            uint partnerShare = SafeMath.div(SafeMath.mul(withdrawalAmount, 4), 100);
            uint ownerShare = SafeMath.div(SafeMath.mul(SafeMath.sub(withdrawalAmount, partnerShare), 15), 100);
            ownerFees = 0;
            if (!owner.send(SafeMath.sub(SafeMath.sub(withdrawalAmount, ownerShare), partnerShare))) revert();
            if (!partner.send(ownerShare)) revert();
            if (!kingGladiator.send(partnerShare)) revert();
            return true;
        } else {
            recipient = msg.sender;
            withdrawalAmount = _amount;
            if (gladiatorCooldown[msg.sender] < now && gladiatorBalance[recipient] >= withdrawalAmount) {
                gladiatorBalance[recipient] = SafeMath.sub(gladiatorBalance[recipient], withdrawalAmount);
                if (gladiatorBalance[recipient] < 10 finney) {
                    removeGladiator(msg.sender);
                }
            } else {
                return false;
            }
        }
        if (withdrawalAmount == 0) revert();
        if (!msg.sender.send(withdrawalAmount)) revert();
        return true;
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}