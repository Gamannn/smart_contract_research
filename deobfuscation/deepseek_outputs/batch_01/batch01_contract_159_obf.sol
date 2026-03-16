```solidity
pragma solidity ^0.4.25;

interface ERC20 {
    function transfer(address to, uint256 value) external returns (bool success);
    function transferFrom(address from, address to, uint256 value) external returns (bool success);
    function approve(address spender, uint256 value) external returns (bool success);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
    
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
    
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
}

contract Exchange is SafeMath {
    struct Config {
        uint256 feeRate;
        address feeAccount;
        address owner;
        bool locked;
        uint8 version;
        uint256 totalTrades;
    }
    
    Config public config = Config(100000, address(0), address(0), false, 0, 0);
    
    mapping(address => uint256) public lastActiveBlock;
    mapping(address => mapping(address => uint256)) public balances;
    mapping(address => bool) public authorized;
    mapping(address => uint256) public minDeposit;
    mapping(address => mapping(address => uint256)) public allowances;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Trade(
        address indexed tokenGive,
        uint256 amountGive,
        address indexed tokenGet,
        uint256 amountGet,
        address indexed maker,
        address taker
    );
    event Deposit(address indexed token, address indexed user, uint256 amount, uint256 balance);
    event Withdraw(address indexed token, address indexed user, uint256 amount, uint256 balance);
    
    modifier onlyOwner() {
        require(msg.sender == config.owner, "Only owner can call");
        _;
    }
    
    modifier onlyAuthorized() {
        require(msg.sender == config.owner && authorized[msg.sender], "Not authorized");
        _;
    }
    
    constructor(address _feeAccount) public {
        config.owner = msg.sender;
        config.feeAccount = _feeAccount;
        config.feeRate = 100000;
    }
    
    function setOwner(address newOwner) public onlyOwner {
        emit OwnershipTransferred(config.owner, newOwner);
        config.owner = newOwner;
    }
    
    function setMinDeposit(address token, uint256 minAmount) public onlyAuthorized {
        require(minAmount > minDeposit[token]);
        minDeposit[token] = minAmount;
    }
    
    function setFeeRate(uint256 newFeeRate) public onlyAuthorized returns (bool) {
        require(newFeeRate < 1000000);
        config.feeRate = newFeeRate;
        return true;
    }
    
    function setAuthorized(address user, bool status) public onlyOwner {
        authorized[user] = status;
    }
    
    function() external {
        revert();
    }
    
    function depositToken(address token, uint256 amount) public {
        balances[token][msg.sender] = safeAdd(balances[token][msg.sender], amount);
        lastActiveBlock[msg.sender] = block.number;
        require(ERC20(token).transferFrom(msg.sender, this, amount));
        emit Deposit(token, msg.sender, amount, balances[token][msg.sender]);
    }
    
    function depositEther() public payable {
        balances[address(0)][msg.sender] = safeAdd(balances[address(0)][msg.sender], msg.value);
        lastActiveBlock[msg.sender] = block.number;
        emit Deposit(address(0), msg.sender, msg.value, balances[address(0)][msg.sender]);
    }
    
    function withdraw(address token, uint256 amount) public returns (bool) {
        require(safeSub(block.number, lastActiveBlock[msg.sender]) > config.feeRate);
        require(balances[token][msg.sender] > amount);
        
        balances[token][msg.sender] = safeSub(balances[token][msg.sender], amount);
        
        if (token == address(0)) {
            msg.sender.transfer(amount);
        } else {
            require(ERC20(token).transfer(msg.sender, amount));
        }
        
        emit Withdraw(token, msg.sender, amount, balances[token][msg.sender]);
        return true;
    }
    
    function adminWithdraw(address token, uint256 amount, address user, uint256 fee) public onlyAuthorized returns (bool) {
        if (fee > 50 finney) fee = 50 finney;
        require(balances[token][user] > amount);
        
        balances[token][user] = safeSub(balances[token][user], amount);
        balances[token][config.feeAccount] = safeAdd(
            balances[token][config.feeAccount],
            safeMul(fee, amount) / 1 ether
        );
        
        amount = safeMul((1 ether - fee), amount) / 1 ether;
        
        if (token == address(0)) {
            user.transfer(amount);
        } else {
            require(ERC20(token).transfer(user, amount));
        }
        
        lastActiveBlock[user] = block.number;
        emit Withdraw(token, user, amount, balances[token][user]);
        return true;
    }
    
    function balanceOf(address token, address user) public view returns (uint256) {
        return balances[token][user];
    }
    
    function trade(
        uint256[8] tradeValues,
        address[4] tradeAddresses
    ) public onlyAuthorized returns (bool) {
        require(minDeposit[tradeAddresses[2]] < tradeValues[3]);
        
        if (tradeValues[6] > 100 finney) tradeValues[6] = 100 finney;
        if (tradeValues[7] > 100 finney) tradeValues[7] = 100 finney;
        
        require(balances[tradeAddresses[0]][tradeAddresses[3]] > tradeValues[4]);
        require(
            balances[tradeAddresses[1]][tradeAddresses[2]] > 
            safeMul(tradeValues[1], tradeValues[4]) / tradeValues[0]
        );
        
        balances[tradeAddresses[0]][tradeAddresses[3]] = safeSub(
            balances[tradeAddresses[0]][tradeAddresses[3]],
            tradeValues[4]
        );
        
        balances[tradeAddresses[0]][tradeAddresses[2]] = safeAdd(
            balances[tradeAddresses[0]][tradeAddresses[2]],
            safeMul(tradeValues[4], (1 ether - tradeValues[6])) / 1 ether
        );
        
        balances[tradeAddresses[0]][config.feeAccount] = safeAdd(
            balances[tradeAddresses[0]][config.feeAccount],
            safeMul(tradeValues[4], tradeValues[6]) / 1 ether
        );
        
        balances[tradeAddresses[1]][tradeAddresses[2]] = safeSub(
            balances[tradeAddresses[1]][tradeAddresses[2]],
            safeMul(tradeValues[1], tradeValues[4]) / tradeValues[0]
        );
        
        balances[tradeAddresses[1]][tradeAddresses[3]] = safeAdd(
            balances[tradeAddresses[1]][tradeAddresses[3]],
            safeMul(safeMul((1 ether - tradeValues[7]), tradeValues[1]), tradeValues[4]) / tradeValues[0] / 1 ether
        );
        
        balances[tradeAddresses[1]][config.feeAccount] = safeAdd(
            balances[tradeAddresses[1]][config.feeAccount],
            safeMul(safeMul(tradeValues[7], tradeValues[1]), tradeValues[4]) / tradeValues[0] / 1 ether
        );
        
        lastActiveBlock[tradeAddresses[2]] = block.number;
        lastActiveBlock[tradeAddresses[3]] = block.number;
        
        emit Trade(
            tradeAddresses[0],
            tradeValues[4],
            tradeAddresses[1],
            safeMul(tradeValues[1], tradeValues[4]) / tradeValues[0],
            tradeAddresses[2],
            tradeAddresses[3]
        );
        
        return true;
    }
}
```