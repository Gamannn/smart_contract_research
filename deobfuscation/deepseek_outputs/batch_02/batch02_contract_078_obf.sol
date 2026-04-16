```solidity
pragma solidity ^0.4.15;

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

library ECRecovery {
    function recover(bytes32 hash, bytes sig) constant returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        
        if (sig.length != 65) {
            return address(0);
        }
        
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        
        if (v < 27) {
            v += 27;
        }
        
        if (v != 27 && v != 28) {
            return address(0);
        } else {
            bytes memory prefix = "\x19Ethereum Signed Message:\n32";
            bytes32 prefixedHash = keccak256(prefix, hash);
            return ecrecover(prefixedHash, v, r, s);
        }
    }
}

contract Ownable {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    function Ownable() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract WithdrawContract is Ownable {
    using SafeMath for uint;
    using ECRecovery for bytes32;
    
    mapping (address => uint) public nonce;
    
    event Withdraw(address indexed user, uint amount);
    event WithdrawCanceled(address indexed user);
    
    function() payable {
        require(msg.value != 0);
    }
    
    function _withdraw(address user, uint amount) private {
        user.transfer(amount);
        Withdraw(user, amount);
    }
    
    function withdraw(uint amount, bytes signature) external {
        uint currentNonce = nonce[msg.sender].add(1);
        bytes32 hash = keccak256(msg.sender, amount, currentNonce);
        address signer = hash.recover(signature);
        require(signer == owner);
        
        _withdraw(msg.sender, amount);
        nonce[msg.sender] = currentNonce;
    }
    
    function cancelWithdraw() {
        nonce[msg.sender] = nonce[msg.sender].add(1);
        WithdrawCanceled(msg.sender);
    }
    
    function ownerWithdraw(address user, uint amount) external onlyOwner {
        require(user != 0);
        _withdraw(user, amount);
    }
}
```