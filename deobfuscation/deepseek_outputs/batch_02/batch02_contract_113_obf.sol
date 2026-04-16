```solidity
pragma solidity ^0.4.25;

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
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
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
    mapping(address => uint256) public lastActiveBlock;
    
    event SetOwner(address indexed previousOwner, address indexed newOwner);
    event Deposit(address indexed token, address indexed user, uint256 amount, uint256 balance);
    event Withdraw(address indexed token, address indexed user, uint256 amount, uint256 balance);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function setOwner(address newOwner) public onlyOwner {
        emit SetOwner(owner, newOwner);
        owner = newOwner;
    }
    
    function invalidateOrdersBefore(address user, uint256 blockNumber) public onlyAdmin {
        require(blockNumber > lastActiveBlock[user]);
        lastActiveBlock[user] = blockNumber;
    }
    
    mapping(address => mapping(address => uint256)) public tokens;
    mapping(address => bool) public admins;
    mapping(address => uint256) public lastActiveTransaction;
    address public feeAccount;
    uint256 public inactivityReleasePeriod;
    
    modifier onlyAdmin() {
        require(msg.sender == owner && admins[msg.sender]);
        _;
    }
    
    function setInactivityReleasePeriod(uint256 blocks) public onlyAdmin returns (bool success) {
        require(blocks < 1000000);
        inactivityReleasePeriod = blocks;
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
    
    function() external {
        revert();
    }
    
    function depositToken(address token, uint256 amount) public {
        tokens[token][msg.sender] = add(tokens[token][msg.sender], amount);
        lastActiveTransaction[msg.sender] = block.number;
        require(ERC20(token).transferFrom(msg.sender, this, amount));
        emit Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
    }
    
    function deposit() public payable {
        tokens[address(0)][msg.sender] = add(tokens[address(0)][msg.sender], msg.value);
        lastActiveTransaction[msg.sender] = block.number;
        emit Deposit(address(0), msg.sender, msg.value, tokens[address(0)][msg.sender]);
    }
    
    function withdraw(address token, uint256 amount) public returns (bool) {
        require(sub(block.number, lastActiveTransaction[msg.sender]) > inactivityReleasePeriod);
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
    
    function adminWithdraw(address token, uint256 amount, address user, uint256 feeMake) public onlyAdmin returns (bool) {
        if (feeMake > 50 finney) feeMake = 50 finney;
        require(tokens[token][user] >= amount);
        
        tokens[token][user] = sub(tokens[token][user], amount);
        tokens[token][feeAccount] = add(tokens[token][feeAccount], mul(feeMake, amount) / 1 ether);
        
        amount = mul((1 ether - feeMake), amount) / 1 ether;
        
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
    
    function trade(
        uint256[8] amounts,
        address[4] addresses
    ) public onlyAdmin returns (bool) {
        require(lastActiveBlock[addresses[2]] < amounts[3]);
        
        if (amounts[6] > 100 finney) amounts[6] = 100 finney;
        if (amounts[7] > 100 finney) amounts[7] = 100 finney;
        
        require(tokens[addresses[0]][addresses[3]] >= amounts[4]);
        require(tokens[addresses[1]][addresses[2]] >= (mul(amounts[1], amounts[4]) / amounts[0]));
        
        tokens[addresses[0]][addresses[3]] = sub(tokens[addresses[0]][addresses[3]], amounts[4]);
        tokens[addresses[0]][addresses[2]] = add(tokens[addresses[0]][addresses[2]], mul(amounts[4], ((1 ether) - amounts[6])) / (1 ether));
        tokens[addresses[0]][feeAccount] = add(tokens[addresses[0]][feeAccount], mul(amounts[4], amounts[6]) / (1 ether));
        
        tokens[addresses[1]][addresses[2]] = sub(tokens[addresses[1]][addresses[2]], mul(amounts[1], amounts[4]) / amounts[0]);
        tokens[addresses[1]][addresses[3]] = add(tokens[addresses[1]][addresses[3]], mul(mul(((1 ether) - amounts[7]), amounts[1]), amounts[4]) / amounts[0] / (1 ether));
        tokens[addresses[1]][feeAccount] = add(tokens[addresses[1]][feeAccount], mul(mul(amounts[7], amounts[1]), amounts[4]) / amounts[0] / (1 ether));
        
        lastActiveBlock[addresses[2]] = block.number;
        lastActiveTransaction[addresses[3]] = block.number;
        
        return true;
    }
}
```