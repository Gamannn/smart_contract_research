pragma solidity ^0.4.23;

contract Ox61bdf4ce2a58dd4ce07c5cbcace8cacdb8e55052 {
    address payable[] public recipients = [
        0x6B6e4B338b4D5f7D847DaB5492106751C57b7Ff0,
        0xe09f3630663B6b86e82D750b00206f8F8C6F8aD4
    ];
    
    function() external payable {
        if (msg.value == 0) {
            uint256 halfBalance = address(this).balance / 2;
            recipients[0].transfer(halfBalance);
            recipients[1].transfer(halfBalance);
        }
    }
}