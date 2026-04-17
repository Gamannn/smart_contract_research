```solidity
pragma solidity ^0.4.18;

interface Token {
    function transfer(address to, uint256 value) public;
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Crowdsale {
    using SafeMath for uint256;
    
    address public owner;
    uint256 public fundingGoal;
    uint256 public amountRaised;
    uint256 public deadline;
    
    Token public rewardToken;
    mapping(address => uint256) public balanceOf;
    
    event FundTransfer(address backer, uint256 amount, bool isContribution);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function Crowdsale(
        address _owner,
        uint256 _fundingGoal,
        uint256 _deadline,
        address _rewardToken
    ) public {
        owner = _owner;
        fundingGoal = _fundingGoal;
        deadline = _deadline;
        rewardToken = Token(_rewardToken);
    }
    
    function () public payable {
        uint256 amount = msg.value;
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
        amountRaised = amountRaised.add(amount);
        
        uint256 tokenAmount = amount.mul(fundingGoal).div(amountRaised);
        rewardToken.transfer(msg.sender, tokenAmount);
        
        FundTransfer(msg.sender, amount, true);
    }
    
    function withdrawFunds() public onlyOwner {
        uint256 amount = amountRaised;
        amountRaised = 0;
        owner.transfer(amount);
        FundTransfer(owner, amount, false);
    }
    
    function kill() public onlyOwner {
        selfdestruct(owner);
    }
    
    function killAndSend(address recipient) public onlyOwner {
        selfdestruct(recipient);
    }
}
```