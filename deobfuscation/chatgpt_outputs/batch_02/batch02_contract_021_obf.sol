```solidity
pragma solidity ^0.4.24;

contract SafeMath {
    function safeMul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}

contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, SafeMath {
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    uint256 totalSupply_;

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balances[msg.sender]);

        balances[msg.sender] = safeSub(balances[msg.sender], value);
        balances[to] = safeAdd(balances[to], value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balances[from]);
        require(value <= allowed[from][msg.sender]);

        balances[from] = safeSub(balances[from], value);
        balances[to] = safeAdd(balances[to], value);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], value);
        emit Transfer(from, to, value);
        return true;
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

contract Token is StandardToken {
    string public name;
    string public symbol;
    uint8 public decimals;

    constructor(string _name, string _symbol, uint8 _decimals, uint256 _initialSupply) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply_ = _initialSupply * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply_;
        emit Transfer(address(0), msg.sender, totalSupply_);
    }
}

contract Exchange is SafeMath {
    address public admin;
    address public feeAccount;
    address public rebateAccount;
    mapping(address => mapping(bytes32 => uint)) public orderFills;
    mapping(address => mapping(address => uint)) public tokens;
    uint public feeMake;
    uint public feeTake;
    uint public feeRebate;

    event Order(address indexed maker, uint amountGive, address indexed tokenGive, uint amountGet, uint expires, uint nonce, address indexed user);
    event Cancel(address indexed maker, uint amountGive, address indexed tokenGive, uint amountGet, uint expires, uint nonce, address indexed user, uint8 v, bytes32 r, bytes32 s);
    event Trade(address indexed maker, uint amountGive, address indexed tokenGive, uint amountGet, address indexed taker, address user);
    event Deposit(address indexed token, address indexed user, uint amount, uint balance);
    event Withdraw(address indexed token, address indexed user, uint amount, uint balance);

    constructor(address _admin, address _feeAccount, address _rebateAccount, uint _feeMake, uint _feeTake, uint _feeRebate) public {
        admin = _admin;
        feeAccount = _feeAccount;
        rebateAccount = _rebateAccount;
        feeMake = _feeMake;
        feeTake = _feeTake;
        feeRebate = _feeRebate;
    }

    function() public {
        revert();
    }

    function changeAdmin(address _admin) public {
        require(msg.sender == admin);
        admin = _admin;
    }

    function changeFeeAccount(address _feeAccount) public {
        require(msg.sender == admin);
        feeAccount = _feeAccount;
    }

    function changeRebateAccount(address _rebateAccount) public {
        require(msg.sender == admin);
        rebateAccount = _rebateAccount;
    }

    function changeFeeMake(uint _feeMake) public {
        require(msg.sender == admin);
        feeMake = _feeMake;
    }

    function changeFeeTake(uint _feeTake) public {
        require(msg.sender == admin);
        feeTake = _feeTake;
    }

    function changeFeeRebate(uint _feeRebate) public {
        require(msg.sender == admin);
        feeRebate = _feeRebate;
    }

    function deposit() payable public {
        tokens[0][msg.sender] = safeAdd(tokens[0][msg.sender], msg.value);
        emit Deposit(0, msg.sender, msg.value, tokens[0][msg.sender]);
    }

    function withdraw(uint amount) public {
        require(tokens[0][msg.sender] >= amount);
        tokens[0][msg.sender] = safeSub(tokens[0][msg.sender], amount);
        msg.sender.transfer(amount);
        emit Withdraw(0, msg.sender, amount, tokens[0][msg.sender]);
    }

    function depositToken(address token, uint amount) public {
        require(token != 0);
        require(Token(token).transferFrom(msg.sender, this, amount));
        tokens[token][msg.sender] = safeAdd(tokens[token][msg.sender], amount);
        emit Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
    }

    function withdrawToken(address token, uint amount) public {
        require(token != 0);
        require(tokens[token][msg.sender] >= amount);
        tokens[token][msg.sender] = safeSub(tokens[token][msg.sender], amount);
        require(Token(token).transfer(msg.sender, amount));
        emit Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
    }

    function balanceOf(address token, address user) public view returns (uint) {
        return tokens[token][user];
    }

    function order(address tokenGive, uint amountGive, address tokenGet, uint amountGet, uint expires, uint nonce) public {
        bytes32 hash = sha256(this, tokenGive, amountGive, tokenGet, amountGet, expires, nonce);
        orderFills[msg.sender][hash] = 0;
        emit Order(tokenGive, amountGive, tokenGet, amountGet, expires, nonce, msg.sender);
    }

    function trade(address tokenGive, uint amountGive, address tokenGet, uint amountGet, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount) public {
        bytes32 hash = sha256(this, tokenGive, amountGive, tokenGet, amountGet, expires, nonce);
        require((orderFills[user][hash] == 0 || ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == user) && block.number <= expires && safeAdd(orderFills[user][hash], amount) <= amountGive);
        tradeBalances(tokenGive, amountGive, tokenGet, amountGet, user, amount);
        orderFills[user][hash] = safeAdd(orderFills[user][hash], amount);
        emit Trade(tokenGive, amount, tokenGet, safeMul(amountGet, amount) / amountGive, user, msg.sender);
    }

    function tradeBalances(address tokenGive, uint amountGive, address tokenGet, uint amountGet, address user, uint amount) private {
        uint feeMakeXfer = safeMul(amount, feeMake) / (1 ether);
        uint feeTakeXfer = safeMul(amount, feeTake) / (1 ether);
        uint feeRebateXfer = 0;
        if (rebateAccount != 0x0) {
            uint accountLevel = AccountLevels(rebateAccount).accountLevel(user);
            if (accountLevel == 1) feeRebateXfer = safeMul(amount, feeRebate) / (1 ether);
            if (accountLevel == 2) feeRebateXfer = feeTakeXfer;
        }
        tokens[tokenGive][msg.sender] = safeSub(tokens[tokenGive][msg.sender], safeAdd(amount, feeTakeXfer));
        tokens[tokenGive][user] = safeAdd(tokens[tokenGive][user], safeSub(amount, feeMakeXfer));
        tokens[tokenGive][feeAccount] = safeAdd(tokens[tokenGive][feeAccount], safeSub(feeMakeXfer, feeRebateXfer));
        tokens[tokenGet][user] = safeSub(tokens[tokenGet][user], safeMul(amountGet, amount) / amountGive);
        tokens[tokenGet][msg.sender] = safeAdd(tokens[tokenGet][msg.sender], safeMul(amountGet, amount) / amountGive);
    }

    function availableVolume(address tokenGive, uint amountGive, address tokenGet, uint amountGet, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) public view returns (uint) {
        bytes32 hash = sha256(this, tokenGive, amountGive, tokenGet, amountGet, expires, nonce);
        if (!((orderFills[user][hash] == 0 || ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == user) && block.number <= expires)) return 0;
        uint available1 = safeSub(amountGive, orderFills[user][hash]);
        uint available2 = safeMul(tokens[tokenGet][user], amountGive) / amountGet;
        if (available1 < available2) return available1;
        return available2;
    }

    function amountFilled(address tokenGive, uint amountGive, address tokenGet, uint amountGet, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) public view returns (uint) {
        bytes32 hash = sha256(this, tokenGive, amountGive, tokenGet, amountGet, expires, nonce);
        return orderFills[user][hash];
    }

    function cancelOrder(address tokenGive, uint amountGive, address tokenGet, uint amountGet, uint expires, uint nonce, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 hash = sha256(this, tokenGive, amountGive, tokenGet, amountGet, expires, nonce);
        require(orderFills[msg.sender][hash] == 0 || ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == msg.sender);
        orderFills[msg.sender][hash] = amountGive;
        emit Cancel(tokenGive, amountGive, tokenGet, amountGet, expires, nonce, msg.sender, v, r, s);
    }
}

contract AccountLevels {
    function accountLevel(address user) public view returns (uint);
}
```