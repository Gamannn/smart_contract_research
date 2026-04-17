pragma solidity ^0.5.11;

contract OwnerContract {
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    address payable owner;
    address payable newOwner;

    function setNewOwner(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function confirmNewOwner() public {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}

contract ERC20Interface {
    uint256 public totalSupply;

    function balanceOf(address account) view public returns (uint256 balance);
    function transfer(address to, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function approve(address spender, uint256 value) public returns (bool success);
    function allowance(address owner, address spender) view public returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Token is OwnerContract, ERC20Interface {
    string public name;
    string public symbol;
    uint8 public decimals;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    function balanceOf(address account) view public returns (uint256 balance) {
        return balances[account];
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balances[msg.sender] >= value && value > 0 && balances[to] + value > balances[to]);
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(balances[from] >= value && allowed[from][msg.sender] >= value && value > 0 && balances[to] + value > balances[to]);
        balances[from] -= value;
        allowed[from][msg.sender] -= value;
        balances[to] += value;
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) view public returns (uint256 remaining) {
        return allowed[owner][spender];
    }
}

contract MyToken is Token {
    constructor() public {
        name = "BOT";
        symbol = "MyToken";
        decimals = 8;
        totalSupply = 0;
        owner = msg.sender;
    }

    function getCurrentBlockNumber() public view returns (uint blockNumber) {
        return block.number;
    }

    function burnTokens(uint256 value) public returns (bool success) {
        require(value > 0 && balances[msg.sender] >= value && value * block.number <= address(this).balanceOf(address(this)));
        balances[msg.sender] -= value;
        totalSupply -= value;
        uint256 reward = value * block.number;
        uint256 fee = reward * 1 / 100;
        msg.sender.transfer(reward - fee);
        owner.transfer(fee);
        return true;
    }

    function () payable external {
        if (msg.value > 0) {
            uint256 tokens = msg.value / block.number;
            totalSupply += tokens;
            balances[msg.sender] += tokens;
        }
    }
}

function getBoolFunc(uint256 index) internal view returns (bool) {
    return _bool_constant[index];
}

function getStrFunc(uint256 index) internal view returns (string storage) {
    return _string_constant[index];
}

function getIntFunc(uint256 index) internal view returns (uint256) {
    return _integer_constant[index];
}

bool[] public _bool_constant = [true];
string[] public _string_constant = ["MyToken", "BOT"];
uint256[] public _integer_constant = [100, 0, 1, 8];