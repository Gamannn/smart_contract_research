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

contract StabilizationFund {
    address public owner;
    address public fundAddress = 0x0223f73a53a549B8F5a9661aDB4cD9Dd4E25BEDa;
    uint public invest;
    
    event MoneyAdd(uint amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, 'Only the owner can call this method');
        _;
    }
    
    function withdrawToFund() public returns(bool) {
        uint balance = address(this).balance;
        require(balance > 0, 'Not enough funds for transaction');
        
        if(fundAddress.call.value(balance)()) {
            emit MoneyAdd(balance);
            return true;
        } else {
            return false;
        }
    }
    
    function investFund() internal payable {
        invest += msg.value;
        emit MoneyAdd(msg.value);
    }
}

contract InvestmentContract is StabilizationFund {
    using SafeMath for uint;
    
    struct Investor {
        address investorAddress;
        uint depositAmount;
        uint withdrawnAmount;
        uint depositTime;
        uint lastPaymentTime;
        bool exists;
    }
    
    mapping (address => uint) public deposits;
    mapping (address => uint) private lastPaymentTime;
    mapping (address => Investor) public investors;
    
    address public marketingAddress = 0xf846f84841b3242Ccdeac8c43C9cF73Bd781baA7;
    address public devAddress = 0xa7A20b9f36CD88fC2c776C9BB23FcEA34ba80ef7;
    
    uint public standardPercent = 5;
    uint public totalWithdrawn;
    uint public totalInvestors;
    uint public lastPaymentDate;
    uint public totalInvested;
    uint public dividendsTime = 1 days;
    uint public minPercent = 5;
    uint public minDeposit = 100000;
    uint public standardPercentValue = 100;
    uint public gasLimit = 100000;
    address public stabilizationFundAddress;
    
    event NewInvestor(address indexed investor, uint amount);
    event NewDeposit(address indexed investor, uint amount);
    event PayDividends(address indexed investor, uint amount);
    event ResiveFromStubFund(uint amount);
    
    function setStabilizationFundAddress(address _address) onlyOwner public {
        require(_address != address(0), 'Incorrect address');
        stabilizationFundAddress = _address;
    }
    
    function addInvestorRecord(address investor, uint deposit, uint withdrawn, uint depositTime) private {
        Investor storage investorRecord = investors[investor];
        
        if (!investorRecord.exists) {
            investorRecord.exists = true;
            investorRecord.investorAddress = investor;
            investorRecord.depositAmount = deposit;
            investorRecord.withdrawnAmount = withdrawn;
            investorRecord.depositTime = depositTime;
            investorRecord.lastPaymentTime = now;
            totalInvestors += 1;
        } else {
            investorRecord.depositAmount += deposit;
            investorRecord.withdrawnAmount += withdrawn;
        }
    }
    
    function getInvestorInfo(address investor) public view returns(
        address investorAddress,
        uint depositAmount,
        uint withdrawnAmount,
        uint depositTime
    ) {
        Investor storage investorRecord = investors[investor];
        require(investorRecord.exists, '404: Investor Not Found :(');
        
        return(
            investorRecord.investorAddress,
            investorRecord.depositAmount,
            investorRecord.withdrawnAmount,
            investorRecord.depositTime
        );
    }
    
    modifier hasDeposit() {
        require(deposits[msg.sender] > 0, "Deposit not found");
        _;
    }
    
    modifier paymentAvailable() {
        require(now >= lastPaymentTime[msg.sender].add(dividendsTime), "Too fast payout request");
        _;
    }
    
    function withdrawDividends() hasDeposit paymentAvailable internal {
        uint percent = getCurrentPercent();
        uint payout = deposits[msg.sender].mul(percent).div(1000);
        
        lastPaymentTime[msg.sender] = now;
        msg.sender.transfer(payout);
        
        totalWithdrawn += payout;
        lastPaymentDate = now;
        
        addInvestorRecord(msg.sender, 0, payout, 0);
        emit PayDividends(msg.sender, payout);
    }
    
    function isDividendsAvailable() public view returns(bool) {
        if (deposits[msg.sender] > 0 && now >= (lastPaymentTime[msg.sender].add(dividendsTime))) {
            return true;
        } else {
            return false;
        }
    }
    
    function getCurrentPercent() internal returns(uint) {
        uint value = deposits[msg.sender].mul(standardPercentValue).div(1000);
        uint min_value = deposits[msg.sender].mul(minPercent).div(1000);
        
        if(address(this).balance < min_value) {
            StabilizationFund stabFund = StabilizationFund(stabilizationFundAddress);
            require(stabFund.withdrawToFund(), 'Forgive, the stabilization fund can not cover your deposit, try to withdraw your interest later ');
            emit ResiveFromStubFund(25);
        }
        
        uint contractBalance = address(this).balance;
        require(contractBalance > 0, 'Out of money, wait a few days, we will attract new investments');
        
        if(contractBalance > (value.mul(standardPercentValue).div(1000))) {
            return 30;
        }
        
        if(contractBalance > (value.mul(standardPercentValue.sub(5)).div(1000))) {
            return 25;
        }
        
        if(contractBalance > (value.mul(standardPercentValue.sub(10)).div(1000))) {
            return 20;
        }
        
        if(contractBalance > (value.mul(standardPercent).div(1000))) {
            return 15;
        }
        
        if(contractBalance > (value.mul(standardPercentValue.sub(20)).div(1000))) {
            return 10;
        }
        
        if(contractBalance > (value.mul(standardPercentValue.sub(25)).div(1000))) {
            return 5;
        }
        
        return 5;
    }
    
    function makeInvestment() private {
        uint investment = msg.value;
        uint marketingFee = investment.mul(5).div(100);
        uint devFee = investment.mul(5).div(100);
        uint stabilizationFee = investment.mul(10).div(100);
        
        if(msg.value > 0) {
            if (deposits[msg.sender] == 0) {
                emit NewInvestor(msg.sender, msg.value);
            }
            
            deposits[msg.sender] = deposits[msg.sender].add(msg.value);
            lastPaymentTime[msg.sender] = now;
            
            addInvestorRecord(msg.sender, msg.value, 0, now);
            
            marketingAddress.transfer(marketingFee);
            devAddress.transfer(devFee);
            stabilizationFundAddress.call.value(stabilizationFee).gas(gasLimit)();
            
            totalInvested += msg.value;
            emit NewDeposit(msg.sender, msg.value);
        } else {
            withdrawDividends();
        }
    }
    
    function() external payable {
        require((deposits[msg.sender].add(msg.value)) >= deposits[msg.sender]);
        
        if(msg.sender != stabilizationFundAddress) {
            makeInvestment();
        } else {
            emit ResiveFromStubFund(msg.value);
        }
    }
}
```