```solidity
pragma solidity ^0.4.19;

contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}

contract ERC20 {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public constant returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Token is ERC20, SafeMath {
    uint256 public totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 _allowance = allowed[_from][msg.sender];
        balances[_to] = safeAdd(balances[_to], _value);
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][msg.sender] = safeSub(_allowance, _value);
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract Exchange is SafeMath {
    address public admin;
    address public feeAccount;
    uint256 public feeMake;
    uint256 public feeTake;
    uint256 public feeRebate;
    mapping(bytes32 => uint256) public orderFills;
    mapping(bytes32 => uint256) public orderBalances;

    event MakeOrder(bytes32 indexed hash, address indexed tokenGet, uint256 amountGet, uint256 amountGive, address indexed user);
    event CancelOrder(bytes32 indexed hash, address indexed tokenGet, uint256 amountGet, uint256 amountGive, address indexed user);
    event Trade(bytes32 indexed hash, address indexed tokenGet, uint256 amountGet, uint256 amountGive, address indexed user, uint256 amount);

    function Exchange(address _admin, address _feeAccount, uint256 _feeMake, uint256 _feeTake, uint256 _feeRebate) public {
        admin = _admin;
        feeAccount = _feeAccount;
        feeMake = _feeMake;
        feeTake = _feeTake;
        feeRebate = _feeRebate;
    }

    function changeAdmin(address _admin) public {
        require(msg.sender == admin);
        admin = _admin;
    }

    function changeFeeAccount(address _feeAccount) public {
        require(msg.sender == admin);
        feeAccount = _feeAccount;
    }

    function changeFeeMake(uint256 _feeMake) public {
        require(msg.sender == admin);
        require(_feeMake < feeMake);
        feeMake = _feeMake;
    }

    function changeFeeTake(uint256 _feeTake) public {
        require(msg.sender == admin);
        require(_feeTake < feeTake);
        feeTake = _feeTake;
    }

    function changeFeeRebate(uint256 _feeRebate) public {
        require(msg.sender == admin);
        require(_feeRebate < feeRebate);
        feeRebate = _feeRebate;
    }

    function makeOrder(address tokenGet, uint256 amountGet, uint256 amountGive) public {
        require(amountGet != 0);
        require(amountGive != 0);
        bytes32 hash = sha256(tokenGet, amountGet, amountGive, msg.sender);
        orderBalances[hash] = safeAdd(orderBalances[hash], amountGet);
        require(amountGet <= Token(tokenGet).balanceOf(msg.sender));
        require(Token(tokenGet).transferFrom(msg.sender, this, amountGet));
        MakeOrder(hash, tokenGet, amountGet, amountGive, msg.sender);
    }

    function cancelOrder(address tokenGet, uint256 amountGet, uint256 amountGive) public {
        bytes32 hash = sha256(tokenGet, amountGet, amountGive, msg.sender);
        uint256 amount = orderBalances[hash];
        delete orderBalances[hash];
        Token(tokenGet).transfer(msg.sender, amount);
        CancelOrder(hash, tokenGet, amountGet, amountGive, msg.sender);
    }

    function trade(address tokenGet, uint256 amountGet, uint256 amountGive, uint256 amount, address user) public {
        require(amountGet != 0);
        require(amountGive != 0);
        require(amount != 0);
        bytes32 hash = sha256(tokenGet, amountGet, amountGive, user);
        uint256 tradeAmount = safeMul(amount, amountGive) / amountGet;
        uint256 feeAmount = safeMul(tradeAmount, feeTake) / (1 ether);
        uint256 rebateAmount = safeMul(tradeAmount, feeRebate) / (1 ether);
        require(orderBalances[hash] >= tradeAmount);
        orderBalances[hash] = safeSub(orderBalances[hash], tradeAmount);
        require(Token(tokenGet).balanceOf(msg.sender) >= amount);
        if (rebateAmount > feeAmount) {
            uint256 refundAmount = safeSub(rebateAmount, feeAmount);
            if (!user.send(refundAmount)) {
                revert();
            }
        }
        if (!Token(tokenGet).transferFrom(msg.sender, user, amount)) {
            revert();
        }
        if (safeSub(feeAmount, rebateAmount) > 0) {
            if (!feeAccount.send(safeSub(feeAmount, rebateAmount))) {
                revert();
            }
        }
        if (!msg.sender.send(safeSub(tradeAmount, rebateAmount))) {
            revert();
        }
        Trade(hash, tokenGet, amountGet, amountGive, user, amount);
    }
}
```