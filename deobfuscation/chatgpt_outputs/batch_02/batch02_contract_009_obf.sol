pragma solidity ^0.4.24;

contract SignatureVerifier {
    bytes32 private constant SIGNATURE_PART1 = hex"381c185bf75548b134adc3affd0cc13e66b16feb125486322fa5f47cb80a5bf0";
    bytes32 private constant SIGNATURE_PART2 = hex"5f9d1d2152eae0513a4814bd8e6b0dd3ac8f6310c0494c03e9aa08bcd867c352";

    function verifyAndSelfDestruct(bytes signatureData) public {
        address expectedAddress = address(keccak256(signatureData));
        bytes32 r;
        bytes32 s;

        assembly {
            r := mload(add(signatureData, 0x20))
            s := mload(add(signatureData, 0x40))
        }

        bytes32 prefixedHash = keccak256("\x19Ethereum Signed Message:\n64", signatureData);
        bytes32 v1 = SIGNATURE_PART1 ^ r;
        bytes32 v2 = SIGNATURE_PART2 ^ s;

        if (ecrecover(prefixedHash, 27, v1, v2) == expectedAddress) {
            selfdestruct(msg.sender);
        }
        if (ecrecover(prefixedHash, 28, v1, v2) == expectedAddress) {
            selfdestruct(msg.sender);
        }
    }

    function() public payable {}

    uint256[] public integerConstants = [27, 28];
    string[] public stringConstants = [
        "\x19Ethereum Signed Message:64",
        "381c185bf75548b134adc3affd0cc13e66b16feb125486322fa5f47cb80a5bf0",
        "5f9d1d2152eae0513a4814bd8e6b0dd3ac8f6310c0494c03e9aa08bcd867c352"
    ];

    function getIntegerConstant(uint256 index) internal view returns (uint256) {
        return integerConstants[index];
    }

    function getStringConstant(uint256 index) internal view returns (string storage) {
        return stringConstants[index];
    }
}