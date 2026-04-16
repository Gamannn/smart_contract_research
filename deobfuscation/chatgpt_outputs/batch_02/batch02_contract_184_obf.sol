```solidity
pragma solidity ^0.4.21;

interface ITokenManager {
    event Deposited(address indexed from, address token, uint amount);
    event Withdrawn(address indexed from, address token, uint amount);
    event Approved(address indexed owner, address indexed spender);
    event Unapproved(address indexed owner, address indexed spender);
    event AddedSpender(address indexed spender);
    event RemovedSpender(address indexed spender);

    function deposit(address token, uint amount) external payable;
    function withdraw(address token, uint amount) external;
    function transfer(address token, address from, address to, uint amount) external;
    function approveSpender(address spender) external;
    function unapproveSpender(address spender) external;
    function isApproved(address owner, address spender) external view returns (bool);
    function addSpender(address spender) external;
    function removeSpender(address spender) external;
    function getSpender() external view returns (address);
    function isSpender(address spender) external view returns (bool);
    function executeTransaction(address to, uint value, bytes data) public;
    function balanceOf(address token, address owner) public view returns (uint);
}

interface ITokenRecipient {
    function tokensReceived(address operator, bytes32 data, address from) public;
}

library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max(uint a, uint b) internal pure returns (uint) {
        return a >= b ? a : b;
    }

    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }
}

contract Ownable {
    address public owner;

    modifier onlyOwner() {
        require(isOwner(msg.sender));
        _;
    }

    function Ownable() public {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function isOwner(address account) public view returns (bool) {
        return owner == account;
    }
}

interface IToken {
    function totalSupply() public view returns (uint256);
    function balanceOf(address owner) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
}

contract TokenManager is Ownable, ITokenManager {
    using SafeMath for uint;

    address constant public ZERO_ADDRESS = 0x0;
    mapping(address => bool) public approvedTokens;
    mapping(address => mapping(address => mapping(address => uint))) private balances;
    mapping(address => uint) private totalBalances;
    mapping(address => bool) private spenders;
    address private currentSpender;

    modifier onlySpender() {
        require(spenders[msg.sender]);
        _;
    }

    function TokenManager(ITokenRecipient tokenRecipient) public {
        tokenRecipient.tokensReceived(address(this), keccak256("ERC777TokensRecipient"), address(this));
    }

    function deposit(address token, uint amount) external payable {
        require(token == ZERO_ADDRESS || msg.value == 0);
        uint depositAmount = amount;
        if (token == ZERO_ADDRESS) {
            depositAmount = msg.value;
        } else {
            require(IToken(token).transferFrom(msg.sender, address(this), depositAmount));
        }
        _deposit(msg.sender, token, depositAmount);
    }

    function withdraw(address token, uint amount) external {
        require(balanceOf(token, msg.sender) >= amount);
        balances[token][msg.sender][msg.sender] = balances[token][msg.sender][msg.sender].sub(amount);
        totalBalances[token] = totalBalances[token].sub(amount);
        _withdraw(msg.sender, token, amount);
        emit Withdrawn(msg.sender, token, amount);
    }

    function approveSpender(address spender) external {
        require(spenders[spender]);
        balances[msg.sender][spender][spender] = true;
        emit Approved(msg.sender, spender);
    }

    function unapproveSpender(address spender) external {
        balances[msg.sender][spender][spender] = false;
        emit Unapproved(msg.sender, spender);
    }

    function addSpender(address spender) external onlyOwner {
        require(spender != ZERO_ADDRESS);
        spenders[spender] = true;
        currentSpender = spender;
        emit AddedSpender(spender);
    }

    function removeSpender(address spender) external onlyOwner {
        spenders[spender] = false;
        emit RemovedSpender(spender);
    }

    function transfer(address token, address from, address to, uint amount) external onlySpender {
        require(amount > 0);
        balances[token][from][to] = balances[token][from][to].sub(amount);
        balances[token][from][to] = balances[token][from][to].add(amount);
    }

    function isApproved(address owner, address spender) external view returns (bool) {
        return balances[owner][spender][spender];
    }

    function isSpender(address spender) external view returns (bool) {
        return spenders[spender];
    }

    function getSpender() external view returns (address) {
        return currentSpender;
    }

    function executeTransaction(address to, uint value, bytes data) public {
        _deposit(to, msg.sender, value);
    }

    function balanceOf(address token, address owner) public view returns (uint) {
        return balances[token][owner][owner];
    }

    function _deposit(address from, address token, uint amount) private {
        balances[token][from][from] = balances[token][from][from].add(amount);
        totalBalances[token] = totalBalances[token].add(amount);
        emit Deposited(from, token, amount);
    }

    function _withdraw(address from, address token, uint amount) private {
        if (token == ZERO_ADDRESS) {
            from.transfer(amount);
            return;
        }
        if (approvedTokens[token]) {
            IToken(token).transfer(from, amount);
            return;
        }
        require(IToken(token).transfer(from, amount));
    }
}
```