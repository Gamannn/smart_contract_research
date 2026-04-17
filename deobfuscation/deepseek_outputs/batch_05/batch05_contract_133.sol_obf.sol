```solidity
pragma solidity ^0.4.18;

contract InvestmentContract {
    mapping (address => uint256) public userDeposits;
    mapping (address => uint256) public lastActionTime;
    mapping (address => uint256) public referralRewards;
    
    address public owner;
    address public feeReceiver;
    
    function invest(address referrer) public payable {
        require(msg.value >= 0.01 ether);
        
        uint256 dividends = calculateDividends(msg.sender);
        if(dividends > 0) {
            lastActionTime[msg.sender] = now;
            msg.sender.transfer(dividends);
        }
        
        uint256 investmentAmount = msg.value;
        uint256 referralFee = SafeMath.div(investmentAmount, 10);
        
        if(referrer != msg.sender && 
           referrer != address(0x1) && 
           referrer != owner && 
           referrer != feeReceiver) {
            referralRewards[referrer] = SafeMath.add(referralRewards[referrer], referralFee);
        }
        
        referralRewards[owner] = SafeMath.add(referralRewards[owner], SafeMath.div(investmentAmount, 40));
        referralRewards[feeReceiver] = SafeMath.add(referralRewards[feeReceiver], SafeMath.div(investmentAmount, 100));
        
        userDeposits[msg.sender] = SafeMath.add(userDeposits[msg.sender], investmentAmount);
        lastActionTime[msg.sender] = now;
    }
    
    function withdraw() public {
        uint256 dividends = calculateDividends(msg.sender);
        lastActionTime[msg.sender] = now;
        
        uint256 deposit = userDeposits[msg.sender];
        uint256 dailyReturn = SafeMath.div(deposit, 2);
        deposit = SafeMath.sub(deposit, dailyReturn);
        
        uint256 totalWithdraw = SafeMath.add(deposit, dividends);
        require(totalWithdraw > 0);
        
        userDeposits[msg.sender] = 0;
        msg.sender.transfer(totalWithdraw);
    }
    
    function withdrawDividends() public {
        uint256 dividends = calculateDividends(msg.sender);
        require(dividends > 0);
        lastActionTime[msg.sender] = now;
        msg.sender.transfer(dividends);
    }
    
    function getDividends() public view returns(uint256) {
        return calculateDividends(msg.sender);
    }
    
    function calculateDividends(address user) public view returns(uint256) {
        uint256 timePassed = SafeMath.sub(now, lastActionTime[user]);
        return SafeMath.div(SafeMath.mul(timePassed, userDeposits[user]), 2592000);
    }
    
    function reinvest() public {
        uint256 dividends = calculateDividends(msg.sender);
        require(dividends > 0);
        lastActionTime[msg.sender] = now;
        userDeposits[msg.sender] = SafeMath.add(userDeposits[msg.sender], dividends);
    }
    
    function getReferralRewards() public view returns(uint256) {
        return referralRewards[msg.sender];
    }
    
    function withdrawReferralRewards() public {
        require(referralRewards[msg.sender] > 0);
        uint256 rewards = referralRewards[msg.sender];
        referralRewards[msg.sender] = 0;
        msg.sender.transfer(rewards);
    }
    
    function getDeposit() public view returns(uint256) {
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