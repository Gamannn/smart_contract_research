pragma solidity ^0.5.0;

contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
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
        require(sender != address(0), "ERC20: transfer from the zero address");
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

        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract MyToken is Ownable, ERC20 {
    using SafeMath for uint256;

    uint public loanInterestRate = 0.01 ether;
    uint public totalLoaned;
    uint public totalDebt;
    uint public maxLoanAmount;
    uint public totalLoanedAmount;
    address payable public loaner;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    event TokenWithdrawn(address indexed from, uint256 value);
    event Loan(address indexed loaner, uint256 value);
    event DebtReturned(address indexed from, uint256 value);
    event NewLoaner(address indexed previousLoaner, address indexed newLoaner);

    constructor () public {
        _name = "MyToken";
        _symbol = "MTT";
        _decimals = 18;
        maxLoanAmount = 100;
        loaner = 0x840A4023A0147094321444E74dDC09231A397a8A;
    }

    function deposit() public payable {
        require(msg.value > loanInterestRate, "Deposit amount is too low");
        uint tokenAmount = msg.value.mul(maxLoanAmount);
        _mint(msg.sender, tokenAmount);
        totalLoaned = totalLoaned.add(msg.value);
        totalLoanedAmount = totalLoanedAmount.add(msg.value);
    }

    function withdrawTokens(address account, uint tokenAmount) internal {
        _mint(account, tokenAmount);
    }

    function withdraw(uint tokenAmount) public {
        uint loanAmount = tokenAmount.div(maxLoanAmount).mul(2);
        require(loanAmount <= totalDebt, "Loan amount exceeds total debt");
        require(balanceOf(msg.sender) >= tokenAmount, "Insufficient balance");
        msg.sender.transfer(loanAmount);
        totalDebt = totalDebt.sub(loanAmount);
        _burn(msg.sender, tokenAmount);
        emit TokenWithdrawn(msg.sender, tokenAmount);
    }

    function loan(uint loanAmount) public {
        require(msg.sender == loaner, "Caller is not the loaner");
        require(totalLoaned >= loanAmount, "Loan amount exceeds total loaned");
        loaner.transfer(loanAmount);
        totalLoaned = totalLoaned.sub(loanAmount);
        emit Loan(loaner, loanAmount);
    }

    function returnDebt() public payable {
        totalDebt += msg.value;
        emit DebtReturned(msg.sender, msg.value);
    }

    function changeLoaner(address payable newLoaner) public onlyOwner {
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

    function totalLoanedAmount() public view returns (uint) {
        return totalLoaned;
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