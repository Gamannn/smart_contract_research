```solidity
pragma solidity ^0.4.0;

contract InvestmentContract {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public lastBlock;
    
    address public owner;
    uint256 public totalFunds;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function InvestmentContract() public {
        owner = msg.sender;
    }
    
    function () external payable {
        if (balances[msg.sender] != 0) {
            uint256 reward = balances[msg.sender] * 6 / 100 * (block.number - lastBlock[msg.sender]) / 5900;
            msg.sender.transfer(reward);
        }
        
        lastBlock[msg.sender] = block.number;
        balances[msg.sender] += msg.value;
        totalFunds += msg.value;
    }
    
    function setOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }
    
    function withdrawFunds(address recipient, uint256 amount) public payable onlyOwner {
        recipient.transfer(amount);
        totalFunds -= amount;
    }
    
    function getTotalFunds() public constant returns(uint256) {
        return totalFunds;
    }
    
    function getOwner() public constant onlyOwner returns(address) {
        return owner;
    }
}
```