pragma solidity ^0.8.0;

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
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
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

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Token is IERC20 {
    using SafeMath for uint256;

    struct Account {
        uint256 balance;
        uint256 lastDividendPoints;
    }

    string public constant name = "Token";
    string public constant symbol = "TKN";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => Account) accounts;
    mapping(address => mapping(address => uint256)) allowed;
    address public owner;
    address public dividendDistributor;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 _initialSupply) {
        owner = msg.sender;
        totalSupply = _initialSupply;
        accounts[owner].balance = _initialSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return accounts[account].balance;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(amount <= allowed[sender][msg.sender], "Allowance exceeded");
        allowed[sender][msg.sender] = allowed[sender][msg.sender].sub(amount);
        _transfer(sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return allowed[owner][spender];
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "Invalid address");
        require(amount <= accounts[from].balance, "Insufficient balance");

        uint256 senderDividendPoints = _calculateDividendPoints(from);
        uint256 recipientDividendPoints = _calculateDividendPoints(to);

        require(senderDividendPoints == 0 && recipientDividendPoints == 0, "Pending dividends");

        accounts[from].balance = accounts[from].balance.sub(amount);
        accounts[to].balance = accounts[to].balance.add(amount);

        accounts[to].lastDividendPoints = accounts[from].lastDividendPoints;

        emit Transfer(from, to, amount);
    }

    function _calculateDividendPoints(address account) internal view returns (uint256) {
        uint256 totalDividendPoints = totalSupply.sub(accounts[account].lastDividendPoints);
        uint256 accountDividendPoints = accounts[account].balance.mul(totalDividendPoints);
        return accountDividendPoints.div(totalSupply);
    }

    function claimDividends() public {
        uint256 owing = _calculateDividendPoints(msg.sender);
        if (owing > 0) {
            accounts[msg.sender].lastDividendPoints = totalSupply;
            payable(msg.sender).transfer(owing);
        }
    }

    function setDividendDistributor(address _dividendDistributor) public {
        require(msg.sender == owner, "Only owner can set dividend distributor");
        dividendDistributor = _dividendDistributor;
    }

    function distributeDividends() public payable {
        require(msg.sender == dividendDistributor, "Only dividend distributor can distribute dividends");
        totalSupply = totalSupply.add(msg.value);
    }

    receive() external payable {
        revert("Direct payments not allowed");
    }
}