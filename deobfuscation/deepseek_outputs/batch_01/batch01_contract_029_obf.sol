```solidity
pragma solidity ^0.4.11;

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
    
    function assert(bool assertion) internal {
        if (!assertion) throw;
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
    
    string public symbol;
}

contract StandardToken is Token {
    function transfer(address to, uint256 value) returns (bool success) {
        if (balances[msg.sender] >= value && balances[to] + value > balances[to]) {
            balances[msg.sender] -= value;
            balances[to] += value;
            Transfer(msg.sender, to, value);
            return true;
        } else {
            return false;
        }
    }
    
    function transferFrom(address from, address to, uint256 value) returns (bool success) {
        if (balances[from] >= value && allowed[from][msg.sender] >= value && balances[to] + value > balances[to]) {
            balances[to] += value;
            balances[from] -= value;
            allowed[from][msg.sender] -= value;
            Transfer(from, to, value);
            return true;
        } else {
            return false;
        }
    }
    
    function balanceOf(address owner) constant returns (uint256 balance) {
        return balances[owner];
    }
    
    function approve(address spender, uint256 value) returns (bool success) {
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }
    
    function allowance(address owner, address spender) constant returns (uint256 remaining) {
        return allowed[owner][spender];
    }
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
}

contract ReserveToken is StandardToken, SafeMath {
    function ReserveToken() {
        exchangeState.minter = msg.sender;
    }
    
    function create(address account, uint amount) {
        if (msg.sender != exchangeState.minter) throw;
        balances[account] = safeAdd(balances[account], amount);
        exchangeState.totalSupply = safeAdd(exchangeState.totalSupply, amount);
    }
    
    function destroy(address account, uint amount) {
        if (msg.sender != exchangeState.minter) throw;
        if (balances[account] < amount) throw;
        balances[account] = safeSub(balances[account], amount);
        exchangeState.totalSupply = safeSub(exchangeState.totalSupply, amount);
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
    mapping(address => mapping(address => uint)) public tokens;
    mapping(address => mapping(bytes32 => bool)) public orders;
    mapping(address => mapping(bytes32 => uint)) public orderFills;
    
    event Order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user);
    event Cancel(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s);
    event Trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address get, address give);
    event Deposit(address token, address user, uint amount, uint balance);
    event Withdraw(address token, address user, uint amount, uint balance);
    
    function Exchange(
        address admin_,
        address feeAccount_,
        address accountLevelsAddr_,
        uint feeMake_,
        uint feeTake_,
        uint feeRebate_
    ) {
        exchangeState.admin = admin_;
        exchangeState.feeAccount = feeAccount_;
        exchangeState.accountLevelsAddr = accountLevelsAddr_;
        exchangeState.feeMake = feeMake_;
        exchangeState.feeTake = feeTake_;
        exchangeState.feeRebate = feeRebate_;
    }
    
    function() {
        throw;
    }
    
    function changeAdmin(address admin_) {
        if (msg.sender != exchangeState.admin) throw;
        exchangeState.admin = admin_;
    }
    
    function changeAccountLevelsAddr(address accountLevelsAddr_) {
        if (msg.sender != exchangeState.admin) throw;
        exchangeState.accountLevelsAddr = accountLevelsAddr_;
    }
    
    function changeFeeAccount(address feeAccount_) {
        if (msg.sender != exchangeState.admin) throw;
        exchangeState.feeAccount = feeAccount_;
    }
    
    function changeFeeMake(uint feeMake_) {
        if (msg.sender != exchangeState.admin) throw;
        if (feeMake_ > exchangeState.feeMake) throw;
        exchangeState.feeMake = feeMake_;
    }
    
    function changeFeeTake(uint feeTake_) {
        if (msg.sender != exchangeState.admin) throw;
        if (feeTake_ > exchangeState.feeTake || feeTake_ < exchangeState.feeRebate) throw;
        exchangeState.feeTake = feeTake_;
    }
    
    function changeFeeRebate(uint feeRebate_) {
        if (msg.sender != exchangeState.admin) throw;
        if (feeRebate_ < exchangeState.feeRebate || feeRebate_ > exchangeState.feeTake) throw;
        exchangeState.feeRebate = feeRebate_;
    }
    
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
        if (!Token(token).transferFrom(msg.sender, this, amount)) throw;
        tokens[token][msg.sender] = safeAdd(tokens[token][msg.sender], amount);
        Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
    }
    
    function withdrawToken(address token, uint amount) {
        if (token == 0) throw;
        if (tokens[token][msg.sender] < amount) throw;
        tokens[token][msg.sender] = safeSub(tokens[token][msg.sender], amount);
        if (!Token(token).transfer(msg.sender, amount)) throw;
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
    
    function trade(
        address tokenGet,
        uint amountGet,
        address tokenGive,
        uint amountGive,
        uint expires,
        uint nonce,
        address user,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint amount
    ) {
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
    
    function tradeBalances(
        address tokenGet,
        uint amountGet,
        address tokenGive,
        uint amountGive,
        address user,
        uint amount
    ) private {
        uint feeMakeXfer = safeMul(amount, exchangeState.feeMake) / (1 ether);
        uint feeTakeXfer = safeMul(amount, exchangeState.feeTake) / (1 ether);
        uint feeRebateXfer = 0;
        
        if (exchangeState.accountLevelsAddr != 0x0) {
            uint accountLevel = AccountLevels(exchangeState.accountLevelsAddr).accountLevel(user);
            if (accountLevel == 1) {
                feeRebateXfer = safeMul(amount, exchangeState.feeRebate) / (1 ether);
            }
            if (accountLevel == 2) {
                feeRebateXfer = feeTakeXfer;
            }
        }
        
        tokens[tokenGet][msg.sender] = safeSub(tokens[tokenGet][msg.sender], safeAdd(amount, feeTakeXfer));
        tokens[tokenGet][user] = safeAdd(tokens[tokenGet][user], safeSub(safeAdd(amount, feeRebateXfer), feeMakeXfer));
        tokens[tokenGet][exchangeState.feeAccount] = safeAdd(tokens[tokenGet][exchangeState.feeAccount], safeSub(safeAdd(feeMakeXfer, feeTakeXfer), feeRebateXfer));
        tokens[tokenGive][user] = safeSub(tokens[tokenGive][user], safeMul(amountGive, amount) / amountGet);
        tokens[tokenGive][msg.sender] = safeAdd(tokens[tokenGive][msg.sender], safeMul(amountGive, amount) / amountGet);
    }
    
    function testTrade(
        address tokenGet,
        uint amountGet,
        address tokenGive,
        uint amountGive,
        uint expires,
        uint nonce,
        address user,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint amount,
        address sender
    ) constant returns(bool) {
        if (!(
            tokens[tokenGet][sender] >= amount &&
            availableVolume(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, user, v, r, s) >= amount
        )) return false;
        return true;
    }
    
    function availableVolume(
        address tokenGet,
        uint amountGet,
        address tokenGive,
        uint amountGive,
        uint expires,
        uint nonce,
        address user,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) constant returns(uint) {
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
    
    function amountFilled(
        address tokenGet,
        uint amountGet,
        address tokenGive,
        uint amountGive,
        uint expires,
        uint nonce,
        address user,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) constant returns(uint) {
        bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        return orderFills[user][hash];
    }
    
    function cancelOrder(
        address tokenGet,
        uint amountGet,
        address tokenGive,
        uint amountGive,
        uint expires,
        uint nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) {
        bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        if (!(orders[msg.sender][hash] || ecrecover(sha3("\x19Ethereum Signed Message:\n32", hash), v, r, s) == msg.sender)) throw;
        orderFills[msg.sender][hash] = amountGet;
        Cancel(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender, v, r, s);
    }
    
    struct ExchangeState {
        uint256 feeRebate;
        uint256 feeTake;
        uint256 feeMake;
        address accountLevelsAddr;
        address feeAccount;
        address admin;
        address minter;
        uint256 totalSupply;
        uint256 dummy;
    }
    
    ExchangeState exchangeState = ExchangeState(0, 0, 0, address(0), address(0), address(0), address(0), 0, 0);
}
```