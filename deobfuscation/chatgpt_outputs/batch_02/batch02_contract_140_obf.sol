pragma solidity ^0.4.18;

contract TimedRewardContract {
    uint256 public rewardPool;
    uint256 public winnerPool;
    uint256 public totalFunds;
    address public lastParticipant;
    address public owner;
    uint256 public deadline;

    function TimedRewardContract() public payable {
        owner = msg.sender;
        deadline = now + 30 minutes;
        lastParticipant = msg.sender;
        totalFunds += msg.value;
    }

    function participate() public payable {
        require(msg.value >= 0.001 ether);
        if (now > deadline) {
            revert();
        }
        totalFunds += msg.value * 8 / 10;
        winnerPool += msg.value * 2 / 10;
        lastParticipant = msg.sender;
        deadline = now + 30 minutes;
    }

    function withdrawFunds() public {
        require(msg.sender == lastParticipant);
        require(now > deadline);
        uint256 amount = totalFunds;
        totalFunds = 0;
        msg.sender.transfer(amount);
    }

    function withdrawWinnerReward() public {
        uint256 amount = winnerPool;
        winnerPool = 0;
        owner.transfer(amount);
    }

    function getConstant(uint256 index) internal view returns (uint256) {
        return _integer_constant[index];
    }

    uint256[] public _integer_constant = [10, 10800, 1, 0, 8, 2, 1800, 1000000000000000];
}