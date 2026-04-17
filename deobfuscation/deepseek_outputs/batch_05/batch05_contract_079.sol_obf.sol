```solidity
pragma solidity ^0.4.20;

contract GladiatorGame {
    address public owner;
    address public partner;
    address public oracleContract;
    address public kingGladiator;
    address public founder;
    
    mapping (address => uint) public gladiatorPower;
    mapping (address => uint) public gladiatorCooldown;
    mapping (address => uint) public gladiatorToQueuePosition;
    mapping (address => bool) public authorized;
    
    uint public totalFees;
    bool public started;
    
    address[] public gladiatorQueue;
    
    event FightEvent(
        address indexed attacker,
        address indexed defender,
        uint randomRoll,
        uint attackPower,
        uint defenderPower
    );
    
    modifier onlyAuthorized() {
        require(msg.sender == owner || authorized[msg.sender]);
        _;
    }
    
    function GladiatorGame() public {
        owner = msg.sender;
    }
    
    function setAuthorized(address _address, bool _status) public onlyAuthorized() {
        require(msg.sender != _address);
        authorized[_address] = _status;
    }
    
    function setPartner(address _partner) public onlyAuthorized() {
        partner = _partner;
    }
    
    function setOracleContract(address _oracle) public onlyAuthorized() {
        require(!started);
        oracleContract = _oracle;
        started = true;
    }
    
    function joinArena() public payable returns (bool) {
        require(msg.value >= 10 finney && gladiatorCooldown[msg.sender] < 9999999999999);
        
        if(gladiatorQueue.length > gladiatorToQueuePosition[msg.sender]) {
            if(gladiatorQueue[gladiatorToQueuePosition[msg.sender]] == msg.sender) {
                gladiatorPower[msg.sender] += msg.value;
                checkKingGladiator(msg.sender);
                return false;
            }
        }
        
        addGladiator(msg.sender);
        return true;
    }
    
    function addGladiator(address _gladiator) private {
        gladiatorCooldown[_gladiator] = now + 1 days;
        gladiatorQueue.push(_gladiator);
        gladiatorToQueuePosition[_gladiator] = gladiatorQueue.length - 1;
        gladiatorPower[_gladiator] += msg.value;
        checkKingGladiator(_gladiator);
    }
    
    function checkKingGladiator(address _gladiator) internal {
        if(gladiatorPower[_gladiator] > gladiatorPower[kingGladiator] || now < 1529532000) {
            kingGladiator = _gladiator;
        }
    }
    
    function removeFromQueue(address _gladiator) private returns(bool) {
        if(gladiatorQueue.length > gladiatorToQueuePosition[_gladiator]) {
            if(gladiatorQueue[gladiatorToQueuePosition[_gladiator]] == _gladiator) {
                gladiatorQueue[gladiatorToQueuePosition[_gladiator]] = gladiatorQueue[gladiatorQueue.length - 1];
                gladiatorToQueuePosition[gladiatorQueue[gladiatorQueue.length - 1]] = gladiatorToQueuePosition[_gladiator];
                gladiatorCooldown[_gladiator] = 9999999999999;
                delete gladiatorQueue[gladiatorQueue.length - 1];
                gladiatorQueue.length = gladiatorQueue.length - 1;
                return true;
            }
        }
        return false;
    }
    
    function removeGladiator(address _gladiator) public {
        require(msg.sender == founder);
        removeFromQueue(_gladiator);
    }
    
    function setCooldown(address _gladiator, uint _cooldown) internal {
        gladiatorCooldown[_gladiator] = _cooldown;
    }
    
    function getPower(address _gladiator) public view returns (uint) {
        return gladiatorPower[_gladiator];
    }
    
    function getQueueLength() public view returns (uint) {
        return gladiatorQueue.length;
    }
    
    function getCooldown(address _gladiator) public view returns (uint) {
        return gladiatorCooldown[_gladiator];
    }
    
    function fight(address _attacker, string _seed) public {
        require(msg.sender == founder);
        
        if(gladiatorQueue.length == 0) {
            gladiatorCooldown[_attacker] = now + 1 days;
            checkKingGladiator(_attacker);
            gladiatorToQueuePosition[_attacker] = gladiatorQueue.length - 1;
            kingGladiator = _attacker;
        } else {
            uint defenderIndex = uint(sha3(_seed)) % gladiatorQueue.length;
            uint randomRoll = uint(sha3(_seed)) % 1000;
            address defender = gladiatorQueue[defenderIndex];
            
            require(gladiatorPower[_attacker] >= 10 finney && _attacker != defender);
            
            uint attackPower = gladiatorPower[_attacker];
            uint defenderPower = gladiatorPower[defender];
            uint attackValue = SafeMath.div(attackPower * 1000, defenderPower);
            
            if(attackValue <= 958) {
                attackValue = SafeMath.mul(attackValue, 40);
            } else {
                attackValue = 998;
            }
            
            emit FightEvent(_attacker, defender, randomRoll, attackPower, defenderPower);
            
            uint feeAmount;
            
            if(randomRoll <= attackValue) {
                feeAmount = SafeMath.div(SafeMath.mul(gladiatorPower[defender], 5), 100);
                gladiatorPower[_attacker] = SafeMath.add(
                    gladiatorPower[_attacker],
                    SafeMath.sub(gladiatorPower[defender], feeAmount)
                );
                
                gladiatorQueue[gladiatorToQueuePosition[defender]] = _attacker;
                gladiatorToQueuePosition[_attacker] = gladiatorToQueuePosition[defender];
                gladiatorPower[defender] = 0;
                gladiatorCooldown[_attacker] = now + 1 days;
                
                if(gladiatorPower[_attacker] > gladiatorPower[kingGladiator]) {
                    kingGladiator = _attacker;
                }
            } else {
                feeAmount = SafeMath.div(SafeMath.mul(gladiatorPower[_attacker], 5), 100);
                gladiatorPower[defender] = SafeMath.add(
                    gladiatorPower[defender],
                    SafeMath.sub(gladiatorPower[_attacker], feeAmount)
                );
                gladiatorPower[_attacker] = 0;
                removeFromQueue(_attacker);
                
                if(gladiatorPower[defender] > gladiatorPower[kingGladiator]) {
                    kingGladiator = defender;
                }
            }
            
            founder.transfer(SafeMath.div(feeAmount, 5));
            totalFees = SafeMath.add(
                totalFees,
                SafeMath.sub(feeAmount, SafeMath.div(feeAmount, 5))
            );
        }
    }
    
    function withdraw(uint _amount) public returns (bool success) {
        address receiver;
        uint withdrawalAmount;
        
        if (msg.sender == owner || msg.sender == founder) {
            receiver = owner;
            withdrawalAmount = totalFees;
            uint partnerShare = SafeMath.div(withdrawalAmount, 4);
            uint founderShare = SafeMath.div(SafeMath.mul(SafeMath.sub(withdrawalAmount, partnerShare), 15), 100);
            totalFees = 0;
            
            if (!owner.send(SafeMath.sub(SafeMath.sub(withdrawalAmount, founderShare), partnerShare))) revert();
            if (!partner.send(founderShare)) revert();
            if (!kingGladiator.send(partnerShare)) revert();
            return true;
        } else {
            receiver = msg.sender;
            withdrawalAmount = _amount;
            
            if(gladiatorCooldown[msg.sender] < now && gladiatorPower[receiver] >= withdrawalAmount) {
                gladiatorPower[receiver] = SafeMath.sub(gladiatorPower[receiver], withdrawalAmount);
                
                if(gladiatorPower[receiver] < 10 finney) {
                    removeFromQueue(msg.sender);
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
```