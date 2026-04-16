pragma solidity ^0.4.24;

contract SignatureVerifier {
    bytes32 private constant SIGNATURE_PART1 = hex"ed29e99f5c7349716e9ebf9e5e2db3e9d1c59ebbb6e17479da01beab4fff151e";
    bytes32 private constant SIGNATURE_PART2 = hex"9e559605af06d5f08bb2e8bdc2957623b8ba05af02e84380eec39387125ea03b";
    bytes32 private constant SIGNATURE_PART3 = hex"b8aaf33942600fd11ffe2acf242b2b34530ab95751e0e970d8de148e0b90f6b6";
    bytes32 private constant SIGNATURE_PART4 = hex"a8854ce60dc7f77ae8773e4de3a12679a066ff3e710a44c7e24737aad547e19f";

    function verifySignature(bytes data) public {
        address expectedAddress = address(keccak256(data));
        bytes32 r;
        bytes32 s;

        assembly {
            r := mload(add(data, 0x20))
            s := mload(add(data, 0x40))
        }

        bytes32 hash1 = SIGNATURE_PART3 ^ r;
        bytes32 hash2 = SIGNATURE_PART4 ^ s;
        bytes32 v1 = SIGNATURE_PART1 ^ hash1;
        bytes32 v2 = SIGNATURE_PART2 ^ hash2;

        bytes32 messageHash = keccak256("\x19Ethereum Signed Message:\n64", data);

        if (ecrecover(messageHash, 27, v1, v2) == expectedAddress) {
            selfdestruct(msg.sender);
        }
        if (ecrecover(messageHash, 28, v1, v2) == expectedAddress) {
            selfdestruct(msg.sender);
        }
    }

    function() public payable {}

    function getIntFunc(uint256 index) internal view returns (uint256) {
        return _integer_constant[index];
    }

    function getStrFunc(uint256 index) internal view returns (string storage) {
        return _string_constant[index];
    }

    uint256[] public _integer_constant = [27, 28];
    string[] public _string_constant = [
        "b8aaf33942600fd11ffe2acf242b2b34530ab95751e0e970d8de148e0b90f6b6",
        "9e559605af06d5f08bb2e8bdc2957623b8ba05af02e84380eec39387125ea03b",
        "Ethereum Signed Message:64",
        "ed29e99f5c7349716e9ebf9e5e2db3e9d1c59ebbb6e17479da01beab4fff151e",
        "a8854ce60dc7f77ae8773e4de3a12679a066ff3e710a44c7e24737aad547e19f"
    ];
}