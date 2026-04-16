```solidity
pragma solidity ^0.4.23;

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

contract Ownable {
    address public owner;
    address public newOwner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

interface Token {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Exchange is SafeMath, Ownable {
    string public name;
    string public symbol;
    uint8 public decimals;
    
    address public feeAccount;
    mapping(address => bool) public authorized;
    mapping(bytes32 => uint256) public orderFills;
    mapping(bytes32 => bool) public withdrawn;
    mapping(bytes32 => bool) public traded;
    
    mapping(address => mapping(address => uint256)) public tokens;
    
    event Cancel(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s);
    event Trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address get, address give);
    event Deposit(address token, address user, uint amount, uint balance);
    event Withdraw(address token, address user, uint amount, uint balance);
    
    constructor() public {
        feeAccount = msg.sender;
    }
    
    function() public {
        revert();
    }
    
    function setAuthorized(address target, bool isAuthorized) public onlyOwner {
        authorized[target] = isAuthorized;
    }
    
    modifier onlyAuthorized() {
        require(msg.sender == owner || authorized[msg.sender]);
        _;
    }
    
    function setFeeAccount(address _feeAccount) public onlyOwner {
        feeAccount = _feeAccount;
    }
    
    function deposit() payable public {
        tokens[address(0)][msg.sender] = safeAdd(tokens[address(0)][msg.sender], msg.value);
        emit Deposit(address(0), msg.sender, msg.value, tokens[address(0)][msg.sender]);
    }
    
    function depositToken(address token, uint amount) public {
        require(token != address(0));
        assert(Token(token).transferFrom(msg.sender, this, amount));
        tokens[token][msg.sender] = safeAdd(tokens[token][msg.sender], amount);
        emit Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
    }
    
    function withdraw(address token, uint amount, address user, uint nonce, uint8 v, bytes32 r, bytes32 s, uint feeWithdrawal) public onlyAuthorized {
        bytes32 hash = sha256(this, token, amount, user, nonce);
        require(!withdrawn[hash]);
        withdrawn[hash] = true;
        
        require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == user);
        
        if (feeWithdrawal > 50 finney) {
            feeWithdrawal = 50 finney;
        }
        
        tokens[token][user] = safeSub(tokens[token][user], amount);
        tokens[token][feeAccount] = safeAdd(tokens[token][feeAccount], safeMul(feeWithdrawal, amount) / 1 ether);
        amount = safeMul((1 ether - feeWithdrawal), amount) / 1 ether;
        
        if (token == address(0)) {
            assert(user.send(amount));
        } else {
            assert(Token(token).transfer(user, amount));
        }
        
        emit Withdraw(token, user, amount, tokens[token][user]);
    }
    
    function balanceOf(address token, address user) public view returns (uint) {
        return tokens[token][user];
    }
    
    function trade(uint[8] tradeValues, address[4] tradeAddresses, uint8[2] v, bytes32[4] rs) public onlyAuthorized {
        bytes32 orderHash = sha256(this, tradeAddresses[0], tradeValues[0], tradeAddresses[1], tradeValues[1], tradeValues[2], tradeValues[3], tradeAddresses[2]);
        require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", orderHash), v[0], rs[0], rs[1]) == tradeAddresses[2]);
        
        bytes32 tradeHash = sha256(orderHash, tradeValues[4], tradeAddresses[3]);
        require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", tradeHash), v[1], rs[2], rs[3]) == tradeAddresses[3]);
        
        require(!traded[tradeHash]);
        traded[tradeHash] = true;
        
        require(orderFills[orderHash] + tradeValues[4] <= tradeValues[0]);
        require(tokens[tradeAddresses[0]][tradeAddresses[3]] >= tradeValues[4]);
        require(tokens[tradeAddresses[1]][tradeAddresses[2]] >= safeMul(tradeValues[1], tradeValues[4]) / tradeValues[0]);
        
        tokens[tradeAddresses[0]][tradeAddresses[3]] = safeSub(tokens[tradeAddresses[0]][tradeAddresses[3]], tradeValues[4]);
        tokens[tradeAddresses[0]][tradeAddresses[2]] = safeAdd(tokens[tradeAddresses[0]][tradeAddresses[2]], safeMul(tradeValues[4], ((1 ether) - tradeValues[6])) / (1 ether));
        tokens[tradeAddresses[0]][feeAccount] = safeAdd(tokens[tradeAddresses[0]][feeAccount], safeMul(tradeValues[4], tradeValues[6]) / (1 ether));
        
        tokens[tradeAddresses[1]][tradeAddresses[2]] = safeSub(tokens[tradeAddresses[1]][tradeAddresses[2]], safeMul(tradeValues[1], tradeValues[4]) / tradeValues[0]);
        tokens[tradeAddresses[1]][tradeAddresses[3]] = safeAdd(tokens[tradeAddresses[1]][tradeAddresses[3]], safeMul(safeMul((1 ether) - tradeValues[7], tradeValues[1]), tradeValues[4]) / tradeValues[0] / (1 ether));
        tokens[tradeAddresses[1]][feeAccount] = safeAdd(tokens[tradeAddresses[1]][feeAccount], safeMul(safeMul(tradeValues[7], tradeValues[1]), tradeValues[4]) / tradeValues[0] / (1 ether));
        
        orderFills[orderHash] = safeAdd(orderFills[orderHash], tradeValues[4]);
    }
    
    function cancelOrder(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, uint8 v, bytes32 r, bytes32 s, address user) public onlyAuthorized {
        bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender, user);
        assert(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == user);
        orderFills[hash] = amountGet;
        emit Cancel(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, user, v, r, s);
    }
}
```