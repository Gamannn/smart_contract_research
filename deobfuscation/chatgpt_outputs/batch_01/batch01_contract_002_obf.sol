```solidity
pragma solidity ^0.4.16;

contract Token {
    bytes32 public standard;
    bytes32 public name;
    bytes32 public symbol;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    function transfer(address _to, uint256 _value) returns (bool success);
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
}

contract Exchange {
    struct ExchangeData {
        uint256 inactivityReleasePeriod;
        address feeAccount;
        address owner;
    }

    ExchangeData public exchangeData;

    mapping (address => uint256) public invalidOrder;
    mapping (address => mapping (address => uint256)) public tokens;
    mapping (address => bool) public admins;
    mapping (address => uint256) public lastActiveTransaction;
    mapping (bytes32 => uint256) public orderFills;
    mapping (bytes32 => bool) public traded;
    mapping (bytes32 => bool) public withdrawn;

    event SetOwner(address indexed previousOwner, address indexed newOwner);
    event Order(address tokenBuy, uint256 amountBuy, address tokenSell, uint256 amountSell, uint256 expires, uint256 nonce, address user, uint8 v, bytes32 r, bytes32 s);
    event Cancel(address tokenBuy, uint256 amountBuy, address tokenSell, uint256 amountSell, uint256 expires, uint256 nonce, address user, uint8 v, bytes32 r, bytes32 s);
    event Trade(address tokenBuy, uint256 amountBuy, address tokenSell, uint256 amountSell, address get, address give);
    event Deposit(address token, address user, uint256 amount, uint256 balance);
    event Withdraw(address token, address user, uint256 amount, uint256 balance);

    modifier onlyOwner {
        require(msg.sender == exchangeData.owner);
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == exchangeData.owner || admins[msg.sender]);
        _;
    }

    function Exchange(address feeAccount_) {
        exchangeData.owner = msg.sender;
        exchangeData.feeAccount = feeAccount_;
        exchangeData.inactivityReleasePeriod = 100000;
    }

    function assert(bool assertion) internal {
        if (!assertion) throw;
    }

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

    function setOwner(address newOwner) onlyOwner {
        SetOwner(exchangeData.owner, newOwner);
        exchangeData.owner = newOwner;
    }

    function getOwner() returns (address out) {
        return exchangeData.owner;
    }

    function invalidateOrdersBefore(address user, uint256 nonce) onlyAdmin {
        require(nonce >= invalidOrder[user]);
        invalidOrder[user] = nonce;
    }

    function setInactivityReleasePeriod(uint256 expiry) onlyAdmin returns (bool success) {
        require(expiry <= 1000000);
        exchangeData.inactivityReleasePeriod = expiry;
        return true;
    }

    function setAdmin(address admin, bool isAdmin) onlyOwner {
        admins[admin] = isAdmin;
    }

    function() external {
        throw;
    }

    function depositToken(address token, uint256 amount) {
        tokens[token][msg.sender] = safeAdd(tokens[token][msg.sender], amount);
        lastActiveTransaction[msg.sender] = block.number;
        require(Token(token).transferFrom(msg.sender, this, amount));
        Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
    }

    function depositEther() payable {
        tokens[address(0)][msg.sender] = safeAdd(tokens[address(0)][msg.sender], msg.value);
        lastActiveTransaction[msg.sender] = block.number;
        Deposit(address(0), msg.sender, msg.value, tokens[address(0)][msg.sender]);
    }

    function withdraw(address token, uint256 amount) returns (bool success) {
        require(safeSub(block.number, lastActiveTransaction[msg.sender]) >= exchangeData.inactivityReleasePeriod);
        require(tokens[token][msg.sender] >= amount);
        tokens[token][msg.sender] = safeSub(tokens[token][msg.sender], amount);
        if (token == address(0)) {
            require(msg.sender.send(amount));
        } else {
            require(Token(token).transfer(msg.sender, amount));
        }
        Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
    }

    function adminWithdraw(address token, uint256 amount, address user, uint256 nonce, uint8 v, bytes32 r, bytes32 s, uint256 feeWithdrawal) onlyAdmin returns (bool success) {
        bytes32 hash = keccak256(this, token, amount, user, nonce);
        require(!withdrawn[hash]);
        withdrawn[hash] = true;
        require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == user);
        if (feeWithdrawal > 50 finney) feeWithdrawal = 50 finney;
        require(tokens[token][user] >= amount);
        tokens[token][user] = safeSub(tokens[token][user], amount);
        tokens[token][exchangeData.feeAccount] = safeAdd(tokens[token][exchangeData.feeAccount], safeMul(feeWithdrawal, amount) / 1 ether);
        amount = safeMul((1 ether - feeWithdrawal), amount) / 1 ether;
        if (token == address(0)) {
            require(user.send(amount));
        } else {
            require(Token(token).transfer(user, amount));
        }
        lastActiveTransaction[user] = block.number;
        Withdraw(token, user, amount, tokens[token][user]);
    }

    function balanceOf(address token, address user) constant returns (uint256) {
        return tokens[token][user];
    }

    function trade(uint256[8] tradeValues, address[4] tradeAddresses, uint8[2] v, bytes32[4] rs) onlyAdmin returns (bool success) {
        require(invalidOrder[tradeAddresses[2]] <= tradeValues[3]);
        bytes32 orderHash = keccak256(this, tradeAddresses[0], tradeValues[0], tradeAddresses[1], tradeValues[1], tradeValues[2], tradeValues[3], tradeAddresses[2]);
        require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", orderHash), v[0], rs[0], rs[1]) == tradeAddresses[2]);
        bytes32 tradeHash = keccak256(orderHash, tradeValues[4], tradeAddresses[3], tradeValues[5]);
        require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", tradeHash), v[1], rs[2], rs[3]) == tradeAddresses[3]);
        require(!traded[tradeHash]);
        traded[tradeHash] = true;
        if (tradeValues[6] > 100 finney) tradeValues[6] = 100 finney;
        if (tradeValues[7] > 100 finney) tradeValues[7] = 100 finney;
        require(safeAdd(orderFills[orderHash], tradeValues[4]) <= tradeValues[0]);
        require(tokens[tradeAddresses[0]][tradeAddresses[3]] >= tradeValues[4]);
        require(tokens[tradeAddresses[1]][tradeAddresses[2]] >= (safeMul(tradeValues[1], tradeValues[4]) / tradeValues[0]));
        tokens[tradeAddresses[0]][tradeAddresses[3]] = safeSub(tokens[tradeAddresses[0]][tradeAddresses[3]], tradeValues[4]);
        tokens[tradeAddresses[0]][tradeAddresses[2]] = safeAdd(tokens[tradeAddresses[0]][tradeAddresses[2]], safeMul(tradeValues[4], ((1 ether) - tradeValues[6])) / (1 ether));
        tokens[tradeAddresses[0]][exchangeData.feeAccount] = safeAdd(tokens[tradeAddresses[0]][exchangeData.feeAccount], safeMul(tradeValues[4], tradeValues[6]) / (1 ether));
        tokens[tradeAddresses[1]][tradeAddresses[2]] = safeSub(tokens[tradeAddresses[1]][tradeAddresses[2]], safeMul(tradeValues[1], tradeValues[4]) / tradeValues[0]);
        tokens[tradeAddresses[1]][tradeAddresses[3]] = safeAdd(tokens[tradeAddresses[1]][tradeAddresses[3]], safeMul(safeMul(((1 ether) - tradeValues[7]), tradeValues[1]), tradeValues[4]) / tradeValues[0] / (1 ether));
        tokens[tradeAddresses[1]][exchangeData.feeAccount] = safeAdd(tokens[tradeAddresses[1]][exchangeData.feeAccount], safeMul(safeMul(tradeValues[7], tradeValues[1]), tradeValues[4]) / tradeValues[0] / (1 ether));
        orderFills[orderHash] = safeAdd(orderFills[orderHash], tradeValues[4]);
        lastActiveTransaction[tradeAddresses[2]] = block.number;
        lastActiveTransaction[tradeAddresses[3]] = block.number;
    }
}
```