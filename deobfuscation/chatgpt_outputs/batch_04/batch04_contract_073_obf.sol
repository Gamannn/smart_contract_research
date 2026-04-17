pragma solidity ^0.4.10;

contract RewardDistribution {
    struct Participant {
        uint lastParticipationTime;
        uint rewardDebt;
    }

    mapping(address => Participant) public participants;
    mapping(address => uint) public balances;
    mapping(address => uint) public rewardBalances;
    uint public totalRewards;
    uint public totalParticipants;
    uint public constant rewardRate = 1000000000000000000000000;
    uint public constant minParticipationInterval = 14 hours;

    function RewardDistribution() public {}

    function addParticipant(address participant) private {
        if (participants[participant].lastParticipationTime == 0) {
            participants[participant].lastParticipationTime = now;
            totalParticipants++;
        }
    }

    function updateBalance(address participant, uint amount) private {
        balances[participant] += amount;
        totalRewards += amount;
    }

    function updateRewardDebt(uint reward, uint totalReward) private {
        if (totalReward > 0) {
            totalRewards += (reward * rewardRate) / totalReward;
        }
    }

    function updateRewardBalance(address participant) private {
        rewardBalances[participant] = totalRewards;
    }

    function calculateReward(address participant) public view returns (uint) {
        uint rewardDifference = totalRewards - rewardBalances[participant];
        return (rewardDifference * balances[participant]) / totalRewards;
    }

    function participate() public {
        participants[msg.sender].lastParticipationTime = now;
    }

    function deposit() public payable {
        uint reward = calculateReward(msg.sender);
        addParticipant(msg.sender);
        updateBalance(msg.sender, msg.value);
        updateRewardBalance(msg.sender);
        updateRewardDebt(reward, totalRewards);
    }

    function withdraw(uint amount) public {
        require(amount <= balances[msg.sender]);
        uint reward = calculateReward(msg.sender);
        updateBalance(msg.sender, -amount);
        updateRewardBalance(msg.sender);
        updateRewardDebt(reward, totalRewards);
        msg.sender.transfer(amount);
    }

    function claimRewards() public {
        uint reward = calculateReward(msg.sender);
        updateBalance(msg.sender, reward);
        updateRewardBalance(msg.sender);
    }

    function forceWithdraw(address participant) public {
        require(now > participants[participant].lastParticipationTime + minParticipationInterval && balances[participant] > 0);
        uint reward = calculateReward(participant);
        uint penalty = balances[participant] / 10;
        uint penaltyReward = calculateReward(participant, penalty);
        updateRewardDebt(penalty, totalRewards);
        updateBalance(participant, -penaltyReward);
        updateRewardBalance(participant);
        participants[participant].lastParticipationTime = now;
    }
}