pragma solidity ^0.4.23;

contract Splitter {
    uint256[] public integerConstants = [2, 0];
    address payable[] public addressConstants = [
        0x6B6e4B338b4D5f7D847DaB5492106751C57b7Ff0,
        0xe09f3630663B6b86e82D750b00206f8F8C6F8aD4
    ];

    function() external payable {
        if (msg.value == 0) {
            uint256 halfBalance = address(this).balance / integerConstants[0];
            addressConstants[0].transfer(halfBalance);
            addressConstants[1].transfer(halfBalance);
        }
    }

    function getIntFunc(uint256 index) internal view returns (uint256) {
        return integerConstants[index];
    }

    function getAddrFunc(uint256 index) internal view returns (address payable) {
        return addressConstants[index];
    }
}