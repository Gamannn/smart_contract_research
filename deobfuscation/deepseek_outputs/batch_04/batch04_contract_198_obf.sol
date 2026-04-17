```solidity
pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract InvestmentContract {
    using SafeMath for uint256;
    
    address public owner;
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public lastWithdrawalTime;
    mapping(address => uint256) public totalWithdrawn;
    
    function transferOwnership(address newOwner) external {
        require(msg.sender == owner);
        require(newOwner != address(0));
        owner = newOwner;
    }
    
    function getInvestorInfo(address investor) public view returns(
        uint256 depositAmount,
        uint256 totalWithdrawnAmount,
        uint256 pendingReward
    ) {
        depositAmount = deposits[investor];
        totalWithdrawnAmount = totalWithdrawn[investor];
        pendingReward = calculateReward(investor);
    }
    
    constructor() public {
        owner = msg.sender;
    }
    
    function() external payable {
        invest();
    }
    
    function invest() public payable {
        require(msg.value > 10000000000000000);
        
        owner.transfer(msg.value.div(5));
        
        if (deposits[msg.sender] > 0) {
            uint256 reward = calculateReward(msg.sender);
            if (reward != 0) {
                totalWithdrawn[msg.sender] = totalWithdrawn[msg.sender].add(reward);
                msg.sender.transfer(reward);
            }
            lastWithdrawalTime[msg.sender] = block.timestamp;
            deposits[msg.sender] = deposits[msg.sender].add(msg.value);
            return;
        }
        
        lastWithdrawalTime[msg.sender] = block.timestamp;
        deposits[msg.sender] = msg.value;
    }
    
    function withdrawReward() public {
        uint256 reward = calculateReward(msg.sender);
        if (reward == 0) {
            revert();
        }
        
        totalWithdrawn[msg.sender] = totalWithdrawn[msg.sender].add(reward);
        lastWithdrawalTime[msg.sender] = block.timestamp.sub(
            (block.timestamp.sub(lastWithdrawalTime[msg.sender])).mod(1 days)
        );
        msg.sender.transfer(reward);
    }
    
    function calculateReward(address investor) internal view returns(uint256) {
        uint256 timeSinceLastWithdrawal = block.timestamp.sub(lastWithdrawalTime[investor]);
        uint256 fullDays = timeSinceLastWithdrawal.sub(timeSinceLastWithdrawal.mod(1 days));
        
        return fullDays.mul(
            deposits[investor].mul(3).div(100)
        ).div(1 days);
    }
}
```