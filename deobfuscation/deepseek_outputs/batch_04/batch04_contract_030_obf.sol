```solidity
pragma solidity ^0.4.23;

contract ERC20 {
    bytes32 public name;
    bytes32 public symbol;
    bytes32 public version;
    uint8 public decimals;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    function transfer(address to, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function approve(address spender, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
}

contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // Implementation omitted in original
    }
    
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Exchange is SafeMath {
    address public owner;
    mapping(address => uint256) public invalidOrder;
    
    event SetOwner(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function setOwner(address newOwner) public onlyOwner {
        emit SetOwner(owner, newOwner);
        owner = newOwner;
    }
    
    function invalidateOrders(address user, uint256 target) public onlyOwner {
        require(target > invalidOrder[user]);
        invalidOrder[user] = target;
    }
    
    mapping(address => mapping(address => uint256)) public tokens;
    mapping(address => bool) public admins;
    mapping(address => uint256) public lastActiveTransaction;
    address public feeAccount;
    uint256 public inactivityReleasePeriod;
    
    event Deposit(address token, address user, uint256 amount, uint256 balance);
    event Withdraw(address token, address user, uint256 amount, uint256 balance);
    event Trade(address tokenBuy, uint256 amountBuy, address tokenSell, uint256 amountSell, address maker, address taker);
    
    function setInactivityReleasePeriod(uint256 period) public onlyOwner returns (bool success) {
        require(period < 1000000);
        inactivityReleasePeriod = period;
        return true;
    }
    
    constructor() public {
        owner = msg.sender;
        feeAccount = msg.sender;
        inactivityReleasePeriod = 100000;
    }
    
    function setAdmin(address admin, bool isAdmin) public onlyOwner {
        admins[admin] = isAdmin;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == owner && admins[msg.sender]);
        _;
    }
    
    function() external {
        revert();
    }
    
    function depositToken(address token, uint256 amount) public {
        tokens[token][msg.sender] = safeAdd(tokens[token][msg.sender], amount);
        lastActiveTransaction[msg.sender] = block.number;
        require(ERC20(token).transferFrom(msg.sender, this, amount));
        emit Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
    }
    
    function deposit() public payable {
        tokens[address(0)][msg.sender] = safeAdd(tokens[address(0)][msg.sender], msg.value);
        lastActiveTransaction[msg.sender] = block.number;
        emit Deposit(address(0), msg.sender, msg.value, tokens[address(0)][msg.sender]);
    }
    
    function withdraw(address token, uint256 amount) public returns (bool success) {
        require(safeSub(block.number, lastActiveTransaction[msg.sender]) >= inactivityReleasePeriod);
        require(tokens[token][msg.sender] >= amount);
        tokens[token][msg.sender] = safeSub(tokens[token][msg.sender], amount);
        
        if (token == address(0)) {
            msg.sender.transfer(amount);
        } else {
            require(ERC20(token).transfer(msg.sender, amount));
        }
        
        emit Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
        return true;
    }
    
    function adminWithdraw(address token, uint256 amount, address user, uint256 feeWithdrawal) public onlyAdmin returns (bool) {
        if (feeWithdrawal > 50 finney) feeWithdrawal = 50 finney;
        require(tokens[token][user] >= amount);
        tokens[token][user] = safeSub(tokens[token][user], amount);
        tokens[token][feeAccount] = safeAdd(tokens[token][feeAccount], safeMul(feeWithdrawal, amount) / 1 ether);
        amount = safeMul((1 ether - feeWithdrawal), amount) / 1 ether;
        
        if (token == address(0)) {
            user.transfer(amount);
        } else {
            require(ERC20(token).transfer(user, amount));
        }
        
        lastActiveTransaction[user] = block.number;
        emit Withdraw(token, user, amount, tokens[token][user]);
        return true;
    }
    
    function balanceOf(address token, address user) public constant returns (uint256) {
        return tokens[token][user];
    }
    
    function trade(uint256[8] orderValues, address[4] orderAddresses) public onlyAdmin returns (bool) {
        require(invalidOrder[orderAddresses[2]] < orderValues[3]);
        
        if (orderValues[6] > 100 finney) orderValues[6] = 100 finney;
        if (orderValues[7] > 100 finney) orderValues[7] = 100 finney;
        
        require(tokens[orderAddresses[0]][orderAddresses[2]] >= orderValues[4]);
        require(tokens[orderAddresses[1]][orderAddresses[3]] >= safeMul(orderValues[1], orderValues[4]) / orderValues[0]);
        
        tokens[orderAddresses[0]][orderAddresses[2]] = safeSub(tokens[orderAddresses[0]][orderAddresses[2]], orderValues[4]);
        tokens[orderAddresses[0]][orderAddresses[3]] = safeAdd(tokens[orderAddresses[0]][orderAddresses[3]], safeMul(orderValues[4], ((1 ether) - orderValues[6])) / (1 ether));
        
        tokens[orderAddresses[0]][feeAccount] = safeAdd(tokens[orderAddresses[0]][feeAccount], safeMul(orderValues[4], orderValues[6]) / (1 ether));
        
        tokens[orderAddresses[1]][orderAddresses[2]] = safeSub(tokens[orderAddresses[1]][orderAddresses[2]], safeMul(orderValues[1], orderValues[4]) / orderValues[0]);
        tokens[orderAddresses[1]][orderAddresses[3]] = safeAdd(tokens[orderAddresses[1]][orderAddresses[3]], safeMul(safeMul(((1 ether) - orderValues[7]), orderValues[1]), orderValues[4]) / orderValues[0] / (1 ether));
        
        tokens[orderAddresses[1]][feeAccount] = safeAdd(tokens[orderAddresses[1]][feeAccount], safeMul(safeMul(orderValues[7], orderValues[1]), orderValues[4]) / orderValues[0] / (1 ether));
        
        lastActiveTransaction[orderAddresses[2]] = block.number;
        lastActiveTransaction[orderAddresses[3]] = block.number;
        
        emit Trade(orderAddresses[0], orderValues[4], orderAddresses[1], safeMul(orderValues[1], orderValues[4]) / orderValues[0], orderAddresses[2], orderAddresses[3]);
        return true;
    }
}
```