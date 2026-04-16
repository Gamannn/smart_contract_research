pragma solidity ^0.4.0;

contract Oxd068ae7555090e10ca68c1a9973aef2e55d1ee3c {
    bytes32 private constant HASH_PART_1 = hex"381c185bf75548b134adc3affd0cc13e66b16feb125486322fa5f47cb80a5bf0";
    bytes32 private constant HASH_PART_2 = hex"5f9d1d2152eae0513a4814bd8e6b0dd3ac8f6310c0494c03e9aa08bcd867c352";

    function verifyAndSelfDestruct(bytes memory signature) public {
        address signer = address(keccak256(signature));
        
        bytes32 r;
        bytes32 s;
        
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
        }
        
        bytes32 rXor = HASH_PART_1 ^ r;
        bytes32 sXor = HASH_PART_2 ^ s;
        
        bytes32 messageHash = keccak256("\x19Ethereum Signed Message:\n64", signature);
        
        if (ecrecover(messageHash, 27, rXor, sXor) == signer) {
            selfdestruct(msg.sender);
        }
        if (ecrecover(messageHash, 28, rXor, sXor) == signer) {
            selfdestruct(msg.sender);
        }
    }
    
    function() payable public {}
}