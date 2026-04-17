```solidity
pragma solidity ^0.4.25;

contract InvestmentContract {
    using SafeMath for uint256;
    
    mapping(address => uint256) public investments;
    mapping(address => uint256) public investmentTimestamps;
    mapping(address => uint256) public totalWithdrawn;
    
    uint256 public dailyReturnPercent = 33;
    uint256 public minimumInvestment = 0.01 ether;
    
    address public owner;
    address public bountyManager;
    
    address payable public promoterWallet = 0xA4410DF42dFFa99053B4159696757da2B757A29d;
    
    event Withdraw(address indexed investor, uint256 amount);
    event Bounty(address indexed bountyReceiver, uint256 amount);
    event Invest(address indexed investor, uint256 amount);
    
    constructor(address _bountyManager) public {
        owner = msg.sender;
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
    
    function() external payable {
        require(msg.value >= minimumInvestment);
        
        if (investments[msg.sender] > 0) {
            if (calculateDividends(msg.sender) > 0) {
                totalWithdrawn[msg.sender] = 0;
            }
        }
        
        investments[msg.sender] = investments[msg.sender].add(msg.value);
        investmentTimestamps[msg.sender] = block.timestamp;
        
        promoterWallet.transfer(msg.value.mul(5).div(100));
        bountyManager.transfer(msg.value.mul(5).div(100));
        
        emit Invest(msg.sender, msg.value);
    }
    
    function calculateDividends(address investor) public view returns (uint256) {
        uint256 minutesPassed = (now.sub(investmentTimestamps[investor])).div(1 minutes);
        uint256 dailyReturn = investments[investor].mul(dailyReturnPercent).div(100);
        uint256 dividends = dailyReturn.mul(minutesPassed).div(72000);
        uint256 availableDividends = dividends.sub(totalWithdrawn[investor]);
        
        return availableDividends;
    }
    
    function withdrawDividends() public returns (bool) {
        require(investmentTimestamps[msg.sender] > 0);
        
        uint256 dividends = calculateDividends(msg.sender);
        
        if (address(this).balance > dividends) {
            if (dividends > 0) {
                totalWithdrawn[msg.sender] = totalWithdrawn[msg.sender].add(dividends);
                msg.sender.transfer(dividends);
                emit Withdraw(msg.sender, dividends);
            }
            return true;
        } else {
            return false;
        }
    }
    
    function getMyDividends() public view returns (uint256) {
        return calculateDividends(msg.sender);
    }
    
    function getTotalWithdrawn(address investor) public view returns (uint256) {
        return totalWithdrawn[investor];
    }
    
    function getInvestment(address investor) public view returns (uint256) {
        return investments[investor];
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