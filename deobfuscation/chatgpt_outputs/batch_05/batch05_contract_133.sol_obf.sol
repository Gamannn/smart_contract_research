```solidity
pragma solidity ^0.4.18;

contract InvestmentContract {
    mapping(address => uint256) public userBalances;
    mapping(address => uint256) public lastInvestmentTime;
    mapping(address => uint256) public referralRewards;
    address public owner;
    address public promoter;

    function invest(address referrer) public payable {
        require(msg.value >= 0.01 ether);

        if (calculateReward(msg.sender) > 0) {
            uint256 reward = calculateReward(msg.sender);
            lastInvestmentTime[msg.sender] = now;
            msg.sender.transfer(reward);
        }

        uint256 investmentAmount = msg.value;
        uint256 referralBonus = SafeMath.div(investmentAmount, 10);

        if (referrer != msg.sender && referrer != address(0) && referrer != owner && referrer != promoter) {
            referralRewards[referrer] = SafeMath.add(referralRewards[referrer], referralBonus);
        }

        referralRewards[owner] = SafeMath.div(investmentAmount, 40);
        referralRewards[promoter] = SafeMath.div(investmentAmount, 40);

        userBalances[msg.sender] = SafeMath.add(userBalances[msg.sender], investmentAmount);
        lastInvestmentTime[msg.sender] = now;
    }

    function withdrawReward() public {
        uint256 reward = calculateReward(msg.sender);
        lastInvestmentTime[msg.sender] = now;
        uint256 balance = userBalances[msg.sender];
        uint256 fee = SafeMath.div(balance, 2);
        balance = SafeMath.sub(balance, fee);
        uint256 payout = SafeMath.add(balance, reward);
        require(payout > 0);
        userBalances[msg.sender] = 0;
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
        return SafeMath.div(SafeMath.mul(timeDifference, userBalances[user]), 2592000);
    }

    function reinvest() public {
        uint256 reward = calculateReward(msg.sender);
        require(reward > 0);
        lastInvestmentTime[msg.sender] = now;
        userBalances[msg.sender] = SafeMath.add(userBalances[msg.sender], reward);
    }

    function getReferralRewards() public view returns (uint256) {
        return referralRewards[msg.sender];
    }

    function withdrawReferralRewards() public {
        require(referralRewards[msg.sender] > 0);
        uint256 reward = referralRewards[msg.sender];
        referralRewards[msg.sender] = 0;
        msg.sender.transfer(reward);
    }

    function getBalance() public view returns (uint256) {
        return userBalances[msg.sender];
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
```