```solidity
pragma solidity ^0.4.25;

contract Ox22466a084ceba6fe09a32f9f9ad72ffe387c9f2a {
    using SafeMath for uint256;
    
    mapping(address => uint256) public userDeposits;
    mapping(address => uint256) public depositTimestamps;
    mapping(address => uint256) public totalWithdrawn;
    mapping(address => uint256) public referralBonuses;
    
    uint256 public dailyPercent = 5;
    
    address public owner;
    address public ownerWallet;
    uint256 public stakingRequirement = 0;
    uint256 public bountyRequirement = 10 finney;
    uint256 public minimumInvestment = 0;
    
    event Invest(address indexed investor, uint256 amount);
    event Withdraw(address indexed investor, uint256 amount);
    event Bounty(address indexed referrer, uint256 amount);
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
        invest(address(0));
    }
    
    function invest(address referrer) public payable {
        require(msg.value > minimumInvestment);
        
        address investor = msg.sender;
        
        if(referrer != address(0) && userDeposits[referrer] >= stakingRequirement) {
            referralBonuses[referrer] = referralBonuses[referrer].add(msg.value.mul(5).div(100));
        }
        
        if(userDeposits[msg.sender] > 0) {
            if(withdraw()) {
                totalWithdrawn[msg.sender] = 0;
            }
        }
        
        userDeposits[msg.sender] = userDeposits[msg.sender].add(msg.value);
        depositTimestamps[msg.sender] = block.timestamp;
        ownerWallet.transfer(msg.value.mul(5).div(100));
        
        emit Invest(msg.sender, msg.value);
    }
    
    function calculateDividends(address investor) public view returns (uint256) {
        uint256 timeDiff = now.sub(depositTimestamps[investor]).div(1 minutes);
        uint256 dailyPayout = userDeposits[investor].mul(dailyPercent).div(100);
        uint256 dividends = dailyPayout.mul(timeDiff).div(1440);
        uint256 payout = dividends.sub(totalWithdrawn[investor]);
        return payout;
    }
    
    function withdraw() public returns (bool) {
        require(depositTimestamps[msg.sender] > 0);
        
        uint256 payout = calculateDividends(msg.sender);
        
        if(address(this).balance > payout) {
            if(payout > 0) {
                totalWithdrawn[msg.sender] = totalWithdrawn[msg.sender].add(payout);
                msg.sender.transfer(payout);
                emit Withdraw(msg.sender, payout);
            }
            return true;
        } else {
            return false;
        }
    }
    
    function claimBounty() public {
        uint256 bountyAmount = referralBonuses[msg.sender];
        
        if(bountyAmount >= bountyRequirement) {
            if(address(this).balance > bountyAmount) {
                referralBonuses[msg.sender] = 0;
                msg.sender.transfer(bountyAmount);
                emit Bounty(msg.sender, bountyAmount);
            }
        }
    }
    
    function myDividends() public view returns (uint256) {
        return calculateDividends(msg.sender);
    }
    
    function userTotalWithdrawn(address user) public view returns (uint256) {
        return totalWithdrawn[user];
    }
    
    function userBalance(address user) public view returns (uint256) {
        return userDeposits[user];
    }
    
    function userReferralBonus(address user) public view returns (uint256) {
        return referralBonuses[user];
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if(a == 0) {
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
```