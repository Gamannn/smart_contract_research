pragma solidity ^0.4.0;

contract InvestmentContract {
    address public owner;
    uint256 public minWei;
    uint256 public lastBlockTime;
    uint256 public commissionPercentage;
    uint256 public gasPriceMultiplier;
    uint256 public secondsInDay;
    
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public payouts;
    mapping(address => uint256) public lastPayDate;
    mapping(address => uint256) public accruedInterest;

    event PayOut(address indexed investor, uint256 amount, uint256 timestamp);
    event DepositIn(address indexed investor, uint256 amount, uint256 timestamp);

    constructor() public {
        owner = msg.sender;
        lastBlockTime = now;
        commissionPercentage = 3;
        gasPriceMultiplier = 50000;
        secondsInDay = 86400;
        minWei = 40000000000000000;
    }

    function() public payable {
        require(now >= lastBlockTime && msg.value >= minWei);
        lastBlockTime = now;
        uint256 commission = msg.value / 100 * commissionPercentage;
        uint256 depositAmount = msg.value - commission;

        if (deposits[msg.sender] > 0) {
            uint256 daysGone = (now - lastPayDate[msg.sender]) / secondsInDay;
            accruedInterest[msg.sender] += depositAmount / 100 * daysGone;
        } else {
            lastPayDate[msg.sender] = now;
        }

        deposits[msg.sender] += depositAmount;
        emit DepositIn(msg.sender, msg.value, now);
        owner.transfer(commission);
    }

    function depositFor(address payoutAddress) public payable {
        require(now >= lastBlockTime && msg.value >= minWei);
        lastBlockTime = now;
        uint256 commission = msg.value / 100 * commissionPercentage;
        uint256 depositAmount = msg.value - commission;

        if (deposits[payoutAddress] > 0) {
            uint256 daysGone = (now - lastPayDate[payoutAddress]) / secondsInDay;
            accruedInterest[payoutAddress] += depositAmount / 100 * daysGone;
        } else {
            lastPayDate[payoutAddress] = now;
        }

        deposits[payoutAddress] += depositAmount;
        emit DepositIn(payoutAddress, msg.value, now);
        owner.transfer(commission);
    }

    function changeOwner(address newOwner) public {
        require(msg.sender == owner);
        owner = newOwner;
    }

    function withdraw() public {
        require(deposits[msg.sender] > 0);
        require(lastPayDate[msg.sender] < now);
        uint256 daysGone = (now - lastPayDate[msg.sender]) / secondsInDay;
        require(daysGone >= 30);
        processPayout(msg.sender, false, daysGone);
    }

    function adminWithdraw(address investor) public {
        require(msg.sender == owner && deposits[investor] > 0);
        require(lastPayDate[investor] < now);
        uint256 daysGone = (now - lastPayDate[investor]) / secondsInDay;
        require(daysGone >= 30);
        processPayout(investor, true, daysGone);
    }

    function processPayout(address investor, bool isAdmin, uint256 daysGone) private {
        uint256 payoutAmount = deposits[investor] / 100 * daysGone - accruedInterest[investor];
        if (payoutAmount >= address(this).balance) {
            payoutAmount = address(this).balance;
        }
        assert(payoutAmount > 0);

        if (isAdmin) {
            uint256 gasFee = gasPriceMultiplier * tx.gasprice;
            assert(gasFee < payoutAmount);
            payoutAmount -= gasFee;
            owner.transfer(gasFee);
        }

        lastPayDate[investor] = now;
        investor.transfer(payoutAmount);
        payouts[investor] += payoutAmount;
        accruedInterest[investor] = 0;
        emit PayOut(investor, payoutAmount, now);
    }

    function totalDepositOf(address investor) public view returns (uint256) {
        return deposits[investor];
    }

    function lastPaymentDateOf(address investor) public view returns (uint256) {
        return lastPayDate[investor];
    }

    function totalPayoutOf(address investor) public view returns (uint256) {
        return payouts[investor];
    }
}