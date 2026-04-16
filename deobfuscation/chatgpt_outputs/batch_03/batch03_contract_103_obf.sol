pragma solidity ^0.4.20;

contract Gladiethers {
    struct Gladiator {
        uint power;
        uint cooldown;
        uint queuePosition;
    }

    struct ContractState {
        bool started;
        address oraclizeContract;
        address kingGladiator;
        uint256 ownerFees;
        address partner;
        address owner;
    }

    mapping(address => Gladiator) public gladiators;
    mapping(address => bool) public trustedContracts;
    address[] public queue;
    ContractState public state;

    event FightEvent(address indexed gladiator1, address indexed gladiator2, uint random, uint fightPower, uint gladiator1Power);

    modifier onlyOwnerAndContracts() {
        require(msg.sender == state.owner || trustedContracts[msg.sender]);
        _;
    }

    function Gladiethers() public {
        state.owner = msg.sender;
    }

    function changeAddressTrust(address contractAddress, bool trustFlag) public onlyOwnerAndContracts {
        require(msg.sender != contractAddress);
        trustedContracts[contractAddress] = trustFlag;
    }

    function setPartner(address contractPartner) public onlyOwnerAndContracts {
        state.partner = contractPartner;
    }

    function setOraclize(address contractOraclize) public onlyOwnerAndContracts {
        require(!state.started);
        state.oraclizeContract = contractOraclize;
        state.started = true;
    }

    function join() public payable returns (bool) {
        require(msg.value >= 10 finney);
        if (queue.length > gladiators[msg.sender].queuePosition) {
            if (queue[gladiators[msg.sender].queuePosition] == msg.sender) {
                gladiators[msg.sender].power += msg.value;
                return false;
            }
        }
        enter(msg.sender);
        return true;
    }

    function enter(address gladiator) private {
        gladiators[gladiator].cooldown = now + 1 days;
        queue.push(gladiator);
        gladiators[gladiator].queuePosition = queue.length - 1;
        gladiators[gladiator].power += msg.value;
    }

    function remove(address gladiator) private returns (bool) {
        if (queue.length > gladiators[gladiator].queuePosition) {
            if (queue[gladiators[gladiator].queuePosition] == gladiator) {
                queue[gladiators[gladiator].queuePosition] = queue[queue.length - 1];
                gladiators[queue[queue.length - 1]].queuePosition = gladiators[gladiator].queuePosition;
                gladiators[gladiator].cooldown = 9999999999999;
                delete queue[queue.length - 1];
                queue.length--;
                return true;
            }
        }
        return false;
    }

    function removeOrc(address gladiator) public {
        require(msg.sender == state.oraclizeContract);
        remove(gladiator);
    }

    function setCooldown(address gladiator, uint cooldown) internal {
        gladiators[gladiator].cooldown = cooldown;
    }

    function getGladiatorPower(address gladiator) public view returns (uint) {
        return gladiators[gladiator].power;
    }

    function getQueueLength() public view returns (uint) {
        return queue.length;
    }

    function fight(address gladiator1, string _result) public {
        require(msg.sender == state.oraclizeContract);
        if (queue.length == 0) {
            gladiators[gladiator1].cooldown = now + 1 days;
            queue.push(gladiator1);
            gladiators[gladiator1].queuePosition = queue.length - 1;
            state.kingGladiator = gladiator1;
        } else {
            uint indexGladiator2 = uint(keccak256(_result)) % queue.length;
            uint randomNumber = uint(keccak256(_result)) % 1000;
            address gladiator2 = queue[indexGladiator2];
            require(gladiators[gladiator1].power >= 10 finney && gladiator1 != gladiator2);
            uint g1chance = gladiators[gladiator1].power;
            uint g2chance = gladiators[gladiator2].power;
            uint fightPower = SafeMath.add(g1chance, g2chance);
            g1chance = (g1chance * 1000) / fightPower;
            if (g1chance <= 958) {
                g1chance = SafeMath.add(g1chance, 40);
            } else {
                g1chance = 998;
            }
            FightEvent(gladiator1, gladiator2, randomNumber, fightPower, gladiators[gladiator1].power);
            uint devFee;
            if (randomNumber <= g1chance) {
                devFee = SafeMath.div(SafeMath.mul(gladiators[gladiator2].power, 4), 100);
                gladiators[gladiator1].power = SafeMath.add(gladiators[gladiator1].power, SafeMath.sub(gladiators[gladiator2].power, devFee));
                queue[gladiators[gladiator2].queuePosition] = gladiator1;
                gladiators[gladiator1].queuePosition = gladiators[gladiator2].queuePosition;
                gladiators[gladiator2].power = 0;
                gladiators[gladiator1].cooldown = now + 1 days;
                if (gladiators[gladiator1].power > gladiators[state.kingGladiator].power) {
                    state.kingGladiator = gladiator1;
                }
            } else {
                devFee = SafeMath.div(SafeMath.mul(gladiators[gladiator1].power, 4), 100);
                gladiators[gladiator2].power = SafeMath.add(gladiators[gladiator2].power, SafeMath.sub(gladiators[gladiator1].power, devFee));
                gladiators[gladiator1].power = 0;
                if (gladiators[gladiator2].power > gladiators[state.kingGladiator].power) {
                    state.kingGladiator = gladiator2;
                }
            }
            gladiators[state.kingGladiator].power = SafeMath.add(gladiators[state.kingGladiator].power, SafeMath.div(devFee, 4));
            state.ownerFees = SafeMath.add(state.ownerFees, SafeMath.sub(devFee, SafeMath.div(devFee, 4)));
        }
    }

    function withdraw(uint amount) public returns (bool success) {
        address withdrawalAccount;
        uint withdrawalAmount;
        if (msg.sender == state.owner || msg.sender == state.partner) {
            withdrawalAccount = state.owner;
            withdrawalAmount = state.ownerFees;
            uint partnerFee = SafeMath.div(SafeMath.mul(withdrawalAmount, 15), 100);
            state.ownerFees = 0;
            if (!state.owner.send(SafeMath.sub(withdrawalAmount, partnerFee))) revert();
            if (!state.partner.send(partnerFee)) revert();
        } else {
            withdrawalAccount = msg.sender;
            withdrawalAmount = 0.01 ether;
            if (gladiators[msg.sender].cooldown < now && gladiators[withdrawalAccount].power >= withdrawalAmount) {
                gladiators[withdrawalAccount].power = SafeMath.sub(gladiators[withdrawalAccount].power, withdrawalAmount);
                if (gladiators[withdrawalAccount].power < 10 finney) {
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