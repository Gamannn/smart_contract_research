```solidity
pragma solidity ^0.4.24;

contract MathOperations {
    function safeMultiply(uint a, uint b) internal pure returns (uint) {
        uint result = a * b;
        assert(a == 0 || result / a == b);
        return result;
    }

    function safeSubtract(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal pure returns (uint) {
        uint result = a + b;
        assert(result >= a && result >= b);
        return result;
    }
}

contract Token {
    bytes32 public name;
    bytes32 public symbol;
    bytes32 public standard;
    uint256 public totalSupply;
    uint8 public decimals;
    mapping(address => mapping(address => uint256)) public allowance;

    function transfer(address to, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function approve(address spender, uint256 value) public returns (bool success);
    function allowance(address owner, address spender) public view returns (uint256 remaining);
}

contract Exchange is MathOperations {
    address public admin;
    mapping(address => mapping(bytes32 => bool)) public orderCancelled;
    mapping(address => mapping(bytes32 => uint)) public orderFilled;
    event Order(address indexed user, uint amountGet, address tokenGet, uint amountGive, uint expires, uint nonce, address indexed tokenGive);
    event Cancel(address indexed user, uint amountGet, address tokenGet, uint amountGive, uint expires, uint nonce, address indexed tokenGive, uint8 v, bytes32 r, bytes32 s);
    event Trade(address indexed user, uint amountGet, address tokenGet, uint amountGive, address indexed tokenGive, address indexed get);
    event Deposit(address indexed token, address indexed user, uint amount, uint balance);
    event Withdraw(address indexed token, address indexed user, uint amount, uint balance);

    constructor() public {
        admin = msg.sender;
    }

    function changeAdmin(address newAdmin) public {
        require(msg.sender == admin);
        admin = newAdmin;
    }

    function deposit() payable public {
        balances[0][msg.sender] = safeAdd(balances[0][msg.sender], msg.value);
        emit Deposit(0, msg.sender, msg.value, balances[0][msg.sender]);
    }

    function withdraw(uint amount) public {
        require(balances[0][msg.sender] >= amount);
        balances[0][msg.sender] = safeSubtract(balances[0][msg.sender], amount);
        require(msg.sender.call.value(amount)());
        emit Withdraw(0, msg.sender, amount, balances[0][msg.sender]);
    }

    function depositToken(address token, uint amount) public {
        require(token != 0);
        require(Token(token).transferFrom(msg.sender, this, amount));
        balances[token][msg.sender] = safeAdd(balances[token][msg.sender], amount);
        emit Deposit(token, msg.sender, amount, balances[token][msg.sender]);
    }

    function withdrawToken(address token, uint amount) public {
        require(token != 0);
        require(balances[token][msg.sender] >= amount);
        balances[token][msg.sender] = safeSubtract(balances[token][msg.sender], amount);
        require(Token(token).transfer(msg.sender, amount));
        emit Withdraw(token, msg.sender, amount, balances[token][msg.sender]);
    }

    function balanceOf(address token, address user) public view returns (uint) {
        return balances[token][user];
    }

    function order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce) public {
        bytes32 hash = keccak256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        orders[msg.sender][hash] = true;
        emit Order(msg.sender, amountGet, tokenGet, amountGive, expires, nonce, tokenGive);
    }

    function cancelOrder(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 hash = keccak256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        require((ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == msg.sender) && block.number <= expires);
        orderCancelled[msg.sender][hash] = true;
        emit Cancel(msg.sender, amountGet, tokenGet, amountGive, expires, nonce, tokenGive, v, r, s);
    }

    function trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint amount) public {
        bytes32 hash = keccak256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        require((ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == user) && block.number <= expires && safeAdd(orderFilled[user][hash], amount) <= amountGet);
        tradeBalances(tokenGet, amountGet, tokenGive, amountGive, user, amount);
        orderFilled[user][hash] = safeAdd(orderFilled[user][hash], amount);
        emit Trade(user, amount, tokenGet, safeMultiply(amountGive, amount) / amountGet, tokenGive, msg.sender);
    }

    function tradeBalances(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address user, uint amount) private {
        uint feeMakeXfer = safeMultiply(amount, feeMake) / (1 ether);
        uint feeTakeXfer = safeMultiply(amount, feeTake) / (1 ether);
        balances[tokenGet][msg.sender] = safeSubtract(balances[tokenGet][msg.sender], safeAdd(amount, feeTakeXfer));
        balances[tokenGet][user] = safeAdd(balances[tokenGet][user], safeSubtract(amount, feeMakeXfer));
        balances[tokenGet][feeAccount] = safeAdd(balances[tokenGet][feeAccount], safeAdd(feeMakeXfer, feeTakeXfer));
        balances[tokenGive][user] = safeSubtract(balances[tokenGive][user], safeMultiply(amountGive, amount) / amountGet);
        balances[tokenGive][msg.sender] = safeAdd(balances[tokenGive][msg.sender], safeMultiply(amountGive, amount) / amountGet);
    }

    function availableVolume(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user) public view returns (uint) {
        bytes32 hash = keccak256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        if (!(orderFilled[user][hash] < amountGet && availableVolume(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, user) >= amount)) return 0;
        uint available1 = safeSubtract(amountGet, orderFilled[user][hash]);
        uint available2 = safeMultiply(balances[tokenGive][user], amountGet) / amountGive;
        if (available1 < available2) return available1;
        return available2;
    }

    function amountFilled(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user) public view returns (uint) {
        bytes32 hash = keccak256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        return orderFilled[user][hash];
    }
}
```