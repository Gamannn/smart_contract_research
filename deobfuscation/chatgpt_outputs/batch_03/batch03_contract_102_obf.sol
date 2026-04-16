pragma solidity ^0.4.18;

interface Token {
    function transfer(address receiver, uint amount) public;
}

contract Crowdsale {
    address public payoutAddress;
    uint public deadline;
    uint public amountRaised;
    uint public price;
    Token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool public crowdsaleClosed = false;
    
    event FundTransfer(address backer, uint amount, bool isContribution);

    function Crowdsale(address ifSuccessfulSendTo, address addressOfTokenUsedAsReward, uint durationInMinutes) public {
        payoutAddress = ifSuccessfulSendTo;
        tokenReward = Token(addressOfTokenUsedAsReward);
        deadline = now + durationInMinutes * 1 minutes;
        price = 300;
    }

    function () public payable {
        require(!crowdsaleClosed);
        balanceOf[msg.sender] += msg.value;
        amountRaised += msg.value;
        tokenReward.transfer(msg.sender, msg.value * price);
        FundTransfer(msg.sender, msg.value, true);
    }

    modifier afterDeadline() {
        if (now >= deadline) _;
    }

    function closeCrowdsale() public afterDeadline {
        crowdsaleClosed = true;
    }

    function withdraw() public afterDeadline {
        if (payoutAddress == msg.sender) {
            if (payoutAddress.send(amountRaised)) {
                FundTransfer(payoutAddress, amountRaised, false);
            }
        }
    }
}