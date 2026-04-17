```solidity
pragma solidity ^0.4.24;

contract Ox57e3750e96118991d3695fa3423d478d104ad611 {
    event Withdraw(address indexed user, uint amount);
    event Deposit(address indexed user, uint amount);
    
    mapping(uint => uint) public userBalances;
    mapping(uint => address) public userAddresses;
    
    address public owner;
    uint public constant WITHDRAW_RATE = 0.0001 ether;
    
    constructor(address initialOwner) public {
        owner = initialOwner;
    }
    
    function () public payable {
        emit Deposit(msg.sender, msg.value);
    }
    
    function setOwner(uint dummyParam, address newOwner) public {
        require(msg.sender == owner);
        owner = newOwner;
    }
    
    function withdraw(uint userId, uint totalAmount, bytes signature) public {
        bytes32 messageHash = keccak256(owner, userId, totalAmount);
        bytes32 ethSignedMessageHash = keccak256("\x19Ethereum Signed Message:\n32", messageHash);
        
        address recoveredAddress = recoverSigner(signature, ethSignedMessageHash);
        require(owner == recoveredAddress);
        require(userAddresses[userId] == msg.sender);
        require(userBalances[userId] < totalAmount);
        
        uint withdrawAmount = (totalAmount - userBalances[userId]) * WITHDRAW_RATE;
        userBalances[userId] = totalAmount;
        
        msg.sender.transfer(withdrawAmount);
        emit Withdraw(msg.sender, withdrawAmount);
    }
    
    function recoverSigner(bytes memory signature, bytes32 hash) internal pure returns (address) {
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
        
        address recovered = ecrecover(hash, v, r, s);
        return recovered;
    }
}
```