```solidity
pragma solidity ^0.4.15;

contract MathOperations {
    function safeMultiply(uint a, uint b) internal returns (uint) {
        uint result = a * b;
        assert(a == 0 || result / a == b);
        return result;
    }

    function safeSubtract(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint result = a + b;
        assert(result >= a && result >= b);
        return result;
    }
}

contract Token {
    function totalSupply() constant returns (uint256 supply) {}
    function balanceOf(address owner) constant returns (uint256 balance) {}
    function transfer(address to, uint256 value) returns (bool success) {}
    function transferFrom(address from, address to, uint256 value) returns (bool success) {}
    function approve(address spender, uint256 value) returns (bool success) {}
    function allowance(address owner, address spender) constant returns (uint256 remaining) {}
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    uint public decimals;
    string public name;
}

contract Exchange is MathOperations {
    mapping (address => mapping (bytes32 => bool)) public orderFills;
    mapping (address => mapping (bytes32 => uint)) public orderAmounts;
    event Order(address indexed trader, uint amount, address tokenGet, uint amountGet, uint amountGive, uint expires, address indexed tokenGive);
    event Cancel(address indexed trader, uint amount, address tokenGet, uint amountGet, uint amountGive, uint expires, address indexed tokenGive, uint8 v, bytes32 r, bytes32 s);
    event Trade(address indexed trader, uint amount, address tokenGet, uint amountGet, address tokenGive, address indexed buyer);
    event Deposit(address indexed token, address indexed user, uint amount, uint balance);
    event Withdraw(address indexed token, address indexed user, uint amount, uint balance);

    address public admin;
    address public feeAccount;
    uint public feeMake;
    uint public feeTake;
    uint public feeRebate;

    mapping (address => mapping (address => uint)) public tokens;

    function Exchange(address admin_, address feeAccount_, uint feeMake_, uint feeTake_, uint feeRebate_) {
        admin = admin_;
        feeAccount = feeAccount_;
        feeMake = feeMake_;
        feeTake = feeTake_;
        feeRebate = feeRebate_;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    function changeAdmin(address admin_) onlyAdmin {
        admin = admin_;
    }

    function changeFeeAccount(address feeAccount_) onlyAdmin {
        feeAccount = feeAccount_;
    }

    function changeFeeMake(uint feeMake_) onlyAdmin {
        require(feeMake_ <= feeMake);
        feeMake = feeMake_;
    }

    function changeFeeTake(uint feeTake_) onlyAdmin {
        require(feeTake_ <= feeTake);
        feeTake = feeTake_;
    }

    function deposit() payable {
        tokens[0][msg.sender] = safeAdd(tokens[0][msg.sender], msg.value);
        Deposit(0, msg.sender, msg.value, tokens[0][msg.sender]);
    }

    function withdraw(uint amount) {
        require(tokens[0][msg.sender] >= amount);
        tokens[0][msg.sender] = safeSubtract(tokens[0][msg.sender], amount);
        require(msg.sender.call.value(amount)());
        Withdraw(0, msg.sender, amount, tokens[0][msg.sender]);
    }

    function depositToken(address token, uint amount) {
        require(token != 0);
        require(Token(token).transferFrom(msg.sender, this, amount));
        tokens[token][msg.sender] = safeAdd(tokens[token][msg.sender], amount);
        Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
    }

    function withdrawToken(address token, uint amount) {
        require(token != 0);
        require(tokens[token][msg.sender] >= amount);
        tokens[token][msg.sender] = safeSubtract(tokens[token][msg.sender], amount);
        require(Token(token).transfer(msg.sender, amount));
        Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
    }

    function balanceOf(address token, address user) constant returns (uint) {
        return tokens[token][user];
    }

    function order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce) {
        bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        orderFills[msg.sender][hash] = true;
        Order(msg.sender, amountGet, tokenGet, amountGet, amountGive, expires, tokenGive);
    }

    function trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount) {
        bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        require((orderFills[user][hash] || ecrecover(sha3("\x19Ethereum Signed Message:\n32", hash), v, r, s) == user) && block.number <= expires && safeAdd(orderAmounts[user][hash], amount) <= amountGet);
        executeTrade(tokenGet, amountGet, tokenGive, amountGive, user, amount);
        orderAmounts[user][hash] = safeAdd(orderAmounts[user][hash], amount);
        Trade(user, amount, tokenGet, amountGet, tokenGive, msg.sender);
    }

    function executeTrade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address user, uint amount) internal {
        uint feeMakeXfer = safeMultiply(amount, feeMake) / (1 ether);
        uint feeTakeXfer = safeMultiply(amount, feeTake) / (1 ether);
        tokens[tokenGet][msg.sender] = safeSubtract(tokens[tokenGet][msg.sender], safeAdd(amount, feeTakeXfer));
        tokens[tokenGet][user] = safeAdd(tokens[tokenGet][user], safeSubtract(amount, feeMakeXfer));
        tokens[tokenGet][feeAccount] = safeAdd(tokens[tokenGet][feeAccount], safeAdd(feeMakeXfer, feeTakeXfer));
        tokens[tokenGive][user] = safeSubtract(tokens[tokenGive][user], safeMultiply(amountGive, amount) / amountGet);
        tokens[tokenGive][msg.sender] = safeAdd(tokens[tokenGive][msg.sender], safeMultiply(amountGive, amount) / amountGet);
    }

    function availableVolume(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user) constant returns(uint) {
        bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        if (!(orderFills[user][hash] || ecrecover(sha3("\x19Ethereum Signed Message:\n32", hash), 0, 0, 0) == user) && block.number <= expires) return 0;
        uint available1 = safeSubtract(amountGet, orderAmounts[user][hash]);
        uint available2 = safeMultiply(tokens[tokenGive][user], amountGet) / amountGive;
        if (available1 < available2) return available1;
        return available2;
    }

    function amountFilled(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user) constant returns(uint) {
        bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        return orderAmounts[user][hash];
    }

    function cancelOrder(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, uint8 v, bytes32 r, bytes32 s) {
        bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        require((orderFills[msg.sender][hash] || ecrecover(sha3("\x19Ethereum Signed Message:\n32", hash), v, r, s) == msg.sender));
        orderAmounts[msg.sender][hash] = amountGet;
        Cancel(msg.sender, amountGet, tokenGet, amountGet, amountGive, expires, tokenGive, v, r, s);
    }
}
```