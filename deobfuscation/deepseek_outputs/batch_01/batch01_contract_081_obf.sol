```solidity
pragma solidity ^0.5.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }
    
    function name() public view returns (string memory) {
        return _name;
    }
    
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

contract Sparkle is ERC20Detailed {
    using SafeMath for uint256;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    
    event SparkleRedistribution(address from, uint amount);
    event Mint(address to, uint amount);
    event Sell(address from, uint amount);
    
    uint256 private _totalSupply;
    uint256 private _tobinsCollected;
    address payable private creator;
    uint256 private constant COST_PER_TOKEN = 1e14;
    uint256 private constant TAX = 1;
    uint256 private constant PERCENT = 100;
    uint256 private constant MAX_SUPPLY = 400000000 * 10 ** 18;
    
    mapping (address => uint256) private _tobinsClaimed;
    
    constructor() public ERC20Detailed("Sparkle!", "SPRK", 18) {
        creator = 0x4C3cC1D2229CBD17D26ec984F2E1b9bD336cBf69;
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function tobinsCollected() public view returns (uint256) {
        return _tobinsCollected;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        if (_totalSupply == 0) return _balances[account];
        
        uint256 unclaimed = _tobinsCollected.sub(_tobinsClaimed[account]);
        uint256 floatingSupply = _totalSupply.sub(_tobinsCollected);
        uint256 redistribution = _balances[account].mul(unclaimed).div(floatingSupply);
        
        return _balances[account].add(redistribution);
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }
    
    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(0));
        
        uint256 taxAmount = amount.mul(TAX).div(PERCENT);
        uint256 netAmount = amount.sub(taxAmount);
        
        _balances[msg.sender] = balanceOf(msg.sender).sub(amount).sub(taxAmount);
        _balances[recipient] = balanceOf(recipient).add(netAmount);
        
        _tobinsClaimed[msg.sender] = _tobinsCollected;
        _tobinsClaimed[recipient] = _tobinsCollected;
        _tobinsCollected = _tobinsCollected.add(taxAmount);
        
        emit Transfer(msg.sender, recipient, amount);
        emit SparkleRedistribution(msg.sender, taxAmount);
        
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(amount <= _allowed[sender][msg.sender]);
        require(recipient != address(0));
        
        uint256 taxAmount = amount.mul(TAX).div(PERCENT);
        uint256 netAmount = amount.sub(taxAmount);
        
        _balances[sender] = balanceOf(sender).sub(amount).sub(taxAmount);
        _balances[recipient] = balanceOf(recipient).add(netAmount);
        
        _tobinsClaimed[sender] = _tobinsCollected;
        _tobinsClaimed[recipient] = _tobinsCollected;
        _tobinsCollected = _tobinsCollected.add(taxAmount);
        
        _allowed[sender][msg.sender] = _allowed[sender][msg.sender].sub(amount);
        
        emit Transfer(sender, recipient, amount);
        emit SparkleRedistribution(sender, taxAmount);
        
        return true;
    }
    
    function approve(address spender, uint256 amount) public returns (bool) {
        require(spender != address(0));
        
        _allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        
        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));
        
        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));
        
        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        
        return true;
    }
    
    function () external payable {
        mintSparkle();
    }
    
    function mintSparkle() public payable returns (bool) {
        uint256 amount = msg.value.mul(10 ** 18).div(COST_PER_TOKEN);
        require(_totalSupply.add(amount) <= MAX_SUPPLY);
        
        uint256 taxAmount = amount.mul(TAX).div(PERCENT);
        uint256 creatorAmount = amount.mul(1).div(PERCENT);
        uint256 buyerAmount = amount.sub(taxAmount).sub(creatorAmount);
        
        _balances[msg.sender] = balanceOf(msg.sender).add(buyerAmount);
        _balances[creator] = balanceOf(creator).add(creatorAmount);
        _totalSupply = _totalSupply.add(amount);
        
        _tobinsClaimed[msg.sender] = _tobinsCollected;
        _tobinsClaimed[creator] = _tobinsCollected;
        _tobinsCollected = _tobinsCollected.add(taxAmount);
        
        emit Mint(msg.sender, buyerAmount);
        emit SparkleRedistribution(msg.sender, taxAmount);
        
        return true;
    }
    
    function sellSparkle(uint256 amount) public returns (bool) {
        require(amount > 0 && balanceOf(msg.sender) >= amount);
        
        uint256 reward = amount.mul(COST_PER_TOKEN).div(10 ** 18);
        uint256 creatorAmount = reward.mul(3).div(PERCENT);
        uint256 sellerAmount = reward.sub(creatorAmount);
        
        _balances[msg.sender] = balanceOf(msg.sender).sub(amount);
        _tobinsClaimed[msg.sender] = _tobinsCollected;
        _totalSupply = _totalSupply.sub(amount);
        
        creator.transfer(creatorAmount);
        msg.sender.transfer(sellerAmount);
        
        emit Sell(msg.sender, amount);
        
        return true;
    }
}
```