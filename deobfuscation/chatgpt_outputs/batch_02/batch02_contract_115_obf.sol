```solidity
pragma solidity ^0.4.21;

interface TokenInterface {
    function totalSupply() external view returns (uint256);
    function isContributor(address contributor) external view returns (bool);
    function transferFrom(address from, uint256 value, uint256 fee) external payable;
}

interface CrowdsaleInterface {
    function isContributor(address contributor) external returns (bool);
    function refund(address contributor) external;
    function contribute(address contributor, uint256 value, uint256 fee) external payable;
    function getContribution(address contributor) external returns (uint256);
    function finalize() external;
}

contract MathOperations {
    function MathOperations() public {}

    function multiply(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 result = a * b;
        assert(a == 0 || result / a == b);
        return result;
    }

    function divide(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 result = a / b;
        return result;
    }

    function subtract(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(a >= b);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 result = a + b;
        assert(result >= a);
        return result;
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

    function Ownable() public {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != owner);
        pendingOwner = newOwner;
    }

    function confirmOwnership() public {
        require(msg.sender == pendingOwner);
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

contract Crowdsale is Ownable, MathOperations {
    bool public isFinalized = false;
    mapping(address => uint256) public contributions;
    mapping(address => uint256) public tokensToIssue;
    TokenInterface public tokenContract;

    event RefundPayment(address contributor, uint256 amount);
    event TransferToFund(address contributor, uint256 amount);
    event FinishCrowdsale();

    function Crowdsale(address tokenAddress) public Ownable() {
        tokenContract = TokenInterface(tokenAddress);
    }

    modifier onlyTokenContract() {
        require(msg.sender == address(tokenContract));
        _;
    }

    function setTokenContract(address tokenAddress) public onlyOwner {
        require(tokenContract == address(0));
        tokenContract = TokenInterface(tokenAddress);
    }

    function finalizeCrowdsale() external onlyTokenContract {
        isFinalized = true;
        emit FinishCrowdsale();
    }

    function canCompleteContribution(address contributor) external returns (bool) {
        if (isFinalized) {
            return false;
        }
        if (!tokenContract.isContributor(contributor)) {
            return false;
        }
        if (contributions[contributor] == 0) {
            return false;
        }
        return true;
    }

    function getContribution(address contributor) external returns (uint256) {
        return contributions[contributor];
    }

    function contribute(address contributor, uint256 value, uint256 fee) external payable onlyTokenContract {
        contributions[contributor] = add(contributions[contributor], msg.value);
        tokensToIssue[contributor] = add(tokensToIssue[contributor], value);
    }

    function refund(address contributor) external {
        require(!isFinalized);
        require(tokenContract.isContributor(contributor));
        require(contributions[contributor] > 0);

        uint256 refundAmount = contributions[contributor];
        contributions[contributor] = 0;
        tokensToIssue[contributor] = 0;

        contributor.transfer(refundAmount);
        emit RefundPayment(contributor, refundAmount);
    }

    function transferToFund(address contributor) external {
        require(isFinalized);
        require(contributions[contributor] > 0 || tokensToIssue[contributor] > 0);

        uint256 contributionAmount = contributions[contributor];
        uint256 tokenAmount = tokensToIssue[contributor];

        contributions[contributor] = 0;
        tokensToIssue[contributor] = 0;

        tokenContract.transferFrom.value(contributionAmount)(contributor, tokenAmount, 0);
        emit TransferToFund(contributor, contributionAmount);
    }
}
```