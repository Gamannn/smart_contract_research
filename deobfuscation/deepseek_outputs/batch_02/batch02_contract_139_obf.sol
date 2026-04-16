```solidity
pragma solidity ^0.4.23;

contract ERC20Interface {
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function balanceOf(address owner) public view returns (uint256);
    function allowance(address owner, address spender) public view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
        assert(b > 0);
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b != 0);
        return a % b;
    }
}

contract Token is ERC20Interface {
    using SafeMath for uint256;
    
    uint256 public totalSupply;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;
    
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
        require(value == 0 || allowed[msg.sender][spender] == 0);
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }
    
    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }
}

contract Vitalik2X is Token {
    using SafeMath for uint256;
    
    string public constant symbol = "V2X";
    string public constant name = "Vitalik2X";
    uint8 public constant decimals = 18;
    
    uint256 public mainPotETHBalance;
    uint256 public mainPotTokenBalance;
    uint256 public creationBlock;
    address public owner;
    mapping(address => uint256) public lockUntilBlock;
    
    event DonatedETH(address indexed donor, uint256 amount);
    event SoldTokensFromPot(address indexed seller, uint256 amount);
    event BoughtTokensFromPot(address indexed buyer, uint256 amount);
    
    constructor() public {
        owner = msg.sender;
        totalSupply = 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply;
        creationBlock = block.number;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function donateTokens(uint256 amount) external returns (bool) {
        require(_transfer(address(this), amount));
        mainPotTokenBalance = mainPotTokenBalance.add(amount);
        emit Transfer(msg.sender, address(this), amount);
        return true;
    }
    
    function donateETH() external payable returns (bool) {
        require(msg.value > 0);
        mainPotETHBalance = mainPotETHBalance.add(msg.value);
        emit DonatedETH(msg.sender, msg.value);
        return true;
    }
    
    function sellTokens(uint256 amount) external returns (bool) {
        uint256 ethAmount = calculateETHForTokens(amount);
        require(ethAmount <= getMaxETHForSale(), "Amount sent is above the cap.");
        require(_transfer(address(this), amount));
        mainPotTokenBalance = mainPotTokenBalance.add(amount);
        mainPotETHBalance = mainPotETHBalance.sub(ethAmount);
        msg.sender.transfer(ethAmount);
        emit SoldTokensFromPot(msg.sender, amount);
        return true;
    }
    
    function buyTokens() external payable returns (uint256) {
        require(msg.value > 0);
        uint256 tokenAmount = calculateTokensForETH(msg.value);
        require(tokenAmount <= getMaxTokensForPurchase(), "Msg.value is above the cap.");
        require(mainPotTokenBalance >= tokenAmount, "Pot does not have enough tokens.");
        mainPotETHBalance = mainPotETHBalance.add(msg.value);
        mainPotTokenBalance = mainPotTokenBalance.sub(tokenAmount);
        balances[msg.sender] = balances[msg.sender].add(tokenAmount);
        emit Transfer(address(this), msg.sender, tokenAmount);
        emit BoughtTokensFromPot(msg.sender, tokenAmount);
        return tokenAmount;
    }
    
    function getLockUntilBlock(address user) external view returns (uint256) {
        return lockUntilBlock[user];
    }
    
    function withdrawETH() external onlyOwner {
        owner.transfer(address(this).balance.sub(mainPotETHBalance));
    }
    
    function transferAnyERC20Token(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(this));
        ERC20Interface token = ERC20Interface(tokenAddress);
        token.transfer(owner, token.balanceOf(this));
    }
    
    function calculateETHForTokens(uint256 tokenAmount) public view returns (uint256) {
        uint256 ethAmount = mainPotETHBalance.mul(tokenAmount).div(mainPotTokenBalance);
        ethAmount = ethAmount.sub(ethAmount.mul(30).div(100));
        return ethAmount;
    }
    
    function calculateTokensForETH(uint256 ethAmount) public view returns (uint256) {
        uint256 tokenAmount = mainPotTokenBalance.mul(ethAmount).div(mainPotETHBalance);
        tokenAmount = tokenAmount.sub(tokenAmount.mul(30).div(100));
        return tokenAmount;
    }
    
    function getMaxETHForSale() public view returns (uint256) {
        return mainPotETHBalance.mul(30).div(100);
    }
    
    function getMaxTokensForPurchase() public view returns (uint256) {
        return mainPotTokenBalance.mul(30).div(100);
    }
    
    function isLocked(address user) public view returns (bool) {
        return (block.number < lockUntilBlock[user]);
    }
    
    function transfer(address to, uint256 value) public returns (bool) {
        require(block.number >= lockUntilBlock[msg.sender], "Address is still locked.");
        if (to == address(this)) {
            return _mint(msg.sender, value);
        } else {
            return _transfer(to, value);
        }
    }
    
    function transfer(address to, uint256 value, bytes data) public returns (bool) {
        require(to != address(this));
        require(transfer(to, value));
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(to)
        }
        if (codeSize > 0) {
            ERC223Receiver receiver = ERC223Receiver(to);
            receiver.tokenFallback(msg.sender, value, data);
        }
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(block.number >= lockUntilBlock[from], "Address is still locked.");
        require(from != address(0));
        require(to != address(0));
        require(to != address(this));
        balances[to] = balances[to].add(value);
        balances[from] = balances[from].sub(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }
    
    function _transfer(address to, uint256 value) internal returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function _mint(address recipient, uint256 value) internal returns (bool) {
        require(balances[recipient] >= value, "Owner doesnt have enough tokens.");
        uint256 blocksSinceCreation = (block.number - creationBlock) / 5;
        lockUntilBlock[recipient] = block.number + (blocksSinceCreation > 2600 ? blocksSinceCreation : 2600);
        require(msg.sender.send(value), "Minting failed");
        emit Transfer(address(0), recipient, value);
        return true;
    }
    
    function mint(address recipient, uint256 amount) external onlyOwner returns (bool) {
        totalSupply = totalSupply.add(amount);
        balances[recipient] = balances[recipient].add(amount);
        return true;
    }
}

contract ERC223Receiver {
    function tokenFallback(address from, uint256 value, bytes data) public;
}
```