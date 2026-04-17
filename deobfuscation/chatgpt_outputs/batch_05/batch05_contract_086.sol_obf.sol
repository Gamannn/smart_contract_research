```solidity
pragma solidity 0.4.25;

library SafeMath {
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
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract InvestmentContract {
    using SafeMath for uint256;

    address public owner;
    address public stabilizationFundAddress = 0x0223f73a53a549B8F5a9661aDB4cD9Dd4E25BEDa;
    uint public totalInvested;
    uint public totalWithdrawn;
    uint public totalInvestors;
    uint public lastPaymentTime;

    struct Investor {
        address addr;
        uint investedAmount;
        uint withdrawnAmount;
        uint lastWithdrawTime;
        bool exists;
    }

    mapping(address => Investor) public investors;
    mapping(address => uint) private depositTimestamps;

    event NewInvestor(address indexed investor, uint amount);
    event NewDeposit(address indexed investor, uint amount);
    event Withdraw(address indexed investor, uint amount);
    event ReceivedFromStabilizationFund(uint amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this method");
        _;
    }

    modifier hasDeposit() {
        require(investors[msg.sender].investedAmount > 0, "Deposit not found");
        _;
    }

    modifier canWithdraw() {
        require(now >= depositTimestamps[msg.sender].add(1 days), "Too fast payout request");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function invest() public payable {
        require(msg.value > 0, "Investment must be greater than 0");

        if (investors[msg.sender].exists == false) {
            investors[msg.sender] = Investor(msg.sender, msg.value, 0, now, true);
            totalInvestors = totalInvestors.add(1);
            emit NewInvestor(msg.sender, msg.value);
        } else {
            investors[msg.sender].investedAmount = investors[msg.sender].investedAmount.add(msg.value);
        }

        depositTimestamps[msg.sender] = now;
        totalInvested = totalInvested.add(msg.value);

        emit NewDeposit(msg.sender, msg.value);
    }

    function withdraw() public hasDeposit canWithdraw {
        uint amount = calculateDividends(msg.sender);
        require(amount > 0, "No dividends available");

        investors[msg.sender].withdrawnAmount = investors[msg.sender].withdrawnAmount.add(amount);
        investors[msg.sender].lastWithdrawTime = now;
        totalWithdrawn = totalWithdrawn.add(amount);
        lastPaymentTime = now;

        msg.sender.transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    function calculateDividends(address investor) internal view returns (uint) {
        uint investedAmount = investors[investor].investedAmount;
        uint daysPassed = now.sub(depositTimestamps[investor]).div(1 days);
        uint dailyInterest = 5; // 0.5% daily interest
        uint dividends = investedAmount.mul(dailyInterest).div(1000).mul(daysPassed);
        return dividends;
    }

    function() external payable {
        if (msg.sender != stabilizationFundAddress) {
            invest();
        } else {
            emit ReceivedFromStabilizationFund(msg.value);
        }
    }
}
```