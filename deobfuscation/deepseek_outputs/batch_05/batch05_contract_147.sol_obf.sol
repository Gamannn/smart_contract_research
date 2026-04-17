```solidity
pragma solidity 0.4.25;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
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

contract Ownable {
    address public owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner returns (bool) {
        require(msg.sender == owner);
        owner = newOwner;
        return true;
    }
}

contract CommunityBankCoin is Ownable {
    using SafeMath for uint256;
    
    uint256 public totalSupply;
    uint8 public decimals;
    string public name;
    string public symbol;
    bool public tokenIsFrozen;
    bool public tokenMintingEnabled;
    bool public contractLaunched;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event LaunchContract(address indexed launcher, bool launched);
    event FreezeTransfers(address indexed freezer, bool frozen);
    event UnFreezeTransfers(address indexed unfreezer, bool unfrozen);
    event MintTokens(address indexed minter, uint256 amount, bool indexed minted);
    event TokenMintingDisabled(address indexed disabler, bool indexed disabled);
    event TokenMintingEnabled(address indexed enabler, bool indexed enabled);
    
    constructor() public {
        name = "Community Bank Coin";
        symbol = "CBC";
        decimals = 6;
        totalSupply = 100000000000000;
        balanceOf[msg.sender] = totalSupply;
        tokenIsFrozen = false;
        tokenMintingEnabled = false;
        contractLaunched = false;
        owner = msg.sender;
    }
    
    function launchContract() public onlyOwner {
        require(!contractLaunched);
        tokenIsFrozen = false;
        tokenMintingEnabled = true;
        contractLaunched = true;
        emit LaunchContract(msg.sender, true);
    }
    
    function transfer(address to, uint256 amount) public returns (bool) {
        require(canTransfer(msg.sender, to, amount));
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);
        balanceOf[to] = balanceOf[to].add(amount);
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function burn(uint256 amount) public onlyOwner returns (bool) {
        require(amount > 0);
        require(totalSupply.sub(amount) > 0);
        require(balanceOf[msg.sender] > amount);
        require(balanceOf[msg.sender].sub(amount) > 0);
        
        totalSupply = totalSupply.sub(amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);
        emit Transfer(msg.sender, 0, amount);
        return true;
    }
    
    function canMint(uint256 amount) internal view returns (bool) {
        require(tokenMintingEnabled);
        require(amount > 0);
        require(totalSupply.add(amount) > 0);
        require(totalSupply.add(amount) > totalSupply);
        return true;
    }
    
    function mint(uint256 amount) public onlyOwner returns (bool) {
        require(canMint(amount));
        totalSupply = totalSupply.add(amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
        emit Transfer(0, msg.sender, amount);
        return true;
    }
    
    function canTransfer(address from, address to, uint256 amount) private constant returns (bool) {
        require(!tokenIsFrozen);
        require(amount > 0);
        require(to != address(0));
        require(balanceOf[from].sub(amount) >= 0);
        require(balanceOf[to].add(amount) > balanceOf[to]);
        return true;
    }
    
    function totalSupply() public constant returns (uint256) {
        return totalSupply;
    }
    
    function balanceOf(address person) public constant returns (uint256) {
        return balanceOf[person];
    }
    
    function allowance(address owner, address spender) public constant returns (uint256) {
        return allowance[owner][spender];
    }
    
    function withdraw() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        address(owner).transfer(contractBalance);
    }
    
    uint256 public buyPrice;
    uint256 public sellPrice;
    
    function setPrices(uint256 newBuyPrice, uint256 newSellPrice) onlyOwner public {
        buyPrice = newBuyPrice;
        sellPrice = newSellPrice;
    }
    
    function buy() public payable returns (uint256 amount) {
        amount = msg.value.div(buyPrice);
        require(balanceOf[owner] >= amount);
        balanceOf[owner] = balanceOf[owner].sub(amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
        emit Transfer(owner, msg.sender, amount);
        return amount;
    }
    
    function sell(uint256 amount) public returns (uint256 revenue) {
        require(balanceOf[msg.sender] >= amount);
        balanceOf[owner] = balanceOf[owner].add(amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);
        revenue = amount.mul(sellPrice);
        msg.sender.transfer(revenue);
        emit Transfer(msg.sender, owner, amount);
    }
}
```