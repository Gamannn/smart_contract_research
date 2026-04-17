```solidity
pragma solidity ^0.4.9;

contract SafeMath {
    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        require(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        require(c >= a && c >= b);
        return c;
    }

    function assert(bool assertion) internal {
        if (!assertion) throw;
    }
}

contract Token {
    function transfer(address to, uint256 value) returns (bool success) {}
    function transferFrom(address from, address to, uint256 value) returns (bool success) {}
}

contract Exchange is SafeMath {
    address public admin;
    bool public tradeEnabled;
    string public message;
    mapping(address => mapping(address => mapping(bytes32 => bool))) public orderFills;
    mapping(address => mapping(bytes32 => uint)) public orderAmounts;

    event Order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, bytes32 hash);
    event Cancel(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, bytes32 hash, string message);
    event Trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address get, address give, bytes32 hash, string message);
    event Deposit(address token, address user, uint amount, uint balance);
    event Withdraw(address token, address user, uint amount, uint balance);

    function Exchange() {
        admin = msg.sender;
        tradeEnabled = true;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    modifier isTradeEnabled() {
        require(tradeEnabled);
        _;
    }

    function setTradeEnabled(bool enabled) onlyAdmin {
        tradeEnabled = enabled;
    }

    function setMessage(string newMessage) onlyAdmin {
        message = newMessage;
    }

    function deposit() payable isTradeEnabled {
        balances[0][msg.sender] = safeAdd(balances[0][msg.sender], msg.value);
        Deposit(0, msg.sender, msg.value, balances[0][msg.sender]);
    }

    function withdraw(uint amount) {
        require(balances[0][msg.sender] >= amount);
        balances[0][msg.sender] = safeSub(balances[0][msg.sender], amount);
        if (!msg.sender.call.value(amount)()) throw;
        Withdraw(0x0000000000000000000000000000000000000000, msg.sender, amount, balances[0][msg.sender]);
    }

    function depositToken(address token, uint amount) isTradeEnabled {
        require(token != 0);
        if (!Token(token).transferFrom(msg.sender, this, amount)) throw;
        balances[token][msg.sender] = safeAdd(balances[token][msg.sender], amount);
        Deposit(token, msg.sender, amount, balances[token][msg.sender]);
    }

    function withdrawToken(address token, uint amount) {
        require(token != 0);
        require(balances[token][msg.sender] >= amount);
        balances[token][msg.sender] = safeSub(balances[token][msg.sender], amount);
        if (!Token(token).transfer(msg.sender, amount)) throw;
        Withdraw(token, msg.sender, amount, balances[token][msg.sender]);
    }

    function balanceOf(address token, address user) constant returns (uint) {
        return balances[token][user];
    }

    function order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce) {
        bytes32 hash = sha3(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        orderFills[msg.sender][hash] = true;
        Order(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender, hash);
    }

    function trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount, string message) {
        bytes32 hash = sha3(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        require((orderFills[user][hash] || ecrecover(sha3("\x19Ethereum Signed Message:\n32", hash), v, r, s) == user) && block.number <= expires && safeAdd(orderAmounts[user][hash], amount) <= amountGet);
        executeTrade(tokenGet, amountGet, tokenGive, amountGive, user, amount);
        orderAmounts[user][hash] = safeAdd(orderAmounts[user][hash], amount);
        Trade(tokenGet, amount, tokenGive, safeMul(amountGive, amount) / amountGet, user, msg.sender, hash, message);
    }

    function executeTrade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address user, uint amount) private {
        balances[tokenGet][msg.sender] = safeSub(balances[tokenGet][msg.sender], amount);
        balances[tokenGet][user] = safeAdd(balances[tokenGet][user], amount);
        balances[tokenGive][user] = safeSub(balances[tokenGive][user], safeMul(amountGive, amount) / amountGet);
        balances[tokenGive][msg.sender] = safeAdd(balances[tokenGive][msg.sender], safeMul(amountGive, amount) / amountGet);
    }

    function cancelOrder(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, uint8 v, bytes32 r, bytes32 s, string message) {
        bytes32 hash = sha3(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        require(orderFills[msg.sender][hash] || ecrecover(sha3("\x19Ethereum Signed Message:\n32", hash), v, r, s) == msg.sender);
        orderAmounts[msg.sender][hash] = amountGet;
        Cancel(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender, v, r, s, hash, message);
    }

    mapping(address => mapping(address => uint)) public balances;
}
```