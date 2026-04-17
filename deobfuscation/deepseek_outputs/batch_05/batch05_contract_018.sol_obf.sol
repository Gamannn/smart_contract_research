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
    
    event LogEtherReceived(address indexed sender, uint amount, uint timestamp);
    event LogUpgrade(address indexed newContract, uint amount, uint timestamp);
    
    function UpgradeableContract(address _owner) {
        owner = _owner;
        EtherReceiver receiver = EtherReceiver(address(this));
        receiver.receiveEther.value(this.balance)();
    }
    
    function receiveEther() payable external {
        emit LogEtherReceived(msg.sender, msg.value, now);
    }
    
    function transferOwnership(address _newOwner) onlyOwner external {
        owner = _newOwner;
        isInitialized = true;
    }
    
    function destroyContract(address _recipient) onlyOwner {
        require(isInitialized);
        selfdestruct(_recipient);
    }
    
    function () payable external {}
}
```