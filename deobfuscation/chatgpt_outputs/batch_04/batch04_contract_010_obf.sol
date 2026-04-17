```solidity
pragma solidity ^0.4.24;

contract Ownable {
    address private owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    function getOwner() public view returns(address) {
        return owner;
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

    mapping (address => uint256) public userInvestments;
    mapping (address => uint256) public userWithdrawals;
    mapping (address => uint256) public lastInvestmentTime;
    mapping (address => uint256) public affiliateCommission;

    address public promoter1 = address(0x0);
    address public promoter2;
    address public promoter3;
    address public promoter4;
    address public promoter5;
    address public promoter6;
    address public lastPotWinner;

    uint256 public launchTime = 1;
    uint256 public maxProfit = 87;
    uint256 public maxWithdrawalLimit = 10;

    function() public payable {}

    function invest(address referrer) public payable {
        require(now >= launchTime);
        require(msg.value >= 0.4 ether);

        uint256 timeSinceLastInvestment = now.sub(lastInvestmentTime[msg.sender]);
        if (timeSinceLastInvestment < 1296000 && userInvestments[msg.sender] > 0) {
            reinvestProfit();
        }

        if (timeSinceLastInvestment > 1296000 && launchTime > 0) {
            uint256 profit = calculateProfit(msg.sender);
            lastInvestmentTime[msg.sender] = now;
            userWithdrawals[msg.sender] = now;
            affiliateCommission[msg.sender] = affiliateCommission[msg.sender].add(profit);
            msg.sender.transfer(profit);
        }

        uint256 investmentAmount = msg.value;
        uint256 promoterShare = investmentAmount.mul(7).div(100);
        uint256 devShare = investmentAmount.mul(3).div(100);
        uint256 potShare = investmentAmount.mul(2).div(100);

        promoter1.transfer(promoterShare);
        promoter2.transfer(promoterShare);
        promoter3.transfer(promoterShare);
        promoter4.transfer(promoterShare);
        promoter5.transfer(promoterShare);
        promoter6.transfer(potShare);

        if (referrer != msg.sender && referrer != address(0) && referrer != promoter1 && referrer != promoter2 && referrer != promoter3 && referrer != promoter4 && referrer != promoter5 && referrer != promoter6) {
            affiliateCommission[referrer] = affiliateCommission[referrer].add(promoterShare);
        }

        userInvestments[msg.sender] = userInvestments[msg.sender].add(investmentAmount);
        lastInvestmentTime[msg.sender] = now;

        if (potShare > maxProfit) {
            uint256 potProfit = potShare;
            msg.sender.transfer(potProfit);
            lastPotWinner = msg.sender;
            emit PotWinner(msg.sender, potProfit);
            potShare = 0;
        }
    }

    function withdraw() public {
        uint256 profit = calculateProfit(msg.sender);
        uint256 timeSinceLastInvestment = now.sub(lastInvestmentTime[msg.sender]);
        uint256 availableProfit = calculateAvailableProfit();

        require(profit > 0);
        require(timeSinceLastInvestment >= 1296000);

        lastInvestmentTime[msg.sender] = now;
        userWithdrawals[msg.sender] = now;

        if (profit < availableProfit) {
            if (profit < maxWithdrawalLimit) {
                affiliateCommission[msg.sender] = affiliateCommission[msg.sender].add(profit);
                msg.sender.transfer(profit);
            } else if (profit >= maxWithdrawalLimit) {
                uint256 withdrawalAmount = maxWithdrawalLimit;
                uint256 remainingProfit = profit.sub(withdrawalAmount);
                affiliateCommission[msg.sender] = affiliateCommission[msg.sender].add(profit);
                msg.sender.transfer(withdrawalAmount);
                userInvestments[msg.sender] = userInvestments[msg.sender].sub(remainingProfit);
            }
        } else if (profit >= availableProfit && affiliateCommission[msg.sender] < calculateAvailableProfit()) {
            uint256 withdrawalAmount = availableProfit;
            if (withdrawalAmount < maxWithdrawalLimit) {
                affiliateCommission[msg.sender] = 0;
                userInvestments[msg.sender] = 0;
                delete affiliateCommission[msg.sender];
                msg.sender.transfer(withdrawalAmount);
            } else if (withdrawalAmount >= maxWithdrawalLimit) {
                uint256 withdrawalAmount = maxWithdrawalLimit;
                uint256 remainingProfit = profit.sub(withdrawalAmount);
                affiliateCommission[msg.sender] = affiliateCommission[msg.sender].add(withdrawalAmount);
                msg.sender.transfer(withdrawalAmount);
                userInvestments[msg.sender] = userInvestments[msg.sender].sub(remainingProfit);
            }
        }
    }

    function calculateProfit(address user) public view returns(uint256) {
        uint256 timeSinceLastInvestment = now.sub(lastInvestmentTime[user]);
        uint256 profit = userInvestments[user].mul(timeSinceLastInvestment).div(1234440);
        uint256 availableProfit = calculateAvailableProfit();
        uint256 remainingProfit = availableProfit.sub(affiliateCommission[msg.sender]);

        if (profit > remainingProfit && affiliateCommission[msg.sender] < availableProfit) {
            return remainingProfit;
        }

        uint256 maxProfit = calculateMaxProfit();
        if (maxProfit == 0) {
            return profit;
        }

        return profit.sub(profit.mul(maxProfit).div(100));
    }

    function calculateMaxProfit() public view returns(uint256) {
        uint256 totalInvested = calculateTotalInvested();
        if (totalInvested >= 0.5 ether && 4 ether >= totalInvested) {
            return 0;
        } else if (totalInvested >= 4.01 ether && 7 ether >= totalInvested) {
            return 20;
        } else if (totalInvested >= 7.01 ether && 10 ether >= totalInvested) {
            return 40;
        } else if (totalInvested >= 10.01 ether && 15 ether >= totalInvested) {
            return 60;
        } else if (totalInvested >= 15.01 ether) {
            return 99;
        }
    }

    function reinvestProfit() public {
        uint256 profit = calculateProfit(msg.sender);
        require(profit > 0);
        lastInvestmentTime[msg.sender] = now;
        userWithdrawals[msg.sender] = userWithdrawals[msg.sender].add(profit);
        userInvestments[msg.sender] = userInvestments[msg.sender].add(profit);
    }

    function getAffiliateCommission() public view returns(uint256) {
        return affiliateCommission[msg.sender];
    }

    function withdrawAffiliateCommission() public {
        require(affiliateCommission[msg.sender] > 0);
        uint256 commission = affiliateCommission[msg.sender];
        affiliateCommission[msg.sender] = 0;
        msg.sender.transfer(commission);
    }

    function calculateTotalInvested() public view returns(uint256) {
        return userInvestments[msg.sender];
    }

    function getContractBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function setPromoter1(address newPromoter) external onlyOwner {
        require(newPromoter != address(0));
        promoter1 = newPromoter;
    }

    function setPromoter2(address newPromoter) external onlyOwner {
        require(newPromoter != address(0));
        promoter2 = newPromoter;
    }

    function setPromoter3(address newPromoter) external onlyOwner {
        require(newPromoter != address(0));
        promoter3 = newPromoter;
    }

    function setPromoter4(address newPromoter) external onlyOwner {
        require(newPromoter != address(0));
        promoter4 = newPromoter;
    }

    function setPromoter5(address newPromoter) external onlyOwner {
        require(newPromoter != address(0));
        promoter5 = newPromoter;
    }

    function setPromoter6(address newPromoter) external onlyOwner {
        require(newPromoter != address(0));
        promoter6 = newPromoter;
    }

    function setLaunchTime(uint256 newLaunchTime) external onlyOwner {
        launchTime = newLaunchTime;
    }

    function setMaxProfit(uint256 newMaxProfit) external onlyOwner {
        maxProfit = newMaxProfit;
    }
}
```