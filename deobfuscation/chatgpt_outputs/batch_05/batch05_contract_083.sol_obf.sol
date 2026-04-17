```solidity
pragma solidity ^0.4.16;

contract Token {
    bytes32 public name;
    bytes32 public symbol;
    bytes32 public standard;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
}

contract SafeMath {
    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}

contract Owned {
    address public owner;
    event SetOwner(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address newOwner) onlyOwner {
        SetOwner(owner, newOwner);
        owner = newOwner;
    }

    function getOwner() constant returns (address) {
        return owner;
    }
}

contract Exchange is SafeMath, Owned {
    mapping(address => mapping(address => uint256)) public tokens;
    mapping(address => bool) public admins;
    mapping(address => uint256) public lastActiveTransaction;
    mapping(bytes32 => uint256) public orderFills;
    address public feeAccount;
    uint256 public inactivityReleasePeriod;
    mapping(bytes32 => mapping(bytes32 => bool)) public traded;

    event Order(address tokenGet, uint256 amountGet, address tokenGive, uint256 amountGive, uint256 expires, uint256 nonce, address user, uint8 v, bytes32 r, bytes32 s);
    event Cancel(address tokenGet, uint256 amountGet, address tokenGive, uint256 amountGive, uint256 expires, uint256 nonce, address user, uint8 v, bytes32 r, bytes32 s);
    event Trade(address tokenGet, uint256 amountGet, address tokenGive, uint256 amountGive, address get, address give);
    event Deposit(address token, address user, uint256 amount, uint256 balance);
    event Withdraw(address token, address user, uint256 amount, uint256 balance);

    function setInactivityReleasePeriod(uint256 _inactivityReleasePeriod) onlyOwner returns (bool success) {
        require(_inactivityReleasePeriod <= 1000000);
        inactivityReleasePeriod = _inactivityReleasePeriod;
        return true;
    }

    function Exchange(address _feeAccount, address _admin) {
        owner = msg.sender;
        feeAccount = _feeAccount;
        inactivityReleasePeriod = 100000;
        admins[_admin] = true;
    }

    modifier onlyAdmin {
        require(msg.sender == owner || admins[msg.sender]);
        _;
    }

    function() external {
        revert();
    }

    function depositToken(address token, uint256 amount) {
        tokens[token][msg.sender] = safeAdd(tokens[token][msg.sender], amount);
        lastActiveTransaction[msg.sender] = block.number;
        require(Token(token).transferFrom(msg.sender, this, amount));
        Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
    }

    function deposit() payable {
        tokens[address(0)][msg.sender] = safeAdd(tokens[address(0)][msg.sender], msg.value);
        lastActiveTransaction[msg.sender] = block.number;
        Deposit(address(0), msg.sender, msg.value, tokens[address(0)][msg.sender]);
    }

    function withdrawToken(address token, uint256 amount) returns (bool success) {
        require(safeSub(block.number, lastActiveTransaction[msg.sender]) >= inactivityReleasePeriod);
        require(tokens[token][msg.sender] >= amount);
        tokens[token][msg.sender] = safeSub(tokens[token][msg.sender], amount);
        if (token == address(0)) {
            require(msg.sender.send(amount));
        } else {
            require(Token(token).transfer(msg.sender, amount));
        }
        Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
        return true;
    }

    function withdraw(uint256 amount) returns (bool success) {
        return withdrawToken(address(0), amount);
    }

    function balanceOf(address token, address user) constant returns (uint256) {
        return tokens[token][user];
    }

    function trade(address tokenGet, uint256 amountGet, address tokenGive, uint256 amountGive, uint256 expires, uint256 nonce, address user, uint8 v, bytes32 r, bytes32 s, uint256 feeMake, uint256 feeTake) onlyAdmin returns (bool success) {
        bytes32 hash = keccak256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        require(!traded[hash][user]);
        traded[hash][user] = true;
        require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == user);
        require(feeMake <= 50 finney);
        require(feeTake <= 50 finney);
        require(tokens[tokenGet][user] >= amountGet);
        tokens[tokenGet][user] = safeSub(tokens[tokenGet][user], amountGet);
        tokens[tokenGet][feeAccount] = safeAdd(tokens[tokenGet][feeAccount], safeMul(feeMake, amountGet) / 1 ether);
        amountGet = safeMul((1 ether - feeMake), amountGet) / 1 ether;
        if (tokenGet == address(0)) {
            require(user.send(amountGet));
        } else {
            require(Token(tokenGet).transfer(user, amountGet));
        }
        lastActiveTransaction[user] = block.number;
        Withdraw(tokenGet, user, amountGet, tokens[tokenGet][user]);
        return true;
    }
}
```