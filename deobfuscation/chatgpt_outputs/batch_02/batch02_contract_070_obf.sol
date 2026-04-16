```solidity
pragma solidity ^0.4.22;

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

contract Trade is SafeMath {
    address public admin;
    address public feeAccount;
    mapping (address => uint) public balances;
    mapping (address => uint) public tokenBalances;
    mapping (address => mapping (address => uint)) public allowed;
    mapping (address => mapping (bytes32 => bool)) public orders;
    mapping (address => mapping (bytes32 => uint)) public orderFills;
    mapping (address => bool) public activeTokens;
    mapping (address => uint) public minOrderSize;
    mapping (address => uint) public maxOrderSize;

    event Order(address indexed user, uint amount, address token, uint price, uint expires, uint nonce, address feeAccount);
    event Cancel(address indexed user, uint amount, address token, uint price, uint expires, uint nonce, address feeAccount, uint8 v, bytes32 r, bytes32 s);
    event Trade(address indexed user, uint amount, address token, uint price, address buyer, address seller);
    event Deposit(address indexed user, address token, uint amount, uint balance);
    event Withdraw(address indexed user, address token, uint amount, uint balance);
    event ActivateToken(address indexed token, string name);
    event DeactivateToken(address indexed token, string name);

    function Trade(address admin_, address feeAccount_) public {
        admin = admin_;
        feeAccount = feeAccount_;
    }

    function() public {
        revert();
    }

    function activateToken(address token) public {
        require(msg.sender == admin);
        activeTokens[token] = true;
        ActivateToken(token, ERC20(token).name());
    }

    function deactivateToken(address token) public {
        require(msg.sender == admin);
        activeTokens[token] = false;
        DeactivateToken(token, ERC20(token).name());
    }

    function isActiveToken(address token) public view returns(bool) {
        if (token == address(0)) return true;
        return activeTokens[token];
    }

    function setMinOrderSize(address token, uint size) public {
        require(msg.sender == admin);
        minOrderSize[token] = size;
    }

    function setMaxOrderSize(address token, uint size) public {
        require(msg.sender == admin);
        maxOrderSize[token] = size;
    }

    function deposit() public payable {
        uint fee = safeMul(msg.value, balances[0]) / (1 ether);
        uint depositAmount = safeSub(msg.value, fee);
        allowed[0][msg.sender] = safeAdd(allowed[0][msg.sender], depositAmount);
        allowed[0][feeAccount] = safeAdd(allowed[0][feeAccount], fee);
        Deposit(0, msg.sender, msg.value, allowed[0][msg.sender]);
    }

    function withdraw(uint amount) public {
        require(allowed[0][msg.sender] >= amount);
        uint fee = safeMul(amount, tokenBalances[0]) / (1 ether);
        uint withdrawAmount = safeSub(amount, fee);
        allowed[0][msg.sender] = safeSub(allowed[0][msg.sender], amount);
        allowed[0][feeAccount] = safeAdd(allowed[0][feeAccount], fee);
        require(msg.sender.call.value(withdrawAmount)());
        Withdraw(0, msg.sender, amount, allowed[0][msg.sender]);
    }

    function depositToken(address token, uint amount) public {
        require(token != address(0));
        require(isActiveToken(token));
        require(ERC20(token).transferFrom(msg.sender, this, amount));
        uint fee = safeMul(amount, balances[token]) / (1 ether);
        uint depositAmount = safeSub(amount, fee);
        allowed[token][msg.sender] = safeAdd(allowed[token][msg.sender], depositAmount);
        allowed[token][feeAccount] = safeAdd(allowed[token][feeAccount], fee);
        Deposit(token, msg.sender, amount, allowed[token][msg.sender]);
    }

    function withdrawToken(address token, uint amount) public {
        require(token != address(0));
        require(allowed[token][msg.sender] >= amount);
        uint fee = safeMul(amount, tokenBalances[token]) / (1 ether);
        uint withdrawAmount = safeSub(amount, fee);
        allowed[token][msg.sender] = safeSub(allowed[token][msg.sender], amount);
        allowed[token][feeAccount] = safeAdd(allowed[token][feeAccount], fee);
        require(ERC20(token).transfer(msg.sender, withdrawAmount));
        Withdraw(token, msg.sender, amount, allowed[token][msg.sender]);
    }

    function balanceOf(address user, address token) public view returns (uint) {
        return allowed[user][token];
    }

    function placeOrder(address user, uint amount, address token, uint price, uint expires, uint nonce) public {
        require(isActiveToken(user) && isActiveToken(token));
        require(amount >= minOrderSize[user] && amount <= maxOrderSize[token]);
        bytes32 hash = sha256(this, user, amount, token, price, expires, nonce);
        orders[msg.sender][hash] = true;
        Order(user, amount, token, price, expires, nonce, msg.sender);
    }

    function cancelOrder(address user, uint amount, address token, uint price, uint expires, uint nonce, address feeAccount, uint8 v, bytes32 r, bytes32 s, uint cancelAmount) public {
        require(isActiveToken(user) && isActiveToken(token));
        bytes32 hash = sha256(this, user, amount, token, price, expires, nonce);
        require((orders[feeAccount][hash] || ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == feeAccount) && block.number <= expires && safeAdd(orderFills[feeAccount][hash], cancelAmount) <= amount);
        executeTrade(user, amount, token, price, feeAccount, cancelAmount);
        orderFills[feeAccount][hash] = safeAdd(orderFills[feeAccount][hash], cancelAmount);
        Trade(user, cancelAmount, token, safeMul(price, cancelAmount) / amount, feeAccount, msg.sender);
    }

    function executeTrade(address user, uint amount, address token, uint price, address feeAccount, uint tradeAmount) private {
        uint fee = safeMul(tradeAmount, tokenBalances[user]) / (1 ether);
        uint fee2 = safeMul(tradeAmount, balances[user]) / (1 ether);
        allowed[user][msg.sender] = safeSub(allowed[user][msg.sender], safeAdd(tradeAmount, fee2));
        allowed[user][feeAccount] = safeAdd(allowed[user][feeAccount], fee);
        allowed[user][feeAccount] = safeAdd(allowed[user][feeAccount], safeAdd(fee, fee2));
        allowed[token][feeAccount] = safeSub(allowed[token][feeAccount], safeMul(price, tradeAmount) / amount);
        allowed[token][msg.sender] = safeAdd(allowed[token][msg.sender], safeMul(price, tradeAmount) / amount);
    }

    function availableVolume(address user, uint amount, address token, uint price, uint expires, uint nonce, address feeAccount, uint8 v, bytes32 r, bytes32 s) public view returns(uint) {
        bytes32 hash = sha256(this, user, amount, token, price, expires, nonce);
        if (!(orders[feeAccount][hash] || ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == feeAccount) && block.number <= expires) return 0;
        uint available1 = safeSub(amount, orderFills[feeAccount][hash]);
        uint available2 = safeMul(allowed[token][feeAccount], amount) / price;
        if (available1 < available2) return available1;
        return available2;
    }

    function amountFilled(address user, uint amount, address token, uint price, uint expires, uint nonce, address feeAccount, uint8 v, bytes32 r, bytes32 s) public view returns(uint) {
        bytes32 hash = sha256(this, user, amount, token, price, expires, nonce);
        return orderFills[feeAccount][hash];
    }

    function cancelOrder(address user, uint amount, address token, uint price, uint expires, uint nonce, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 hash = sha256(this, user, amount, token, price, expires, nonce);
        require((orders[msg.sender][hash] || ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == msg.sender));
        orderFills[msg.sender][hash] = amount;
        Cancel(user, amount, token, price, expires, nonce, msg.sender, v, r, s);
    }
}
```