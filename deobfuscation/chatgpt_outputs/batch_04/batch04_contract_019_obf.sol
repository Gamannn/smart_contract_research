```solidity
pragma solidity ^0.4.16;

contract Ownable {
    address public owner;

    function Ownable() public {
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
    function receiveApproval(address from, uint256 value, address token, bytes extraData) public;
}

contract Token {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    function Token(uint256 initialSupply, string tokenName, string tokenSymbol) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != 0x0);
        require(balanceOf[from] >= value);
        require(balanceOf[to] + value > balanceOf[to]);
        uint previousBalances = balanceOf[from] + balanceOf[to];
        balanceOf[from] -= value;
        balanceOf[to] += value;
        Transfer(from, to, value);
        assert(balanceOf[from] + balanceOf[to] == previousBalances);
    }

    function transfer(address to, uint256 value) public {
        _transfer(msg.sender, to, value);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(value <= allowance[from][msg.sender]);
        allowance[from][msg.sender] -= value;
        _transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        allowance[msg.sender][spender] = value;
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
        Burn(msg.sender, value);
        return true;
    }

    function burnFrom(address from, uint256 value) public returns (bool success) {
        require(balanceOf[from] >= value);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;
        allowance[from][msg.sender] -= value;
        totalSupply -= value;
        Burn(from, value);
        return true;
    }
}

contract MyAdvancedToken is Ownable, Token {
    uint256 public sellPrice;
    uint256 public buyPrice;
    mapping (address => bool) public frozenAccount;

    event FrozenFunds(address target, bool frozen);

    function MyAdvancedToken() Token(500000000, "TMET", "TMET") payable public {}

    function _transfer(address from, address to, uint256 value) internal {
        require(to != 0x0);
        require(balanceOf[from] >= value);
        require(balanceOf[to] + value > balanceOf[to]);
        require(!frozenAccount[from]);
        balanceOf[from] -= value;
        balanceOf[to] += value;
        Transfer(from, to, value);
    }

    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }

    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    function buy() payable public {
        uint amount = msg.value / buyPrice;
        _transfer(this, msg.sender, amount);
    }

    function () payable public {
        uint amount = msg.value * buyPrice;
        _transfer(owner, msg.sender, amount);
    }

    function selfDestruct() onlyOwner payable public {
        selfdestruct(owner);
    }

    function withdrawEther(uint amount) onlyOwner payable public {
        owner.transfer(amount);
    }

    function balanceOf(address account) public constant returns (uint256) {
        return balanceOf[account];
    }
}
```