```solidity
pragma solidity ^0.4.9;

contract SafeMath {
    function safeMul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a && c >= b);
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
    uint256 public totalSupply;

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = safeSub(balances[_from], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
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
        totalSupply = _initialSupply * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply;
    }
}

contract Exchange is SafeMath {
    address public feeAccount;
    address public admin;
    uint public feeMake;
    uint public feeTake;
    uint public feeRebate;

    mapping(address => mapping(address => uint256)) public tokens;
    mapping(address => mapping(bytes32 => bool)) public orders;
    mapping(address => mapping(bytes32 => uint256)) public orderFills;

    event Order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user);
    event Cancel(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s);
    event Trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address get, address give, bytes32 hash);
    event Deposit(address token, address user, uint amount, uint balance);
    event Withdraw(address token, address user, uint amount, uint balance);

    constructor(address _feeAccount, address _admin, uint _feeMake, uint _feeTake, uint _feeRebate) public {
        feeAccount = _feeAccount;
        admin = _admin;
        feeMake = _feeMake;
        feeTake = _feeTake;
        feeRebate = _feeRebate;
    }

    function() public {
        revert();
    }

    function changeFeeAccount(address _feeAccount) public {
        require(msg.sender == admin);
        feeAccount = _feeAccount;
    }

    function changeAdmin(address _admin) public {
        require(msg.sender == admin);
        admin = _admin;
    }

    function changeFeeMake(uint _feeMake) public {
        require(msg.sender == admin);
        require(_feeMake < feeMake);
        feeMake = _feeMake;
    }

    function changeFeeTake(uint _feeTake) public {
        require(msg.sender == admin);
        require(_feeTake < feeTake);
        feeTake = _feeTake;
    }

    function changeFeeRebate(uint _feeRebate) public {
        require(msg.sender == admin);
        require(_feeRebate < feeRebate);
        feeRebate = _feeRebate;
    }

    function deposit() public payable {
        tokens[0][msg.sender] = safeAdd(tokens[0][msg.sender], msg.value);
        emit Deposit(0, msg.sender, msg.value, tokens[0][msg.sender]);
    }

    function withdraw(uint _amount) public {
        require(tokens[0][msg.sender] >= _amount);
        tokens[0][msg.sender] = safeSub(tokens[0][msg.sender], _amount);
        msg.sender.transfer(_amount);
        emit Withdraw(0, msg.sender, _amount, tokens[0][msg.sender]);
    }

    function depositToken(address _token, uint _amount) public {
        require(_token != 0);
        require(Token(_token).transferFrom(msg.sender, this, _amount));
        tokens[_token][msg.sender] = safeAdd(tokens[_token][msg.sender], _amount);
        emit Deposit(_token, msg.sender, _amount, tokens[_token][msg.sender]);
    }

    function withdrawToken(address _token, uint _amount) public {
        require(_token != 0);
        require(tokens[_token][msg.sender] >= _amount);
        tokens[_token][msg.sender] = safeSub(tokens[_token][msg.sender], _amount);
        require(Token(_token).transfer(msg.sender, _amount));
        emit Withdraw(_token, msg.sender, _amount, tokens[_token][msg.sender]);
    }

    function balanceOf(address _token, address _user) public view returns (uint) {
        return tokens[_token][_user];
    }

    function order(address _tokenGet, uint _amountGet, address _tokenGive, uint _amountGive, uint _expires, uint _nonce) public {
        bytes32 hash = sha256(this, _tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce);
        orders[msg.sender][hash] = true;
        emit Order(_tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce, msg.sender);
    }

    function trade(address _tokenGet, uint _amountGet, address _tokenGive, uint _amountGive, uint _expires, uint _nonce, address _user, uint8 _v, bytes32 _r, bytes32 _s, uint _amount) public {
        bytes32 hash = sha256(this, _tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce);
        require((orders[_user][hash] || ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), _v, _r, _s) == _user) && block.number <= _expires && safeAdd(orderFills[_user][hash], _amount) <= _amountGet);
        executeTrade(_tokenGet, _amountGet, _tokenGive, _amountGive, _user, _amount);
        orderFills[_user][hash] = safeAdd(orderFills[_user][hash], _amount);
        emit Trade(_tokenGet, _amount, _tokenGive, safeMul(_amountGive, _amount) / _amountGet, _user, msg.sender, hash);
    }

    function executeTrade(address _tokenGet, uint _amountGet, address _tokenGive, uint _amountGive, address _user, uint _amount) private {
        uint feeMakeXfer = safeMul(_amount, feeMake) / (1 ether);
        uint feeTakeXfer = safeMul(_amount, feeTake) / (1 ether);
        uint feeRebateXfer = 0;
        if (feeRebate != 0) {
            uint accountLevel = AccountLevels(feeRebate).accountLevel(_user);
            if (accountLevel == 1) feeRebateXfer = safeMul(_amount, feeRebate) / (1 ether);
            if (accountLevel == 2) feeTakeXfer = feeRebateXfer;
        }
        tokens[_tokenGet][_user] = safeSub(tokens[_tokenGet][_user], safeAdd(_amount, feeTakeXfer));
        tokens[_tokenGet][msg.sender] = safeAdd(tokens[_tokenGet][msg.sender], safeSub(_amount, feeMakeXfer));
        tokens[_tokenGet][feeAccount] = safeAdd(tokens[_tokenGet][feeAccount], safeSub(feeMakeXfer, feeRebateXfer));
        tokens[_tokenGive][_user] = safeAdd(tokens[_tokenGive][_user], safeMul(_amountGive, _amount) / _amountGet);
        tokens[_tokenGive][msg.sender] = safeSub(tokens[_tokenGive][msg.sender], safeMul(_amountGive, _amount) / _amountGet);
    }

    function availableVolume(address _tokenGet, uint _amountGet, address _tokenGive, uint _amountGive, uint _expires, uint _nonce, address _user, uint8 _v, bytes32 _r, bytes32 _s) public view returns (uint) {
        bytes32 hash = sha256(this, _tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce);
        if (!((orders[_user][hash] || ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), _v, _r, _s) == _user) && block.number <= _expires)) return 0;
        uint available1 = safeSub(_amountGet, orderFills[_user][hash]);
        uint available2 = safeMul(tokens[_tokenGive][msg.sender], _amountGet) / _amountGive;
        if (available1 < available2) return available1;
        return available2;
    }

    function amountFilled(address _tokenGet, uint _amountGet, address _tokenGive, uint _amountGive, uint _expires, uint _nonce, address _user, uint8 _v, bytes32 _r, bytes32 _s) public view returns (uint) {
        bytes32 hash = sha256(this, _tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce);
        return orderFills[_user][hash];
    }

    function cancelOrder(address _tokenGet, uint _amountGet, address _tokenGive, uint _amountGive, uint _expires, uint _nonce, uint8 _v, bytes32 _r, bytes32 _s) public {
        bytes32 hash = sha256(this, _tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce);
        require(orders[msg.sender][hash] || ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), _v, _r, _s) == msg.sender);
        orderFills[msg.sender][hash] = _amountGet;
        emit Cancel(_tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce, msg.sender, _v, _r, _s);
    }
}

contract AccountLevels {
    function accountLevel(address user) public view returns (uint);
}
```