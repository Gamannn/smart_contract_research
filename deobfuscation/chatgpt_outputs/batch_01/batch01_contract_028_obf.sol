```solidity
pragma solidity ^0.4.25;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
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

contract CRP_ERC20 is Owned {
    using SafeMath for uint256;

    string public name = "Chiwoo Rotary Press";
    string public symbol = "CRP";
    uint8 public decimals = 18;
    uint256 public totalSupply = 8000000000 * 10 ** uint256(decimals);

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;

    bool public sellTokenAllowed = true;
    uint256 public tokenPerETHBuy = 1000;
    uint256 public tokenPerETHSell = 1000;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event BuyRateChanged(uint256 oldValue, uint256 newValue);
    event SellRateChanged(uint256 oldValue, uint256 newValue);
    event BuyToken(address user, uint256 eth, uint256 token);
    event SellToken(address user, uint256 eth, uint256 token);
    event FrozenFunds(address target, bool frozen);
    event SellTokenAllowedEvent(bool isAllowed);

    constructor() public {
        balanceOf[owner] = totalSupply;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != 0x0);
        require(balanceOf[from] >= value);
        require(balanceOf[to].add(value) > balanceOf[to]);
        require(!frozenAccount[from]);
        require(!frozenAccount[to]);

        uint256 previousBalances = balanceOf[from].add(balanceOf[to]);
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
        assert(balanceOf[from].add(balanceOf[to]) == previousBalances);
    }

    function transfer(address to, uint256 value) public {
        _transfer(msg.sender, to, value);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(value <= allowance[from][msg.sender]);
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        return true;
    }

    function approveAndCall(address spender, uint256 value, bytes extraData) public returns (bool success) {
        TokenRecipient recipient = TokenRecipient(spender);
        if (approve(spender, value)) {
            recipient.receiveApproval(msg.sender, value, this, extraData);
            return true;
        }
    }

    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] = balanceOf[target].add(mintedAmount);
        totalSupply = totalSupply.add(mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }

    function burn(uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Burn(msg.sender, value);
        return true;
    }

    function burnFrom(address from, uint256 value) public returns (bool success) {
        require(balanceOf[from] >= value);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] = balanceOf[from].sub(value);
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Burn(from, value);
        return true;
    }

    function setBuyRate(uint256 newBuyRate) onlyOwner public {
        require(newBuyRate > 0);
        emit BuyRateChanged(tokenPerETHBuy, newBuyRate);
        tokenPerETHBuy = newBuyRate;
    }

    function setSellRate(uint256 newSellRate) onlyOwner public {
        require(newSellRate > 0);
        emit SellRateChanged(tokenPerETHSell, newSellRate);
        tokenPerETHSell = newSellRate;
    }

    function buy() payable public returns (uint amount) {
        require(msg.value > 0);
        require(!frozenAccount[msg.sender]);

        amount = msg.value.mul(tokenPerETHBuy).mul(10 ** uint256(decimals)).div(1 ether);
        balanceOf[this] = balanceOf[this].sub(amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
        emit Transfer(this, msg.sender, amount);
        return amount;
    }

    function sell(uint amount) public returns (uint revenue) {
        require(balanceOf[msg.sender] >= amount);
        require(sellTokenAllowed);
        require(!frozenAccount[msg.sender]);

        balanceOf[this] = balanceOf[this].add(amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);
        revenue = amount.mul(1 ether).div(tokenPerETHSell.mul(10 ** uint256(decimals)));
        msg.sender.transfer(revenue);
        emit Transfer(msg.sender, this, amount);
        return revenue;
    }

    function deposit() public payable {}

    function withdraw(uint withdrawAmount) onlyOwner public {
        if (withdrawAmount <= address(this).balance) {
            owner.transfer(withdrawAmount);
        }
    }

    function () public payable {
        buy();
    }

    function enableSellToken() onlyOwner public {
        sellTokenAllowed = true;
        emit SellTokenAllowedEvent(true);
    }

    function disableSellToken() onlyOwner public {
        sellTokenAllowed = false;
        emit SellTokenAllowedEvent(false);
    }
}
```