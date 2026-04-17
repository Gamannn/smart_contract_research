```solidity
pragma solidity ^0.4.16;

contract Token {
    bytes32 public name;
    bytes32 public symbol;
    bytes32 public version;
    uint8 public decimals;
    bool public transfersEnabled;
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    function transfer(address to, uint256 value) returns (bool success);
    function transferFrom(address from, address to, uint256 value) returns (bool success);
    function approve(address spender, uint256 value) returns (bool success);
    function transferFrom(address from, address to, uint256 value, bytes data) returns (bool success);
}

contract Exchange {
    function assert(bool condition) {
        if (!condition) throw;
    }
    
    function safeMul(uint a, uint b) returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function safeSub(uint a, uint b) returns (uint) {
        assert(b <= a);
        return a - b;
    }
    
    function safeAdd(uint a, uint b) returns (uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
    
    address public owner;
    mapping (address => bool) public admins;
    
    event SetOwner(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }
    
    function setOwner(address newOwner) onlyOwner {
        SetOwner(owner, newOwner);
        owner = newOwner;
    }
    
    function getOwner() returns (address) {
        return owner;
    }
    
    function setMinOrderSize(address token, uint256 minAmount) onlyAdmin {
        if (minAmount < tokenMinOrderSize[token]) throw;
        tokenMinOrderSize[token] = minAmount;
    }
    
    mapping (address => mapping (address => uint256)) public tokens;
    mapping (address => bool) public authorized;
    mapping (address => uint256) public lastActiveBlock;
    mapping (bytes32 => uint256) public orderFilledAmounts;
    
    address public feeAccount;
    uint256 public inactivityReleasePeriod;
    
    mapping (bytes32 => bool) public withdrawn;
    
    event Order(
        address indexed tokenBuy,
        uint256 amountBuy,
        address indexed tokenSell,
        uint256 amountSell,
        uint256 expires,
        uint256 nonce,
        address indexed user,
        uint8 v,
        bytes32 r,
        bytes32 s
    );
    
    event Cancel(
        address indexed tokenBuy,
        uint256 amountBuy,
        address indexed tokenSell,
        uint256 amountSell,
        uint256 expires,
        uint256 nonce,
        address indexed user,
        uint8 v,
        bytes32 r,
        bytes32 s
    );
    
    event Trade(
        address indexed tokenBuy,
        uint256 amountBuy,
        address indexed tokenSell,
        uint256 amountSell,
        address get,
        address give
    );
    
    event Deposit(
        address indexed token,
        address indexed user,
        uint256 amount,
        uint256 balance
    );
    
    event Withdraw(
        address indexed token,
        address indexed user,
        uint256 amount,
        uint256 balance
    );
    
    function setInactivityReleasePeriod(uint256 blocks) onlyAdmin returns (bool success) {
        if (blocks > 1000000) throw;
        inactivityReleasePeriod = blocks;
        return true;
    }
    
    function Exchange() {
        owner = msg.sender;
        feeAccount = msg.sender;
        inactivityReleasePeriod = 100000;
    }
    
    function setAdmin(address admin, bool isAdmin) onlyOwner {
        authorized[admin] = isAdmin;
    }
    
    modifier onlyAdmin {
        if (msg.sender != owner && !authorized[msg.sender]) throw;
        _;
    }
    
    function() external {
        throw;
    }
    
    function depositToken(address token, uint256 amount) {
        tokens[token][msg.sender] = safeAdd(tokens[token][msg.sender], amount);
        lastActiveBlock[msg.sender] = block.number;
        
        if (!Token(token).transferFrom(msg.sender, this, amount)) throw;
        
        Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
    }
    
    function deposit() payable {
        tokens[address(0)][msg.sender] = safeAdd(tokens[address(0)][msg.sender], msg.value);
        lastActiveBlock[msg.sender] = block.number;
        Deposit(address(0), msg.sender, msg.value, tokens[address(0)][msg.sender]);
    }
    
    function withdraw(address token, uint256 amount) returns (bool success) {
        if (safeSub(block.number, lastActiveBlock[msg.sender]) < inactivityReleasePeriod) throw;
        if (tokens[token][msg.sender] < amount) throw;
        
        tokens[token][msg.sender] = safeSub(tokens[token][msg.sender], amount);
        
        if (token == address(0)) {
            if (!msg.sender.send(amount)) throw;
        } else {
            if (!Token(token).transfer(msg.sender, amount)) throw;
        }
        
        Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
        return true;
    }
    
    function adminWithdraw(
        address token,
        uint256 amount,
        address user,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 feeWithdrawal
    ) onlyAdmin returns (bool success) {
        bytes32 hash = keccak256(this, token, amount, user, nonce);
        
        if (withdrawn[hash]) throw;
        withdrawn[hash] = true;
        
        if (ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) != user) throw;
        
        if (feeWithdrawal > 50 finney) feeWithdrawal = 50 finney;
        
        if (tokens[token][user] < amount) throw;
        
        tokens[token][user] = safeSub(tokens[token][user], amount);
        tokens[token][feeAccount] = safeAdd(tokens[token][feeAccount], safeMul(feeWithdrawal, amount) / 1 ether);
        
        amount = safeMul((1 ether - feeWithdrawal), amount) / 1 ether;
        
        if (token == address(0)) {
            if (!user.send(amount)) throw;
        } else {
            if (!Token(token).transfer(user, amount)) throw;
        }
        
        lastActiveBlock[user] = block.number;
        Withdraw(token, user, amount, tokens[token][user]);
        return true;
    }
    
    function balanceOf(address token, address user) constant returns (uint256) {
        return tokens[token][user];
    }
    
    function trade(
        uint256[8] orderValues,
        address[4] orderAddresses,
        uint8[2] v,
        bytes32[4] rs
    ) onlyAdmin returns (bool success) {
        if (tokenMinOrderSize[orderAddresses[2]] > orderValues[3]) throw;
        
        bytes32 orderHash = keccak256(
            this,
            orderAddresses[0],
            orderValues[0],
            orderAddresses[1],
            orderValues[1],
            orderValues[2],
            orderValues[3],
            orderAddresses[2]
        );
        
        if (ecrecover(keccak256("\x19Ethereum Signed Message:\n32", orderHash), v[0], rs[0], rs[1]) != orderAddresses[2]) throw;
        
        bytes32 tradeHash = keccak256(orderHash, orderValues[4], orderAddresses[3], orderValues[5]);
        
        if (ecrecover(keccak256("\x19Ethereum Signed Message:\n32", tradeHash), v[1], rs[2], rs[3]) != orderAddresses[3]) throw;
        
        if (withdrawn[tradeHash]) throw;
        withdrawn[tradeHash] = true;
        
        if (orderValues[6] > 100 finney) orderValues[6] = 100 finney;
        if (orderValues[7] > 100 finney) orderValues[7] = 100 finney;
        
        if (safeAdd(orderFilledAmounts[orderHash], orderValues[4]) > orderValues[0]) throw;
        
        if (tokens[orderAddresses[0]][orderAddresses[3]] < orderValues[4]) throw;
        
        if (tokens[orderAddresses[1]][orderAddresses[2]] < (safeMul(orderValues[1], orderValues[4]) / orderValues[0])) throw;
        
        tokens[orderAddresses[0]][orderAddresses[3]] = safeSub(tokens[orderAddresses[0]][orderAddresses[3]], orderValues[4]);
        tokens[orderAddresses[0]][orderAddresses[2]] = safeAdd(
            tokens[orderAddresses[0]][orderAddresses[2]],
            safeMul(orderValues[4], (1 ether - orderValues[6])) / (1 ether)
        );
        
        tokens[orderAddresses[0]][feeAccount] = safeAdd(
            tokens[orderAddresses[0]][feeAccount],
            safeMul(orderValues[4], orderValues[6]) / (1 ether)
        );
        
        tokens[orderAddresses[1]][orderAddresses[2]] = safeSub(
            tokens[orderAddresses[1]][orderAddresses[2]],
            safeMul(orderValues[1], orderValues[4]) / orderValues[0]
        );
        
        tokens[orderAddresses[1]][orderAddresses[3]] = safeAdd(
            tokens[orderAddresses[1]][orderAddresses[3]],
            safeMul(safeMul((1 ether - orderValues[7]), orderValues[1]), orderValues[4]) / orderValues[0] / (1 ether)
        );
        
        tokens[orderAddresses[1]][feeAccount] = safeAdd(
            tokens[orderAddresses[1]][feeAccount],
            safeMul(safeMul(orderValues[7], orderValues[1]), orderValues[4]) / orderValues[0] / (1 ether)
        );
        
        orderFilledAmounts[orderHash] = safeAdd(orderFilledAmounts[orderHash], orderValues[4]);
        
        lastActiveBlock[orderAddresses[2]] = block.number;
        lastActiveBlock[orderAddresses[3]] = block.number;
        
        return true;
    }
    
    mapping (address => uint256) public tokenMinOrderSize;
}
```