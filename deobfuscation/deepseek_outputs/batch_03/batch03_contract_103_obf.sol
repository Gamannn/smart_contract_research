```solidity
pragma solidity ^0.4.20;

contract Gladiethers {
    address public owner;
    address public partner;
    address public oraclizeContract;
    address public kingGladiator;
    
    uint256 public ownerFees;
    bool public started;
    
    mapping(address => uint256) public gladiatorToPower;
    mapping(address => uint256) public gladiatorToCooldown;
    mapping(address => uint256) public gladiatorToQueuePosition;
    mapping(address => bool) public trustedContracts;
    
    address[] public queue;
    
    event FightEvent(
        address indexed gladiator1,
        address indexed gladiator2,
        uint256 random,
        uint256 fightPower,
        uint256 gladiator1Power
    );
    
    modifier onlyOwnerAndContracts() {
        require(msg.sender == owner || trustedContracts[msg.sender]);
        _;
    }
    
    function Gladiethers() public {
        owner = msg.sender;
    }
    
    function changeAddressTrust(address contractAddress, bool trustFlag) public onlyOwnerAndContracts() {
        require(msg.sender != contractAddress);
        trustedContracts[contractAddress] = trustFlag;
    }
    
    function setPartner(address contractPartner) public onlyOwnerAndContracts() {
        partner = contractPartner;
    }
    
    function setOraclize(address contractOraclize) public onlyOwnerAndContracts() {
        require(!started);
        oraclizeContract = contractOraclize;
        started = true;
    }
    
    function join() public payable returns (bool) {
        require(msg.value >= 10 finney);
        
        if (queue.length > gladiatorToQueuePosition[msg.sender]) {
            if (queue[gladiatorToQueuePosition[msg.sender]] == msg.sender) {
                gladiatorToPower[msg.sender] += msg.value;
                return false;
            }
        }
        
        enter(msg.sender);
        return true;
    }
    
    function enter(address gladiator) private {
        gladiatorToCooldown[gladiator] = now + 1 days;
        queue.push(gladiator);
        gladiatorToQueuePosition[gladiator] = queue.length - 1;
        gladiatorToPower[gladiator] += msg.value;
    }
    
    function remove(address gladiator) private returns (bool) {
        if (queue.length > gladiatorToQueuePosition[gladiator]) {
            if (queue[gladiatorToQueuePosition[gladiator]] == gladiator) {
                queue[gladiatorToQueuePosition[gladiator]] = queue[queue.length - 1];
                gladiatorToQueuePosition[queue[queue.length - 1]] = gladiatorToQueuePosition[gladiator];
                gladiatorToCooldown[gladiator] = 9999999999999;
                delete queue[queue.length - 1];
                queue.length--;
                return true;
            }
        }
        return false;
    }
    
    function removeOrc(address gladiator) public {
        require(msg.sender == oraclizeContract);
        remove(gladiator);
    }
    
    function setCooldown(address gladiator, uint256 cooldown) internal {
        gladiatorToCooldown[gladiator] = cooldown;
    }
    
    function getGladiatorPower(address gladiator) public view returns (uint256) {
        return gladiatorToPower[gladiator];
    }
    
    function getQueueLength() public view returns (uint256) {
        return queue.length;
    }
    
    function fight(address gladiator1, string memory result) public {
        require(msg.sender == oraclizeContract);
        
        if (queue.length == 0) {
            gladiatorToCooldown[gladiator1] = now + 1 days;
            queue.push(gladiator1);
            gladiatorToQueuePosition[gladiator1] = queue.length - 1;
            kingGladiator = gladiator1;
        } else {
            uint256 indexGladiator2 = uint256(sha3(result)) % queue.length;
            uint256 randomNumber = uint256(sha3(result)) % 1000;
            address gladiator2 = queue[indexGladiator2];
            
            require(gladiatorToPower[gladiator1] >= 10 finney && gladiator1 != gladiator2);
            
            uint256 gladiator1Chance = gladiatorToPower[gladiator1];
            uint256 gladiator2Chance = gladiatorToPower[gladiator2];
            uint256 fightPower = SafeMath.add(gladiator1Chance, gladiator2Chance);
            
            gladiator1Chance = (gladiator1Chance * 1000) / fightPower;
            
            if (gladiator1Chance <= 958) {
                gladiator1Chance = SafeMath.add(gladiator1Chance, 40);
            } else {
                gladiator1Chance = 998;
            }
            
            FightEvent(
                gladiator1,
                gladiator2,
                randomNumber,
                fightPower,
                gladiatorToPower[gladiator1]
            );
            
            uint256 devFee;
            
            if (randomNumber <= gladiator1Chance) {
                devFee = SafeMath.div(SafeMath.mul(gladiatorToPower[gladiator2], 4), 100);
                gladiatorToPower[gladiator1] = SafeMath.add(
                    gladiatorToPower[gladiator1],
                    SafeMath.sub(gladiatorToPower[gladiator2], devFee)
                );
                
                queue[gladiatorToQueuePosition[gladiator2]] = gladiator1;
                gladiatorToQueuePosition[gladiator1] = gladiatorToQueuePosition[gladiator2];
                gladiatorToPower[gladiator2] = 0;
                gladiatorToCooldown[gladiator1] = now + 1 days;
                
                if (gladiatorToPower[gladiator1] > gladiatorToPower[kingGladiator]) {
                    kingGladiator = gladiator1;
                }
            } else {
                devFee = SafeMath.div(SafeMath.mul(gladiatorToPower[gladiator1], 4), 100);
                gladiatorToPower[gladiator2] = SafeMath.add(
                    gladiatorToPower[gladiator2],
                    SafeMath.sub(gladiatorToPower[gladiator1], devFee)
                );
                gladiatorToPower[gladiator1] = 0;
                
                if (gladiatorToPower[gladiator2] > gladiatorToPower[kingGladiator]) {
                    kingGladiator = gladiator2;
                }
            }
            
            gladiatorToPower[kingGladiator] = SafeMath.add(
                gladiatorToPower[kingGladiator],
                SafeMath.div(SafeMath.mul(gladiatorToPower[kingGladiator], 4), 100)
            );
            
            ownerFees = SafeMath.add(
                ownerFees,
                SafeMath.sub(devFee, SafeMath.div(SafeMath.mul(devFee, 15), 100))
            );
        }
    }
    
    function withdraw(uint256 amount) public returns (bool success) {
        address withdrawalAccount;
        uint256 withdrawalAmount;
        
        if (msg.sender == owner || msg.sender == partner) {
            withdrawalAccount = owner;
            withdrawalAmount = ownerFees;
            uint256 partnerFee = SafeMath.div(SafeMath.mul(withdrawalAmount, 15), 100);
            
            ownerFees = 0;
            
            if (!owner.send(SafeMath.sub(withdrawalAmount, partnerFee))) revert();
            if (!partner.send(partnerFee)) revert();
            
            return true;
        } else {
            withdrawalAccount = msg.sender;
            withdrawalAmount = amount;
            
            if (gladiatorToCooldown[msg.sender] < now && gladiatorToPower[withdrawalAccount] >= withdrawalAmount) {
                gladiatorToPower[withdrawalAccount] = SafeMath.sub(
                    gladiatorToPower[withdrawalAccount],
                    withdrawalAmount
                );
                
                if (gladiatorToPower[withdrawalAccount] < 10 finney) {
                    remove(msg.sender);
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