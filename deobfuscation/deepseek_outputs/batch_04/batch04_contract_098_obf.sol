```solidity
pragma solidity ^0.4.24;

contract InvestmentContract {
    using SafeMath for uint256;
    
    mapping(address => uint256) public investments;
    mapping(address => uint256) public investmentTimestamps;
    mapping(address => uint256) public withdrawnAmounts;
    mapping(address => uint256) public bountyBalances;
    
    uint256 public minimumInvestment = 0.01 ether;
    uint256 public dailyInterestRate = 4;
    
    address public owner;
    address public ownerWallet;
    address public bountyManager;
    
    event Invest(address indexed investor, uint256 amount);
    event Withdraw(address indexed investor, uint256 amount);
    event Bounty(address indexed recipient, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor(address _bountyManager) public {
        owner = msg.sender;
        ownerWallet = msg.sender;
        bountyManager = _bountyManager;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyBountyManager() {
        require(msg.sender == bountyManager);
        _;
    }
    
    function transferOwnership(address newOwner, address newOwnerWallet) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        ownerWallet = newOwnerWallet;
    }
    
    function () external payable {
        require(msg.value >= minimumInvestment);
        
        if (investments[msg.sender] > 0) {
            if (withdrawDividends()) {
                withdrawnAmounts[msg.sender] = 0;
            }
        }
        
        investments[msg.sender] = investments[msg.sender].add(msg.value);
        investmentTimestamps[msg.sender] = block.timestamp;
        
        ownerWallet.transfer(msg.value.div(100).mul(5));
        
        emit Invest(msg.sender, msg.value);
    }
    
    function calculateDividends(address _address) view public returns (uint256) {
        uint256 minutesPassed = now.sub(investmentTimestamps[_address]).div(1 minutes);
        uint256 dailyProfit = investments[_address].mul(dailyInterestRate).div(100);
        uint256 currentDividend = dailyProfit.mul(minutesPassed).div(1440);
        uint256 balance = currentDividend.sub(withdrawnAmounts[_address]);
        return balance;
    }
    
    function withdrawDividends() public returns (bool) {
        require(investmentTimestamps[msg.sender] > 0);
        
        uint256 dividendAmount = calculateDividends(msg.sender);
        
        if (address(this).balance >= dividendAmount) {
            if (dividendAmount > 0) {
                withdrawnAmounts[msg.sender] = withdrawnAmounts[msg.sender].add(dividendAmount);
                msg.sender.transfer(dividendAmount);
                emit Withdraw(msg.sender, dividendAmount);
            }
            return true;
        } else {
            return false;
        }
    }
    
    function claimBounty() public {
        uint256 bountyBalance = bountyBalances[msg.sender];
        
        if (bountyBalance >= minimumInvestment) {
            if (address(this).balance >= bountyBalance) {
                bountyBalances[msg.sender] = 0;
                msg.sender.transfer(bountyBalance);
                emit Bounty(msg.sender, bountyBalance);
            }
        }
    }
    
    function getDividends() public view returns (uint256) {
        return calculateDividends(msg.sender);
    }
    
    function getWithdrawnAmount(address _address) public view returns (uint256) {
        return withdrawnAmounts[_address];
    }
    
    function getInvestment(address _address) public view returns (uint256) {
        return investments[_address];
    }
    
    function getBountyBalance(address _address) public view returns (uint256) {
        return bountyBalances[_address];
    }
    
    function addBounty(address _address, uint256 _amount) public onlyBountyManager {
        bountyBalances[_address] = bountyBalances[_address].add(_amount);
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