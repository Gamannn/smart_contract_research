```solidity
pragma solidity ^0.4.23;

contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address tokenOwner) public view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
    function transfer(address to, uint256 tokens, bytes data) public returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed owner, address indexed spender, uint256 tokens);
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

contract ERC20Token is ERC20Interface {
    using SafeMath for uint256;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    function approve(address spender, uint256 tokens) public returns (bool) {
        require(spender != address(0));
        require(tokens == 0 || allowed[msg.sender][spender] == 0);
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }
    
    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }
}

contract Token is ERC20Token {
    using SafeMath for uint256;
    
    string public constant name = "V2X";
    string public constant symbol = "Vitalik2X";
    uint256 public constant decimals = 18;
    uint256 public constant totalSupply = 10 ** decimals;
    
    uint256 public creationBlock;
    address public owner;
    
    uint256 public mainPotETHBalance;
    uint256 public mainPotTokenBalance;
    
    mapping(address => uint256) public lockUntilBlock;
    
    event SoldTokensFromPot(address indexed seller, uint256 amount);
    event BoughtTokensFromPot(address indexed buyer, uint256 amount);
    event DonatedTokens(address indexed donor, uint256 amount);
    event DonatedETH(address indexed donor, uint256 amount);
    
    constructor() public {
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
        creationBlock = block.number;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function donateTokens(uint256 amount) external returns (bool) {
        require(transferToContract(amount));
        mainPotTokenBalance = mainPotTokenBalance.add(amount);
        emit DonatedTokens(msg.sender, amount);
        return true;
    }
    
    function donateETH() external payable returns (bool) {
        mainPotETHBalance = mainPotETHBalance.add(msg.value);
        emit DonatedETH(msg.sender, msg.value);
        return true;
    }
    
    function sellTokens(uint256 amount) external returns (bool) {
        uint256 ethAmount = calculateETHForTokens(amount);
        require(ethAmount <= getMaxSellAmount(), "Token amount sent is above the cap.");
        require(transferToContract(amount));
        mainPotTokenBalance = mainPotTokenBalance.add(amount);
        mainPotETHBalance = mainPotETHBalance.sub(ethAmount);
        msg.sender.transfer(ethAmount);
        emit SoldTokensFromPot(msg.sender, amount);
        return true;
    }
    
    function buyTokens() external payable returns (uint256) {
        require(msg.value > 0);
        uint256 tokenAmount = calculateTokensForETH(msg.value);
        require(tokenAmount <= getMaxBuyAmount(), "Msg.value is above the cap.");
        require(mainPotTokenBalance >= 1 finney, "Pot does not have enough tokens.");
        mainPotETHBalance = mainPotETHBalance.add(msg.value);
        mainPotTokenBalance = mainPotTokenBalance.sub(tokenAmount);
        balances[address(this)] = balances[address(this)].sub(tokenAmount);
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
    
    function rescueTokens(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(this));
        ERC20Interface token = ERC20Interface(tokenAddress);
        token.transfer(owner, token.balanceOf(address(this)));
    }
    
    function calculateETHForTokens(uint256 tokenAmount) public view returns (uint256) {
        uint256 ethAmount = mainPotETHBalance.mul(tokenAmount).div(mainPotTokenBalance);
        ethAmount = ethAmount.sub(ethAmount.mul(tokenAmount).div(mainPotTokenBalance));
        return mainPotETHBalance.mul(30).div(100);
    }
    
    function calculateTokensForETH(uint256 ethAmount) public view returns (uint256) {
        uint256 tokenAmount = mainPotTokenBalance.mul(ethAmount).div(mainPotETHBalance);
        tokenAmount = tokenAmount.sub(tokenAmount.mul(ethAmount).div(mainPotETHBalance));
        return tokenAmount;
    }
    
    function getMaxBuyAmount() public view returns (uint256) {
        return mainPotTokenBalance.mul(30).div(100);
    }
    
    function getMaxSellAmount() public view returns (uint256) {
        uint256 ethAmount = calculateETHForTokens(mainPotTokenBalance);
        return ethAmount.mul(100).div(mainPotETHBalance);
    }
    
    function isLocked() public view returns (bool) {
        return (block.number < lockUntilBlock[msg.sender]);
    }
    
    function transfer(address to, uint256 tokens) public returns (bool) {
        require(block.number >= lockUntilBlock[msg.sender], "Address is still locked.");
        if (to == address(this)) {
            return mintTokens(msg.sender, tokens);
        } else {
            return transferTo(to, tokens);
        }
    }
    
    function transfer(address to, uint256 tokens, bytes data) public returns (bool) {
        require(to != address(this));
        require(transfer(to, tokens));
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(to)
        }
        if (codeSize > 0) {
            ERC20Receiver receiver = ERC20Receiver(to);
            receiver.tokenFallback(msg.sender, tokens, data);
        }
        return true;
    }
    
    function transferFrom(address from, address to, uint256 tokens) public returns (bool) {
        require(block.number >= lockUntilBlock[from], "Address is still locked.");
        require(from != address(0));
        require(to != address(0));
        require(to != address(this));
        balances[to] = balances[to].add(tokens);
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    
    function transferTo(address to, uint256 tokens) internal returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    function transferToContract(uint256 tokens) internal returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[address(this)] = balances[address(this)].add(tokens);
        emit Transfer(msg.sender, address(this), tokens);
        return true;
    }
    
    function mintTokens(address recipient, uint256 tokens) internal returns (bool) {
        require(balances[recipient] >= tokens, "Owner doesn't have enough tokens.");
        uint256 lockBlocks = (block.number - creationBlock) / 5;
        lockUntilBlock[recipient] = block.number + (lockBlocks > 1337 ? lockBlocks : 1337);
        if (lockUntilBlock[recipient] >= block.number + 42000) {
            lockUntilBlock[recipient] = block.number + 42000;
        }
        require(mint(recipient, tokens), "Minting failed");
        emit Transfer(address(0), recipient, tokens);
        return true;
    }
    
    function mint(address recipient, uint256 amount) internal returns (bool) {
        // Note: This function appears to be incomplete in the original
        // It should increase total supply and recipient's balance
        // Keeping original logic
        return true;
    }
}

contract ERC20Receiver {
    function tokenFallback(address from, uint256 value, bytes data) public;
}
```