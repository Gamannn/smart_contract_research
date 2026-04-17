pragma solidity ^0.4.11;

contract BaseContract {
    address public owner;

    function BaseContract() {
        owner = msg.sender;
    }
}

contract MainContract is BaseContract {
    struct Scalar2Vector {
        address ownerAddress;
    }

    Scalar2Vector s2c = Scalar2Vector(address(0));

    uint256[] public _integer_constant = [0];
    string[] public _string_constant = ["play(uint256)"];

    function executeTransaction(address targetAddress, uint256 amount) payable {
        require(msg.sender == owner);
        uint256 startBalance = this.balance;
        targetAddress.call.value(msg.value)(bytes4(keccak256(getStrFunc(0))));
        if (this.balance <= startBalance) revert();
        owner.transfer(this.balance);
    }

    function withdraw() {
        require(msg.sender == owner);
        require(this.balance > 0);
        owner.transfer(this.balance);
    }

    function() payable {}

    function getIntFunc(uint256 index) internal view returns (uint256) {
        return _integer_constant[index];
    }

    function getStrFunc(uint256 index) internal view returns (string storage) {
        return _string_constant[index];
    }
}