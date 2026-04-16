```solidity
pragma solidity ^0.4.23;

contract ERC20 {
    bytes32 public name;
    bytes32 public symbol;
    bytes32 public version;
    uint8 public decimals;
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    function transfer(address to, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function approve(address spender, uint256 value) public returns (bool success);
    function transfer(address from, address to, uint256 value) public returns (bool success);
}

contract SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Exchange is SafeMath {
    address public owner;
    address adminAddress = 0x46705E8fef2E868FACAFeDc45F47114EC01c2EEd;
    
    event SetOwner(address indexed previousOwner, address indexed newOwner);
    event Deposit(address indexed token, address indexed user, uint256 amount, uint256 balance);
    event Withdraw(address indexed token, address indexed user, uint256 amount, uint256 balance);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == owner && admins[msg.sender]);
        _;
    }
    
    mapping(address => mapping(address => uint256)) public tokens;
    mapping(address => bool) public admins;
    mapping(address => uint256) public lastActiveBlock;
    mapping(address => uint256) public orderExpiration;
    
    address public feeAccount;
    uint256 public inactivityReleasePeriod;
    
    constructor(address _feeAccount) public {
        owner = msg.sender;
        feeAccount = _feeAccount;
        inactivityReleasePeriod = 100000;
    }
    
    function setOwner(address newOwner) public onlyOwner {
        emit SetOwner(owner, newOwner);
        owner = newOwner;
    }
    
    function setInactivityReleasePeriod(uint256 blocks) public onlyAdmin returns (bool success) {
        require(blocks < 1000000);
        inactivityReleasePeriod = blocks;
        return true;
    }
    
    function setAdmin(address admin, bool isAdmin) public onlyOwner {
        admins[admin] = isAdmin;
    }
    
    function setOrderExpiration(address user, uint256 expiration) public onlyAdmin {
        require(expiration > orderExpiration[user]);
        orderExpiration[user] = expiration;
    }
    
    function() external {
        revert();
    }
    
    function depositToken(address token, uint256 amount) public {
        tokens[token][msg.sender] = add(tokens[token][msg.sender], amount);
        lastActiveBlock[msg.sender] = block.number;
        require(ERC20(token).transfer(msg.sender, this, amount));
        emit Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
    }
    
    function deposit() public payable {
        tokens[address(0)][msg.sender] = add(tokens[address(0)][msg.sender], msg.value);
        lastActiveBlock[msg.sender] = block.number;
        emit Deposit(address(0), msg.sender, msg.value, tokens[address(0)][msg.sender]);
    }
    
    function withdraw(address token, uint256 amount) public returns (bool) {
        require(sub(block.number, lastActiveBlock[msg.sender]) > inactivityReleasePeriod);
        require(tokens[token][msg.sender] >= amount);
        tokens[token][msg.sender] = sub(tokens[token][msg.sender], amount);
        
        if (token == address(0)) {
            msg.sender.transfer(amount);
        } else {
            require(ERC20(token).transfer(msg.sender, amount));
        }
        
        emit Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
        return true;
    }
    
    function adminWithdraw(address token, uint256 amount, address user, uint256 fee) public onlyAdmin returns (bool) {
        if (fee > 50 finney) fee = 50 finney;
        require(tokens[token][user] >= amount);
        
        tokens[token][user] = sub(tokens[token][user], amount);
        tokens[token][feeAccount] = add(tokens[token][feeAccount], mul(fee, amount) / 1 ether);
        
        amount = mul((1 ether - fee), amount) / 1 ether;
        
        if (token == address(0)) {
            user.transfer(amount);
        } else {
            require(ERC20(token).transfer(user, amount));
        }
        
        lastActiveBlock[user] = block.number;
        emit Withdraw(token, user, amount, tokens[token][user]);
        return true;
    }
    
    function balanceOf(address token, address user) public constant returns (uint256) {
        return tokens[token][user];
    }
    
    function trade(
        uint256[8] tradeValues,
        address[4] tradeAddresses
    ) public onlyAdmin returns (bool) {
        require(orderExpiration[tradeAddresses[2]] < tradeValues[3]);
        
        if (tradeValues[6] > 100 finney) tradeValues[6] = 100 finney;
        if (tradeValues[7] > 100 finney) tradeValues[7] = 100 finney;
        
        require(tokens[tradeAddresses[0]][tradeAddresses[3]] >= tradeValues[4]);
        require(tokens[tradeAddresses[1]][tradeAddresses[2]] >= mul(tradeValues[1], tradeValues[4]) / tradeValues[0]);
        
        tokens[tradeAddresses[0]][tradeAddresses[3]] = sub(tokens[tradeAddresses[0]][tradeAddresses[3]], tradeValues[4]);
        tokens[tradeAddresses[0]][tradeAddresses[2]] = add(tokens[tradeAddresses[0]][tradeAddresses[2]], mul(tradeValues[4], (1 ether - tradeValues[6])) / (1 ether));
        tokens[tradeAddresses[0]][feeAccount] = add(tokens[tradeAddresses[0]][feeAccount], mul(tradeValues[4], tradeValues[6]) / (1 ether));
        
        tokens[tradeAddresses[1]][tradeAddresses[2]] = sub(tokens[tradeAddresses[1]][tradeAddresses[2]], mul(tradeValues[1], tradeValues[4]) / tradeValues[0]);
        tokens[tradeAddresses[1]][tradeAddresses[3]] = add(tokens[tradeAddresses[1]][tradeAddresses[3]], mul(mul((1 ether - tradeValues[7]), tradeValues[1]), tradeValues[4]) / tradeValues[0] / (1 ether));
        tokens[tradeAddresses[1]][feeAccount] = add(tokens[tradeAddresses[1]][feeAccount], mul(mul(tradeValues[7], tradeValues[1]), tradeValues[4]) / tradeValues[0] / (1 ether));
        
        lastActiveBlock[tradeAddresses[2]] = block.number;
        lastActiveBlock[tradeAddresses[3]] = block.number;
        
        return true;
    }
}
```