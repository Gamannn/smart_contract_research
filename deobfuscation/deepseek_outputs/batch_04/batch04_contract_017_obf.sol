```solidity
pragma solidity ^0.5.16;

contract Ownable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    address public owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface IERC20 {
    function name() external view returns (bytes32);
    function symbol() external view returns (bytes32);
    function decimals() external view returns (bytes32);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

library ECRecovery {
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

contract Bridge is Ownable {
    using ECRecovery for bytes32;
    
    mapping(bytes32 => bool) public processedTransactions;
    
    event Swap(
        address indexed sender,
        bytes32 indexed transactionId,
        address sourceToken,
        address destinationToken,
        uint256 sourceAmount,
        uint256 destinationAmount
    );
    
    event TransferAltChain(
        bytes32 indexed transactionId,
        address indexed recipient,
        address token,
        uint256 amount
    );
    
    event AddEth(uint256 amount);
    
    function swap(
        bytes32 transactionId,
        address sourceToken,
        address destinationToken,
        uint256 sourceAmount,
        uint256 destinationAmount,
        uint256 deadline,
        bytes calldata signature
    ) payable external {
        require(sourceToken != destinationToken);
        
        bytes32 messageHash = keccak256(abi.encodePacked(
            transactionId,
            sourceToken,
            destinationToken,
            sourceAmount,
            destinationAmount,
            deadline
        ));
        
        if(now > deadline) {
            return;
        }
        
        _verifySignature(messageHash, signature, transactionId);
        
        processedTransactions[transactionId] = true;
        
        if (sourceToken == address(0x0)) {
            require(msg.value > 0);
            require(msg.value == sourceAmount);
        } else {
            require(IERC20(sourceToken).transferFrom(msg.sender, address(this), sourceAmount));
        }
        
        if (destinationToken == address(0x0)) {
            msg.sender.transfer(destinationAmount);
        } else {
            require(IERC20(destinationToken).transfer(msg.sender, destinationAmount));
        }
        
        emit Swap(msg.sender, transactionId, sourceToken, destinationToken, sourceAmount, destinationAmount);
    }
    
    function _verifySignature(
        bytes32 messageHash,
        bytes memory signature,
        bytes32 transactionId
    ) private view {
        require(messageHash.recover(signature) == owner);
        require(!processedTransactions[transactionId]);
    }
    
    function transferTokens(
        address payable recipient,
        address token,
        uint256 amount
    ) external onlyOwner {
        if (token == address(0x0)) {
            recipient.transfer(amount);
        } else {
            IERC20(token).transfer(recipient, amount);
        }
    }
    
    function transferAltChain(
        bytes32 transactionId,
        address payable recipient,
        address token,
        uint256 amount
    ) external onlyOwner {
        if (token == address(0x0)) {
            recipient.transfer(amount);
        } else {
            IERC20(token).transfer(recipient, amount);
        }
        
        emit TransferAltChain(transactionId, recipient, token, amount);
    }
    
    function addEth() payable external {
        emit AddEth(msg.value);
    }
}
```