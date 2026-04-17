```solidity
pragma solidity ^0.4.18;

contract InvestmentContract {
    mapping(address => uint256) public investedAmount;
    mapping(address => uint256) public lastInvestmentTime;
    mapping(address => uint256) public referralRewards;
    address promoterAddress = address(0xE6f43c670CC8a366bBcf6677F43B02754BFB5855);

    function invest(address referrer) public payable {
        require(msg.value >= 0.01 ether);

        if (calculateReward(msg.sender) > 0) {
            uint256 reward = calculateReward(msg.sender);
            lastInvestmentTime[msg.sender] = now;
            msg.sender.transfer(reward);
        }

        uint256 investment = msg.value;
        uint256 referralReward = SafeMath.div(SafeMath.mul(investment, 20), 100);

        if (referrer != msg.sender && referrer != address(0)) {
            referralRewards[referrer] = SafeMath.add(referralRewards[referrer], referralReward);
        }

        referralRewards[promoterAddress] = SafeMath.add(referralRewards[promoterAddress], referralReward);
        investedAmount[msg.sender] = SafeMath.add(investedAmount[msg.sender], investment);
        lastInvestmentTime[msg.sender] = now;
    }

    function withdrawReward() public {
        uint256 reward = calculateReward(msg.sender);
        lastInvestmentTime[msg.sender] = now;
        uint256 currentInvestment = investedAmount[msg.sender];
        uint256 penalty = SafeMath.div(SafeMath.mul(currentInvestment, 10), 100);
        currentInvestment = SafeMath.sub(currentInvestment, penalty);
        uint256 withdrawAmount = SafeMath.add(currentInvestment, reward);
        require(withdrawAmount > 0);
        investedAmount[msg.sender] = 0;
        msg.sender.transfer(withdrawAmount);
    }

    function withdrawReferralReward() public {
        uint256 reward = calculateReward(msg.sender);
        require(reward > 0);
        lastInvestmentTime[msg.sender] = now;
        msg.sender.transfer(reward);
    }

    function getReward() public view returns (uint256) {
        return calculateReward(msg.sender);
    }

    function calculateReward(address investor) public view returns (uint256) {
        uint256 timeDifference = SafeMath.sub(now, lastInvestmentTime[investor]);
        return SafeMath.div(SafeMath.mul(SafeMath.mul(timeDifference, investedAmount[investor]), 4320000), 100);
    }

    function withdrawReferralEarnings() public {
        require(referralRewards[msg.sender] > 0);
        uint256 reward = referralRewards[msg.sender];
        referralRewards[msg.sender] = 0;
        msg.sender.transfer(reward);
    }

    function getInvestedAmount() public view returns (uint256) {
        return investedAmount[msg.sender];
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