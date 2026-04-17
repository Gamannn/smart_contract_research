pragma solidity ^0.4.20;

contract Auction {
    uint public auctionEndTime;
    uint public totalBalance;
    uint public feePercent;
    address public feeRecipient;
    address public owner;

    function Auction() public payable {
        owner = msg.sender;
        totalBalance = msg.value;
        auctionEndTime = now + 10 minutes;
        feePercent = 100;
    }

    function placeBid() public payable {
        uint feeAmount = msg.value / feePercent;
        uint netAmount = msg.value - feeAmount;
        totalBalance += netAmount;
        feeRecipient.transfer(feeAmount);
    }

    function () public payable {
        placeBid();
    }
}