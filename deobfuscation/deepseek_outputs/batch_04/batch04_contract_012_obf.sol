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
    
    function require(bool condition) internal {
        if (!condition) throw;
    }
}

contract ERC20 {
    function totalSupply() constant returns (uint256) {}
    function balanceOf(address who) constant returns (uint256) {}
    function transfer(address to, uint256 value) returns (bool success) {}
    function transferFrom(address from, address to, uint256 value) returns (bool success) {}
    function approve(address spender, uint256 value) returns (bool success) {}
    function allowance(address owner, address spender) constant returns (uint256 remaining) {}
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    uint public decimals;
    string public name;
}

contract StandardToken is ERC20, SafeMath {
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    uint256 public totalSupply;
    
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] = safeSub(balances[msg.sender], _value);
            balances[_to] = safeAdd(balances[_to], _value);
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }
    
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] = safeAdd(balances[_to], _value);
            balances[_from] = safeSub(balances[_from], _value);
            allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }
    
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
    
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract MintableToken is StandardToken, SafeMath {
    address public minter;
    
    function MintableToken(address _minter) {
        minter = _minter;
    }
    
    function mint(address _account, uint _amount) {
        if (msg.sender != minter) throw;
        balances[_account] = safeAdd(balances[_account], _amount);
        totalSupply = safeAdd(totalSupply, _amount);
    }
    
    function burn(address _account, uint _amount) {
        if (msg.sender != minter) throw;
        if (balances[_account] < _amount) throw;
        balances[_account] = safeSub(balances[_account], _amount);
        totalSupply = safeSub(totalSupply, _amount);
    }
}

contract AccountLevels {
    function accountLevel(address user) constant returns(uint) {}
}

contract AccountLevelsTest is AccountLevels {
    mapping(address => uint) public accountLevels;
    
    function setAccountLevel(address user, uint level) {
        accountLevels[user] = level;
    }
    
    function accountLevel(address user) constant returns(uint) {
        return accountLevels[user];
    }
}

contract Exchange is SafeMath {
    address public admin;
    address public feeAccount;
    address public accountLevelsAddr;
    
    uint public feeMake;
    uint public feeTake;
    uint public feeRebate;
    
    event Order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user);
    event Cancel(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s);
    event Trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address get, address give);
    event Deposit(address token, address user, uint amount, uint balance);
    event Withdraw(address token, address user, uint amount, uint balance);
    
    function Exchange(address _admin, address _feeAccount, address _accountLevelsAddr, uint _feeMake, uint _feeTake, uint _feeRebate) {
        admin = _admin;
        feeAccount = _feeAccount;
        accountLevelsAddr = _accountLevelsAddr;
        feeMake = _feeMake;
        feeTake = _feeTake;
        feeRebate = _feeRebate;
    }
    
    function changeAdmin(address _admin) {
        if (msg.sender != admin) throw;
        admin = _admin;
    }
    
    function changeAccountLevelsAddr(address _accountLevelsAddr) {
        if (msg.sender != admin) throw;
        accountLevelsAddr = _accountLevelsAddr;
    }
    
    function changeFeeAccount(address _feeAccount) {
        if (msg.sender != admin) throw;
        feeAccount = _feeAccount;
    }
    
    function changeFeeMake(uint _feeMake) {
        if (msg.sender != admin) throw;
        if (_feeMake > feeMake) throw;
        feeMake = _feeMake;
    }
    
    function changeFeeTake(uint _feeTake) {
        if (msg.sender != admin) throw;
        if (_feeTake > feeTake || _feeTake < feeRebate) throw;
        feeTake = _feeTake;
    }
    
    function changeFeeRebate(uint _feeRebate) {
        if (msg.sender != admin) throw;
        if (_feeRebate > feeTake || _feeRebate > feeRebate) throw;
        feeRebate = _feeRebate;
    }
    
    mapping(address => mapping(address => uint)) public tokens;
    mapping(address => mapping(bytes32 => bool)) public orders;
    mapping(address => mapping(bytes32 => uint)) public orderFills;
    
    function deposit() payable {
        tokens[0][msg.sender] = safeAdd(tokens[0][msg.sender], msg.value);
        Deposit(0, msg.sender, msg.value, tokens[0][msg.sender]);
    }
    
    function withdraw(uint amount) {
        if (tokens[0][msg.sender] < amount) throw;
        tokens[0][msg.sender] = safeSub(tokens[0][msg.sender], amount);
        if (!msg.sender.call.value(amount)()) throw;
        Withdraw(0, msg.sender, amount, tokens[0][msg.sender]);
    }
    
    function depositToken(address token, uint amount) {
        if (token == 0) throw;
        if (!ERC20(token).transferFrom(msg.sender, this, amount)) throw;
        tokens[token][msg.sender] = safeAdd(tokens[token][msg.sender], amount);
        Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
    }
    
    function withdrawToken(address token, uint amount) {
        if (token == 0) throw;
        if (tokens[token][msg.sender] < amount) throw;
        tokens[token][msg.sender] = safeSub(tokens[token][msg.sender], amount);
        if (!ERC20(token).transfer(msg.sender, amount)) throw;
        Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
    }
    
    function balanceOf(address token, address user) constant returns (uint) {
        return tokens[token][user];
    }
    
    function order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce) {
        bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        orders[msg.sender][hash] = true;
        Order(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender);
    }
    
    function trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount) {
        bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        if (!(
            (orders[user][hash] || ecrecover(sha3("\x19Ethereum Signed Message:\n32", hash), v, r, s) == user) &&
            block.number <= expires &&
            safeAdd(orderFills[user][hash], amount) <= amountGet
        )) throw;
        tradeBalances(tokenGet, amountGet, tokenGive, amountGive, user, amount);
        orderFills[user][hash] = safeAdd(orderFills[user][hash], amount);
        Trade(tokenGet, amount, tokenGive, amountGive * amount / amountGet, user, msg.sender);
    }
    
    function tradeBalances(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address user, uint amount) private {
        uint feeMakeXfer = safeMul(amount, feeMake) / (1 ether);
        uint feeTakeXfer = safeMul(amount, feeTake) / (1 ether);
        uint feeRebateXfer = 0;
        
        if (accountLevelsAddr != 0x0) {
            uint accountLevel = AccountLevels(accountLevelsAddr).accountLevel(user);
            if (accountLevel == 1) feeRebateXfer = safeMul(amount, feeRebate) / (1 ether);
            if (accountLevel == 2) feeRebateXfer = feeTakeXfer;
        }
        
        tokens[tokenGet][msg.sender] = safeSub(tokens[tokenGet][msg.sender], safeAdd(amount, feeTakeXfer));
        tokens[tokenGet][user] = safeAdd(tokens[tokenGet][user], safeSub(safeAdd(amount, feeRebateXfer), feeMakeXfer));
        tokens[tokenGet][feeAccount] = safeAdd(tokens[tokenGet][feeAccount], safeSub(safeAdd(feeMakeXfer, feeTakeXfer), feeRebateXfer));
        tokens[tokenGive][user] = safeSub(tokens[tokenGive][user], safeMul(amountGive, amount) / amountGet);
        tokens[tokenGive][msg.sender] = safeAdd(tokens[tokenGive][msg.sender], safeMul(amountGive, amount) / amountGet);
    }
    
    function testTrade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount, address sender) constant returns(bool) {
        if (!(
            tokens[tokenGet][sender] >= amount &&
            availableVolume(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, user, v, r, s) >= amount
        )) return false;
        return true;
    }
    
    function availableVolume(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) constant returns(uint) {
        bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        if (!(
            (orders[user][hash] || ecrecover(sha3("\x19Ethereum Signed Message:\n32", hash), v, r, s) == user) &&
            block.number <= expires
        )) return 0;
        
        uint available1 = safeSub(amountGet, orderFills[user][hash]);
        uint available2 = safeMul(tokens[tokenGive][user], amountGet) / amountGive;
        if (available1 < available2) return available1;
        return available2;
    }
    
    function amountFilled(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) constant returns(uint) {
        bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        return orderFills[user][hash];
    }
    
    function cancelOrder(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, uint8 v, bytes32 r, bytes32 s) {
        bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        if (!(orders[msg.sender][hash] || ecrecover(sha3("\x19Ethereum Signed Message:\n32", hash), v, r, s) == msg.sender)) throw;
        orderFills[msg.sender][hash] = amountGet;
        Cancel(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender, v, r, s);
    }
}
```