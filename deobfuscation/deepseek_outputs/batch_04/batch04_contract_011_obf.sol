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

    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract HYIPRETHPRO4 is Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) public userDeposits;
    mapping(address => uint256) public userLastInvestTime;
    mapping(address => uint256) public userLastWithdrawTime;
    mapping(address => uint256) public userTotalWithdrawals;
    mapping(address => uint256[]) public userDepositHistory;

    address public devAddress = address(0xB5f6a633992cC9BF735974c3E09B5849c7633E2f);
    address public promoter1 = address(0xcF8Fd8bA33A341130B5662Ba4cDee8de61366DF0);
    address public promoter2;
    address public lastPotWinner;

    uint256 public pot;
    uint256 public maxPot = 10 ether;
    uint256 public startTime = 1554822000;

    event PotWinner(address indexed winner, uint256 amount);

    function maxProfit() public view returns (uint256) {
        return userDeposits[msg.sender].mul(3);
    }

    function depositCount() public view returns (uint256) {
        return userDepositHistory[msg.sender].length;
    }

    function() public payable {}

    function invest(address referrer) public payable {
        require(now >= startTime);
        require(msg.value >= 0.1 ether);

        uint256 timeSinceStart = now.sub(startTime);

        if (timeSinceStart < 1728000 && userDeposits[msg.sender] > 0) {
            withdrawProfit();
        }

        if (timeSinceStart > 1728000 && getProfit(msg.sender) > 0) {
            uint256 profit = calculateProfit(msg.sender);
            userLastWithdrawTime[msg.sender] = now;
            userTotalWithdrawals[msg.sender] = userTotalWithdrawals[msg.sender].add(profit);
            msg.sender.transfer(profit);
        }

        uint256 depositAmount = msg.value;

        uint256 devShare = depositAmount.mul(9).div(100);
        uint256 promoter1Share = depositAmount.mul(8).div(100);
        uint256 promoter2Share = depositAmount.mul(3).div(100);

        pot = pot.add(promoter2Share);

        devAddress.transfer(devShare);
        promoter1.transfer(promoter1Share);

        if (referrer != msg.sender && referrer != address(0) && referrer != promoter1) {
            userTotalWithdrawals[referrer] = userTotalWithdrawals[referrer].add(devShare);
        }

        userDeposits[msg.sender] = userDeposits[msg.sender].add(depositAmount);
        userLastInvestTime[msg.sender] = now;
        userDepositHistory[msg.sender].push(depositAmount);

        if (pot >= maxPot) {
            uint256 potPrize = pot;
            msg.sender.transfer(potPrize);
            lastPotWinner = msg.sender;
            emit PotWinner(msg.sender, potPrize);
            pot = 0;
        }
    }

    function withdrawProfit() public {
        uint256 profit = calculateProfit(msg.sender);
        uint256 timeSinceStart = now.sub(startTime);
        uint256 maxProfitLimit = maxProfit();
        uint256 availableProfit = maxProfitLimit.sub(userTotalWithdrawals[msg.sender]);
        uint256 maxDailyWithdraw = userDeposits[msg.sender].mul(100).div(100);

        require(profit > 0);
        require(timeSinceStart >= 1728000);

        userLastInvestTime[msg.sender] = now;
        userLastWithdrawTime[msg.sender] = now;

        if (profit < availableProfit) {
            if (profit < maxDailyWithdraw) {
                userTotalWithdrawals[msg.sender] = userTotalWithdrawals[msg.sender].add(profit);
                msg.sender.transfer(profit);
            } else if (profit >= maxDailyWithdraw) {
                uint256 dailyLimit = maxDailyWithdraw;
                uint256 remaining = profit.sub(dailyLimit);
                userTotalWithdrawals[msg.sender] = userTotalWithdrawals[msg.sender].add(profit);
                msg.sender.transfer(dailyLimit);
                userDeposits[msg.sender] = userDeposits[msg.sender].add(remaining);
            }
        } else if (profit >= availableProfit && userTotalWithdrawals[msg.sender] < maxProfitLimit) {
            uint256 finalPayment = availableProfit;
            if (finalPayment < maxDailyWithdraw) {
                userTotalWithdrawals[msg.sender] = 0;
                userDeposits[msg.sender] = 0;
                delete userDepositHistory[msg.sender];
                msg.sender.transfer(finalPayment);
            } else if (finalPayment >= maxDailyWithdraw) {
                uint256 dailyLimit = maxDailyWithdraw;
                uint256 remaining = finalPayment.sub(dailyLimit);
                userTotalWithdrawals[msg.sender] = userTotalWithdrawals[msg.sender].add(finalPayment);
                msg.sender.transfer(dailyLimit);
                userDeposits[msg.sender] = userDeposits[msg.sender].add(remaining);
            }
        }
    }

    function getProfit(address investor) public view returns (uint256) {
        uint256 timeSinceLastInvest = now.sub(userLastInvestTime[investor]);
        uint256 profit = timeSinceLastInvest.mul(userDeposits[investor]).div(985010);
        uint256 maxProfitLimit = maxProfit();
        uint256 availableProfit = maxProfitLimit.sub(userTotalWithdrawals[msg.sender]);

        if (profit > availableProfit && userTotalWithdrawals[msg.sender] < maxProfitLimit) {
            profit = availableProfit;
        }

        uint256 tax = getTax();
        if (tax == 0) {
            return profit;
        }
        return profit.add(profit.mul(tax).div(100));
    }

    function getTax() public view returns (uint256) {
        uint256 totalDeposit = userDeposits[msg.sender];
        if (totalDeposit >= 0.1 ether && totalDeposit <= 4 ether) {
            return 0;
        } else if (totalDeposit >= 4.01 ether && totalDeposit <= 7 ether) {
            return 20;
        } else if (totalDeposit >= 7.01 ether && totalDeposit <= 10 ether) {
            return 40;
        } else if (totalDeposit >= 10.01 ether && totalDeposit <= 15 ether) {
            return 60;
        } else if (totalDeposit >= 15.01 ether) {
            return 99;
        }
    }

    function calculateProfit(address investor) internal view returns (uint256) {
        uint256 timeSinceLastInvest = now.sub(userLastInvestTime[investor]);
        return timeSinceLastInvest.mul(userDeposits[investor]).div(985010);
    }

    function myDeposit() public view returns (uint256) {
        return userDeposits[msg.sender];
    }

    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? a : b;
    }

    function updatePromoter1(address newPromoter1) external onlyOwner {
        require(newPromoter1 != address(0));
        promoter1 = newPromoter1;
    }

    function updatePromoter2(address newPromoter2) external onlyOwner {
        require(newPromoter2 != address(0));
        promoter2 = newPromoter2;
    }

    function updateMaxPot(uint256 newMaxPot) external onlyOwner {
        maxPot = newMaxPot;
    }

    function updateStartTime(uint256 newStartTime) external onlyOwner {
        startTime = newStartTime;
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