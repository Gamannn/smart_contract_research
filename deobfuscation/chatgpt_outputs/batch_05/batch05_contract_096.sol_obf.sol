```solidity
pragma solidity ^0.4.18;

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
        if (msg.sender != owner) return;
        owner = newOwner;
    }
}

interface TokenRecipient {
    function receiveApproval(address from, uint256 value, address token, bytes extraData) public;
}

contract Token is Ownable {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public buyPrice;
    uint256 public amountRaised;
    bool public crowdsaleClosed = false;
    string constant tokenName = "DUDE";
    uint256 constant initialSupply = 1000000000000;
    uint constant durationInMinutes = 259200;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => uint256) public balanceOf;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);

    function Token() public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[this] = initialSupply * 8 * (10 ** uint256(decimals - 1));
        balanceOf[msg.sender] = initialSupply * 2 * (10 ** uint256(decimals - 1));
        name = tokenName;
        symbol = tokenName;
        buyPrice = initialSupply;
        amountRaised = 0;
    }

    modifier afterDeadline() {
        require(now >= durationInMinutes);
        _;
    }

    function finalizeCrowdsale() public afterDeadline {
        owner.transfer(amountRaised);
        amountRaised = 0;
        crowdsaleClosed = true;
    }

    function _transfer(address from, address to, uint value) internal {
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
        Approval(msg.sender, spender, value);
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

    function setPrices(uint256 newBuyPrice) public onlyOwner {
        buyPrice = newBuyPrice;
    }

    function () payable public {
        require(!crowdsaleClosed);
        uint256 amount = (msg.value * 1 ether) / buyPrice;
        require(balanceOf[this] >= amount);
        balanceOf[msg.sender] += amount;
        balanceOf[this] -= amount;
        Transfer(this, msg.sender, amount);
        amountRaised += msg.value;
        if (amountRaised >= 0.5 * 1 ether) {
            owner.transfer(amountRaised);
            amountRaised = 0;
        }
    }

    function getTotalSupply() public constant returns (uint256) {
        return totalSupply;
    }

    function balanceOf(address account) public constant returns (uint256) {
        return balanceOf[account];
    }

    function allowance(address owner, address spender) public constant returns (uint256) {
        return allowance[owner][spender];
    }
}
```