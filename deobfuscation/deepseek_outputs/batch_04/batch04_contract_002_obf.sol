```solidity
pragma solidity ^0.5.2;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is IERC20 {
    using SafeMath for uint256;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        _totalSupply = _totalSupply.sub(amount);
        _balances[account] = _balances[account].sub(amount);
        emit Transfer(account, address(0), amount);
    }
    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

contract CONM is ERC20 {
    using SafeMath for uint256;
    
    IPriceOracle public priceOracle;
    string public constant name = "CONM";
    string public constant symbol = "CONM";
    uint8 public constant decimals = 18;
    uint256 internal _reserveOwnerSupply;
    address public owner;
    
    constructor(address oracleAddress) public {
        priceOracle = IPriceOracle(oracleAddress);
        _reserveOwnerSupply = 300000000 * 10**uint256(decimals);
        owner = msg.sender;
        _mint(owner, _reserveOwnerSupply);
    }
    
    function buyTokens() public payable {
        uint256 ethAmount = msg.value;
        uint256 tokenPrice = priceOracle.getPrice();
        uint256 tokensToMint = ethAmount.mul(1 ether).div(tokenPrice);
        
        require(tokensToMint > 0, "No tokens to mint");
        _mint(msg.sender, tokensToMint);
    }
    
    function getPrice() public view returns (uint256) {
        return priceOracle.getPrice();
    }
    
    function sellTokens(uint256 tokenAmount) public returns (uint256 ethAmount) {
        require(tokenAmount <= balanceOf(msg.sender));
        
        ethAmount = tokenAmount.mul(1 ether).div(priceOracle.getPrice());
        
        if (balanceOf(msg.sender) <= ethAmount) {
            ethAmount = ethAmount.mul(balanceOf(msg.sender));
            ethAmount = ethAmount.mul(priceOracle.getPrice());
            ethAmount = ethAmount.div(1 ether);
            ethAmount = ethAmount.mul(totalSupply());
        }
        
        _burn(msg.sender, tokenAmount);
        msg.sender.transfer(ethAmount);
    }
}

interface IPriceOracle {
    function getPrice() external view returns (uint256);
}

contract PriceOracle is IPriceOracle {
    uint256 public price;
    address public owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call");
        _;
    }
    
    constructor() public {
        owner = msg.sender;
    }
    
    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }
    
    function getPrice() external view returns (uint256) {
        return price;
    }
}
```