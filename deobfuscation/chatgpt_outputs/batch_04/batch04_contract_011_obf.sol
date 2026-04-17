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

contract HYIPRETHPRO4 is Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) public userDeposits;
    mapping (address => uint256) public userWithdrawals;
    mapping (address => uint256) public userLastInvestment;
    mapping (address => uint256) public userReferralRewards;

    address public promoter1 = address(0xB5f6a633992cC9BF735974c3E09B5849c7633E2f);
    address public promoter2 = address(0xcF8Fd8bA33A341130B5662Ba4cDee8de61366DF0);
    address public lastPotWinner;
    uint256 public maxProfit;
    uint256 public maxPotentialDeposits;
    uint256 public lastInvestmentTime;

    function getMaxProfit() public view returns(uint256) {
        return maxProfit;
    }

    function getMaxPotentialDeposits() public view returns(uint256) {
        return maxPotentialDeposits;
    }

    function() public payable {}

    function invest(address referrer) public payable {
        require(now >= lastInvestmentTime);
        require(msg.value >= 0.1 ether);

        uint256 timeSinceLastInvestment = now.sub(lastInvestmentTime);
        if (timeSinceLastInvestment < 1728000 && getProfit(msg.sender) > 0) {
            withdrawProfit();
        }

        if (timeSinceLastInvestment > 1728000 && getProfit(msg.sender) > 0) {
            uint256 profit = calculateProfit(msg.sender);
            userLastInvestment[msg.sender] = now;
            userWithdrawals[msg.sender] = now;
            userDeposits[msg.sender] = userDeposits[msg.sender].add(profit);
            msg.sender.transfer(profit);
        }

        uint256 depositAmount = msg.value;
        uint256 promoter1Fee = depositAmount.mul(9).div(100);
        uint256 promoter2Fee = depositAmount.mul(8).div(100);
        uint256 referralFee = depositAmount.mul(3).div(100);

        maxPotentialDeposits = maxPotentialDeposits.add(referralFee);

        promoter1.transfer(promoter1Fee);
        promoter2.transfer(promoter2Fee);

        if (referrer != msg.sender && referrer != address(0) && referrer != promoter2) {
            userReferralRewards[referrer] = userReferralRewards[referrer].add(referralFee);
        }

        userDeposits[msg.sender] = userDeposits[msg.sender].add(depositAmount);
        userLastInvestment[msg.sender] = now;
        maxPotentialDeposits = maxPotentialDeposits.add(depositAmount);

        if (maxPotentialDeposits >= maxProfit) {
            uint256 potReward = maxPotentialDeposits.div(2);
            msg.sender.transfer(potReward);
            lastPotWinner = msg.sender;
            emit PotWinner(msg.sender, potReward);
            maxPotentialDeposits = 0;
        }
    }

    function withdrawProfit() public {
        uint256 profit = calculateProfit(msg.sender);
        require(profit > 0);

        uint256 timeSinceLastInvestment = now.sub(lastInvestmentTime);
        require(timeSinceLastInvestment >= 1728000);

        userLastInvestment[msg.sender] = now;
        userWithdrawals[msg.sender] = now;

        if (profit < availableProfit()) {
            if (profit < maxProfit) {
                userDeposits[msg.sender] = userDeposits[msg.sender].add(profit);
                msg.sender.transfer(profit);
            } else if (profit >= maxProfit) {
                uint256 partialPayment = maxProfit;
                uint256 remainingProfit = profit.sub(partialPayment);
                userDeposits[msg.sender] = userDeposits[msg.sender].add(profit);
                msg.sender.transfer(partialPayment);
                userDeposits[msg.sender] = userDeposits[msg.sender].sub(remainingProfit);
            }
        } else if (profit >= availableProfit() && userDeposits[msg.sender] < maxProfit) {
            uint256 finalPartialPayment = availableProfit();
            if (finalPartialPayment < maxProfit) {
                userDeposits[msg.sender] = 0;
                userDeposits[msg.sender] = 0;
                delete userDeposits[msg.sender];
                msg.sender.transfer(finalPartialPayment);
            } else if (finalPartialPayment >= maxProfit) {
                uint256 partialPayment = maxProfit;
                uint256 remainingProfit = finalPartialPayment.sub(partialPayment);
                userDeposits[msg.sender] = userDeposits[msg.sender].add(finalPartialPayment);
                msg.sender.transfer(partialPayment);
                userDeposits[msg.sender] = userDeposits[msg.sender].sub(remainingProfit);
            }
        }
    }

    function calculateProfit(address user) public view returns(uint256) {
        uint256 timeSinceLastInvestment = now.sub(userLastInvestment[user]);
        uint256 profit = timeSinceLastInvestment.mul(userDeposits[user]).div(985010);
        uint256 maxProfit = getMaxProfit();
        uint256 availableProfit = maxProfit.sub(userDeposits[msg.sender]);

        if (profit > availableProfit && userDeposits[msg.sender] < maxProfit) {
            profit = availableProfit;
        }

        uint256 profitPercentage = getProfitPercentage();
        if (profitPercentage == 0) {
            return profit;
        }

        return profit.mul(profitPercentage).div(100);
    }

    function getProfitPercentage() public view returns(uint256) {
        uint256 totalDeposits = getTotalDeposits();
        if (totalDeposits >= 0.1 ether && 4 ether >= totalDeposits) {
            return 0;
        } else if (totalDeposits >= 4.01 ether && 7 ether >= totalDeposits) {
            return 20;
        } else if (totalDeposits >= 7.01 ether && 10 ether >= totalDeposits) {
            return 40;
        } else if (totalDeposits >= 10.01 ether && 15 ether >= totalDeposits) {
            return 60;
        } else if (totalDeposits >= 15.01 ether) {
            return 99;
        }
    }

    function getTotalDeposits() public view returns(uint256) {
        return userDeposits[msg.sender];
    }

    function withdrawReferralRewards() public {
        require(userReferralRewards[msg.sender] > 0);
        uint256 reward = userReferralRewards[msg.sender];
        userReferralRewards[msg.sender] = 0;
        msg.sender.transfer(reward);
    }

    function getAvailableProfit() public view returns(uint256) {
        return userDeposits[msg.sender];
    }

    function getContractBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? a : b;
    }

    function updatePromoter1(address newPromoter) external onlyOwner {
        require(newPromoter != address(0x0));
        promoter1 = newPromoter;
    }

    function updatePromoter2(address newPromoter) external onlyOwner {
        require(newPromoter != address(0x0));
        promoter2 = newPromoter;
    }

    function updateMaxProfit(uint256 newMaxProfit) external onlyOwner {
        maxProfit = newMaxProfit;
    }

    function updateLastInvestmentTime(uint256 newTime) external onlyOwner {
        lastInvestmentTime = newTime;
    }
}
```