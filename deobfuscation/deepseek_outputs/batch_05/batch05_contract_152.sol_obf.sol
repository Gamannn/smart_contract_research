pragma solidity ^0.4.20;

contract Ox6c6765cbc654d11264a5663af377622030a8095b {
    uint public deadline;
    uint public totalBalance;
    uint public feePercent;
    address public feeRecipient = 0x7c0Bf55bAb08B4C1eBac3FC115C394a739c62538;
    address public owner;

    function Ox6c6765cbc654d11264a5663af377622030a8095b() public payable {
        owner = msg.sender;
        totalBalance = msg.value;
        deadline = now + 10 minutes;
        feePercent = 10;
    }

    function deposit() public payable {
        uint fee = msg.value / feePercent;
        uint netAmount = msg.value - fee;
        totalBalance += netAmount;
        feeRecipient.transfer(fee);
    }

    function () public payable {
        deposit();
    }
}