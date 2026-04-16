pragma solidity ^0.4.15;

library ECRecovery {
    function recover(bytes32 hash, bytes signature) constant returns (address) {
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

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        return a / b;
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

contract Withdrawable is Ownable {
    using SafeMath for uint;
    using ECRecovery for bytes32;

    mapping (address => uint) public nonces;

    event Withdraw(address indexed to, uint amount);
    event WithdrawCanceled(address indexed to);

    function() payable {
        require(msg.value != 0);
    }

    function withdraw(address to, uint amount) private {
        to.transfer(amount);
        Withdraw(to, amount);
    }

    function withdrawWithSignature(uint amount, bytes signature) external {
        uint256 nonce = nonces[msg.sender] + 1;
        bytes32 hash = keccak256(msg.sender, amount, nonce);
        address signer = hash.recover(signature);
        require(signer == owner);
        withdraw(msg.sender, amount);
        nonces[msg.sender] = nonce;
    }

    function cancelWithdraw() {
        nonces[msg.sender]++;
        WithdrawCanceled(msg.sender);
    }

    function adminWithdraw(address to, uint amount) external onlyOwner {
        require(to != 0);
        withdraw(to, amount);
    }
}