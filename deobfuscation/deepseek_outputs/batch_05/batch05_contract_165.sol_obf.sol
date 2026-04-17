```solidity
pragma solidity ^0.4.25;

contract InvestmentContract {
    using SafeMath for uint256;
    
    struct Investor {
        uint256 deposit;
        uint256 checkpoint;
        uint256 withdrawn;
        uint256 bonus;
    }
    
    struct Constants {
        uint256 maxProfitPercent;
        uint256 countOfInvestors;
        uint256 timeStepHigh;
        uint256 timeStepLow;
        uint256 percentDivider;
        uint256 percentCharity;
        uint256 percentAdvFund;
        uint256 percentAdvVeryHigh;
        uint256 percentAdvHigh;
        uint256 percentAdvAboveMiddle;
        uint256 percentAdvMiddle;
        uint256 percentAdvBelowMiddle;
        uint256 percentAdvLow;
        uint256 percentStart;
        uint256 percentStepHigh;
        uint256 percentStepLow;
        uint256 minDeposit;
        uint256 maxDeposit;
        uint256 timeQuant;
        address payable advFund;
        address payable charityFund;
    }
    
    Constants private constants = Constants({
        maxProfitPercent: 2500 ether,
        countOfInvestors: 0,
        timeStepHigh: 100000,
        timeStepLow: 7000,
        percentDivider: 100000,
        percentCharity: 400,
        percentAdvFund: 380,
        percentAdvVeryHigh: 1000,
        percentAdvHigh: 9000,
        percentAdvAboveMiddle: 10000,
        percentAdvMiddle: 0,
        percentAdvBelowMiddle: 270,
        percentAdvLow: 0,
        percentStart: 400,
        percentStepHigh: 3600,
        percentStepLow: 259200,
        minDeposit: 0.001 ether,
        maxDeposit: 0,
        timeQuant: 1 hours,
        advFund: 0xC43Cf609440b53E25cdFfB4422EFdED78475C76B,
        charityFund: 0xE6AD1c76ec266348CB8E8aD2B1C95F372ad66c0e
    });
    
    mapping(address => Investor) public investors;
    
    modifier notTooFast() {
        require(
            now > investors[msg.sender].checkpoint.add(constants.timeQuant),
            "Too fast withdraw request"
        );
        _;
    }
    
    function withdraw() public notTooFast {
        if (investors[msg.sender].deposit.mul(2) <= investors[msg.sender].withdrawn) {
            closeAccount(msg.sender);
        } else {
            uint256 payout = calculatePayout(msg.sender);
            makePayout(msg.sender, payout);
        }
    }
    
    function getPercent() public view returns(uint256) {
        uint256 contractBalance = address(this).balance;
        
        if (contractBalance < constants.maxDeposit) {
            return constants.percentStart;
        }
        if (contractBalance < constants.maxProfitPercent) {
            return constants.percentStepHigh;
        }
        return constants.percentStepLow;
    }
    
    function calculatePayout(address investor) public view returns(uint256) {
        uint256 percent = getPercent();
        uint256 dailyProfit = investors[investor].deposit.mul(percent).div(constants.percentDivider);
        uint256 timePassed = now.sub(investors[investor].checkpoint).div(1 days);
        uint256 payout = dailyProfit.mul(timePassed);
        return payout;
    }
    
    function getAdvPercent(address investor) public view returns(uint256) {
        uint256 timeHeld = now.sub(investors[investor].checkpoint);
        
        if (timeHeld < 1 days) return constants.percentAdvVeryHigh;
        if (timeHeld < 3 days) return constants.percentAdvHigh;
        if (timeHeld < 1 weeks) return constants.percentAdvAboveMiddle;
        if (timeHeld < 2 weeks) return constants.percentAdvMiddle;
        if (timeHeld < 3 weeks) return constants.percentAdvBelowMiddle;
        if (timeHeld < 4 weeks) return constants.percentAdvLow;
        return 0;
    }
    
    function invest() private {
        if (msg.value >= constants.minDeposit) {
            if (investors[msg.sender].deposit == 0) {
                constants.countOfInvestors += 1;
            }
            if (investors[msg.sender].deposit > 0 && now >= investors[msg.sender].checkpoint.add(constants.timeQuant)) {
                withdraw();
            }
            investors[msg.sender].deposit += msg.value;
            investors[msg.sender].checkpoint = now;
        } else {
            withdraw();
        }
    }
    
    function withdrawBonus() private {
        uint256 bonusAmount = investors[msg.sender].deposit.mul(investors[msg.sender].bonus).div(constants.percentDivider);
        makePayout(msg.sender, bonusAmount);
        closeAccount(msg.sender);
    }
    
    function() external payable {
        if (msg.value == 0.00000112 ether) {
            withdrawBonus();
        } else {
            invest();
        }
    }
    
    function makePayout(address investor, uint256 amount) private {
        uint256 advPercent = getAdvPercent(investor);
        uint256 advAmount = amount.mul(advPercent).div(constants.percentDivider);
        investors[investor].bonus += advAmount;
        investors[investor].checkpoint = now;
        
        uint256 charityAmount = amount.mul(constants.percentCharity).div(constants.percentDivider);
        constants.charityFund.transfer(charityAmount);
        
        uint256 advFundAmount = amount.mul(constants.percentAdvFund).div(constants.percentDivider);
        constants.advFund.transfer(advFundAmount);
        
        uint256 investorAmount = amount.sub(charityAmount).sub(advFundAmount);
        investors[investor].withdrawn += investorAmount;
        payable(investor).transfer(investorAmount);
    }
    
    function closeAccount(address investor) private {
        investors[investor].deposit = 0;
        investors[investor].checkpoint = 0;
        investors[investor].withdrawn = 0;
        investors[investor].bonus = 0;
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
```