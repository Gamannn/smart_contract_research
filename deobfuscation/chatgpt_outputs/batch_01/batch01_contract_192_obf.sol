pragma solidity ^0.4.13;

contract Owned {
    address public owner;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract TokenRecipient {
    function receiveApproval(address from, uint256 value, address token, bytes extraData);
}

contract Token {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    function Token(uint256 initialSupply, string tokenName, uint8 decimalUnits, string tokenSymbol) {
        balanceOf[address(this)] = initialSupply;
        totalSupply = initialSupply;
        name = tokenName;
        symbol = tokenSymbol;
        decimals = decimalUnits;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != 0x0);
        require(balanceOf[from] >= value);
        require(balanceOf[to] + value > balanceOf[to]);
        balanceOf[from] -= value;
        balanceOf[to] += value;
        Transfer(from, to, value);
    }

    function transfer(address to, uint256 value) {
        _transfer(msg.sender, to, value);
    }

    function transferFrom(address from, address to, uint256 value) returns (bool success) {
        require(value <= allowance[from][msg.sender]);
        allowance[from][msg.sender] -= value;
        _transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) returns (bool success) {
        allowance[msg.sender][spender] = value;
        return true;
    }

    function approveAndCall(address spender, uint256 value, bytes extraData) returns (bool success) {
        TokenRecipient recipient = TokenRecipient(spender);
        if (approve(spender, value)) {
            recipient.receiveApproval(msg.sender, value, this, extraData);
            return true;
        }
    }

    function burn(uint256 value) returns (bool success) {
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;
        totalSupply -= value;
        Burn(msg.sender, value);
        return true;
    }

    function burnFrom(address from, uint256 value) returns (bool success) {
        require(balanceOf[from] >= value);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;
        allowance[from][msg.sender] -= value;
        totalSupply -= value;
        Burn(from, value);
        return true;
    }
}

contract MyAdvancedToken is Owned, Token {
    mapping (address => bool) public frozenAccount;

    event FrozenFunds(address target, bool frozen);

    function MyAdvancedToken(uint256 initialSupply, string tokenName, uint8 decimalUnits, string tokenSymbol) 
        Token(initialSupply, tokenName, decimalUnits, tokenSymbol) {}

    function _transfer(address from, address to, uint256 value) internal {
        require(to != 0x0);
        require(balanceOf[from] >= value);
        require(balanceOf[to] + value > balanceOf[to]);
        require(!frozenAccount[from]);
        require(!frozenAccount[to]);
        balanceOf[from] -= value;
        balanceOf[to] += value;
        Transfer(from, to, value);
    }

    function mintToken(address target, uint256 mintedAmount) onlyOwner {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }

    function freezeAccount(address target, bool freeze) onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    function () payable {
        uint256 amount = msg.value / buyPrice;
        _transfer(this, msg.sender, amount);
    }

    function sell(uint256 amount) {
        require(this.balance >= amount * sellPrice);
        _transfer(msg.sender, this, amount);
        msg.sender.transfer(amount * sellPrice);
    }

    uint256 public sellPrice;
    uint256 public buyPrice;
}

contract NeuroToken is MyAdvancedToken {
    uint256 public frozenTokensSupply;

    function NeuroToken() MyAdvancedToken(17500000, "NeuroToken", 0, "NRT") {
        freezeTokens(17437000);
    }

    function freezeTokens(uint256 frozenAmount) onlyOwner {
        require(balanceOf[address(this)] >= frozenAmount);
        frozenTokensSupply += frozenAmount;
        balanceOf[address(this)] -= frozenAmount;
    }

    function releaseTokens(uint256 releasedAmount) onlyOwner {
        require(frozenTokensSupply >= releasedAmount);
        frozenTokensSupply -= releasedAmount;
        balanceOf[address(this)] += releasedAmount;
    }

    function safeWithdrawal(address target, uint256 amount) onlyOwner {
        require(this.balance >= amount);
        target.transfer(amount);
    }
}