```solidity
pragma solidity ^0.5.0;

contract Ownable {
    address private _owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    
    function owner() public view returns (address) {
        return _owner;
    }
    
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
    
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is IERC20 {
    using SafeMath for uint256;
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
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
    
    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        _transfer(from, to, amount);
        _approve(from, msg.sender, _allowances[from][msg.sender].sub(amount));
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
    
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount);
        emit Transfer(from, to, amount);
    }
    
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        require(_balances[account] >= amount);
        
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

contract MTTToken is Ownable, ERC20 {
    using SafeMath for uint256;
    
    uint public minDeposit = 0.01 ether;
    uint public loanBalance;
    uint public debtPool;
    uint public rewardRate = 100;
    uint public totalDeposits;
    address payable public loaner;
    
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    event TokenWithdrawn(address indexed user, uint256 amount);
    event Loan(address indexed loaner, uint256 amount);
    event DebtReturned(address indexed payer, uint256 amount);
    event NewLoaner(address indexed previousLoaner, address indexed newLoaner);
    
    constructor() public {
        _name = "MTTToken";
        _symbol = "MTT";
        _decimals = 18;
        rewardRate = 100;
        loaner = 0x840A4023A0147094321444E74dDC09231A397a8A;
    }
    
    function deposit() public payable {
        require(msg.value > minDeposit, "Insufficient deposit");
        
        uint256 tokens = msg.value.mul(rewardRate);
        _mint(msg.sender, tokens);
        
        loanBalance = loanBalance.add(msg.value);
        totalDeposits = totalDeposits.add(msg.value);
    }
    
    function _mint(address account, uint256 amount) internal {
        super._mint(account, amount);
    }
    
    function withdraw(uint256 tokenAmount) public {
        uint256 ethAmount = tokenAmount.div(rewardRate).mul(2);
        require(ethAmount <= debtPool, "Insufficient debt pool");
        require(balanceOf(msg.sender) >= tokenAmount, "Insufficient balance");
        
        msg.sender.transfer(ethAmount);
        debtPool = debtPool.sub(ethAmount);
        _burn(msg.sender, tokenAmount);
        
        emit TokenWithdrawn(msg.sender, tokenAmount);
    }
    
    function takeLoan(uint256 amount) public {
        require(msg.sender == loaner, "Only loaner can take loan");
        require(loanBalance >= amount, "Insufficient loan balance");
        
        loaner.transfer(amount);
        loanBalance = loanBalance.sub(amount);
        
        emit Loan(loaner, amount);
    }
    
    function repayDebt() public payable {
        debtPool += msg.value;
        emit DebtReturned(msg.sender, msg.value);
    }
    
    function setLoaner(address payable newLoaner) public onlyOwner {
        emit NewLoaner(loaner, newLoaner);
        loaner = newLoaner;
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
    
    function getLoanBalance() public view returns (uint) {
        return loanBalance;
    }
}

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
```