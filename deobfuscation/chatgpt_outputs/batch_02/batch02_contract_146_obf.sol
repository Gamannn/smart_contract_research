```solidity
pragma solidity ^0.4.13;

contract BaseContract {
    address public owner;
    address public operator;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator);
        _;
    }

    modifier onlyOwnerOrOperator() {
        require(msg.sender == owner || msg.sender == operator);
        _;
    }

    function setOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

    function setOperator(address newOperator) public onlyOwner {
        require(newOperator != address(0));
        operator = newOperator;
    }

    function transfer(address to, uint256 amount) external onlyOwnerOrOperator {
        require(amount > 0);
        require(amount <= this.balance);
        require(to != address(0));
        to.transfer(amount);
    }

    function () external payable {}
}

contract Pausable is BaseContract {
    bool public paused;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    function pause() external onlyOwnerOrOperator {
        paused = true;
    }

    function unpause() public onlyOwner {
        paused = false;
    }
}

contract Exchange is Pausable {
    address internal exchangeAddress;

    function setExchangeAddress(address newExchangeAddress) external onlyOwnerOrOperator {
        exchangeAddress = newExchangeAddress;
    }

    function executeExchange() public {
        require(exchangeAddress != address(0));
        super.executeExchange();
    }

    function callExchange(bytes data) external onlyOwnerOrOperator {
        require(exchangeAddress.call(data));
    }
}

contract Token is BaseContract {
    uint8 constant FEE_RATE = 5;
    uint256 public exchangeRate;

    function Token() public {
        owner = msg.sender;
        exchangeRate = 1000000000000 wei;
        paused = true;
    }

    function setExchangeRate(uint256 newRate) external onlyOwnerOrOperator {
        exchangeRate = newRate;
    }

    function withdraw(address to, uint256 amount) public whenNotPaused {
        require(exchangeAddress.call(bytes4(keccak256("transfer(address,uint256)")), to, amount));
        uint256 fee = (amount / 100) * (100 - FEE_RATE);
        to.transfer(fee);
    }

    function () external payable {
        revert();
    }
}

contract GoCryptobotCoin is Token {
    using SafeMath for uint256;

    string public constant name = "GoCryptobotCoin";
    string public constant symbol = "GCC";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        Transfer(msg.sender, to, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balances[from]);
        require(value <= allowed[from][msg.sender]);

        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        Transfer(from, to, value);
        return true;
    }

    function increaseApproval(address spender, uint256 addedValue) public returns (bool) {
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);
        Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function decreaseApproval(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 oldValue = allowed[msg.sender][spender];
        if (subtractedValue > oldValue) {
            allowed[msg.sender][spender] = 0;
        } else {
            allowed[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        Approval(msg.sender, spender, allowed[msg.sender][spender]);
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
        uint256 c = a / b;
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
}
```