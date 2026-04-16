```solidity
pragma solidity ^0.5.16;

contract Ownable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    struct OwnerData {
        bool initialized;
        uint8 version;
        uint256 someValue;
        address owner;
    }

    OwnerData private ownerData = OwnerData(false, 0, 0, address(0));

    constructor() public {
        ownerData.owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == ownerData.owner, "Caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(ownerData.owner, newOwner);
        ownerData.owner = newOwner;
    }
}

contract Token {
    bytes32 public name;
    bytes32 public symbol;
    bytes32 public standard;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function transfer(address to, uint256 value) public;
    function approve(address spender, uint256 value) public;
    function transferFrom(address from, address to, uint256 value) public;
}

library SignatureVerifier {
    function recoverSigner(bytes32 hash, bytes memory signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length != 65) {
            return address(0);
        }

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            return address(0);
        } else {
            return ecrecover(hash, v, r, s);
        }
    }
}

contract SwapContract is Ownable {
    using SignatureVerifier for bytes32;

    mapping(bytes32 => bool) public processedTransactions;

    event Swap(
        address indexed sender,
        bytes32 indexed transactionId,
        address tokenAddress,
        address recipient,
        uint256 amount,
        uint256 fee
    );

    event SwapAltChain(
        address indexed sender,
        bytes32 indexed transactionId,
        address tokenAddress,
        uint256 amount
    );

    event TransferAltChain(
        bytes32 indexed transactionId,
        address indexed from,
        address indexed to,
        uint256 amount
    );

    event AddEth(uint256 amount);

    function swap(
        bytes32 transactionId,
        address tokenAddress,
        address recipient,
        uint256 amount,
        uint256 fee,
        uint256 deadline,
        bytes calldata signature
    ) payable external {
        require(tokenAddress != recipient, "Token address and recipient cannot be the same");

        bytes32 hash = keccak256(abi.encodePacked(transactionId, tokenAddress, recipient, amount, fee, deadline));

        if (now > deadline) {
            return;
        }

        verifySignature(hash, signature, transactionId);

        processedTransactions[transactionId] = true;

        if (tokenAddress == address(0)) {
            require(msg.value > 0, "No ETH sent");
            require(msg.value == amount, "Incorrect ETH amount");
        } else {
            require(transferTokens(tokenAddress, msg.sender, address(this), amount), "Token transfer failed");
        }

        if (recipient == address(0)) {
            msg.sender.transfer(fee);
        } else {
            require(transferTokens(recipient, msg.sender, fee), "Fee transfer failed");
        }

        emit Swap(msg.sender, transactionId, tokenAddress, recipient, amount, fee);
    }

    function verifySignature(
        bytes32 hash,
        bytes memory signature,
        bytes32 transactionId
    ) private view {
        require(hash.recoverSigner(signature) == ownerData.owner, "Invalid signature");
        require(!processedTransactions[transactionId], "Transaction already processed");
    }

    function transferTokens(
        address tokenAddress,
        address from,
        address to,
        uint256 amount
    ) private returns (bool success) {
        Token(tokenAddress).transferFrom(from, to, amount);
        assembly {
            switch returndatasize()
            case 0 {
                success := not(0)
            }
            case 32 {
                returndatacopy(0, 0, 32)
                success := mload(0)
            }
            default {
                revert(0, 0)
            }
        }
        require(success, "Token transfer failed");
    }

    function transferTokens(
        address tokenAddress,
        address to,
        uint256 amount
    ) private returns (bool success) {
        Token(tokenAddress).transfer(to, amount);
        assembly {
            switch returndatasize()
            case 0 {
                success := not(0)
            }
            case 32 {
                returndatacopy(0, 0, 32)
                success := mload(0)
            }
            default {
                revert(0, 0)
            }
        }
        require(success, "Token transfer failed");
    }

    function swapAltChain(
        bytes32 transactionId,
        address tokenAddress,
        uint256 amount,
        uint256 deadline,
        bytes calldata signature
    ) payable external {
        bytes32 hash = keccak256(abi.encodePacked(transactionId, tokenAddress, amount, deadline));

        if (now > deadline) {
            return;
        }

        verifySignature(hash, signature, transactionId);

        processedTransactions[transactionId] = true;

        if (tokenAddress == address(0)) {
            require(msg.value > 0, "No ETH sent");
            require(msg.value == amount, "Incorrect ETH amount");
        } else {
            require(transferTokens(tokenAddress, msg.sender, address(this), amount), "Token transfer failed");
        }

        emit SwapAltChain(msg.sender, transactionId, tokenAddress, amount);
    }

    function transferAltChain(
        bytes32 transactionId,
        address payable from,
        address to,
        uint256 amount
    ) external onlyOwner {
        if (to == address(0)) {
            from.transfer(amount);
        } else {
            Token(to).transfer(from, amount);
        }

        emit TransferAltChain(transactionId, from, to, amount);
    }

    function addEth() payable external {
        emit AddEth(msg.value);
    }
}
```