pragma solidity ^0.5.11;

contract MathOperations {
    function multiply(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 result = a * b;
        assert(result / a == b);
        return result;
    }

    function divide(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "Division by zero");
        uint256 result = a / b;
        return result;
    }

    function subtract(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 result = a + b;
        assert(result >= a);
        return result;
    }
}

contract ERC20Interface {
    function transfer(address to, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function approve(address spender, uint256 value) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Token is ERC20Interface, MathOperations {
    string public name;
    string public symbol;
    uint8 public decimals;
    address payable public owner;
    address public admin;
    bool public paused = false;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public frozenBalance;

    event Burn(address indexed from, uint256 value);
    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);
    event Pause(address indexed by);
    event Unpause(address indexed by);

    constructor(
        uint256 initialSupply,
        string memory tokenName,
        uint8 decimalUnits,
        string memory tokenSymbol,
        address adminAddress
    ) public {
        balanceOf[msg.sender] = initialSupply;
        totalSupply = initialSupply;
        name = tokenName;
        symbol = tokenSymbol;
        decimals = decimalUnits;
        owner = msg.sender;
        admin = adminAddress;
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(!paused, "Contract is paused");
        require(to != address(0), "Invalid address");
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        require(balanceOf[to] + value >= balanceOf[to], "Overflow error");

        balanceOf[msg.sender] = subtract(balanceOf[msg.sender], value);
        balanceOf[to] = add(balanceOf[to], value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        require(!paused, "Contract is paused");
        require(value > 0, "Invalid value");

        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(!paused, "Contract is paused");
        require(to != address(0), "Invalid address");
        require(value > 0, "Invalid value");
        require(balanceOf[from] >= value, "Insufficient balance");
        require(balanceOf[to] + value >= balanceOf[to], "Overflow error");
        require(value <= allowance[from][msg.sender], "Allowance exceeded");

        balanceOf[from] = subtract(balanceOf[from], value);
        balanceOf[to] = add(balanceOf[to], value);
        allowance[from][msg.sender] = subtract(allowance[from][msg.sender], value);
        emit Transfer(from, to, value);
        return true;
    }

    function burn(uint256 value) public returns (bool success) {
        require(!paused, "Contract is paused");
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        balanceOf[msg.sender] = subtract(balanceOf[msg.sender], value);
        totalSupply = subtract(totalSupply, value);
        emit Burn(msg.sender, value);
        return true;
    }

    function freeze(address target, uint256 value) public returns (bool success) {
        require(!paused, "Contract is paused");
        require(msg.sender == owner || msg.sender == admin, "No permission");
        require(balanceOf[target] >= value, "Insufficient balance");

        balanceOf[target] = subtract(balanceOf[target], value);
        frozenBalance[target] = add(frozenBalance[target], value);
        emit Freeze(target, value);
        return true;
    }

    function unfreeze(address target, uint256 value) public returns (bool success) {
        require(!paused, "Contract is paused");
        require(msg.sender == owner || msg.sender == admin, "No permission");
        require(frozenBalance[target] >= value, "Insufficient frozen balance");

        frozenBalance[target] = subtract(frozenBalance[target], value);
        balanceOf[target] = add(balanceOf[target], value);
        emit Unfreeze(target, value);
        return true;
    }

    function transferOwnership(uint256 newOwner) public {
        require(msg.sender == owner, "No permission");
        owner = address(newOwner);
    }

    function() external payable {}

    function pause() public {
        require(msg.sender == owner || msg.sender == admin, "No permission");
        paused = true;
        emit Pause(msg.sender);
    }

    function unpause() public {
        require(msg.sender == owner || msg.sender == admin, "No permission");
        paused = false;
        emit Unpause(msg.sender);
    }
}