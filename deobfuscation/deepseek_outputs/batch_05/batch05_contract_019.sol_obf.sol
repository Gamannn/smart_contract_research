```solidity
pragma solidity ^0.4.21;

contract EtherReceiver {
    function receiveEther() external payable {}
}

contract UpgradeableContract {
    bool public isInitialized;
    address public owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    event EtherReceived(address indexed sender, uint amount, uint timestamp);
    event Upgraded(address indexed newOwner, uint timestamp, uint blockNumber);
    
    function UpgradeableContract(address _owner) {
        owner = _owner;
    }
    
    function receiveEther() payable external {
        emit EtherReceived(msg.sender, msg.value, now);
    }
    
    function transferOwnership(address newOwner) onlyOwner external {
        owner = newOwner;
    }
    
    function upgrade(address recipient) onlyOwner {
        require(isInitialized);
        selfdestruct(recipient);
    }
    
    function () payable external {}
}

bool[] public boolConstants = [true];

struct ContractState {
    address owner;
    bool isInitialized;
}

ContractState public contractState = ContractState(address(0), false);
```