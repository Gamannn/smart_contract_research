pragma solidity ^0.4.16;

contract MathOperations {
    function multiply(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 result = a * b;
        assert(a == 0 || result / a == b);
        return result;
    }

    function divide(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 result = a / b;
        assert(a == b * result + a % b);
        return result;
    }

    function subtract(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 result = a + b;
        assert(result >= a && result >= b);
        return result;
    }
}

contract Token is MathOperations {
    string public constant name = "Token";
    string public constant symbol = "TKN";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 1000000;
    uint256 public airdropSupply = 900000;
    address public owner;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public frozenBalance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);

    function Token() public {
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
    }

    function transfer(address to, uint256 value) public {
        require(to != 0x0);
        require(value > 0);
        require(balanceOf[msg.sender] >= value);
        require(balanceOf[to] + value > balanceOf[to]);

        balanceOf[msg.sender] = subtract(balanceOf[msg.sender], value);
        balanceOf[to] = add(balanceOf[to], value);
        Transfer(msg.sender, to, value);
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        require(value > 0);
        allowance[msg.sender][spender] = value;
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(to != 0x0);
        require(value > 0);
        require(balanceOf[from] >= value);
        require(balanceOf[to] + value > balanceOf[to]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] = subtract(balanceOf[from], value);
        balanceOf[to] = add(balanceOf[to], value);
        allowance[from][msg.sender] = subtract(allowance[from][msg.sender], value);
        Transfer(from, to, value);
        return true;
    }

    function burn(uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);
        require(value > 0);

        balanceOf[msg.sender] = subtract(balanceOf[msg.sender], value);
        totalSupply = subtract(totalSupply, value);
        Burn(msg.sender, value);
        return true;
    }

    function freeze(uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);
        require(value > 0);

        balanceOf[msg.sender] = subtract(balanceOf[msg.sender], value);
        frozenBalance[msg.sender] = add(frozenBalance[msg.sender], value);
        Freeze(msg.sender, value);
        return true;
    }

    function unfreeze(uint256 value) public returns (bool success) {
        require(frozenBalance[msg.sender] >= value);
        require(value > 0);

        frozenBalance[msg.sender] = subtract(frozenBalance[msg.sender], value);
        balanceOf[msg.sender] = add(balanceOf[msg.sender], value);
        Unfreeze(msg.sender, value);
        return true;
    }

    function withdrawEther(uint256 amount) public {
        require(msg.sender == owner);
        owner.transfer(amount);
    }

    function () external payable {
        require(balanceOf[address(this)] > 0);
        require(msg.value > 0);
        require(airdropSupply > 0);

        uint256 airdropAmount = 100; // Example airdrop amount
        balanceOf[msg.sender] = add(balanceOf[msg.sender], airdropAmount);
        airdropSupply = subtract(airdropSupply, airdropAmount);
        Transfer(address(this), msg.sender, airdropAmount);
    }
}