pragma solidity ^0.4.16;

contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface TokenRecipient {
    function receiveApproval(address from, uint256 value, address token, bytes extraData) external;
}

contract Token {
    string public name;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);

    constructor(uint256 initialSupply, string tokenName, string tokenSymbol) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
    }

    function _transfer(address from, address to, uint value) internal {
        require(to != 0x0);
        require(balanceOf[from] >= value);
        require(balanceOf[to] + value > balanceOf[to]);

        uint previousBalances = balanceOf[from] + balanceOf[to];
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
        assert(balanceOf[from] + balanceOf[to] == previousBalances);
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(value <= allowance[from][msg.sender]);
        allowance[from][msg.sender] -= value;
        _transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function approveAndCall(address spender, uint256 value, bytes extraData) public returns (bool success) {
        TokenRecipient spenderContract = TokenRecipient(spender);
        if (approve(spender, value)) {
            spenderContract.receiveApproval(msg.sender, value, this, extraData);
            return true;
        }
    }

    function burn(uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;
        totalSupply -= value;
        emit Burn(msg.sender, value);
        return true;
    }

    function burnFrom(address from, uint256 value) public returns (bool success) {
        require(balanceOf[from] >= value);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;
        allowance[from][msg.sender] -= value;
        totalSupply -= value;
        emit Burn(from, value);
        return true;
    }
}

contract AdvancedToken is Ownable, Token {
    uint256 public sellPrice;
    uint256 public buyPrice;
    mapping(address => bool) public frozenAccount;

    event FrozenFunds(address target, bool frozen);

    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }

    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    function buy() payable public {
        uint amount = msg.value / buyPrice;
        _transfer(this, msg.sender, amount);
    }

    function sell(uint256 amount) public {
        address myAddress = this;
        require(myAddress.balance >= amount * sellPrice);
        _transfer(msg.sender, this, amount);
        msg.sender.transfer(amount * sellPrice);
    }
}