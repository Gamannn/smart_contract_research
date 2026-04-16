```solidity
pragma solidity ^0.4.21;

interface IERC777TokensRecipient {
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

interface IERC777 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function balanceOf(address holder) external view returns (uint256);
    function transfer(address to, uint256 amount) external;
    function transfer(address to, uint256 amount, bytes calldata data) external;
    function burn(uint256 amount, bytes calldata data) external;
    function isOperatorFor(address operator, address holder) external view returns (bool);
    function authorizeOperator(address operator) external;
    function revokeOperator(address operator) external;
    function defaultOperators() external view returns (address[] memory);
    function operatorSend(
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
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

    function max(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

contract Ownable {
    address public owner;

    modifier onlyOwner() {
        require(isOwner(msg.sender));
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function isOwner(address account) public view returns (bool) {
        return owner == account;
    }
}

contract TokenVault is Ownable {
    using SafeMath for uint256;

    event Deposited(address indexed depositor, address indexed token, uint256 amount);
    event Withdrawn(address indexed withdrawer, address indexed token, uint256 amount);
    event Approved(address indexed owner, address indexed spender);
    event Unapproved(address indexed owner, address indexed spender);
    event AddedSpender(address indexed spender);
    event RemovedSpender(address indexed spender);

    address constant public ETH_ADDRESS = 0x0;
    
    mapping(address => bool) public isERC777;
    mapping(address => mapping(address => uint256)) private allowances;
    mapping(address => uint256) private totalBalances;
    mapping(address => bool) private spenders;
    mapping(address => mapping(address => bool)) private approvals;
    
    address private latestSpender;

    modifier onlySpender() {
        require(spenders[msg.sender]);
        _;
    }

    modifier onlyApproved(address spender) {
        require(approvals[msg.sender][spender]);
        _;
    }

    constructor(IERC777TokensRecipient registry) public {
        registry.tokensReceived(address(this), keccak256("ERC777TokensRecipient"), address(this));
    }

    function deposit(address token, uint256 amount) external payable {
        require(token == ETH_ADDRESS || msg.value == 0);
        
        uint256 actualAmount = amount;
        
        if (token == ETH_ADDRESS) {
            actualAmount = msg.value;
        } else {
            require(IERC20(token).transferFrom(msg.sender, address(this), actualAmount));
        }
        
        _addDeposit(msg.sender, token, actualAmount);
    }

    function withdraw(address token, uint256 amount) external {
        require(allowance(token, msg.sender) >= amount);
        
        allowances[token][msg.sender] = allowances[token][msg.sender].sub(amount);
        totalBalances[token] = totalBalances[token].sub(amount);
        
        _transferOut(msg.sender, token, amount);
        emit Withdrawn(msg.sender, token, amount);
    }

    function approve(address spender) external {
        require(spenders[spender]);
        approvals[msg.sender][spender] = true;
        emit Approved(msg.sender, spender);
    }

    function unapprove(address spender) external {
        approvals[msg.sender][spender] = false;
        emit Unapproved(msg.sender, spender);
    }

    function addSpender(address spender) external onlyOwner {
        require(spender != address(0));
        spenders[spender] = true;
        latestSpender = spender;
        emit AddedSpender(spender);
    }

    function removeSpender(address spender) external onlyOwner {
        spenders[spender] = false;
        emit RemovedSpender(spender);
    }

    function transferAllowance(
        address token,
        address from,
        address to,
        uint256 amount
    ) external onlySpender onlyApproved(from) {
        require(amount > 0);
        
        allowances[token][from] = allowances[token][from].sub(amount);
        allowances[token][to] = allowances[token][to].add(amount);
    }

    function isApproved(address owner, address spender) external view returns (bool) {
        return approvals[owner][spender];
    }

    function isSpender(address spender) external view returns (bool) {
        return spenders[spender];
    }

    function getLatestSpender() external view returns (address) {
        return latestSpender;
    }

    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata,
        bytes calldata
    ) external {
        if (!isERC777[msg.sender]) {
            isERC777[msg.sender] = true;
        }
        _addDeposit(from, msg.sender, amount);
    }

    function markAsERC777(address token) public onlyOwner {
        isERC777[token] = true;
    }

    function unmarkAsERC777(address token) public onlyOwner {
        isERC777[token] = false;
    }

    function withdrawAll(address token) public onlyOwner {
        _transferOut(msg.sender, token, availableBalance(token));
    }

    function allowance(address token, address owner) public view returns (uint256) {
        return allowances[token][owner];
    }

    function availableBalance(address token) internal view returns (uint256) {
        if (token == ETH_ADDRESS) {
            return address(this).balance.sub(totalBalances[token]);
        }
        return IERC20(token).balanceOf(address(this)).sub(totalBalances[token]);
    }

    function _addDeposit(address depositor, address token, uint256 amount) private {
        allowances[token][depositor] = allowances[token][depositor].add(amount);
        totalBalances[token] = totalBalances[token].add(amount);
        emit Deposited(depositor, token, amount);
    }

    function _transferOut(address recipient, address token, uint256 amount) private {
        if (token == ETH_ADDRESS) {
            recipient.transfer(amount);
            return;
        }
        
        if (isERC777[token]) {
            IERC777(token).transfer(recipient, amount);
            return;
        }
        
        require(IERC20(token).transfer(recipient, amount));
    }
}
```