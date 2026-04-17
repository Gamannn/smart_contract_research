pragma solidity ^0.4.24;

contract PaymentChannel {
    event Withdraw(address indexed user, uint amount);
    event Deposit(address indexed user, uint amount);

    mapping(uint => uint) public balances;
    mapping(uint => address) public owners;
    address public owner;
    uint public conversionRate;

    struct Channel {
        uint conversionRate;
        address owner;
    }

    Channel channel = Channel(0.0001 ether, address(0));

    constructor(address initialOwner) public {
        owner = initialOwner;
    }

    function () public payable {
        emit Deposit(msg.sender, msg.value);
    }

    function updateOwner(uint channelId, address newOwner) public {
        require(msg.sender == owner);
        owners[channelId] = newOwner;
    }

    function withdraw(uint channelId, uint amount, bytes signature) public {
        bytes32 messageHash = keccak256(abi.encodePacked(owner, channelId, amount));
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        address signer = recoverSigner(signature, ethSignedMessageHash);
        require(owner == signer);
        require(owners[channelId] == msg.sender);
        require(balances[channelId] < amount);

        uint withdrawAmount = (amount - balances[channelId]) * conversionRate;
        balances[channelId] = amount;
        msg.sender.transfer(withdrawAmount);
        emit Withdraw(msg.sender, withdrawAmount);
    }

    function recoverSigner(bytes signature, bytes32 ethSignedMessageHash) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length != 65) {
            return (address(0));
        }

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    function getStringConstant(uint256 index) internal view returns (string) {
        return _string_constant[index];
    }

    function getIntegerConstant(uint256 index) internal view returns (uint256) {
        return _integer_constant[index];
    }

    string[] public _string_constant = ["\x19Ethereum Signed Message:\n32"];
    uint256[] public _integer_constant = [27, 0, 100000000000000, 65];
}