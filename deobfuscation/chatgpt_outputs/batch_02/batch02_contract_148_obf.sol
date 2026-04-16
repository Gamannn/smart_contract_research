pragma solidity ^0.4.24;

contract PaymentSplitter {
    
    address payable[] public recipients = [
        0xF4c6BB681800Ffb96Bc046F56af9f06Ab5774156, 
        0xD79D762727A6eeb9c47Cfb6FB451C858dfBF8405, 
        0x83c0Efc6d8B16D87BFe1335AB6BcAb3Ed3960285
    ];
    
    uint256 public constant splitFactor = 3;

    function deposit() public payable {}

    function() public payable {}

    function distributeFunds() public {
        uint256 balance = address(this).balance;
        recipients[0].transfer(balance / splitFactor);
        recipients[1].transfer(balance / splitFactor);
        recipients[2].transfer(address(this).balance);
    }

    function getRecipient(uint256 index) internal view returns(address payable) {
        return recipients[index];
    }

    function getSplitFactor() internal view returns(uint256) {
        return splitFactor;
    }
}