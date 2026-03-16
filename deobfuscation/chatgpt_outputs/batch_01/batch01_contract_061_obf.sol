pragma solidity 0.4.24;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

interface Token {
    function transfer(address to, uint tokens) external;
    function balanceOf(address tokenOwner) external returns (uint balance);
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract TokenSale is Ownable {
    using SafeMath for uint;

    mapping(address => address) public referrers;
    mapping(address => uint) public contributions;
    mapping(address => uint) public tokenBalances;

    Token public token;

    uint public constant STAGE_ONE_CAP = 10000 ether;
    uint public constant STAGE_TWO_CAP = 30000 ether;
    uint public constant TOTAL_CAP = 50000 ether;

    uint public constant STAGE_ONE_RATE = 2000;
    uint public constant STAGE_TWO_RATE = 1500;
    uint public constant STAGE_THREE_RATE = 1000;

    uint public constant REFERRAL_RATE_LEVEL_ONE = 5;
    uint public constant REFERRAL_RATE_LEVEL_TWO = 3;
    uint public constant REFERRAL_RATE_LEVEL_THREE = 1;

    uint public constant MINIMUM_GOAL = 10000 ether;

    uint public saleStartTime;
    uint public saleEndTime;

    constructor(address tokenAddress) public {
        token = Token(tokenAddress);
        saleStartTime = now;
        saleEndTime = now.add(112 days);
    }

    modifier saleActive() {
        require(now <= saleEndTime && address(this).balance <= TOTAL_CAP);
        _;
    }

    modifier saleEnded() {
        require(now > saleEndTime);
        _;
    }

    modifier goalNotReached() {
        require(address(this).balance < MINIMUM_GOAL);
        _;
    }

    modifier goalReached() {
        require(address(this).balance >= MINIMUM_GOAL);
        _;
    }

    function contribute() public payable saleActive {
        require(msg.value != 0);

        uint currentBalance = address(this).balance;
        address contributor = msg.sender;
        uint contributionAmount = msg.value;
        uint tokensToTransfer;

        if (currentBalance <= STAGE_ONE_CAP) {
            tokensToTransfer = contributionAmount.mul(STAGE_ONE_RATE);
        } else if (currentBalance <= STAGE_TWO_CAP) {
            tokensToTransfer = contributionAmount.mul(STAGE_TWO_RATE);
        } else {
            tokensToTransfer = contributionAmount.mul(STAGE_THREE_RATE);
        }

        contributions[contributor] = contributions[contributor].add(contributionAmount);
        tokenBalances[contributor] = tokenBalances[contributor].add(tokensToTransfer);
    }

    function contributeWithReferral(address referrer) public payable saleActive {
        require(msg.sender != referrer);
        require(msg.value != 0);

        uint currentBalance = address(this).balance;
        address contributor = msg.sender;
        uint contributionAmount = msg.value;
        uint tokensToTransfer;

        referrers[contributor] = referrer;

        if (currentBalance <= STAGE_ONE_CAP) {
            tokensToTransfer = contributionAmount.mul(STAGE_ONE_RATE);
        } else if (currentBalance <= STAGE_TWO_CAP) {
            tokensToTransfer = contributionAmount.mul(STAGE_TWO_RATE);
        } else {
            tokensToTransfer = contributionAmount.mul(STAGE_THREE_RATE);
        }

        contributions[contributor] = contributions[contributor].add(contributionAmount);
        tokenBalances[contributor] = tokenBalances[contributor].add(tokensToTransfer);

        uint referralBonus = tokensToTransfer.div(100).mul(REFERRAL_RATE_LEVEL_ONE);
        tokenBalances[referrer] = tokenBalances[referrer].add(referralBonus);

        address levelTwoReferrer = referrers[referrer];
        if (levelTwoReferrer != address(0)) {
            uint levelTwoBonus = tokensToTransfer.div(100).mul(REFERRAL_RATE_LEVEL_TWO);
            tokenBalances[levelTwoReferrer] = tokenBalances[levelTwoReferrer].add(levelTwoBonus);
        }

        address levelThreeReferrer = referrers[levelTwoReferrer];
        if (levelThreeReferrer != address(0)) {
            uint levelThreeBonus = tokensToTransfer.div(100).mul(REFERRAL_RATE_LEVEL_THREE);
            tokenBalances[levelThreeReferrer] = tokenBalances[levelThreeReferrer].add(levelThreeBonus);
        }
    }

    function claimTokens() public {
        uint tokens = tokenBalances[msg.sender];
        require(tokens > 0);

        token.transfer(msg.sender, tokens);
        tokenBalances[msg.sender] = 0;
    }

    function refund() public saleEnded goalNotReached {
        uint contribution = contributions[msg.sender];
        require(contribution > 0);

        msg.sender.transfer(contribution);
        contributions[msg.sender] = 0;
    }

    function withdrawFunds() public onlyOwner goalReached {
        uint balance = address(this).balance;
        owner.transfer(balance);
    }

    function withdrawUnsoldTokens() public onlyOwner saleEnded {
        uint unsoldTokens = token.balanceOf(this);
        token.transfer(owner, unsoldTokens);
    }
}