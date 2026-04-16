```solidity
pragma solidity ^0.4.0;

contract Oxaa94056cb5524fc0bac318156647d9f9f5a7d556 {
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public totalPaidOut;
    mapping(address => uint256) public lastDepositTime;
    mapping(address => uint256) public pendingPayouts;
    
    uint256 public minWei;
    
    event DepositIn(address indexed depositor, uint256 amount, uint256 timestamp);
    event PayOut(address indexed recipient, uint256 amount, uint256 timestamp);
    
    address public owner;
    uint256 public lastBlockTime;
    
    struct Config {
        uint256 commissionPercent;
        uint256 lastBlockTime;
        uint256 gasCost;
        uint256 secondsInDay;
        uint256 minWei;
        address owner;
    }
    
    Config public config = Config(0, 0, 0, 86400, 0, address(0));
    
    uint256[] public _integer_constant = [30, 40000000000000000, 3, 100, 86400, 50000, 0];
    bool[] public _bool_constant = [true, false];
    
    constructor() public {
        owner = msg.sender;
        lastBlockTime = now;
    }
    
    function() public payable {
        require(now >= lastBlockTime && msg.value >= minWei);
        lastBlockTime = now;
        
        uint256 commission = msg.value / 100 * _integer_constant[2];
        uint256 depositAmount = msg.value - commission;
        
        if (deposits[msg.sender] > 0) {
            uint256 daysGone = (now - lastDepositTime[msg.sender]) / _integer_constant[4];
            pendingPayouts[msg.sender] += depositAmount / 100 * daysGone;
        } else {
            lastDepositTime[msg.sender] = now;
        }
        
        deposits[msg.sender] += depositAmount;
        emit DepositIn(msg.sender, msg.value, now);
        owner.transfer(commission);
    }
    
    function depositForRecipient(address payoutAddress) public payable {
        require(now >= lastBlockTime && msg.value >= minWei);
        lastBlockTime = now;
        
        uint256 commission = msg.value / 100 * _integer_constant[2];
        uint256 depositAmount = msg.value - commission;
        
        if (deposits[payoutAddress] > 0) {
            uint256 daysGone = (now - lastDepositTime[payoutAddress]) / _integer_constant[4];
            pendingPayouts[payoutAddress] += depositAmount / 100 * daysGone;
        } else {
            lastDepositTime[payoutAddress] = now;
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
        require(lastDepositTime[msg.sender] < now);
        
        uint256 daysGone = (now - lastDepositTime[msg.sender]) / _integer_constant[4];
        require(daysGone >= 30);
        
        payout(msg.sender, false, daysGone);
    }
    
    function forcePayout(address recipient) public {
        require(msg.sender == owner && deposits[recipient] > 0);
        require(lastDepositTime[recipient] < now);
        
        uint256 daysGone = (now - lastDepositTime[recipient]) / _integer_constant[4];
        require(daysGone >= 30);
        
        payout(recipient, true, daysGone);
    }
    
    function payout(address recipient, bool deductGas, uint256 daysGone) private {
        uint256 payoutAmount = 0;
        payoutAmount = deposits[recipient] / 100 * daysGone - pendingPayouts[recipient];
        
        if (payoutAmount >= address(this).balance) {
            payoutAmount = address(this).balance;
        }
        
        assert(payoutAmount > 0);
        
        if (deductGas) {
            uint256 gasCost = _integer_constant[5] * tx.gasprice;
            assert(gasCost < payoutAmount);
            payoutAmount = payoutAmount - gasCost;
            owner.transfer(gasCost);
        }
        
        lastDepositTime[recipient] = now;
        recipient.transfer(payoutAmount);
        totalPaidOut[recipient] += payoutAmount;
        pendingPayouts[recipient] = 0;
        
        emit PayOut(recipient, payoutAmount, now);
    }
    
    function totalDepositOf(address depositor) public constant returns (uint256) {
        return deposits[depositor];
    }
    
    function lastDepositTimeOf(address depositor) public constant returns (uint256) {
        return lastDepositTime[depositor];
    }
    
    function totalPaidOutOf(address depositor) public constant returns (uint256) {
        return totalPaidOut[depositor];
    }
    
    function getIntFunc(uint256 index) internal view returns(uint256) {
        return _integer_constant[index];
    }
    
    function getBoolFunc(uint256 index) internal view returns(bool) {
        return _bool_constant[index];
    }
}
```