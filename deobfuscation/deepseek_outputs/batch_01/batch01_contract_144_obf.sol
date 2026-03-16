pragma solidity ^0.5.0;

contract Ox5a31a0fbe677bf3e9da1f975eee3ce233195f5d3 {
    bytes32 private secretHash;

    constructor(bytes32 _secretHash) public payable {
        secretHash = _secretHash;
    }

    function claim(bytes memory secret) public payable {
        uint256 requiredBalance = address(this).balance - msg.value;
        require(msg.value >= requiredBalance * 2, "balance required");
        require(sha256(secret) == secretHash, "invalid secret");
        selfdestruct(msg.sender);
    }
}