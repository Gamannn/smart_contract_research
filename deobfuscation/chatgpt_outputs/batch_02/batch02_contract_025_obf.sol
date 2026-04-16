pragma solidity ^0.4.25;

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

    function max(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

contract Ownable {
    address public owner;
    event OwnerChanged(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function changeOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnerChanged(owner, newOwner);
        owner = newOwner;
    }
}

contract InvestmentPlatform is Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) public investments;
    mapping(address => uint256) public lastInvestmentTime;
    mapping(address => uint256) public withdrawnProfits;
    mapping(address => uint256) public referralProfits;
    mapping(uint256 => address) public referralLinks;
    mapping(address => uint256) public referralLinkIds;

    uint256 public minimumInvestment = 0.01 ether;
    uint256 public totalInvestors;
    uint256 public totalReferralLinks;

    event ReferrerWithdraw(address indexed referrer, uint256 amount);
    event ReferrerProfit(address indexed referrer, address indexed referral, uint256 amount);
    event MakeReferralLink(address indexed referrer, uint256 referralLinkId);

    constructor(address wallet, address support) public {
        owner = msg.sender;
    }

    function() payable public {
        invest(0);
    }

    function invest(uint256 referralLinkId) public payable returns (uint256) {
        require(msg.value >= minimumInvestment);
        address investor = msg.sender;
        uint256 currentTime = now;

        if (currentTime < 1542240000) {
            revert();
        }

        if (investments[investor] == 0) {
            totalInvestors = totalInvestors.add(1);
        }

        if (investments[investor] > 0) {
            withdrawProfit();
        }

        investments[investor] = investments[investor].add(msg.value);
        lastInvestmentTime[investor] = currentTime;

        if (referralLinkId > 100) {
            makeReferralProfit(referralLinkId);
        } else {
            owner.transfer(msg.value.mul(10).div(100));
        }

        emit Invest(investor, msg.value);
        return referralLinkId;
    }

    function calculateProfit(address investor) public view returns (uint256) {
        uint256 profit = 0;
        if (investments[investor] > 0) {
            uint256 currentTime = now;
            uint256 timeElapsed = currentTime.sub(lastInvestmentTime[investor]).div(1 minutes);
            uint256 daysElapsed = timeElapsed.div(1440);

            if (daysElapsed > 0) {
                uint256 dailyProfit = investments[investor].mul(10).div(10000);
                profit = dailyProfit.mul(daysElapsed);
                if (profit > withdrawnProfits[investor]) {
                    profit = profit.sub(withdrawnProfits[investor]);
                }
            }
        }
        return profit;
    }

    function withdrawProfit() public returns (uint256) {
        address investor = msg.sender;
        require(investments[investor] > 0);

        uint256 profit = calculateProfit(investor);
        if (address(this).balance > profit) {
            if (profit > 0) {
                withdrawnProfits[investor] = withdrawnProfits[investor].add(profit);
                investor.transfer(profit);
                emit Withdraw(investor, profit);
            }
        }
        return profit;
    }

    function withdrawAll() public returns (uint256) {
        address investor = msg.sender;
        require(investments[investor] > 0);

        uint256 currentTime = now;
        uint256 timeElapsed = currentTime.sub(lastInvestmentTime[investor]).div(1 days);
        require(timeElapsed > 10);

        uint256 profit = calculateProfit(investor);
        uint256 totalInvestment = investments[investor];
        uint256 totalAmount = totalInvestment.add(profit);

        require(totalAmount >= 0);
        if (address(this).balance > totalAmount) {
            withdrawnProfits[investor] = 0;
            investments[investor] = 0;
            lastInvestmentTime[investor] = 0;
            investor.transfer(totalAmount);
            emit Withdraw(investor, totalAmount);
            return totalAmount;
        }
    }

    function makeReferralProfit(uint256 referralLinkId) public payable {
        address referrer = referralLinks[referralLinkId];
        require(referrer != address(0));

        uint256 referralProfit = 0;
        if (msg.value > 0) {
            referralProfit = msg.value.mul(10).div(100);
            referralProfits[referrer] = referralProfits[referrer].add(referralProfit);
            emit ReferrerProfit(referrer, msg.sender, referralProfit);
        }
    }

    function withdrawReferralProfit() public returns (uint256) {
        address referrer = msg.sender;
        require(referralProfits[referrer] > 0);

        uint256 profit = referralProfits[referrer];
        require(profit >= minimumInvestment);

        referralProfits[referrer] = 0;
        referrer.transfer(profit);
        emit ReferrerWithdraw(referrer, profit);
        return profit;
    }

    function createReferralLink() public returns (uint256) {
        address referrer = msg.sender;
        if (referralLinkIds[referrer] == 0) {
            totalReferralLinks = totalReferralLinks.add(1);
            referralLinks[totalReferralLinks] = referrer;
            referralLinkIds[referrer] = totalReferralLinks;
            emit MakeReferralLink(referrer, totalReferralLinks);
            return totalReferralLinks;
        } else {
            return referralLinkIds[referrer];
        }
    }

    function getReferralLinkId() public view returns (uint256) {
        return referralLinkIds[msg.sender];
    }

    function getReferralProfit(address referrer) public view returns (uint256) {
        return referralProfits[referrer];
    }

    function getInvestment(address investor) public view returns (uint256) {
        return investments[investor];
    }
}