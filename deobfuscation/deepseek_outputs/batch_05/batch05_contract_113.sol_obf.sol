```solidity
pragma solidity ^0.4.19;

contract ERC20 {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public constant returns (uint256);
    
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

contract LiquidationContract {
    using SafeMath for uint256;
    
    ERC20 public token;
    
    struct Config {
        uint256 totalSupply;
        uint256 burnPercentage;
        uint256 tokenDecimals;
        address burnAddress;
        address owner;
    }
    
    Config public config;
    
    modifier onlyOwner() {
        require(msg.sender == config.owner);
        _;
    }
    
    event LogLiquidation(address indexed user, uint256 tokens, uint256 ethReceived, uint256 tokensBurned);
    
    function initialize(address tokenAddress, uint256 decimals) public {
        token = ERC20(tokenAddress);
        config.tokenDecimals = decimals;
        config.totalSupply = token.totalSupply();
        config.owner = msg.sender;
    }
    
    function liquidateTokens(uint256 tokenAmount) public {
        require(token.transferFrom(msg.sender, address(this), tokenAmount));
        
        uint256 tokensToBurn = calculateBurnAmount(tokenAmount, config.burnPercentage, 8);
        uint256 ethToSend = calculateEthAmount(tokenAmount, tokensToBurn);
        
        token.transfer(config.burnAddress, tokensToBurn);
        msg.sender.transfer(ethToSend);
        
        burnTokens(tokenAmount);
        
        emit LogLiquidation(msg.sender, tokenAmount, ethToSend, tokensToBurn);
    }
    
    function burnTokens(uint256 tokenAmount) internal {
        require(token.transfer(config.burnAddress, tokenAmount));
    }
    
    function setBurnPercentage(uint256 percentage) public onlyOwner {
        config.burnPercentage = percentage;
    }
    
    function setOwner(address newOwner) public onlyOwner {
        config.owner = newOwner;
    }
    
    function calculateBurnAmount(uint256 amount, uint256 percentage, uint256 decimals) internal returns(uint256) {
        uint256 numerator = amount.mul((10 ** (decimals + 1)));
        uint256 result = ((numerator / percentage) + 5) / 10;
        return result;
    }
    
    function calculateEthAmount(uint256 tokenAmount, uint256 tokensToBurn) internal view returns(uint256) {
        uint256 unburnedTokens = tokenAmount.sub(tokensToBurn);
        uint256 ethBalance = address(this).balance;
        uint256 tokenBalance = token.balanceOf(address(this));
        
        return unburnedTokens.mul(ethBalance).div(tokenBalance);
    }
    
    function() public payable {}
}
```