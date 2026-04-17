```solidity
pragma solidity ^0.4.24;

contract Ownable {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(isOwner());
        _;
    }
    
    function isOwner() public view returns(bool) {
        return msg.sender == owner;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
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

contract InvestmentContract is Ownable {
    using SafeMath for uint256;
    
    mapping (address => uint256) public investedETH;
    mapping (address => uint256) public lastInvest;
    mapping (address => uint256) public lastWithdraw;
    mapping (address => uint256) public affiliateCommision;
    mapping (address => uint256) public userWithdrawals;
    mapping (address => uint256[]) public userDeposits;
    
    address public promoter1 = address(0x1b4360A5E654280fCd0149829Dc88cb4b4f06556);
    address public promoter2 = address(0xeC886efC31415b7C93030CD07cCb9592953eF6de);
    address public promoter3 = address(0x0C513b1DA33446a15bD4afb5561Ac3d5B1CB84EE);
    address public promoter4 = address(0x6D990AD82d60Aafec9b193eC2E43CcAe7a514F59);
    address public promoter5 = address(0x1Ca4F7Be21270da59C0BD806888A82583Ae48511);
    address public promoter6 = address(0x0D54F6Ff455e9C4D54e5ad4F0D2aD9b8356fb625);
    address public lastPotWinner;
    
    uint256 public launchTime = 1555164000;
    uint256 public maxWithdrawPercent = 200;
    uint256 public pot;
    uint256 public maxProfit = 150 ether;
    
    event PotWinner(address indexed winner, uint256 amount);
    
    function() public payable {
        invest(address(0));
    }
    
    function invest(address referral) public payable {
        require(now >= launchTime);
        require(msg.value >= 0.4 ether);
        
        uint256 timePassed = SafeMath.sub(now, launchTime);
        
        if(timePassed < 1296000 && getProfit(msg.sender) > 0){
            reinvestProfit();
        }
        
        if(timePassed > 1296000 && getProfit(msg.sender) > 0){
            withdrawProfit();
        }
        
        uint256 profit = calculateProfit(msg.sender);
        lastInvest[msg.sender] = now;
        lastWithdraw[msg.sender] = now;
        userWithdrawals[msg.sender] = userWithdrawals[msg.sender].add(profit);
        msg.sender.transfer(profit);
        
        uint256 amount = msg.value;
        uint256 referralBonus = amount.mul(7).div(100);
        uint256 promoterBonus = amount.mul(3).div(100);
        uint256 potBonus = amount.mul(2).div(100);
        uint256 _pot = amount.mul(3).div(100);
        
        pot = pot.add(_pot);
        uint256 investment = amount;
        
        promoter1.transfer(promoterBonus);
        promoter2.transfer(promoterBonus);
        promoter3.transfer(promoterBonus);
        promoter4.transfer(promoterBonus);
        promoter5.transfer(promoterBonus);
        promoter6.transfer(potBonus);
        
        if(referral != msg.sender && 
           referral != address(0) && 
           referral != promoter1 && 
           referral != promoter2 && 
           referral != promoter3 && 
           referral != promoter4 && 
           referral != promoter5 && 
           referral != promoter6) {
            affiliateCommision[referral] = affiliateCommision[referral].add(referralBonus);
        }
        
        investedETH[msg.sender] = investedETH[msg.sender].add(investment);
        lastInvest[msg.sender] = now;
        userDeposits[msg.sender].push(investment);
        
        if(pot > maxProfit) {
            uint256 potWin = pot;
            pot = 0;
            msg.sender.transfer(potWin);
            lastPotWinner = msg.sender;
            emit PotWinner(msg.sender, potWin);
        }
    }
    
    function withdrawProfit() public {
        uint256 profit = calculateProfit(msg.sender);
        uint256 timePassed = SafeMath.sub(now, launchTime);
        uint256 totalProfit = getTotalProfit();
        uint256 availableProfit = totalProfit - userWithdrawals[msg.sender];
        uint256 maxWithdraw = SafeMath.div(SafeMath.mul(maxWithdrawPercent, investedETH[msg.sender]), 100);
        
        require(profit > 0);
        require(timePassed >= 1296000);
        
        lastInvest[msg.sender] = now;
        lastWithdraw[msg.sender] = now;
        
        if(profit < availableProfit) {
            if(profit < maxWithdraw) {
                userWithdrawals[msg.sender] = userWithdrawals[msg.sender].add(profit);
                msg.sender.transfer(profit);
            } else if(profit >= maxWithdraw) {
                uint256 maxWithdrawAmount = maxWithdraw;
                uint256 remaining = SafeMath.sub(profit, maxWithdrawAmount);
                userWithdrawals[msg.sender] = userWithdrawals[msg.sender].add(profit);
                msg.sender.transfer(maxWithdrawAmount);
                investedETH[msg.sender] = investedETH[msg.sender].add(remaining);
            }
        } else if(profit >= availableProfit && userWithdrawals[msg.sender] < totalProfit) {
            uint256 remainingProfit = availableProfit;
            if(remainingProfit < maxWithdraw) {
                userWithdrawals[msg.sender] = 0;
                investedETH[msg.sender] = 0;
                delete userDeposits[msg.sender];
                msg.sender.transfer(remainingProfit);
            } else if(remainingProfit >= maxWithdraw) {
                uint256 maxWithdrawAmount = maxWithdraw;
                uint256 remaining = SafeMath.sub(remainingProfit, maxWithdrawAmount);
                userWithdrawals[msg.sender] = userWithdrawals[msg.sender].add(remainingProfit);
                msg.sender.transfer(maxWithdrawAmount);
                investedETH[msg.sender] = investedETH[msg.sender].add(remaining);
            }
        }
    }
    
    function getProfit(address user) public view returns(uint256) {
        return calculateProfit(user);
    }
    
    function calculateProfit(address user) public view returns(uint256) {
        uint256 timePassed = SafeMath.sub(now, lastInvest[user]);
        uint256 profit = SafeMath.div(SafeMath.mul(timePassed, investedETH[user]), 1234440);
        uint256 totalProfit = getTotalProfit();
        uint256 availableProfit = totalProfit - userWithdrawals[msg.sender];
        
        if(profit > availableProfit && userWithdrawals[msg.sender] < totalProfit) {
            profit = availableProfit;
        }
        
        uint256 tax = getTax();
        if(tax == 0) {
            return profit;
        }
        
        return SafeMath.add(profit, SafeMath.div(SafeMath.mul(profit, tax), 100));
    }
    
    function getTax() public view returns(uint256) {
        uint256 invested = getInvested();
        if(invested >= 0.5 ether && 4 ether >= invested) {
            return 0;
        } else if(invested >= 4.01 ether && 7 ether >= invested) {
            return 20;
        } else if(invested >= 7.01 ether && 10 ether >= invested) {
            return 40;
        } else if(invested >= 10.01 ether && 15 ether >= invested) {
            return 60;
        } else if(invested >= 15.01 ether) {
            return 99;
        }
        return 0;
    }
    
    function reinvestProfit() public {
        uint256 profit = calculateProfit(msg.sender);
        require(profit > 0);
        lastInvest[msg.sender] = now;
        userWithdrawals[msg.sender] = userWithdrawals[msg.sender].add(profit);
        investedETH[msg.sender] = investedETH[msg.sender].add(profit);
    }
    
    function getAffiliateBalance() public view returns(uint256) {
        return affiliateCommision[msg.sender];
    }
    
    function withdrawAffiliate() public {
        require(affiliateCommision[msg.sender] > 0);
        uint256 commission = affiliateCommision[msg.sender];
        affiliateCommision[msg.sender] = 0;
        msg.sender.transfer(commission);
    }
    
    function getInvested() public view returns(uint256) {
        return investedETH[msg.sender];
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getTotalProfit() public view returns(uint256) {
        uint256 totalInvested = investedETH[msg.sender];
        uint256 daysPassed = SafeMath.div(SafeMath.sub(now, launchTime), 86400);
        return SafeMath.div(SafeMath.mul(totalInvested, daysPassed), 10);
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
    
    function max(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? a : b;
    }
    
    function setPromoter1(address newAddress) external onlyOwner {
        require(newAddress != address(0));
        promoter1 = newAddress;
    }
    
    function setPromoter2(address newAddress) external onlyOwner {
        require(newAddress != address(0));
        promoter2 = newAddress;
    }
    
    function setPromoter3(address newAddress) external onlyOwner {
        require(newAddress != address(0));
        promoter3 = newAddress;
    }
    
    function setPromoter4(address newAddress) external onlyOwner {
        require(newAddress != address(0));
        promoter4 = newAddress;
    }
    
    function setPromoter5(address newAddress) external onlyOwner {
        require(newAddress != address(0));
        promoter5 = newAddress;
    }
    
    function setPromoter6(address newAddress) external onlyOwner {
        require(newAddress != address(0));
        promoter6 = newAddress;
    }
    
    function setMaxProfit(uint256 newMaxProfit) external onlyOwner {
        maxProfit = newMaxProfit;
    }
    
    function setLaunchTime(uint256 newLaunchTime) external onlyOwner {
        launchTime = newLaunchTime;
    }
}
```