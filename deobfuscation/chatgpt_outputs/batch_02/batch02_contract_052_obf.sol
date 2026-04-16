```solidity
pragma solidity ^0.4.24;

contract MathOperations {
    function multiply(uint a, uint b) internal pure returns (uint) {
        uint result = a * b;
        assert(a == 0 || result / a == b);
        return result;
    }

    function subtract(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint result = a + b;
        assert(result >= a && result >= b);
        return result;
    }
}

contract TokenInterface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address owner) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is TokenInterface, MathOperations {
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    uint256 public totalSupply;

    function transfer(address to, uint256 value) public returns (bool) {
        if (balances[msg.sender] >= value && balances[to] + value > balances[to]) {
            balances[msg.sender] = subtract(balances[msg.sender], value);
            balances[to] = add(balances[to], value);
            emit Transfer(msg.sender, to, value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        if (balances[from] >= value && allowed[from][msg.sender] >= value && balances[to] + value > balances[to]) {
            balances[to] = add(balances[to], value);
            balances[from] = subtract(balances[from], value);
            allowed[from][msg.sender] = subtract(allowed[from][msg.sender], value);
            emit Transfer(from, to, value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }
}

contract Exchange is MathOperations {
    address public admin;
    address public feeAccount;
    address public rebateAccount;
    mapping(address => mapping(bytes32 => uint)) public orderFills;
    event Order(address indexed trader, uint amountGive, address indexed tokenGive, uint amountGet, uint expires, uint nonce, address indexed tokenGet);
    event Cancel(address indexed trader, uint amountGive, address indexed tokenGive, uint amountGet, uint expires, uint nonce, address indexed tokenGet, uint8 v, bytes32 r, bytes32 s);
    event Trade(address indexed trader, uint amountGive, address indexed tokenGive, uint amountGet, address indexed tokenGet, address buyer);
    event Deposit(address indexed token, address indexed user, uint amount, uint balance);
    event Withdraw(address indexed token, address indexed user, uint amount, uint balance);

    constructor(address admin_, address feeAccount_, address rebateAccount_) public {
        admin = admin_;
        feeAccount = feeAccount_;
        rebateAccount = rebateAccount_;
    }

    function deposit() payable public {
        balances[0][msg.sender] = add(balances[0][msg.sender], msg.value);
        emit Deposit(0, msg.sender, msg.value, balances[0][msg.sender]);
    }

    function withdraw(uint amount) public {
        require(balances[0][msg.sender] >= amount);
        balances[0][msg.sender] = subtract(balances[0][msg.sender], amount);
        require(msg.sender.call.value(amount)());
        emit Withdraw(0, msg.sender, amount, balances[0][msg.sender]);
    }

    function depositToken(address token, uint amount) public {
        require(token != 0);
        require(TokenInterface(token).transferFrom(msg.sender, this, amount));
        balances[token][msg.sender] = add(balances[token][msg.sender], amount);
        emit Deposit(token, msg.sender, amount, balances[token][msg.sender]);
    }

    function withdrawToken(address token, uint amount) public {
        require(token != 0);
        require(balances[token][msg.sender] >= amount);
        balances[token][msg.sender] = subtract(balances[token][msg.sender], amount);
        require(TokenInterface(token).transfer(msg.sender, amount));
        emit Withdraw(token, msg.sender, amount, balances[token][msg.sender]);
    }

    function balanceOf(address token, address user) public view returns (uint) {
        return balances[token][user];
    }

    function order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce) public {
        bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        orderFills[msg.sender][hash] = 0;
        emit Order(msg.sender, amountGive, tokenGive, amountGet, expires, nonce, tokenGet);
    }

    function trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount) public {
        bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        require((orderFills[user][hash] == 0 || ecrecover(sha3("\x19Ethereum Signed Message:\n32", hash), v, r, s) == user) && block.number <= expires && add(orderFills[user][hash], amount) <= amountGet);
        executeTrade(tokenGet, amountGet, tokenGive, amountGive, user, amount);
        orderFills[user][hash] = add(orderFills[user][hash], amount);
        emit Trade(user, amount, tokenGive, amountGive * amount / amountGet, tokenGet, msg.sender);
    }

    function executeTrade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address user, uint amount) private {
        uint feeMakeXfer = multiply(amount, feeMake) / (1 ether);
        uint feeTakeXfer = multiply(amount, feeTake) / (1 ether);
        uint feeRebateXfer = 0;
        if (rebateAccount != 0x0) {
            uint accountLevel = AccountLevels(rebateAccount).accountLevel(user);
            if (accountLevel == 1) feeRebateXfer = multiply(amount, feeRebate) / (1 ether);
            if (accountLevel == 2) feeRebateXfer = feeTakeXfer;
        }
        balances[tokenGet][msg.sender] = subtract(balances[tokenGet][msg.sender], add(amount, feeTakeXfer));
        balances[tokenGet][user] = add(balances[tokenGet][user], subtract(amount, feeMakeXfer));
        balances[tokenGet][feeAccount] = add(balances[tokenGet][feeAccount], subtract(feeMakeXfer, feeRebateXfer));
        balances[tokenGive][user] = subtract(balances[tokenGive][user], multiply(amountGive, amount) / amountGet);
        balances[tokenGive][msg.sender] = add(balances[tokenGive][msg.sender], multiply(amountGive, amount) / amountGet);
    }

    function availableVolume(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) public view returns (uint) {
        bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        if (!((orderFills[user][hash] == 0 || ecrecover(sha3("\x19Ethereum Signed Message:\n32", hash), v, r, s) == user) && block.number <= expires)) return 0;
        uint available1 = subtract(amountGet, orderFills[user][hash]);
        uint available2 = multiply(balances[tokenGive][user], amountGet) / amountGive;
        if (available1 < available2) return available1;
        return available2;
    }

    function amountFilled(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user) public view returns (uint) {
        bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        return orderFills[user][hash];
    }

    function cancelOrder(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        require(orderFills[msg.sender][hash] == 0 || ecrecover(sha3("\x19Ethereum Signed Message:\n32", hash), v, r, s) == msg.sender);
        orderFills[msg.sender][hash] = amountGet;
        emit Cancel(msg.sender, amountGet, tokenGive, amountGive, expires, nonce, msg.sender, v, r, s);
    }

    mapping(address => mapping(address => uint256)) balances;
    uint public feeMake;
    uint public feeTake;
    uint public feeRebate;
}

contract AccountLevels {
    mapping(address => uint) public accountLevel;

    function setAccountLevel(address user, uint level) public {
        accountLevel[user] = level;
    }

    function getAccountLevel(address user) public view returns (uint) {
        return accountLevel[user];
    }
}
```