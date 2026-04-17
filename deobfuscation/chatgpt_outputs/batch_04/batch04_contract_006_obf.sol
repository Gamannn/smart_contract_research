```solidity
pragma solidity ^0.4.20;

contract ExternalContract {
    function externalFunction(address from, uint256 value, address to, bytes data) public;
}

contract EthereumCashPro {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;
    address public backupAddress;
    uint256 public tokenPrice;
    uint256 public icoTokenPrice;
    uint256 public amountCollected;
    uint256 public remainingTokens;
    uint256 public maxSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public frozenAccount;

    event FrozenFunds(address target, bool frozen);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event TransferSell(address indexed from, address indexed to, uint256 value, string note);

    function EthereumCashPro() public {
        totalSupply = 200000000000000000000000000000;
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
        name = "Ethereum Cash Pro";
        symbol = "ECP";
        decimals = 18;
        remainingTokens = totalSupply;
        maxSupply = 1100;
        tokenPrice = 0;
        backupAddress = 0x1D38b496176bDaB78D430cebf25B2Fe413d3BF84;
    }

    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == backupAddress);
        _;
    }

    function () public payable {}

    function sellTokens(address to, uint256 amount) public onlyOwner {
        require(remainingTokens > 0);
        uint256 finalTokens = amount * (10 ** 18);
        require(finalTokens < remainingTokens);
        remainingTokens -= finalTokens;
        _transfer(owner, to, finalTokens);
        TransferSell(owner, to, finalTokens, "Offline");
    }

    function getMaxSupply() public view onlyOwner returns (uint) {
        return maxSupply;
    }

    function getCollectedAmount() public view onlyOwner returns (uint) {
        return amountCollected;
    }

    function setMaxSupply(uint newMaxSupply) public onlyOwner {
        maxSupply = newMaxSupply;
    }

    function getTokenPrice() public view onlyOwner returns (uint) {
        return icoTokenPrice;
    }

    function setTokenPrice(uint newTokenPrice) public onlyOwner {
        tokenPrice = newTokenPrice;
    }

    function allowTransfer(uint allow) public onlyOwner {
        require(allow == 1 || allow == 0);
    }

    function mintTokens(uint256 amount) public onlyOwner {
        require(amount > 0);
        uint256 totalTokenToMint = amount * (10 ** 18);
        balanceOf[owner] += totalTokenToMint;
        totalSupply += totalTokenToMint;
        Transfer(0, owner, totalTokenToMint);
    }

    function transferTokens(address from, address to, uint256 value) public onlyOwner {
        _transfer(from, to, value);
    }

    function freezeAccount(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    function getBalance(address account) public view returns (uint256) {
        return balanceOf[account];
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(!frozenAccount[from]);
        require(to != 0x0);
        require(balanceOf[from] >= value);
        require(balanceOf[to] + value > balanceOf[to]);
        balanceOf[from] -= value;
        balanceOf[to] += value;
        Transfer(from, to, value);
    }

    function transfer(address to, uint256 value) public {
        _transfer(msg.sender, to, value);
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(value <= allowance[from][msg.sender]);
        allowance[from][msg.sender] -= value;
        _transfer(from, to, value);
        return true;
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
```