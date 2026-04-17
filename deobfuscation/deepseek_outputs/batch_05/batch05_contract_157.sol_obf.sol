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
    function transfer(address to, uint256 value) returns (bool success) {}
    function transferFrom(address from, address to, uint256 value) returns (bool success) {}
}

contract Exchange is SafeMath {
    address public owner;
    bool public tradeState;
    string public message;
    
    mapping(address => mapping(address => uint)) public balances;
    mapping(address => mapping(bytes32 => bool)) public orderConfirmed;
    mapping(address => mapping(bytes32 => uint)) public orderFilled;
    
    event Order(
        address tokenGet,
        uint amountGet,
        address tokenGive,
        uint amountGive,
        uint expires,
        uint nonce,
        address user,
        bytes32 orderHash
    );
    
    event Cancel(
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
        bytes32 orderHash,
        string details
    );
    
    event Trade(
        address tokenGet,
        uint amountGet,
        address tokenGive,
        uint amountGive,
        address get,
        address give,
        bytes32 orderHash,
        string details
    );
    
    event Deposit(
        address token,
        address user,
        uint amount,
        uint balance
    );
    
    event Withdraw(
        address token,
        address user,
        uint amount,
        uint balance
    );
    
    function Exchange() {
        owner = msg.sender;
        tradeState = true;
    }
    
    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }
    
    modifier isOpen {
        if (!tradeState) throw;
        _;
    }
    
    function isOwner() constant returns (bool) {
        return true;
    }
    
    function changeOwner(address newOwner) onlyOwner {
        owner = newOwner;
    }
    
    function setMessage(string newMessage) onlyOwner {
        message = newMessage;
    }
    
    function changeTradeState(bool newState) onlyOwner {
        tradeState = newState;
    }
    
    function depositEther() payable {
        balances[0][msg.sender] = safeAdd(balances[0][msg.sender], msg.value);
        Deposit(0, msg.sender, msg.value, balances[0][msg.sender]);
    }
    
    function withdrawEther(uint amount) {
        if (balances[0][msg.sender] < amount) throw;
        balances[0][msg.sender] = safeSub(balances[0][msg.sender], amount);
        if (!msg.sender.call.value(amount)()) throw;
        Withdraw(0x0000000000000000000000000000000000000000, msg.sender, amount, balances[0][msg.sender]);
    }
    
    function depositToken(address token, uint amount) {
        if (token == 0) throw;
        if (!ERC20(token).transferFrom(msg.sender, this, amount)) throw;
        balances[token][msg.sender] = safeAdd(balances[token][msg.sender], amount);
        Deposit(token, msg.sender, amount, balances[token][msg.sender]);
    }
    
    function withdrawToken(address token, uint amount) {
        if (token == 0) throw;
        if (balances[token][msg.sender] < amount) throw;
        balances[token][msg.sender] = safeSub(balances[token][msg.sender], amount);
        if (!ERC20(token).transfer(msg.sender, amount)) throw;
        Withdraw(token, msg.sender, amount, balances[token][msg.sender]);
    }
    
    function balanceOf(address token, address user) constant returns (uint) {
        return balances[token][user];
    }
    
    function order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce) {
        bytes32 orderHash = sha3(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        orderConfirmed[msg.sender][orderHash] = true;
        Order(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender, orderHash);
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
        uint amount,
        string details
    ) {
        bytes32 orderHash = sha3(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        
        if (!(
            (orderConfirmed[user][orderHash] || 
             ecrecover(sha3("\x19Ethereum Signed Message:\n32", orderHash), v, r, s) == user) &&
            block.number <= expires &&
            safeAdd(orderFilled[user][orderHash], amount) <= amountGet
        )) throw;
        
        tradeBalances(tokenGet, amountGet, tokenGive, amountGive, user, amount);
        orderFilled[user][orderHash] = safeAdd(orderFilled[user][orderHash], amount);
        
        Trade(
            tokenGet,
            amount,
            tokenGive,
            amountGive * amount / amountGet,
            user,
            msg.sender,
            orderHash,
            details
        );
    }
    
    function tradeBalances(
        address tokenGet,
        uint amountGet,
        address tokenGive,
        uint amountGive,
        address user,
        uint amount
    ) private {
        balances[tokenGet][msg.sender] = safeSub(balances[tokenGet][msg.sender], amount);
        balances[tokenGet][user] = safeAdd(balances[tokenGet][user], amount);
        
        balances[tokenGive][user] = safeSub(
            balances[tokenGive][user],
            safeMul(amountGive, amount) / amountGet
        );
        
        balances[tokenGive][msg.sender] = safeAdd(
            balances[tokenGive][msg.sender],
            safeMul(amountGive, amount) / amountGet
        );
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
        bytes32 s,
        string details
    ) {
        bytes32 orderHash = sha3(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        
        if (!(orderConfirmed[msg.sender][orderHash] || 
              ecrecover(sha3("\x19Ethereum Signed Message:\n32", orderHash), v, r, s) == msg.sender)) throw;
        
        orderFilled[msg.sender][orderHash] = amountGet;
        
        Cancel(
            tokenGet,
            amountGet,
            tokenGive,
            amountGive,
            expires,
            nonce,
            msg.sender,
            v,
            r,
            s,
            orderHash,
            details
        );
    }
}
```