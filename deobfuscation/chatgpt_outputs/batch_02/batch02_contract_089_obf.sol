```solidity
pragma solidity ^0.4.25;

contract InvestmentContract {
    mapping(address => uint256) public investorBalances;
    mapping(address => uint256) public withdrawalBalances;
    uint256 public softCap;
    uint256 public hardCap;
    uint256 public startTime;
    uint256 public endTime;
    bool public isFinalized;
    address public owner;

    modifier onlyAfterEnd() {
        require(now > endTime && !isFinalized);
        _;
    }

    constructor() public {
        owner = msg.sender;
        startTime = now;
    }

    function() public payable {
        invest(msg.sender, msg.value, address(0), address(0));
    }

    function investWithReferral(address referrer, address secondaryReferrer) public payable {
        require(msg.value > 0);
        invest(msg.sender, msg.value, referrer, secondaryReferrer);
    }

    function invest(address investor, uint256 amount, address referrer, address secondaryReferrer) internal {
        investorBalances[investor] += amount;
        uint256 totalSupply = getTotalSupply();
        if (totalSupply >= softCap) {
            isFinalized = true;
            endTime = now;
        }

        uint256 referrerBonus = amount * 6 / 100;
        uint256 secondaryReferrerBonus = amount * 3 / 100;
        uint256 remainingAmount = amount - referrerBonus - secondaryReferrerBonus;

        if (referrer != address(0) && investorBalances[owner] >= 125 ether) {
            investorBalances[referrer] += referrerBonus;
        } else {
            investorBalances[owner] += referrerBonus;
        }

        if (secondaryReferrer != address(0) && investorBalances[secondaryReferrer] >= 125 ether) {
            investorBalances[secondaryReferrer] += secondaryReferrerBonus;
        } else {
            withdrawalBalances[owner] += secondaryReferrerBonus;
        }

        withdrawalBalances[owner] += remainingAmount;
        emit OnInvest(investor, amount, totalSupply, referrer, secondaryReferrer, now);
    }

    function withdraw() public {
        require(isFinalized);
        uint256 amount = withdrawalBalances[msg.sender];
        require(amount > 0);
        withdrawalBalances[msg.sender] = 0;
        msg.sender.transfer(amount);
        emit OnWithdraw(msg.sender, amount, now);
    }

    function withdrawPartial(uint256 amount) public {
        require(amount > 0);
        require(isFinalized);
        uint256 balance = withdrawalBalances[msg.sender];
        require(balance >= amount);
        withdrawalBalances[msg.sender] = balance - amount;
        msg.sender.transfer(amount);
        emit OnWithdraw(msg.sender, amount, now);
    }

    function withdrawTo(uint256 amount, address to) public {
        require(amount > 0);
        require(isFinalized);
        uint256 balance = withdrawalBalances[msg.sender];
        require(balance >= amount);
        withdrawalBalances[msg.sender] = balance - amount;
        to.transfer(amount);
        emit OnWithdrawTo(msg.sender, to, amount, now);
    }

    function deinvest() public onlyAfterEnd {
        uint256 balance = investorBalances[msg.sender];
        require(balance > 0);
        investorBalances[msg.sender] = 0;
        uint256 refundAmount = balance * getExchangeRate() / 1e18;
        msg.sender.transfer(refundAmount);
        emit OnDeinvest(msg.sender, balance, refundAmount, getTotalSupply());
    }

    function exchangeForESM() public {
        require(isFinalized);
        uint256 balance = investorBalances[msg.sender];
        require(balance > 0);
        investorBalances[msg.sender] = 0;
        emit OnExchangeForESM(msg.sender, balance, now);
    }

    function transfer(address to) public {
        uint256 balance = investorBalances[msg.sender];
        require(balance > 0);
        investorBalances[msg.sender] = 0;
        investorBalances[to] += balance;
        emit OnTransfer(msg.sender, to, balance, now);
    }

    event OnInvest(address indexed investor, uint256 amount, uint256 totalSupply, address referrer, address secondaryReferrer, uint256 timestamp);
    event OnWithdraw(address indexed investor, uint256 amount, uint256 timestamp);
    event OnWithdrawTo(address indexed investor, address indexed to, uint256 amount, uint256 timestamp);
    event OnDeinvest(address indexed investor, uint256 balance, uint256 refundAmount, uint256 totalSupply);
    event OnExchangeForESM(address indexed investor, uint256 balance, uint256 timestamp);
    event OnTransfer(address indexed from, address indexed to, uint256 amount, uint256 timestamp);

    function getTotalSupply() internal view returns (uint256) {
        return _integer_constant[4];
    }

    function getExchangeRate() internal view returns (uint256) {
        return _integer_constant[3];
    }

    bool[] public _bool_constant = [false, true];
    uint256[] public _integer_constant = [6, 125000000000000000000, 100, 400000000000000, 10000000000000000000000000, 2500000000000000000000000, 1483300, 0, 1000000000000000000, 3];
}
```