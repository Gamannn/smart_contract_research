pragma solidity ^0.4.8;

contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        require(a == b * c + a % b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        require(c >= a && c >= b);
        return c;
    }

    function require(bool condition) internal {
        if (!condition) {
            revert();
        }
    }
}

contract Token is SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public frozenBalance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);

    function Token(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
    ) {
        balanceOf[msg.sender] = initialSupply;
        totalSupply = initialSupply;
        name = tokenName;
        symbol = tokenSymbol;
        decimals = decimalUnits;
        owner = msg.sender;
    }

    function transfer(address to, uint256 value) {
        require(to != 0x0);
        require(value > 0);
        require(balanceOf[msg.sender] >= value);
        require(balanceOf[to] + value >= balanceOf[to]);

        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], value);
        balanceOf[to] = safeAdd(balanceOf[to], value);
        Transfer(msg.sender, to, value);
    }

    function approve(address spender, uint256 value) returns (bool success) {
        require(value > 0);
        allowance[msg.sender][spender] = value;
        return true;
    }

    function transferFrom(address from, address to, uint256 value) returns (bool success) {
        require(to != 0x0);
        require(value > 0);
        require(balanceOf[from] >= value);
        require(balanceOf[to] + value >= balanceOf[to]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] = safeSub(balanceOf[from], value);
        balanceOf[to] = safeAdd(balanceOf[to], value);
        allowance[from][msg.sender] = safeSub(allowance[from][msg.sender], value);
        Transfer(from, to, value);
        return true;
    }

    function burn(uint256 value) returns (bool success) {
        require(balanceOf[msg.sender] >= value);
        require(value > 0);

        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], value);
        totalSupply = safeSub(totalSupply, value);
        Burn(msg.sender, value);
        return true;
    }

    function freeze(uint256 value) returns (bool success) {
        require(balanceOf[msg.sender] >= value);
        require(value > 0);

        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], value);
        frozenBalance[msg.sender] = safeAdd(frozenBalance[msg.sender], value);
        Freeze(msg.sender, value);
        return true;
    }

    function unfreeze(uint256 value) returns (bool success) {
        require(frozenBalance[msg.sender] >= value);
        require(value > 0);

        frozenBalance[msg.sender] = safeSub(frozenBalance[msg.sender], value);
        balanceOf[msg.sender] = safeAdd(balanceOf[msg.sender], value);
        Unfreeze(msg.sender, value);
        return true;
    }

    function mint(uint256 value) {
        require(msg.sender == owner);
        balanceOf[msg.sender] = safeAdd(balanceOf[msg.sender], value);
        totalSupply = safeAdd(totalSupply, value);
    }

    function() payable {}
}