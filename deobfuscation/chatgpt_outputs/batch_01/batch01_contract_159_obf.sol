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
    mapping(address => uint256) public tokenBalance;
    event SetOwner(address indexed previousOwner, address indexed newOwner);
    modifier onlyOwner() {
        require(msg.sender == admin.owner);
        _;
    }

    function setOwner(address newOwner) public onlyOwner {
        emit SetOwner(admin.owner, newOwner);
        admin.owner = newOwner;
    }

    function setTokenBalance(address token, uint256 balance) public onlyAdmin {
        require(balance > tokenBalance[token]);
        tokenBalance[token] = balance;
    }

    mapping(address => mapping(address => uint256)) public tokens;
    mapping(address => bool) public admins;
    mapping(address => uint256) public lastActiveBlock;
    event Trade(address tokenBuy, uint256 amountBuy, address tokenSell, uint256 amountSell, address buyer, address seller);
    event Deposit(address token, address user, uint256 amount, uint256 balance);
    event Withdraw(address token, address user, uint256 amount, uint256 balance);

    function setFee(uint256 fee) public onlyAdmin returns (bool success) {
        require(fee < 1000000);
        admin.fee = fee;
        return true;
    }

    constructor(address feeAccount) public {
        admin.owner = msg.sender;
        admin.feeAccount = feeAccount;
        admin.fee = 100000;
    }

    function setAdmin(address adminAddress, bool isAdmin) public onlyOwner {
        admins[adminAddress] = isAdmin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin.owner && admins[msg.sender]);
        _;
    }

    function() external {
        revert();
    }

    function depositToken(address token, uint256 amount) public {
        tokens[token][msg.sender] = safeAdd(tokens[token][msg.sender], amount);
        lastActiveBlock[msg.sender] = block.number;
        require(Token(token).transferFrom(msg.sender, this, amount));
        emit Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
    }

    function deposit() public payable {
        tokens[address(0)][msg.sender] = safeAdd(tokens[address(0)][msg.sender], msg.value);
        lastActiveBlock[msg.sender] = block.number;
        emit Deposit(address(0), msg.sender, msg.value, tokens[address(0)][msg.sender]);
    }

    function withdrawToken(address token, uint256 amount) public returns (bool) {
        require(safeSub(block.number, lastActiveBlock[msg.sender]) > admin.fee);
        require(tokens[token][msg.sender] > amount);
        tokens[token][msg.sender] = safeSub(tokens[token][msg.sender], amount);
        if (token == address(0)) {
            msg.sender.transfer(amount);
        } else {
            require(Token(token).transfer(msg.sender, amount));
        }
        emit Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
    }

    function withdraw(uint256 amount) public returns (bool) {
        require(safeSub(block.number, lastActiveBlock[msg.sender]) > admin.fee);
        require(tokens[address(0)][msg.sender] > amount);
        tokens[address(0)][msg.sender] = safeSub(tokens[address(0)][msg.sender], amount);
        msg.sender.transfer(amount);
        emit Withdraw(address(0), msg.sender, amount, tokens[address(0)][msg.sender]);
    }

    function balanceOf(address token, address user) public view returns (uint256) {
        return tokens[token][user];
    }

    function trade(uint256[8] tradeValues, address[4] tradeAddresses) public onlyAdmin returns (bool) {
        require(tokenBalance[tradeAddresses[2]] < tradeValues[3]);
        if (tradeValues[6] > 100 finney) tradeValues[6] = 100 finney;
        if (tradeValues[7] > 100 finney) tradeValues[7] = 100 finney;
        require(tokens[tradeAddresses[0]][tradeAddresses[3]] > tradeValues[4]);
        require(tokens[tradeAddresses[1]][tradeAddresses[2]] > (safeMul(tradeValues[1], tradeValues[4]) / tradeValues[0]));
        tokens[tradeAddresses[0]][tradeAddresses[3]] = safeSub(tokens[tradeAddresses[0]][tradeAddresses[3]], tradeValues[4]);
        tokens[tradeAddresses[0]][tradeAddresses[2]] = safeAdd(tokens[tradeAddresses[0]][tradeAddresses[2]], safeMul(tradeValues[4], (1 ether - tradeValues[6])) / 1 ether);
        tokens[tradeAddresses[0]][admin.feeAccount] = safeAdd(tokens[tradeAddresses[0]][admin.feeAccount], safeMul(tradeValues[4], tradeValues[6]) / 1 ether);
        tokens[tradeAddresses[1]][tradeAddresses[2]] = safeSub(tokens[tradeAddresses[1]][tradeAddresses[2]], safeMul(tradeValues[1], tradeValues[4]) / tradeValues[0]);
        tokens[tradeAddresses[1]][tradeAddresses[3]] = safeAdd(tokens[tradeAddresses[1]][tradeAddresses[3]], safeMul(safeMul((1 ether - tradeValues[7]), tradeValues[1]), tradeValues[4]) / tradeValues[0] / 1 ether);
        tokens[tradeAddresses[1]][admin.feeAccount] = safeAdd(tokens[tradeAddresses[1]][admin.feeAccount], safeMul(safeMul(tradeValues[7], tradeValues[1]), tradeValues[4]) / tradeValues[0] / 1 ether);
        lastActiveBlock[tradeAddresses[2]] = block.number;
        lastActiveBlock[tradeAddresses[3]] = block.number;
    }

    struct Admin {
        uint256 fee;
        address feeAccount;
        address owner;
        bool active;
        uint8 version;
        uint256 lastUpdated;
    }

    Admin admin = Admin(0, address(0), address(0), false, 0, 0);
}
```