pragma solidity ^0.4.25;

contract InvestmentContract {
    using SafeMath for uint256;

    mapping(address => uint256) public investments;
    mapping(address => uint256) public lastInvestmentTime;
    mapping(address => uint256) public referralRewards;
    mapping(address => uint256) public bountyRewards;

    uint256 public minimumInvestment = 10 finney;
    uint256 public dailyInterestRate = 5;
    uint256 public stakingRequirement = 100 finney;

    address public owner;
    address public ownerWallet;

    event Invest(address investor, uint256 amount);
    event Withdraw(address investor, uint256 amount);
    event Bounty(address referrer, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
        ownerWallet = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner, address newOwnerWallet) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        ownerWallet = newOwnerWallet;
    }

    function () public payable {
        invest(0x0);
    }

    function invest(address referrer) public payable {
        require(msg.value > minimumInvestment);

        address investor = msg.sender;

        if (referrer != address(0) && investments[referrer] >= stakingRequirement) {
            referralRewards[referrer] = referralRewards[referrer].add(msg.value.mul(dailyInterestRate).div(100));
        }

        if (investments[investor] > 0) {
            if (withdrawDividends()) {
                bountyRewards[investor] = 0;
            }
        }

        investments[investor] = investments[investor].add(msg.value);
        lastInvestmentTime[investor] = now;

        ownerWallet.transfer(msg.value.mul(dailyInterestRate).div(100));
        emit Invest(investor, msg.value);
    }

    function calculateDividends(address investor) view public returns (uint256) {
        uint256 timePassed = now.sub(lastInvestmentTime[investor]).div(1 minutes);
        uint256 dailyInterest = investments[investor].mul(dailyInterestRate).div(100);
        uint256 dividends = dailyInterest.mul(timePassed).div(1440);
        return dividends.add(bountyRewards[investor]);
    }

    function withdrawDividends() public returns (bool) {
        require(lastInvestmentTime[msg.sender] > 0);

        uint256 dividends = calculateDividends(msg.sender);

        if (address(this).balance > dividends) {
            if (dividends > 0) {
                bountyRewards[msg.sender] = bountyRewards[msg.sender].add(dividends);
                msg.sender.transfer(dividends);
                emit Withdraw(msg.sender, dividends);
            }
            return true;
        } else {
            return false;
        }
    }

    function claimBounty() public {
        uint256 bounty = calculateReferral(msg.sender);

        if (bounty >= stakingRequirement) {
            if (address(this).balance > bounty) {
                referralRewards[msg.sender] = 0;
                msg.sender.transfer(bounty);
                emit Bounty(msg.sender, bounty);
            }
        }
    }

    function getDividends() public view returns (uint256) {
        return calculateDividends(msg.sender);
    }

    function getBounty(address investor) public view returns (uint256) {
        return bountyRewards[investor];
    }

    function getInvestment(address investor) public view returns (uint256) {
        return investments[investor];
    }

    function getReferralRewards(address referrer) public view returns (uint256) {
        return referralRewards[referrer];
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

function getAddrFunc(uint256 index) internal view returns(address payable) {
    return _address_constant[index];
}

function getBoolFunc(uint256 index) internal view returns(bool) {
    return _bool_constant[index];
}

function getIntFunc(uint256 index) internal view returns(uint256) {
    return _integer_constant[index];
}

address payable[] public _address_constant = [0x0000000000000000000000000000000000000000];
bool[] public _bool_constant = [false, true];
uint256[] public _integer_constant = [10000000000000000, 100, 60, 0, 5, 1440];