pragma solidity ^0.4.2;

contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract TokenRecipient {
    function receiveApproval(address from, uint256 value, address token, bytes extraData) public;
}

contract Token {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);

    function Token(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
    ) public {
        balanceOf[msg.sender] = initialSupply;
        totalSupply = initialSupply;
        name = tokenName;
        symbol = tokenSymbol;
        decimals = decimalUnits;
    }

    function transfer(address to, uint256 value) public {
        require(balanceOf[msg.sender] >= value);
        require(balanceOf[to] + value >= balanceOf[to]);
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        Transfer(msg.sender, to, value);
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(balanceOf[from] >= value);
        require(balanceOf[to] + value >= balanceOf[to]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        Transfer(from, to, value);
        return true;
    }

    function () public {
        revert();
    }
}

contract AdvancedToken is Ownable, Token {
    uint public sellPrice;
    uint public buyPrice;
    mapping(address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);

    function AdvancedToken(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
    ) Token(initialSupply, tokenName, decimalUnits, tokenSymbol) public {}

    function transfer(address to, uint256 value) public {
        require(balanceOf[msg.sender] >= value);
        require(balanceOf[to] + value >= balanceOf[to]);
        require(!frozenAccount[msg.sender]);
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        Transfer(msg.sender, to, value);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(!frozenAccount[from]);
        require(balanceOf[from] >= value);
        require(balanceOf[to] + value >= balanceOf[to]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        Transfer(from, to, value);
        return true;
    }

    function mintToken(address target, uint256 mintedAmount) public onlyOwner {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, owner, mintedAmount);
        Transfer(owner, target, mintedAmount);
    }

    function freezeAccount(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    function setPrices(uint newSellPrice, uint newBuyPrice) public onlyOwner {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    function buy() payable public {
        uint amount = msg.value / buyPrice;
        require(balanceOf[owner] >= amount);
        balanceOf[msg.sender] += amount;
        balanceOf[owner] -= amount;
        Transfer(owner, msg.sender, amount);
    }

    function sell(uint256 amount) public {
        require(balanceOf[msg.sender] >= amount);
        balanceOf[owner] += amount;
        balanceOf[msg.sender] -= amount;
        msg.sender.transfer(amount * sellPrice);
        Transfer(msg.sender, owner, amount);
    }
}