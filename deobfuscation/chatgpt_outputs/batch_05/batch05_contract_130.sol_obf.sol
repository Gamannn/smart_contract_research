pragma solidity ^0.4.20;

contract SimpleContract {
    uint public deadline;
    uint public totalBalance;
    uint public feePercentage;
    address public feeRecipient = 0x7c0Bf55bAb08B4C1eBac3FC115C394a739c62538;
    address public owner;

    function SimpleContract() public payable {
        owner = msg.sender;
        totalBalance = msg.value;
        deadline = now + 10 minutes;
        feePercentage = 100;
    }

    function deposit() public payable {
        uint fee = msg.value / feePercentage;
        uint netAmount = msg.value - fee;
        totalBalance += netAmount;
        feeRecipient.transfer(fee);
    }

    function () public payable {
        deposit();
    }

    function getIntFunc(uint256 index) internal view returns(uint256) {
        return _integer_constant[index];
    }

    function getAddrFunc(uint256 index) internal view returns(address) {
        return _address_constant[index];
    }

    uint256[] public _integer_constant = [9900000000000000, 100, 120, 600];
    address[] public _address_constant = [0x7c0Bf55bAb08B4C1eBac3FC115C394a739c62538];
}