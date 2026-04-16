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

contract Token {
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
    address public feeAccount;
    mapping (address => mapping (address => uint)) public tokens;
    mapping (bytes32 => uint256) public orderFills;
    mapping (bytes32 => bool) public traded;
    mapping (bytes32 => bool) public cancelled;

    event Cancel(address indexed maker, uint amountGet, address indexed tokenGet, uint amountGive, uint expires, uint nonce, address indexed feeAccount, uint8 v, bytes32 r, bytes32 s);
    event Trade(address indexed maker, uint amountGet, address indexed tokenGet, uint amountGive, address indexed taker, address tokenGive);
    event Deposit(address indexed token, address indexed user, uint amount, uint balance);
    event Withdraw(address indexed token, address indexed user, uint amount, uint balance);

    constructor(address _feeAccount) public {
        feeAccount = _feeAccount;
    }

    function() public {
        revert();
    }

    function deposit() payable public {
        tokens[0][msg.sender] = safeAdd(tokens[0][msg.sender], msg.value);
        emit Deposit(0, msg.sender, msg.value, tokens[0][msg.sender]);
    }

    function depositToken(address token, uint amount) public {
        require(token != 0);
        assert(Token(token).transferFrom(msg.sender, this, amount));
        tokens[token][msg.sender] = safeAdd(tokens[token][msg.sender], amount);
        emit Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
    }

    function withdraw(uint amount) public {
        require(tokens[0][msg.sender] >= amount);
        tokens[0][msg.sender] = safeSub(tokens[0][msg.sender], amount);
        msg.sender.transfer(amount);
        emit Withdraw(0, msg.sender, amount, tokens[0][msg.sender]);
    }

    function withdrawToken(address token, uint amount) public {
        require(token != 0);
        require(tokens[token][msg.sender] >= amount);
        tokens[token][msg.sender] = safeSub(tokens[token][msg.sender], amount);
        assert(Token(token).transfer(msg.sender, amount));
        emit Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
    }

    function balanceOf(address token, address user) public view returns (uint) {
        return tokens[token][user];
    }

    function trade(uint[8] tradeValues, address[4] tradeAddresses, uint8[2] v, bytes32[4] rs) public onlyOwner {
        bytes32 orderHash = sha256(this, tradeAddresses[0], tradeValues[0], tradeAddresses[1], tradeValues[1], tradeValues[2], tradeValues[3], tradeAddresses[2]);
        require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", orderHash), v[0], rs[0], rs[1]) == tradeAddresses[2]);
        bytes32 tradeHash = sha256(orderHash, tradeValues[4], tradeAddresses[3]);
        require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", tradeHash), v[1], rs[2], rs[3]) == tradeAddresses[3]);
        require(!traded[tradeHash]);
        traded[tradeHash] = true;
        require(tokens[tradeAddresses[0]][tradeAddresses[3]] >= tradeValues[4]);
        require(tokens[tradeAddresses[1]][tradeAddresses[2]] >= safeMul(tradeValues[1], tradeValues[4]) / tradeValues[0]);
        tokens[tradeAddresses[0]][tradeAddresses[3]] = safeSub(tokens[tradeAddresses[0]][tradeAddresses[3]], tradeValues[4]);
        tokens[tradeAddresses[0]][tradeAddresses[2]] = safeAdd(tokens[tradeAddresses[0]][tradeAddresses[2]], safeMul(tradeValues[4], (1 ether - tradeValues[6])) / (1 ether));
        tokens[tradeAddresses[0]][feeAccount] = safeAdd(tokens[tradeAddresses[0]][feeAccount], safeMul(tradeValues[4], tradeValues[6]) / (1 ether));
        tokens[tradeAddresses[1]][tradeAddresses[2]] = safeSub(tokens[tradeAddresses[1]][tradeAddresses[2]], safeMul(tradeValues[1], tradeValues[4]) / tradeValues[0]);
        tokens[tradeAddresses[1]][tradeAddresses[3]] = safeAdd(tokens[tradeAddresses[1]][tradeAddresses[3]], safeMul((1 ether - tradeValues[7]), tradeValues[1]) / tradeValues[4] / (1 ether));
        tokens[tradeAddresses[1]][feeAccount] = safeAdd(tokens[tradeAddresses[1]][feeAccount], safeMul(tradeValues[7], tradeValues[1]) / tradeValues[4] / (1 ether));
        orderFills[orderHash] = safeAdd(orderFills[orderHash], tradeValues[4]);
    }

    function cancelOrder(address maker, uint amountGet, address tokenGet, uint amountGive, uint expires, uint nonce, uint8 v, bytes32 r, bytes32 s, address feeAccount) public onlyOwner {
        bytes32 orderHash = sha256(this, maker, amountGet, tokenGet, amountGive, expires, nonce, msg.sender, feeAccount);
        assert(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", orderHash), v, r, s) == feeAccount);
        orderFills[orderHash] = amountGet;
        emit Cancel(maker, amountGet, tokenGet, amountGive, expires, nonce, feeAccount, v, r, s);
    }
}
```