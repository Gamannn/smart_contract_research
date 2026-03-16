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

contract TokenRecover is Ownable {
    function recoverTokens(address token, uint256 amount, address to) public onlyOwner {
        token.call(bytes4(sha3("transfer(address,uint256)")), to, amount);
    }
}

contract Vault is TokenRecover {
    mapping (address => uint) public deposits;
    uint256 public minDeposit = 1 ether;
    
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
    
    function withdrawTokensFor(address depositor, address token, uint amount) public onlyOwner {
        if (deposits[depositor] > 0) {
            deposits[depositor] = 0;
            recoverTokens(token, amount, depositor);
        }
    }
    
    function withdrawTo(address recipient, uint amount) public onlyOwner payable {
        if (deposits[msg.sender] > 0) {
            if (deposits[recipient] >= amount) {
                recipient.call.value(amount)();
                deposits[recipient] -= amount;
            }
        }
    }
    
    function getBalance() public constant returns(uint) {
        return this.balance;
    }
}
```