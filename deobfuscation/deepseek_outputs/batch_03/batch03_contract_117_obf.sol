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
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
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
        address indexed user,
        bytes32 indexed transactionId,
        address sourceToken,
        address destinationToken,
        uint256 sourceAmount,
        uint256 destinationAmount
    );
    
    event SwapAltChain(
        address indexed user,
        bytes32 indexed transactionId,
        address sourceToken,
        uint256 sourceAmount
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
            require(_safeTransferFrom(sourceToken, msg.sender, address(this), sourceAmount));
        }
        
        if (destinationToken == address(0x0)) {
            msg.sender.transfer(destinationAmount);
        } else {
            require(_safeTransfer(destinationToken, msg.sender, destinationAmount));
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
    
    function withdraw(
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
    
    function swapAltChain(
        bytes32 transactionId,
        address sourceToken,
        uint256 sourceAmount,
        uint256 deadline,
        bytes calldata signature
    ) payable external {
        bytes32 messageHash = keccak256(abi.encodePacked(
            transactionId,
            sourceToken,
            sourceAmount,
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
            require(_safeTransferFrom(sourceToken, msg.sender, address(this), sourceAmount));
        }
        
        emit SwapAltChain(msg.sender, transactionId, sourceToken, sourceAmount);
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
    
    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) private returns (bool success) {
        IERC20(token).transfer(to, value);
        
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
        require(success);
    }
    
    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) private returns (bool success) {
        IERC20(token).transferFrom(from, to, value);
        
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
        require(success);
    }
}
```