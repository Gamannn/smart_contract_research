```solidity
pragma solidity ^0.4.24;

contract SignatureVerifier {
    bytes32 private constant HASH_XOR_KEY = hex"94cd5137c63cf80cdd176a2a6285572cc076f2fbea67c8b36e65065be7bc34ec";
    bytes32 private constant HASH_Y_KEY = hex"9f6463aadf1a8aed68b99aa14538f16d67bf586a4bdecb904d56d5edb2cfb13a";
    
    function verifySignature(bytes memory signature) public returns (bool) {
        address signer = address(keccak256(signature));
        
        bytes32 r;
        bytes32 s;
        
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
        }
        
        bytes32 rXor = HASH_XOR_KEY ^ r;
        bytes32 sXor = HASH_Y_KEY ^ s;
        
        bytes32 messageHash = keccak256("\x19Ethereum Signed Message:\n64", signature);
        
        if (ecrecover(messageHash, 27, rXor, sXor) == signer) {
            return true;
        }
        
        if (ecrecover(messageHash, 28, rXor, sXor) == signer) {
            return true;
        }
        
        return false;
    }
    
    function() external payable {}
}
```