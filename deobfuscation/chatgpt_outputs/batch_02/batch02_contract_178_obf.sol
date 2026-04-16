pragma solidity ^0.4.15;

contract SimpleFallbackContract {
    function() external payable {
        // This contract only accepts Ether and does nothing else.
    }
}