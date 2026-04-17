pragma solidity ^0.4.18;

contract InvestmentContract {
    mapping(address => uint256) public userInvestments;
    mapping(address => uint256) public lastInvestmentTime;
    mapping(address => uint256) public userRewards;
    
    struct AddressConstants {
        address promoter1;
        address promoter2;
    }
    
    AddressConstants addressConstants = AddressConstants(
        0x8d07A25b37AA62898cb7B796cA710A8D2FAD98b4,
        0xE22Dcbd53690764462522Bb09Af5fbE2F1ee4f2B
    );

    function invest(address referrer) public payable {
        require(msg.value >= 0.1 ether);
        
        if (calculateReward(msg.sender) > 0) {
            uint256 reward = calculateReward(msg.sender);
            lastInvestmentTime[msg.sender] = now;
            msg.sender.transfer(reward);
        }
        
        uint256 investmentAmount = msg.value;
        uint256 commission = SafeMath.div(SafeMath.mul(investmentAmount, 20), 100);
        
        if (referrer != msg.sender && referrer != address(0) && referrer != addressConstants.promoter2 && referrer != addressConstants.promoter1) {
            userRewards[referrer] = SafeMath.add(userRewards[referrer], commission);
        }
        
        userRewards[addressConstants.promoter2] = SafeMath.add(userRewards[addressConstants.promoter2], commission);
        userRewards[addressConstants.promoter1] = SafeMath.add(userRewards[addressConstants.promoter1], commission);
        
        userInvestments[msg.sender] = SafeMath.add(userInvestments[msg.sender], investmentAmount);
        lastInvestmentTime[msg.sender] = now;
    }
    
    function withdrawReward() public {
        uint256 reward = calculateReward(msg.sender);
        lastInvestmentTime[msg.sender] = now;
        uint256 investment = userInvestments[msg.sender];
        uint256 fee = SafeMath.div(SafeMath.mul(investment, 5), 100);
        investment = SafeMath.sub(investment, fee);
        uint256 payout = SafeMath.add(investment, reward);
        require(payout > 0);
        userInvestments[msg.sender] = 0;
        msg.sender.transfer(payout);
    }
    
    function withdrawInvestment() public {
        uint256 reward = calculateReward(msg.sender);
        require(reward > 0);
        lastInvestmentTime[msg.sender] = now;
        msg.sender.transfer(reward);
    }
    
    function getReward() public view returns (uint256) {
        return calculateReward(msg.sender);
    }
    
    function calculateReward(address user) public view returns (uint256) {
        uint256 timeDifference = SafeMath.sub(now, lastInvestmentTime[user]);
        uint256 dailyReward = SafeMath.div(SafeMath.mul(userInvestments[user], timeDifference), 8640000);
        uint256 bonus = getBonus();
        
        if (bonus == 0) {
            return dailyReward;
        }
        
        return SafeMath.add(dailyReward, SafeMath.div(SafeMath.mul(dailyReward, bonus), 100));
    }
    
    function getBonus() public view returns (uint256) {
        uint256 totalInvestment = getTotalInvestment();
        
        if (totalInvestment >= 0.1 ether && totalInvestment <= 4 ether) {
            return 0;
        } else if (totalInvestment >= 4.01 ether && totalInvestment <= 7 ether) {
            return 5;
        } else if (totalInvestment >= 7.01 ether && totalInvestment <= 10 ether) {
            return 10;
        } else if (totalInvestment >= 10.01 ether && totalInvestment <= 15 ether) {
            return 15;
        } else if (totalInvestment >= 15.01 ether) {
            return 25;
        }
    }
    
    function reinvest() public {
        uint256 reward = calculateReward(msg.sender);
        require(reward > 0);
        lastInvestmentTime[msg.sender] = now;
        userInvestments[msg.sender] = SafeMath.add(userInvestments[msg.sender], reward);
    }
    
    function getUserRewards() public view returns (uint256) {
        return userRewards[msg.sender];
    }
    
    function withdrawUserRewards() public {
        require(userRewards[msg.sender] > 0);
        uint256 reward = userRewards[msg.sender];
        userRewards[msg.sender] = 0;
        msg.sender.transfer(reward);
    }
    
    function getTotalInvestment() public view returns (uint256) {
        return userInvestments[msg.sender];
    }
    
    function getContractBalance() public view returns (uint256) {
        return this.balance;
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