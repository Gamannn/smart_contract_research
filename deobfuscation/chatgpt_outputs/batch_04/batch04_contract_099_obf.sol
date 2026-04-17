pragma solidity ^0.4.4;

contract TokenInterface {
    function totalSupply() constant returns (uint256 totalTokens);
    function balanceOf(address owner) constant returns (uint256 balance);
    function transfer(address to, uint256 value) returns (bool success);
    function transferFrom(address from, address to, uint256 value) returns (bool success);
    function approve(address spender, uint256 value) returns (bool success);
    function allowance(address owner, address spender) constant returns (uint256 remaining);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Token is TokenInterface {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
    string public name;
    uint8 public decimals;
    string public symbol;
    uint256 public unitsOneEthCanBuy;
    address public fundsWallet;

    function Token() {
        balances[msg.sender] = 20000000;
        totalSupply = 20000000;
        name = "ExampleToken";
        decimals = 18;
        symbol = "EXT";
        unitsOneEthCanBuy = 20;
        fundsWallet = msg.sender;
    }

    function totalSupply() constant returns (uint256) {
        return totalSupply;
    }

    function balanceOf(address owner) constant returns (uint256) {
        return balances[owner];
    }

    function transfer(address to, uint256 value) returns (bool success) {
        if (balances[msg.sender] >= value && value > 0) {
            balances[msg.sender] -= value;
            balances[to] += value;
            Transfer(msg.sender, to, value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address from, address to, uint256 value) returns (bool success) {
        if (balances[from] >= value && allowed[from][msg.sender] >= value && value > 0) {
            balances[to] += value;
            balances[from] -= value;
            allowed[from][msg.sender] -= value;
            Transfer(from, to, value);
            return true;
        } else {
            return false;
        }
    }

    function approve(address spender, uint256 value) returns (bool success) {
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) constant returns (uint256 remaining) {
        return allowed[owner][spender];
    }

    function() payable {
        totalSupply += msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        if (balances[fundsWallet] < amount) {
            return;
        }
        balances[fundsWallet] -= amount;
        balances[msg.sender] += amount;
        Transfer(fundsWallet, msg.sender, amount);
        fundsWallet.transfer(msg.value);
    }

    function approveAndCall(address spender, uint256 value, bytes extraData) returns (bool success) {
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        if (!spender.call(bytes4(keccak256("receiveApproval(address,uint256,address,bytes)")), msg.sender, value, this, extraData)) {
            return false;
        }
        return true;
    }
}