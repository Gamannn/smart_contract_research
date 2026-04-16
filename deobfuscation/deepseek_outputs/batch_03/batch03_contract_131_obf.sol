pragma solidity ^0.4.25;

contract Ox72a8e405dd5fea2eaacab48aabc803383a32b5aa {
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public totalInvested;
    mapping(address => uint) public lastActionTime;

    struct PoolState {
        uint256 nextAdjustmentTime;
        uint256 currentRate;
        uint256 lastPoolBalance;
    }

    PoolState public poolState = PoolState(now + 2 days, 1, 0);

    function() external payable {
        uint currentTime = now;
        uint lastUserTime = lastActionTime[msg.sender];

        if (lastUserTime > currentTime) {
            lastUserTime = currentTime;
        }

        lastActionTime[msg.sender] = currentTime;

        if (currentTime >= poolState.nextAdjustmentTime) {
            uint256 currentBalance = address(this).balance;

            if (currentBalance < poolState.lastPoolBalance) {
                currentBalance = poolState.lastPoolBalance;
            }

            poolState.currentRate = (currentBalance - poolState.lastPoolBalance) / 10e18 + 1;

            if (poolState.currentRate > 10) {
                poolState.currentRate = 10;
            } else if (poolState.currentRate < 1) {
                poolState.currentRate = 1;
            }

            poolState.lastPoolBalance = currentBalance;
            poolState.nextAdjustmentTime = currentTime + 2 days;
        }

        if (deposits[msg.sender] != 0) {
            uint256 reward = deposits[msg.sender] * poolState.currentRate / 100 * (currentTime - lastUserTime) / 1 days;

            if (reward > deposits[msg.sender] / 10) {
                reward = deposits[msg.sender] / 10;
            }

            if (currentTime - lastUserTime < 1 days && reward > 5e16) {
                reward = 5e16;
            }

            if (reward > address(this).balance / 10) {
                reward = address(this).balance / 10;
            }

            if (reward > 0) {
                msg.sender.transfer(reward);
            }

            if (currentTime - lastUserTime >= 1 days && msg.value >= 1e18) {
                deposits[msg.sender] += msg.value;
                totalInvested[msg.sender] += msg.value;
            }
        }

        deposits[msg.sender] += msg.value;
    }
}