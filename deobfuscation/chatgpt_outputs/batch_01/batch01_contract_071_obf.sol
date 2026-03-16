pragma solidity 0.5.8;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external returns (uint);
    function balanceOf(address account) external returns (uint);
    function allowance(address owner, address spender) external returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract AdminControl {
    mapping(address => uint8) public adminLevels;

    constructor() internal {
        adminLevels[0x7a3a57c620fA468b304b5d1826CDcDe28E2b2b98] = 2;
        emit AdminshipUpdated(0x7a3a57c620fA468b304b5d1826CDcDe28E2b2b98, 2);
    }

    modifier onlyAdmin(uint8 level) {
        require(adminLevels[msg.sender] >= level, "You don't have rights for this transaction");
        _;
    }

    function updateAdmin(address admin, uint8 level) public onlyAdmin(2) {
        require(admin != address(0), "Address cannot be zero");
        adminLevels[admin] = level;
        emit AdminshipUpdated(admin, level);
    }

    event AdminshipUpdated(address admin, uint8 level);
}

contract Crowdsale is AdminControl {
    using SafeMath for uint256;

    enum State { OnSale, Successful }
    State public saleState = State.OnSale;

    uint256 public startTime = now;
    uint256 public endTime;
    IERC20 public token;
    uint256 public totalRaised;
    uint256 public totalTokensSold;
    uint256 public totalBonusTokens;
    uint256 public constant tokenPrice = 2941;
    uint256 public constant softCap = 52500000 * 1e18;
    uint256 public constant hardCap = 420000000 * 1e18;
    uint256 public constant minContribution = 3000000 * 1e18;

    mapping(address => uint256) public contributions;
    mapping(address => uint256) public tokensPurchased;
    mapping(address => uint256) public bonusTokens;

    address public admin;
    address payable public beneficiary;
    string public version = '1';

    event LogFundingInitialized(address indexed admin);
    event LogFundingReceived(address indexed contributor, uint amount, uint totalRaised);
    event LogContributorsPayout(address indexed contributor, uint amount);
    event LogBeneficiaryPaid(address indexed beneficiary);
    event LogFundingSuccessful(uint totalRaised);

    modifier onlyWhileOpen() {
        require(saleState != State.Successful, "Sale has ended");
        _;
    }

    constructor(IERC20 _token) public {
        token = _token;
        admin = 0x7a3a57c620fA468b304b5d1826CDcDe28E2b2b98;
        beneficiary = 0x8605409D35f707714A83410BE9C8025dcefa9faC;
        emit LogFundingInitialized(admin);
    }

    function contribute(address referrer, uint256 referrerBonus) public onlyWhileOpen payable {
        address contributor;
        uint256 contributionAmount;
        uint256 tokensToPurchase;
        uint256 bonusTokensToPurchase;
        uint256 remainingTokens;
        uint256 availableTokens;
        uint256 referrerTokens;

        if (referrer != address(0) && adminLevels[msg.sender] >= 1) {
            contributor = referrer;
            contributionAmount = referrerBonus;
        } else {
            contributor = msg.sender;
            contributionAmount = msg.value;
            contributions[msg.sender] = contributions[msg.sender].add(msg.value);
        }

        require(contributionAmount >= 0.1 ether, "Not enough value for this transaction");

        totalRaised = totalRaised.add(contributionAmount);
        tokensToPurchase = contributionAmount.div(tokenPrice);
        referrerTokens = contributionAmount.div(tokenPrice);

        if (referrerTokens > 0 && totalTokensSold < softCap) {
            availableTokens = softCap.sub(totalTokensSold);
            if (referrerTokens < availableTokens) {
                bonusTokensToPurchase = referrerTokens.div(4).mul(10);
                totalTokensSold = totalTokensSold.add(referrerTokens);
                referrerTokens = 0;
                bonusTokensToPurchase = 0;
                availableTokens = 0;
            } else {
                bonusTokensToPurchase = availableTokens.div(4).mul(10);
                totalTokensSold = totalTokensSold.add(availableTokens);
                referrerTokens = referrerTokens.sub(availableTokens);
                bonusTokensToPurchase = 0;
                availableTokens = 0;
            }
        }

        if (referrerTokens > 0 && totalTokensSold >= softCap && totalTokensSold < softCap.div(2)) {
            availableTokens = softCap.div(2).sub(totalTokensSold);
            if (referrerTokens < availableTokens) {
                bonusTokensToPurchase = referrerTokens.div(35).mul(100);
                totalTokensSold = totalTokensSold.add(referrerTokens);
                referrerTokens = 0;
                bonusTokensToPurchase = 0;
                availableTokens = 0;
            } else {
                bonusTokensToPurchase = availableTokens.div(35).mul(100);
                totalTokensSold = totalTokensSold.add(availableTokens);
                referrerTokens = referrerTokens.sub(availableTokens);
                bonusTokensToPurchase = 0;
                availableTokens = 0;
            }
        }

        if (referrerTokens > 0 && totalTokensSold >= softCap.div(2) && totalTokensSold < softCap.div(3)) {
            availableTokens = softCap.div(3).sub(totalTokensSold);
            if (referrerTokens < availableTokens) {
                bonusTokensToPurchase = referrerTokens.div(3).mul(10);
                totalTokensSold = totalTokensSold.add(referrerTokens);
                referrerTokens = 0;
                bonusTokensToPurchase = 0;
                availableTokens = 0;
            } else {
                bonusTokensToPurchase = availableTokens.div(3).mul(10);
                totalTokensSold = totalTokensSold.add(availableTokens);
                referrerTokens = referrerTokens.sub(availableTokens);
                bonusTokensToPurchase = 0;
                availableTokens = 0;
            }
        }

        if (referrerTokens > 0 && totalTokensSold >= softCap.div(3) && totalTokensSold < softCap.div(4)) {
            availableTokens = softCap.div(4).sub(totalTokensSold);
            if (referrerTokens < availableTokens) {
                bonusTokensToPurchase = referrerTokens.div(2).mul(10);
                totalTokensSold = totalTokensSold.add(referrerTokens);
                referrerTokens = 0;
                bonusTokensToPurchase = 0;
                availableTokens = 0;
            } else {
                bonusTokensToPurchase = availableTokens.div(2).mul(10);
                totalTokensSold = totalTokensSold.add(availableTokens);
                referrerTokens = referrerTokens.sub(availableTokens);
                bonusTokensToPurchase = 0;
                availableTokens = 0;
            }
        }

        if (referrerTokens > 0 && totalTokensSold >= softCap.div(4) && totalTokensSold < softCap.div(5)) {
            availableTokens = softCap.div(5).sub(totalTokensSold);
            if (referrerTokens < availableTokens) {
                bonusTokensToPurchase = referrerTokens.div(5).mul(100);
                totalTokensSold = totalTokensSold.add(referrerTokens);
                referrerTokens = 0;
                bonusTokensToPurchase = 0;
                availableTokens = 0;
            } else {
                bonusTokensToPurchase = availableTokens.div(5).mul(100);
                totalTokensSold = totalTokensSold.add(availableTokens);
                referrerTokens = referrerTokens.sub(availableTokens);
                bonusTokensToPurchase = 0;
                availableTokens = 0;
            }
        }

        totalTokensSold = totalTokensSold.add(referrerTokens);
        totalBonusTokens = totalBonusTokens.add(bonusTokensToPurchase);

        token.transfer(contributor, tokensToPurchase.add(bonusTokensToPurchase));
        tokensPurchased[contributor] = tokensPurchased[contributor].add(tokensToPurchase);
        bonusTokens[contributor] = bonusTokens[contributor].add(bonusTokensToPurchase);

        emit LogFundingReceived(contributor, contributionAmount, totalRaised);

        checkIfFundingCompleteOrExpired();
    }

    function checkIfFundingCompleteOrExpired() public {
        if (totalTokensSold.add(totalBonusTokens) > hardCap.div(tokenPrice)) {
            saleState = State.Successful;
            endTime = now;
            emit LogFundingSuccessful(totalRaised);
            payout();
        }
    }

    function payout() public onlyAdmin(2) {
        require(totalTokensSold >= minContribution, "Too early to retrieve funds");
        beneficiary.transfer(address(this).balance);
    }

    function refund() public onlyWhileOpen {
        require(totalTokensSold >= minContribution, "Too early to retrieve funds");
        require(contributions[msg.sender] > 0, "No ETH to refund");
        require(token.transferFrom(msg.sender, address(this), tokensPurchased[msg.sender].add(bonusTokens[msg.sender])), "Cannot retrieve tokens");

        totalTokensSold = totalTokensSold.sub(tokensPurchased[msg.sender]);
        totalBonusTokens = totalBonusTokens.sub(bonusTokens[msg.sender]);

        tokensPurchased[msg.sender] = 0;
        bonusTokens[msg.sender] = 0;

        uint256 refundAmount = contributions[msg.sender];
        contributions[msg.sender] = 0;
        msg.sender.transfer(refundAmount);
    }

    function payout() public {
        require(saleState == State.Successful, "Wrong Stage");
        uint256 tokenBalance = token.balanceOf(address(this));
        require(token.transfer(beneficiary, tokenBalance), "Transfer could not be made");
        beneficiary.transfer(address(this).balance);
        emit LogBeneficiaryPaid(beneficiary);
    }

    function() external payable {
        contribute(address(0), 0);
    }
}