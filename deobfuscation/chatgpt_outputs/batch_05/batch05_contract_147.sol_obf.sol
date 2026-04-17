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

    string public name = "Community Bank Coin";
    string public symbol = "CBC";
    uint8 public decimals = 6;
    uint256 public totalSupply = 100000000000000;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    bool public contractLaunched = false;
    bool public tokenMintingEnabled = false;
    bool public tokenIsFrozen = false;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event LaunchContract(address indexed owner, bool launched);
    event FreezeTransfers(address indexed owner, bool frozen);
    event UnFreezeTransfers(address indexed owner, bool unfrozen);
    event MintTokens(address indexed to, uint256 amount, bool indexed success);
    event TokenMintingDisabled(address indexed owner, bool indexed success);
    event TokenMintingEnabled(address indexed owner, bool indexed success);

    constructor() public {
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
    }

    function launchContract() public onlyOwner {
        require(!contractLaunched);
        tokenIsFrozen = false;
        tokenMintingEnabled = true;
        contractLaunched = true;
        emit LaunchContract(msg.sender, true);
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(_transfer(msg.sender, to, value));
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function burn(uint256 value) public onlyOwner returns (bool) {
        require(value > 0);
        require(totalSupply.sub(value) > 0);
        require(balanceOf[msg.sender] > value);
        require(balanceOf[msg.sender].sub(value) > 0);
        totalSupply = totalSupply.sub(value);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
        emit Transfer(msg.sender, address(0), value);
        return true;
    }

    function mint(uint256 value) public onlyOwner returns (bool) {
        require(_canMint(value));
        totalSupply = totalSupply.add(value);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(value);
        emit Transfer(address(0), msg.sender, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) private view returns (bool) {
        require(!tokenIsFrozen);
        require(value > 0);
        require(to != address(0));
        require(balanceOf[from].sub(value) >= 0);
        require(balanceOf[to].add(value) > balanceOf[to]);
        return true;
    }

    function _canMint(uint256 value) internal view returns (bool) {
        require(tokenMintingEnabled);
        require(value > 0);
        require(totalSupply.add(value) > 0);
        require(totalSupply.add(value) > totalSupply);
        return true;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        owner.transfer(balance);
    }

    uint256 public buyPrice;
    uint256 public sellPrice;

    function setPrices(uint256 newBuyPrice, uint256 newSellPrice) public onlyOwner {
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
        return revenue;
    }
}
```