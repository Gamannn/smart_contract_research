pragma solidity 0.4.25;

contract PaymentContract {
    event Withdraw(address indexed user, uint amount);
    event Deposit(address indexed user, uint amount);

    mapping(string => uint) internal balances;
    mapping(string => address) internal users;

    struct Config {
        uint256 feeRate;
        address owner;
    }

    Config config = Config(0.0001 ether, address(0));

    constructor(address initialOwner) public {
        config.owner = initialOwner;
    }

    function () public payable {
        emit Deposit(msg.sender, msg.value);
    }

    function getBalance(string userId) public returns (uint) {
        return balances[userId];
    }

    function getUserAddress(string userId) public returns (address) {
        return users[userId];
    }

    function setUserAddress(string userId, address userAddress) public {
        require(msg.sender == config.owner);
        users[userId] = userAddress;
    }

    function withdraw(string userId, uint amount, bytes signature) public {
        bytes32 messageHash = keccak256(config.owner, userId, amount);
        bytes32 ethSignedMessageHash = keccak256("\x19Ethereum Signed Message:\n32", messageHash);
        address signer = recoverSigner(signature, ethSignedMessageHash);

        require(config.owner == signer);
        require(users[userId] == msg.sender);
        require(balances[userId] < amount);

        uint withdrawAmount = (amount - balances[userId]) * config.feeRate;
        balances[userId] = amount;
        msg.sender.transfer(withdrawAmount);

        emit Withdraw(msg.sender, withdrawAmount);
    }

    function recoverSigner(bytes signature, bytes32 messageHash) internal pure returns (address) {
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

        return ecrecover(messageHash, v, r, s);
    }
}