pragma solidity ^0.5.16;

contract Ownable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    address private owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract ERC20Interface {
    bytes32 public name;
    bytes32 public symbol;
    bytes32 public decimals;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function transfer(address to, uint256 value) public returns (bool success);
    function approve(address spender, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
}

library ECDSA {
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
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
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }
}

contract SwapContract is Ownable {
    using ECDSA for bytes32;

    mapping(bytes32 => bool) public processedTransactions;
    event Swap(address indexed sender, bytes32 indexed transactionId, address indexed fromToken, address toToken, uint256 fromAmount, uint256 toAmount);
    event TransferAltChain(bytes32 indexed transactionId, address indexed from, address indexed to, uint256 amount);
    event AddEth(uint256 amount);

    function swap(
        bytes32 transactionId,
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 toAmount,
        uint256 deadline,
        bytes calldata signature
    ) payable external {
        require(fromToken != toToken, "From and to tokens must be different");
        bytes32 hash = keccak256(abi.encodePacked(transactionId, fromToken, toToken, fromAmount, toAmount, deadline));
        if (now > deadline) {
            return;
        }
        verifyTransaction(hash, signature, transactionId);
        processedTransactions[transactionId] = true;

        if (fromToken == address(0x0)) {
            require(msg.value > 0, "Value must be greater than 0");
            require(msg.value == fromAmount, "Value must match fromAmount");
        } else {
            require(ERC20Interface(fromToken).transferFrom(msg.sender, address(this), fromAmount), "Transfer from failed");
        }

        if (toToken == address(0x0)) {
            msg.sender.transfer(toAmount);
        } else {
            require(ERC20Interface(toToken).transfer(msg.sender, toAmount), "Transfer failed");
        }

        emit Swap(msg.sender, transactionId, fromToken, toToken, fromAmount, toAmount);
    }

    function verifyTransaction(bytes32 hash, bytes memory signature, bytes32 transactionId) private view {
        require(owner == hash.recover(signature), "Invalid signature");
        require(!processedTransactions[transactionId], "Transaction already processed");
    }

    function transferAltChain(
        bytes32 transactionId,
        address payable from,
        address to,
        uint256 amount
    ) external onlyOwner {
        if (to == address(0x0)) {
            from.transfer(amount);
        } else {
            require(ERC20Interface(to).transfer(from, amount), "Transfer failed");
        }
        emit TransferAltChain(transactionId, from, to, amount);
    }

    function addEth() payable external {
        emit AddEth(msg.value);
    }
}