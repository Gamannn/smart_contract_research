```solidity
pragma solidity ^0.4.21;

interface ITokenContract {
    function totalSupply() external view returns(uint256);
    function isContributor(address contributor) external view returns(bool);
    function processContribution(
        address contributor,
        uint256 tokensToIssue,
        uint256 bonusTokens
    ) external payable;
}

interface ICrowdsale {
    function canCompleteContribution(address contributor) external returns(bool);
    function completeContribution(address contributor) external;
    function recordContribution(
        address contributor,
        uint256 tokensToIssue,
        uint256 bonusTokens
    ) external payable;
    function getContributionAmount(address contributor) external returns(uint256);
    function finishCrowdsale() external;
}

contract SafeMath {
    function SafeMath() public {}
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(a >= b);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;
    address public pendingOwner;
    
    event OwnershipTransferred(address previousOwner, address newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != owner);
        pendingOwner = newOwner;
    }
    
    function confirmOwnership() public {
        require(msg.sender == pendingOwner);
        OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

contract Crowdsale is Ownable, SafeMath, ICrowdsale {
    bool public crowdsaleFinished = false;
    mapping(address => uint256) public contributions;
    mapping(address => uint256) public tokensToIssue;
    mapping(address => uint256) public bonusTokens;
    ITokenContract public tokenContract;
    
    event RefundPayment(address contributor, uint256 amount);
    event TransferToFund(address contributor, uint256 amount);
    event FinishCrowdsale();
    
    function Crowdsale(address initialOwner) public Ownable(initialOwner) {}
    
    modifier onlyTokenContract() {
        require(msg.sender == address(tokenContract));
        _;
    }
    
    function setTokenContract(address tokenContractAddress) public onlyOwner {
        require(tokenContract == ITokenContract(0));
        tokenContract = ITokenContract(tokenContractAddress);
    }
    
    function finishCrowdsale() external onlyTokenContract {
        crowdsaleFinished = true;
        emit FinishCrowdsale();
    }
    
    function canCompleteContribution(address contributor) external returns(bool) {
        if(crowdsaleFinished) {
            return false;
        }
        if(!tokenContract.isContributor(contributor)) {
            return false;
        }
        if(contributions[contributor] == 0) {
            return false;
        }
        return true;
    }
    
    function getContributionAmount(address contributor) external returns(uint256) {
        return contributions[contributor];
    }
    
    function recordContribution(
        address contributor,
        uint256 tokensToIssueAmount,
        uint256 bonusTokensAmount
    ) external payable onlyTokenContract {
        contributions[contributor] = add(contributions[contributor], msg.value);
        tokensToIssue[contributor] = add(tokensToIssue[contributor], tokensToIssueAmount);
        bonusTokens[contributor] = add(bonusTokens[contributor], bonusTokensAmount);
    }
    
    function completeContribution(address contributor) external {
        require(!crowdsaleFinished);
        require(tokenContract.isContributor(contributor));
        require(contributions[contributor] > 0);
        
        uint256 amount = contributions[contributor];
        uint256 tokens = tokensToIssue[contributor];
        uint256 bonus = bonusTokens[contributor];
        
        contributions[contributor] = 0;
        tokensToIssue[contributor] = 0;
        bonusTokens[contributor] = 0;
        
        tokenContract.processContribution.value(amount)(contributor, tokens, bonus);
        emit TransferToFund(contributor, amount);
    }
    
    function refund(address contributor) public {
        require(crowdsaleFinished);
        require(contributions[contributor] > 0 || tokensToIssue[contributor] > 0);
        
        uint256 amountToRefund = contributions[contributor];
        contributions[contributor] = 0;
        tokensToIssue[contributor] = 0;
        bonusTokens[contributor] = 0;
        
        contributor.transfer(amountToRefund);
        emit RefundPayment(contributor, amountToRefund);
    }
}
```