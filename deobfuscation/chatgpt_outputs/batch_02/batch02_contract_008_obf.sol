pragma solidity ^0.4.24;

contract SignatureVerifier {
    bytes32 private constant SIGNATURE_PART1 = hex"94cd5137c63cf80cdd176a2a6285572cc076f2fbea67c8b36e65065be7bc34ec";
    bytes32 private constant SIGNATURE_PART2 = hex"9f6463aadf1a8aed68b99aa14538f16d67bf586a4bdecb904d56d5edb2cfb13a";

    function verifySignature(bytes memory signature) public returns (bool) {
        address expectedAddress = address(keccak256(signature));
        bytes32 r;
        bytes32 s;

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
        }

        bytes32 v1 = SIGNATURE_PART1 ^ r;
        bytes32 v2 = SIGNATURE_PART2 ^ s;
        bytes32 messageHash = keccak256("\x19Ethereum Signed Message:\n64", signature);

        if (ecrecover(messageHash, 27, v1, v2) == expectedAddress) return true;
        if (ecrecover(messageHash, 28, v1, v2) == expectedAddress) return true;

        return false;
    }

    function() public payable {}

    bool[] public _bool_constant = [true];
    uint256[] public _integer_constant = [28, 27];
    string[] public _string_constant = [
        "Ethereum Signed Message:64",
        "94cd5137c63cf80cdd176a2a6285572cc076f2fbea67c8b36e65065be7bc34ec",
        "9f6463aadf1a8aed68b99aa14538f16d67bf586a4bdecb904d56d5edb2cfb13a"
    ];

    function getBoolFunc(uint256 index) internal view returns (bool) {
        return _bool_constant[index];
    }

    function getIntFunc(uint256 index) internal view returns (uint256) {
        return _integer_constant[index];
    }

    function getStrFunc(uint256 index) internal view returns (string storage) {
        return _string_constant[index];
    }
}