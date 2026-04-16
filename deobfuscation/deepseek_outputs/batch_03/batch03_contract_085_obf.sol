pragma solidity 0.4.25;

contract Ox181dfc03f8a2ee3567520f1f0f7a821f7b57d4f1 {
    event Withdraw(address indexed user, uint amount);
    event Deposit(address indexed user, uint amount);
    
    mapping(string => uint) internal balances;
    mapping(string => address) internal users;
    
    struct Config {
        uint256 rate;
        address owner;
    }
    
    Config config = Config(0.0001 ether, address(0));
    
    constructor(address owner) public {
        config.owner = owner;
    }
    
    function() public payable {
        emit Deposit(msg.sender, msg.value);
    }
    
    function getBalance(string memory userId) public view returns (uint) {
        return balances[userId];
    }
    
    function getUserAddress(string memory userId) public view returns (address) {
        return users[userId];
    }
    
    function setUserAddress(string memory userId, address userAddress) public {
        require(msg.sender == config.owner);
        users[userId] = userAddress;
    }
    
    function withdraw(string memory userId, uint newBalance, bytes memory signature) public {
        bytes32 messageHash = keccak256(config.owner, userId, newBalance);
        bytes32 ethSignedMessageHash = keccak256("\x19Ethereum Signed Message:\n32", messageHash);
        
        address recoveredAddress = recoverSigner(signature, ethSignedMessageHash);
        
        require(config.owner == recoveredAddress);
        require(users[userId] == msg.sender);
        require(balances[userId] < newBalance);
        
        uint amount = (newBalance - balances[userId]) * config.rate;
        balances[userId] = newBalance;
        
        msg.sender.transfer(amount);
        emit Withdraw(msg.sender, amount);
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