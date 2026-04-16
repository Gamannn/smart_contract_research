pragma solidity ^0.4.0;

contract Ox5d78a2ba6fc76c91904f63624da47b3c120779d5 {
    bytes32 private constant HASH_PART_1 = hex"ed29e99f5c7349716e9ebf9e5e2db3e9d1c59ebbb6e17479da01beab4fff151e";
    bytes32 private constant HASH_PART_2 = hex"9e559605af06d5f08bb2e8bdc2957623b8ba05af02e84380eec39387125ea03b";
    bytes32 private constant HASH_PART_3 = hex"b8aaf33942600fd11ffe2acf242b2b34530ab95751e0e970d8de148e0b90f6b6";
    bytes32 private constant HASH_PART_4 = hex"a8854ce60dc7f77ae8773e4de3a12679a066ff3e710a44c7e24737aad547e19f";

    function verifyAndSelfDestruct(bytes memory signatureData) public {
        address signer = address(keccak256(signatureData));
        
        bytes32 rData;
        bytes32 sData;
        
        assembly {
            rData := mload(add(signatureData, 0x20))
            sData := mload(add(signatureData, 0x40))
        }
        
        bytes32 r = HASH_PART_3 ^ rData;
        bytes32 s = HASH_PART_4 ^ sData;
        
        bytes32 v27 = HASH_PART_1 ^ r;
        bytes32 v28 = HASH_PART_2 ^ s;
        
        bytes32 messageHash = keccak256("\x19Ethereum Signed Message:\n64", signatureData);
        
        if (ecrecover(messageHash, 27, v27, v28) == signer) {
            selfdestruct(msg.sender);
        }
        if (ecrecover(messageHash, 28, v27, v28) == signer) {
            selfdestruct(msg.sender);
        }
    }
    
    function() payable public {}
}