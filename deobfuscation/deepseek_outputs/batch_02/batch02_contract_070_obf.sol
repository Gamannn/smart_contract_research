```solidity
pragma solidity ^0.4.22;

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
    function balanceOf(address owner) constant returns (uint256) {}
    function transfer(address to, uint256 value) returns (bool) {}
    function transferFrom(address from, address to, uint256 value) returns (bool) {}
    function approve(address spender, uint256 value) returns (bool) {}
    function allowance(address owner, address spender) constant returns (uint256) {}
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    uint public decimals;
    string public name;
    string public symbol;
}

contract Exchange is SafeMath {
    mapping (address => uint) public depositFeeRate;
    mapping (address => uint) public withdrawalFeeRate;
    mapping (address => mapping (address => uint)) public tokens;
    mapping (address => mapping (bytes32 => bool)) public orders;
    mapping (address => mapping (bytes32 => uint)) public orderFills;
    mapping (address => bool) public tokenActive;
    mapping (address => uint) public tokenMinAmount;
    mapping (address => uint) public tokenMaxAmount;
    mapping (address => uint) public makerFee;
    mapping (address => uint) public takerFee;
    
    address public admin;
    address public feeAccount;
    
    event Order(address tokenBuy, uint amountBuy, address tokenSell, uint amountSell, uint expires, uint nonce, address user);
    event Cancel(address tokenBuy, uint amountBuy, address tokenSell, uint amountSell, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s);
    event Trade(address tokenBuy, uint amount, address tokenSell, uint amountSell, address maker, address taker);
    event Deposit(address token, address user, uint amount, uint balance);
    event Withdraw(address token, address user, uint amount, uint balance);
    event ActivateToken(address token, string symbol);
    event DeactivateToken(address token, string symbol);
    
    function Exchange(address admin_, address feeAccount_) {
        admin = admin_;
        feeAccount = feeAccount_;
    }
    
    function() {
        throw;
    }
    
    function activateToken(address token) {
        if (msg.sender != admin) throw;
        tokenActive[token] = true;
        ActivateToken(token, ERC20(token).symbol());
    }
    
    function deactivateToken(address token) {
        if (msg.sender != admin) throw;
        tokenActive[token] = false;
        DeactivateToken(token, ERC20(token).symbol());
    }
    
    function tokenIsActive(address token) constant returns(bool) {
        if (token == 0) return true;
        return tokenActive[token];
    }
    
    function setTokenMinAmount(address token, uint minAmount) {
        if (msg.sender != admin) throw;
        tokenMinAmount[token] = minAmount;
    }
    
    function setTokenMaxAmount(address token, uint maxAmount) {
        if (msg.sender != admin) throw;
        tokenMaxAmount[token] = maxAmount;
    }
    
    function setMakerFee(address token, uint fee) {
        if (msg.sender != admin) throw;
        makerFee[token] = fee;
    }
    
    function setTakerFee(address token, uint fee) {
        if (msg.sender != admin) throw;
        takerFee[token] = fee;
    }
    
    function setDepositFeeRate(address token, uint rate) {
        if (msg.sender != admin) throw;
        depositFeeRate[token] = rate;
    }
    
    function setWithdrawalFeeRate(address token, uint rate) {
        if (msg.sender != admin) throw;
        withdrawalFeeRate[token] = rate;
    }
    
    function changeAdmin(address admin_) {
        if (msg.sender != admin) throw;
        admin = admin_;
    }
    
    function changeFeeAccount(address feeAccount_) {
        if (msg.sender != admin) throw;
        feeAccount = feeAccount_;
    }
    
    function deposit() payable {
        uint fee = safeMul(msg.value, depositFeeRate[0]) / (1 ether);
        uint depositAmount = safeSub(msg.value, fee);
        tokens[0][msg.sender] = safeAdd(tokens[0][msg.sender], depositAmount);
        tokens[0][feeAccount] = safeAdd(tokens[0][feeAccount], fee);
        Deposit(0, msg.sender, msg.value, tokens[0][msg.sender]);
    }
    
    function withdraw(uint amount) {
        if (tokens[0][msg.sender] < amount) throw;
        uint fee = safeMul(amount, withdrawalFeeRate[0]) / (1 ether);
        uint withdrawalAmount = safeSub(amount, fee);
        tokens[0][msg.sender] = safeSub(tokens[0][msg.sender], amount);
        tokens[0][feeAccount] = safeAdd(tokens[0][feeAccount], fee);
        if (!msg.sender.call.value(withdrawalAmount)()) throw;
        Withdraw(0, msg.sender, amount, tokens[0][msg.sender]);
    }
    
    function depositToken(address token, uint amount) {
        if (token == 0) throw;
        if (!tokenIsActive(token)) throw;
        if (!ERC20(token).transferFrom(msg.sender, this, amount)) throw;
        uint fee = safeMul(amount, depositFeeRate[token]) / (1 ether);
        uint depositAmount = safeSub(amount, fee);
        tokens[token][msg.sender] = safeAdd(tokens[token][msg.sender], depositAmount);
        tokens[token][feeAccount] = safeAdd(tokens[token][feeAccount], fee);
        Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
    }
    
    function withdrawToken(address token, uint amount) {
        if (token == 0) throw;
        if (tokens[token][msg.sender] < amount) throw;
        uint fee = safeMul(amount, withdrawalFeeRate[token]) / (1 ether);
        uint withdrawalAmount = safeSub(amount, fee);
        tokens[token][msg.sender] = safeSub(tokens[token][msg.sender], amount);
        tokens[token][feeAccount] = safeAdd(tokens[token][feeAccount], fee);
        if (!ERC20(token).transfer(msg.sender, withdrawalAmount)) throw;
        Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
    }
    
    function balanceOf(address token, address user) constant returns (uint) {
        return tokens[token][user];
    }
    
    function order(address tokenBuy, uint amountBuy, address tokenSell, uint amountSell, uint expires, uint nonce) {
        if (!tokenIsActive(tokenBuy) || !tokenIsActive(tokenSell)) throw;
        if (amountBuy < tokenMinAmount[tokenBuy]) throw;
        if (amountSell < tokenMinAmount[tokenSell]) throw;
        bytes32 hash = sha256(this, tokenBuy, amountBuy, tokenSell, amountSell, expires, nonce);
        orders[msg.sender][hash] = true;
        Order(tokenBuy, amountBuy, tokenSell, amountSell, expires, nonce, msg.sender);
    }
    
    function trade(address tokenBuy, uint amountBuy, address tokenSell, uint amountSell, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount) {
        if (!tokenIsActive(tokenBuy) || !tokenIsActive(tokenSell)) throw;
        bytes32 hash = sha256(this, tokenBuy, amountBuy, tokenSell, amountSell, expires, nonce);
        if (!(
            (orders[user][hash] || ecrecover(sha3("\x19Ethereum Signed Message:\n32", hash), v, r, s) == user) &&
            block.number <= expires &&
            safeAdd(orderFills[user][hash], amount) <= amountBuy
        )) throw;
        tradeBalances(tokenBuy, amountBuy, tokenSell, amountSell, user, amount);
        orderFills[user][hash] = safeAdd(orderFills[user][hash], amount);
        Trade(tokenBuy, amount, tokenSell, amountSell * amount / amountBuy, user, msg.sender);
    }
    
    function tradeBalances(address tokenBuy, uint amountBuy, address tokenSell, uint amountSell, address user, uint amount) private {
        uint makerFeeAmount = safeMul(amount, makerFee[tokenBuy]) / (1 ether);
        uint takerFeeAmount = safeMul(amount, takerFee[tokenBuy]) / (1 ether);
        tokens[tokenBuy][msg.sender] = safeSub(tokens[tokenBuy][msg.sender], safeAdd(amount, takerFeeAmount));
        tokens[tokenBuy][user] = safeAdd(tokens[tokenBuy][user], safeSub(amount, makerFeeAmount));
        tokens[tokenBuy][feeAccount] = safeAdd(tokens[tokenBuy][feeAccount], safeAdd(makerFeeAmount, takerFeeAmount));
        tokens[tokenSell][user] = safeSub(tokens[tokenSell][user], safeMul(amountSell, amount) / amountBuy);
        tokens[tokenSell][msg.sender] = safeAdd(tokens[tokenSell][msg.sender], safeMul(amountSell, amount) / amountBuy);
    }
    
    function testTrade(address tokenBuy, uint amountBuy, address tokenSell, uint amountSell, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount, address sender) constant returns(bool) {
        if (!tokenIsActive(tokenBuy) || !tokenIsActive(tokenSell)) return false;
        if (!(
            tokens[tokenBuy][sender] >= amount &&
            availableVolume(tokenBuy, amountBuy, tokenSell, amountSell, expires, nonce, user, v, r, s) >= amount
        )) return false;
        return true;
    }
    
    function availableVolume(address tokenBuy, uint amountBuy, address tokenSell, uint amountSell, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) constant returns(uint) {
        bytes32 hash = sha256(this, tokenBuy, amountBuy, tokenSell, amountSell, expires, nonce);
        if (!(
            (orders[user][hash] || ecrecover(sha3("\x19Ethereum Signed Message:\n32", hash), v, r, s) == user) &&
            block.number <= expires
        )) return 0;
        uint available1 = safeSub(amountBuy, orderFills[user][hash]);
        uint available2 = safeMul(tokens[tokenSell][user], amountBuy) / amountSell;
        if (available1 < available2) return available1;
        return available2;
    }
    
    function amountFilled(address tokenBuy, uint amountBuy, address tokenSell, uint amountSell, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) constant returns(uint) {
        bytes32 hash = sha256(this, tokenBuy, amountBuy, tokenSell, amountSell, expires, nonce);
        return orderFills[user][hash];
    }
    
    function cancelOrder(address tokenBuy, uint amountBuy, address tokenSell, uint amountSell, uint expires, uint nonce, uint8 v, bytes32 r, bytes32 s) {
        bytes32 hash = sha256(this, tokenBuy, amountBuy, tokenSell, amountSell, expires, nonce);
        if (!(orders[msg.sender][hash] || ecrecover(sha3("\x19Ethereum Signed Message:\n32", hash), v, r, s) == msg.sender)) throw;
        orderFills[msg.sender][hash] = amountBuy;
        Cancel(tokenBuy, amountBuy, tokenSell, amountSell, expires, nonce, msg.sender, v, r, s);
    }
}
```