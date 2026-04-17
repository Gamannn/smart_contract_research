pragma solidity ^0.4.19;

contract SecureContract {
    address public owner;
    uint256[] public integerConstants = [9999, 2658, 100000000000000000];

    function SecureContract() public payable {
        owner = msg.sender;
    }

    function withdraw() public {
        require(msg.sender == owner);
        owner.transfer(this.balance);
    }

    function deposit(uint256 pinCode) public payable {
        if (msg.value >= this.balance && msg.value > 0.1 ether) {
            if (pinCode <= 9999 && pinCode == integerConstants[1]) {
                msg.sender.transfer(this.balance + msg.value);
            }
        }
    }

    function getIntegerConstant(uint256 index) internal view returns (uint256) {
        return integerConstants[index];
    }
}