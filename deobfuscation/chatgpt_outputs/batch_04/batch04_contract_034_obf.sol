pragma solidity ^0.4.2;

contract Ownable {
    address public owner;

    function Ownable() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
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
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);

    function Token(uint256 initialSupply, string tokenName, uint8 decimalUnits, string tokenSymbol) {
        balanceOf[msg.sender] = initialSupply;
        totalSupply = initialSupply;
        name = tokenName;
        decimals = decimalUnits;
    }

    function transfer(address to, uint256 value) {
        if (balanceOf[msg.sender] < value) revert();
        if (balanceOf[to] + value < balanceOf[to]) revert();
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        Transfer(msg.sender, to, value);
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

    function transferFrom(address from, address to, uint256 value) returns (bool success) {
        if (balanceOf[from] < value) revert();
        if (balanceOf[to] + value < balanceOf[to]) revert();
        if (value > allowance[from][msg.sender]) revert();
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        Transfer(from, to, value);
        return true;
    }

    function () {
        revert();
    }
}

contract AdvancedToken is Ownable, Token {
    uint256 public sellPrice;
    uint256 public buyPrice;
    mapping(address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);

    function AdvancedToken(uint256 initialSupply, string tokenName, uint8 decimalUnits, string tokenSymbol) 
        Token(initialSupply, tokenName, decimalUnits, tokenSymbol) {}

    function transfer(address to, uint256 value) {
        if (balanceOf[msg.sender] < value) revert();
        if (balanceOf[to] + value < balanceOf[to]) revert();
        if (frozenAccount[msg.sender]) revert();
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        Transfer(msg.sender, to, value);
    }

    function transferFrom(address from, address to, uint256 value) returns (bool success) {
        if (frozenAccount[from]) revert();
        if (balanceOf[from] < value) revert();
        if (balanceOf[to] + value < balanceOf[to]) revert();
        if (value > allowance[from][msg.sender]) revert();
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        Transfer(from, to, value);
        return true;
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

    function buy() payable {
        uint amount = msg.value / buyPrice;
        if (balanceOf[this] < amount) revert();
        balanceOf[msg.sender] += amount;
        balanceOf[this] -= amount;
        Transfer(this, msg.sender, amount);
    }

    function sell(uint256 amount) {
        if (balanceOf[msg.sender] < amount) revert();
        balanceOf[this] += amount;
        balanceOf[msg.sender] -= amount;
        if (!msg.sender.send(amount * sellPrice)) {
            revert();
        } else {
            Transfer(msg.sender, this, amount);
        }
    }
}