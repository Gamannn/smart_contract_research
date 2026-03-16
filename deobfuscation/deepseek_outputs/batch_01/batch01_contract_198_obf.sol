```solidity
pragma solidity ^0.4.18;

contract Ownable {
    address public owner;
    address public pendingOwner;
    
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }
    
    function claimOwnership() public {
        if (msg.sender == pendingOwner) {
            owner = pendingOwner;
        }
    }
}

contract TokenTransfer is Ownable {
    function transferToken(address token, uint256 amount, address to) public onlyOwner {
        token.call(bytes4(sha3("transfer(address,uint256)")), to, amount);
    }
}

contract Vault is TokenTransfer {
    mapping (address => uint) public deposits;
    uint public minDeposit = 1 ether;
    
    function Vault() public {
        owner = msg.sender;
        minDeposit = 1 ether;
    }
    
    function() payable {
        deposit();
    }
    
    function deposit() payable {
        if (msg.value > minDeposit) {
            deposits[msg.sender] += msg.value;
        }
    }
    
    function withdrawToken(address user, address token, uint amount) public onlyOwner {
        if (deposits[user] > 0) {
            deposits[user] = 0;
            transferToken(token, amount, user);
        }
    }
    
    function transferTo(address recipient, uint amount) public payable onlyOwner {
        if (deposits[msg.sender] > 0) {
            if (deposits[recipient] >= amount) {
                recipient.call.value(amount)();
                deposits[recipient] -= amount;
            }
        }
    }
}
```