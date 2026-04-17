```solidity
pragma solidity ^0.4.23;

contract TokenContract {
    address public owner;
    mapping(address => uint256) balances;
    string public name = "chuangjiu";
    string public symbol = "CJ";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    bool public isActive = true;
    uint256 public directDropRate = 1000;
    address public directDropAddress = 0x587b13913F4c708A4F033318056E4b6BA956A6F5;
    bool public isDirectDropActive = false;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed burner, uint256 value);

    mapping(address => mapping(address => uint256)) internal allowances;

    constructor() public {
        owner = msg.sender;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balances[msg.sender]);

        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balances[from]);
        require(value <= allowances[from][msg.sender]);

        balances[from] -= value;
        balances[to] += value;
        allowances[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        allowances[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = allowances[msg.sender][spender];
        if (subtractedValue > currentAllowance) {
            allowances[msg.sender][spender] = 0;
        } else {
            allowances[msg.sender][spender] -= subtractedValue;
        }
        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
        return true;
    }

    function burn(uint256 value) public {
        require(value <= balances[msg.sender]);
        balances[msg.sender] -= value;
        totalSupply -= value;
        emit Burn(msg.sender, value);
        emit Transfer(msg.sender, address(0), value);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address newOwner) public onlyOwner returns (bool) {
        require(newOwner != address(0));
        owner = newOwner;
        return true;
    }

    function setActive(bool active) public onlyOwner returns (bool) {
        isActive = active;
        return true;
    }

    function withdraw() public {
        require(address(this).balance > 0);
        owner.transfer(address(this).balance);
    }

    function () external payable {
        // Fallback function
    }

    function multiply(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function divide(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function subtract(uint256 a, uint256 b) internal pure returns (uint256) {
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