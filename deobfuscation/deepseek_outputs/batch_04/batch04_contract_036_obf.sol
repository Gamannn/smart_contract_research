```solidity
pragma solidity ^0.4.18;

contract InvestmentContract {
    mapping (address => uint256) public userDeposits;
    mapping (address => uint256) public lastActionTime;
    mapping (address => uint256) public referralCommissions;
    
    address public promoter1 = 0x8d07A25b37AA62898cb7B796cA710A8D2FAD98b4;
    address public promoter2 = 0xE22Dcbd53690764462522Bb09Af5fbE2F1ee4f2B;
    
    function invest(address referrer) public payable {
        require(msg.value >= 0.1 ether);
        
        uint256 pendingRewards = calculateRewards(msg.sender);
        if(pendingRewards > 0){
            lastActionTime[msg.sender] = now;
            msg.sender.transfer(pendingRewards);
        }
        
        uint256 investmentAmount = msg.value;
        uint256 referralFee = SafeMath.div(investmentAmount, 20);
        
        if(referrer != msg.sender && 
           referrer != address(0x1) && 
           referrer != promoter2 && 
           referrer != promoter1){
            referralCommissions[referrer] = SafeMath.add(referralCommissions[referrer], referralFee);
        }
        
        referralCommissions[promoter2] = SafeMath.add(referralCommissions[promoter2], referralFee);
        referralCommissions[promoter1] = SafeMath.add(referralCommissions[promoter1], referralFee);
        
        userDeposits[msg.sender] = SafeMath.add(userDeposits[msg.sender], investmentAmount);
        lastActionTime[msg.sender] = now;
    }
    
    function withdraw() public {
        uint256 pendingRewards = calculateRewards(msg.sender);
        lastActionTime[msg.sender] = now;
        
        uint256 userDeposit = userDeposits[msg.sender];
        uint256 withdrawalFee = SafeMath.div(userDeposit, 5);
        userDeposit = SafeMath.sub(userDeposit, withdrawalFee);
        
        uint256 totalWithdraw = SafeMath.add(userDeposit, pendingRewards);
        require(totalWithdraw > 0);
        
        userDeposits[msg.sender] = 0;
        msg.sender.transfer(totalWithdraw);
    }
    
    function claimRewards() public {
        uint256 pendingRewards = calculateRewards(msg.sender);
        require(pendingRewards > 0);
        lastActionTime[msg.sender] = now;
        msg.sender.transfer(pendingRewards);
    }
    
    function getPendingRewards() public view returns(uint256) {
        return calculateRewards(msg.sender);
    }
    
    function calculateRewards(address user) public view returns(uint256) {
        uint256 timeDiff = SafeMath.sub(now, lastActionTime[user]);
        uint256 rewards = SafeMath.div(SafeMath.mul(timeDiff, userDeposits[user]), 8640000);
        
        uint256 penaltyRate = getPenaltyRate();
        if(penaltyRate == 0){
            return rewards;
        }
        
        return SafeMath.add(rewards, SafeMath.div(SafeMath.mul(rewards, penaltyRate), 100));
    }
    
    function getPenaltyRate() public view returns(uint256) {
        uint256 userDeposit = userDeposits[msg.sender];
        
        if(userDeposit >= 0.1 ether && 4 ether >= userDeposit){
            return 0;
        } else if(userDeposit >= 4.01 ether && 7 ether >= userDeposit){
            return 5;
        } else if(userDeposit >= 7.01 ether && 10 ether >= userDeposit){
            return 10;
        } else if(userDeposit >= 10.01 ether && 15 ether >= userDeposit){
            return 15;
        } else if(userDeposit >= 15.01 ether){
            return 25;
        }
    }
    
    function reinvest() public {
        uint256 pendingRewards = calculateRewards(msg.sender);
        require(pendingRewards > 0);
        lastActionTime[msg.sender] = now;
        userDeposits[msg.sender] = SafeMath.add(userDeposits[msg.sender], pendingRewards);
    }
    
    function getReferralCommissions() public view returns(uint256) {
        return referralCommissions[msg.sender];
    }
    
    function withdrawReferralCommissions() public {
        require(referralCommissions[msg.sender] > 0);
        uint256 commissionAmount = referralCommissions[msg.sender];
        referralCommissions[msg.sender] = 0;
        msg.sender.transfer(commissionAmount);
    }
    
    function getUserDeposit() public view returns(uint256) {
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