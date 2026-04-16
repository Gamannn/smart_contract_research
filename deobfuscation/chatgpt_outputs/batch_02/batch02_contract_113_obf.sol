```solidity
pragma solidity ^0.4.25;

contract Token {
    bytes32 public name;
    bytes32 public symbol;
    bytes32 public standard;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function transfer(address to, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function approve(address spender, uint256 value) public returns (bool success);
    function transferTokens(address from, address to, uint256 value) public returns (bool success);
}

contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Exchange is SafeMath {
    address public owner;
    mapping(address => uint256) public lastActive;
    mapping(address => mapping(address => uint256)) public tokens;
    mapping(address => bool) public admins;
    mapping(address => uint256) public invalidOrder;
    address public feeAccount;
    uint256 public inactivityReleasePeriod;

    event SetOwner(address indexed previousOwner, address indexed newOwner);
    event Deposit(address token, address user, uint256 amount, uint256 balance);
    event Withdraw(address token, address user, uint256 amount, uint256 balance);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == owner && admins[msg.sender]);
        _;
    }

    constructor(address _feeAccount) public {
        owner = msg.sender;
        feeAccount = _feeAccount;
        inactivityReleasePeriod = 100000;
    }

    function setOwner(address newOwner) public onlyOwner {
        emit SetOwner(owner, newOwner);
        owner = newOwner;
    }

    function setAdmin(address admin, bool isAdmin) public onlyOwner {
        admins[admin] = isAdmin;
    }

    function setInactivityReleasePeriod(uint256 newPeriod) public onlyAdmin returns (bool success) {
        require(newPeriod < 1000000);
        inactivityReleasePeriod = newPeriod;
        return true;
    }

    function() external {
        revert();
    }

    function depositToken(address token, uint256 amount) public {
        tokens[token][msg.sender] = safeAdd(tokens[token][msg.sender], amount);
        lastActive[msg.sender] = block.number;
        require(Token(token).transferTokens(msg.sender, this, amount));
        emit Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
    }

    function deposit() public payable {
        tokens[address(0)][msg.sender] = safeAdd(tokens[address(0)][msg.sender], msg.value);
        lastActive[msg.sender] = block.number;
        emit Deposit(address(0), msg.sender, msg.value, tokens[address(0)][msg.sender]);
    }

    function withdrawToken(address token, uint256 amount) public returns (bool) {
        require(safeSub(block.number, lastActive[msg.sender]) > inactivityReleasePeriod);
        require(tokens[token][msg.sender] >= amount);
        tokens[token][msg.sender] = safeSub(tokens[token][msg.sender], amount);
        if (token == address(0)) {
            msg.sender.transfer(amount);
        } else {
            require(Token(token).transfer(msg.sender, amount));
        }
        emit Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
        return true;
    }

    function withdraw(address token, uint256 amount, address user, uint256 fee) public onlyAdmin returns (bool) {
        if (fee > 50 finney) fee = 50 finney;
        require(tokens[token][user] >= amount);
        tokens[token][user] = safeSub(tokens[token][user], amount);
        tokens[token][feeAccount] = safeAdd(tokens[token][feeAccount], safeMul(fee, amount) / 1 ether);
        amount = safeMul((1 ether - fee), amount) / 1 ether;
        if (token == address(0)) {
            user.transfer(amount);
        } else {
            require(Token(token).transfer(user, amount));
        }
        lastActive[user] = block.number;
        emit Withdraw(token, user, amount, tokens[token][user]);
        return true;
    }

    function balanceOf(address token, address user) public view returns (uint256) {
        return tokens[token][user];
    }

    function trade(uint256[8] tradeValues, address[4] tradeAddresses) public onlyAdmin returns (bool) {
        require(invalidOrder[tradeAddresses[2]] < tradeValues[3]);
        if (tradeValues[6] > 100 finney) tradeValues[6] = 100 finney;
        if (tradeValues[7] > 100 finney) tradeValues[7] = 100 finney;
        require(tokens[tradeAddresses[0]][tradeAddresses[3]] >= tradeValues[4]);
        require(tokens[tradeAddresses[1]][tradeAddresses[2]] >= (safeMul(tradeValues[1], tradeValues[4]) / tradeValues[0]));
        tokens[tradeAddresses[0]][tradeAddresses[3]] = safeSub(tokens[tradeAddresses[0]][tradeAddresses[3]], tradeValues[4]);
        tokens[tradeAddresses[0]][tradeAddresses[2]] = safeAdd(tokens[tradeAddresses[0]][tradeAddresses[2]], safeMul(tradeValues[4], ((1 ether) - tradeValues[6])) / (1 ether));
        tokens[tradeAddresses[0]][feeAccount] = safeAdd(tokens[tradeAddresses[0]][feeAccount], safeMul(tradeValues[4], tradeValues[6]) / (1 ether));
        tokens[tradeAddresses[1]][tradeAddresses[2]] = safeSub(tokens[tradeAddresses[1]][tradeAddresses[2]], safeMul(tradeValues[1], tradeValues[4]) / tradeValues[0]);
        tokens[tradeAddresses[1]][tradeAddresses[3]] = safeAdd(tokens[tradeAddresses[1]][tradeAddresses[3]], safeMul(safeMul(((1 ether) - tradeValues[7]), tradeValues[1]), tradeValues[4]) / tradeValues[0] / (1 ether));
        tokens[tradeAddresses[1]][feeAccount] = safeAdd(tokens[tradeAddresses[1]][feeAccount], safeMul(safeMul(tradeValues[7], tradeValues[1]), tradeValues[4]) / tradeValues[0] / (1 ether));
        lastActive[tradeAddresses[2]] = block.number;
        lastActive[tradeAddresses[3]] = block.number;
        return true;
    }
}
```