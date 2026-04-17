```solidity
pragma solidity ^0.4.23;

contract Token {
    bytes32 public name;
    bytes32 public symbol;
    bytes32 public standard;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function transfer(address to, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function approve(address spender, uint256 value) public returns (bool success);
    function transferFromContract(address from, address to, uint256 value) public returns (bool success);
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
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
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
    mapping(address => mapping(address => uint256)) public tokens;
    mapping(address => bool) public admins;
    mapping(address => uint256) public lastActiveTransaction;
    address public feeAccount;
    uint256 public inactivityReleasePeriod;
    event Trade(address tokenGet, address tokenGive, uint256 amountGet, uint256 amountGive);
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

    function setOwner(address newOwner) public onlyOwner {
        emit SetOwner(owner, newOwner);
        owner = newOwner;
    }

    function invalidateOrder(address user, uint256 nonce) public onlyAdmin {
        require(nonce > lastActiveTransaction[user]);
        lastActiveTransaction[user] = nonce;
    }

    function setAdmin(address admin, bool isAdmin) public onlyOwner {
        admins[admin] = isAdmin;
    }

    function() external {
        revert();
    }

    function depositToken(address token, uint256 amount) public {
        tokens[token][msg.sender] = safeAdd(tokens[token][msg.sender], amount);
        lastActiveTransaction[msg.sender] = block.number;
        require(Token(token).transferFrom(msg.sender, this, amount));
        emit Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
    }

    function deposit() public payable {
        tokens[address(0)][msg.sender] = safeAdd(tokens[address(0)][msg.sender], msg.value);
        lastActiveTransaction[msg.sender] = block.number;
        emit Deposit(address(0), msg.sender, msg.value, tokens[address(0)][msg.sender]);
    }

    function withdrawToken(address token, uint256 amount) public returns (bool) {
        require(safeSub(block.number, lastActiveTransaction[msg.sender]) < inactivityReleasePeriod);
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

    function withdraw(uint256 amount) public returns (bool) {
        require(safeSub(block.number, lastActiveTransaction[msg.sender]) < inactivityReleasePeriod);
        require(tokens[address(0)][msg.sender] >= amount);
        tokens[address(0)][msg.sender] = safeSub(tokens[address(0)][msg.sender], amount);
        msg.sender.transfer(amount);
        emit Withdraw(address(0), msg.sender, amount, tokens[address(0)][msg.sender]);
        return true;
    }

    function trade(address tokenGet, uint256 amountGet, address tokenGive, uint256 amountGive) public onlyAdmin returns (bool) {
        if (amountGive > 50 finney) amountGive = 50 finney;
        require(tokens[tokenGet][msg.sender] >= amountGet);
        tokens[tokenGet][msg.sender] = safeSub(tokens[tokenGet][msg.sender], amountGet);
        tokens[tokenGive][msg.sender] = safeAdd(tokens[tokenGive][msg.sender], safeMul(amountGive, (1 ether - amountGive)) / 1 ether);
        lastActiveTransaction[msg.sender] = block.number;
        emit Trade(tokenGet, tokenGive, amountGet, amountGive);
        return true;
    }

    function balanceOf(address token, address user) public constant returns (uint256) {
        return tokens[token][user];
    }

    function setInactivityReleasePeriod(uint256 period) public onlyOwner {
        inactivityReleasePeriod = period;
    }
}
```