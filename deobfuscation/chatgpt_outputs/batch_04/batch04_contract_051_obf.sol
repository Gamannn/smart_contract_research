```solidity
pragma solidity ^0.5.0;

contract TokenContract {
    function transfer(TokenContract token, uint256 amount) public returns (bool);
    function transferFrom(address from, uint256 amount) public returns (bool);
    function approve(address spender, uint256 amount) public returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool);
    function totalSupply() public view returns (uint256);
    function balanceOf(address account) public view returns (uint256);
    function allowance(address owner, address spender) public view returns (uint256);
    function mint(uint256 amount) public returns (bool);
}

contract AccessControl {
    mapping(address => uint256) public accessLevels;
    event AccessLevelSet(address indexed user, uint256 level, address indexed admin);
    event AccessRevoked(address indexed user, uint256 level, address indexed admin);

    constructor() public {
        accessLevels[msg.sender] = 4;
    }

    modifier onlyAdmin() {
        require(accessLevels[msg.sender] >= 4, "Access level 4 required");
        _;
    }

    function setAccessLevel(address user, uint256 level) public onlyAdmin {
        require(accessLevels[user] < 4, "Cannot set access level for Admin Level Access User");
        require(level >= 0 && level <= 4, "Erroneous access level");
        accessLevels[user] = level;
        emit AccessLevelSet(user, level, msg.sender);
    }

    function revokeAccess(address user) public onlyAdmin {
        require(accessLevels[user] < 4, "Admin cannot revoke their own access");
        uint256 previousLevel = accessLevels[user];
        accessLevels[user] = 0;
        emit AccessRevoked(user, previousLevel, msg.sender);
    }

    function getAccessLevel(address user) public view returns (uint256) {
        return accessLevels[user];
    }

    function myAccessLevel() public view returns (uint256) {
        return getAccessLevel(msg.sender);
    }
}

contract ERC20Token is TokenContract {
    using SafeMath for uint256;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    uint256 private _totalSupply;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(0), "Transfer to the zero address");
        require(amount <= balances[msg.sender], "Transfer amount exceeds balance");

        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(0), "Transfer to the zero address");
        require(amount <= balances[sender], "Transfer amount exceeds balance");
        require(amount <= allowances[sender][msg.sender], "Transfer amount exceeds allowance");

        balances[sender] = balances[sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount);
        allowances[sender][msg.sender] = allowances[sender][msg.sender].sub(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        allowances[msg.sender][spender] = allowances[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = allowances[msg.sender][spender];
        if (subtractedValue > currentAllowance) {
            allowances[msg.sender][spender] = 0;
        } else {
            allowances[msg.sender][spender] = currentAllowance.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
        return true;
    }
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
```