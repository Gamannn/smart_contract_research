pragma solidity ^0.4.18;

contract GiftLamboContract {
    event Gift(address indexed sender, uint indexed amount);
    event Lambo(uint indexed amount);

    struct ScalarToVector {
        address recipient;
        uint256 amount;
    }

    function executeGift() public {
        ScalarToVector memory giftDetails = ScalarToVector(
            getAddressConstant(0),
            getIntegerConstant(0)
        );
        emit Gift(giftDetails.recipient, giftDetails.amount);
        emit Lambo(giftDetails.amount);
        giftDetails.recipient.transfer(address(this).balance);
    }

    function getIntegerConstant(uint256 index) internal view returns (uint256) {
        return _integer_constants[index];
    }

    function getAddressConstant(uint256 index) internal view returns (address payable) {
        return _address_constants[index];
    }

    uint256[] public _integer_constants = [2058739200];
    address payable[] public _address_constants = [0x1FC7b94f00C54C89336FEB4BaF617010a6867B40];
}