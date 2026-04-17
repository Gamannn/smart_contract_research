pragma solidity ^0.4.20;

contract TimedPaymentContract {
    uint public unlockTime;
    uint public contractBalance;
    uint public feePercentage;
    address public feeRecipient = 0x7c0Bf55bAb08B4C1eBac3FC115C394a739c62538;
    address public owner;

    function TimedPaymentContract() public payable {
        owner = msg.sender;
        contractBalance = msg.value;
        unlockTime = now + 10 minutes;
        feePercentage = 10;
    }

    function deposit() public payable {
        uint fee = msg.value / feePercentage;
        uint amountToContract = msg.value - fee;
        contractBalance += amountToContract;
        feeRecipient.transfer(fee);
    }

    function withdraw() public {
        require(now >= unlockTime);
        require(msg.sender == owner);
        uint amount = contractBalance;
        contractBalance = 0;
        owner.transfer(amount);
    }

    function() public payable {
        deposit();
    }

    function getAddressConstant(uint256 index) internal view returns(address payable) {
        return _address_constant[index];
    }

    function getIntegerConstant(uint256 index) internal view returns(uint256) {
        return _integer_constant[index];
    }

    address payable[] public _address_constant = [0x7c0Bf55bAb08B4C1eBac3FC115C394a739c62538];
    uint256[] public _integer_constant = [90000000, 600, 10, 120];

    struct Scalar2Vector {
        address lastBidder;
        address feeRecipient;
        uint256 feePercentage;
        uint256 contractBalance;
        uint256 unlockTime;
    }

    Scalar2Vector s2c = Scalar2Vector(address(0), 0, 0, 0, 0);
}