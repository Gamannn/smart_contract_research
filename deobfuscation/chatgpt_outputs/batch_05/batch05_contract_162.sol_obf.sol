pragma solidity ^0.4.24;

contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

interface TokenRecipient {
    function receiveApproval(address from, uint256 value, address token, bytes extraData) public;
}

contract LeimenCoin is Ownable {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public frozenAccount;

    string public name = "Leimen coin";
    string public symbol = "Lem";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public sellPrice;
    bool public stopped = false;
    bool public sellAllowed = true;

    event FrozenFunds(address target, bool frozen);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function freezeAccount(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    function setName(string newName) public onlyOwner {
        name = newName;
    }

    function setSymbol(string newSymbol) public onlyOwner {
        symbol = newSymbol;
    }

    function setSellAllowed(bool allowed) public onlyOwner {
        sellAllowed = allowed;
    }

    function stopContract() public onlyOwner {
        stopped = true;
    }

    function startContract() public onlyOwner {
        stopped = false;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(!frozenAccount[from]);
        require(!stopped);
        require(to != 0x0);
        require(value > 0);
        require(balanceOf[from] >= value);
        require(balanceOf[to] + value > balanceOf[to]);

        uint256 previousBalances = balanceOf[from] + balanceOf[to];
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
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
        TokenRecipient recipient = TokenRecipient(spender);
        if (approve(spender, value)) {
            recipient.receiveApproval(msg.sender, value, this, extraData);
            return true;
        }
    }

    function () payable public {
        buy();
    }

    function buy() payable public returns (uint256 amount) {
        require(sellPrice != 0);
        require(sellAllowed);
        amount = msg.value / sellPrice * 100;
        require(balanceOf[this] >= amount);
        balanceOf[msg.sender] += amount;
        balanceOf[this] -= amount;
        emit Transfer(this, msg.sender, amount);
        return amount;
    }
}