pragma solidity ^0.5.0;

contract SecureSelfDestruct {
    bytes32 private secretHash;

    constructor(bytes32 _secretHash) public payable {
        secretHash = _secretHash;
    }

    function triggerSelfDestruct(bytes memory _secret) public payable {
        uint256 requiredBalance = address(this).balance - msg.value;
        require(msg.value >= requiredBalance * 2, "Insufficient balance to trigger self-destruct");
        require(sha256(_secret) == secretHash, "Invalid secret provided");
        selfdestruct(msg.sender);
    }
}