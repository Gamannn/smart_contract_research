pragma solidity ^0.4.18;

contract TimeLockedSavings {
    struct Savings {
        uint256 totalBalance;
        uint256 pendingWithdrawals;
        uint256 totalDeposits;
        address lastDepositor;
        address owner;
        uint256 unlockTime;
    }

    Savings savings = Savings(0, 0, 0, address(0), address(0), 0);

    uint256[] public constants = [2, 10800, 0, 1, 10, 1000000000000000, 1800, 8];

    function TimeLockedSavings() public payable {
        savings.owner = msg.sender;
        savings.unlockTime = now + 30 minutes;
        savings.totalDeposits = msg.value;
    }

    function deposit() public payable {
        require(msg.value >= 0.001 ether);
        if (now > savings.unlockTime) {
            withdraw();
        }
        savings.totalDeposits += msg.value * 8;
        savings.pendingWithdrawals += msg.value * 2 / 1;
        savings.lastDepositor = msg.sender;
        savings.unlockTime = now + 30 minutes;
    }

    function withdraw() public {
        require(msg.sender == savings.lastDepositor);
        require(now > savings.unlockTime);
        uint pendingWithdrawals = savings.pendingWithdrawals;
        savings.totalDeposits = 0;
        savings.lastDepositor.transfer(pendingWithdrawals);
    }

    function withdrawOwner() public {
        uint pendingWithdrawals = savings.pendingWithdrawals;
        savings.pendingWithdrawals = 0;
        savings.owner.transfer(pendingWithdrawals);
    }

    function getIntFunc(uint256 index) internal view returns(uint256) {
        return constants[index];
    }
}