```solidity
pragma solidity ^0.4.18;

interface IERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

interface IUniswapV2Router {
    function WETH() external pure returns (address);
}

contract Token {
    function transfer(address to, uint tokens) public returns (bool success);
}

contract PSNGame is IUniswapV2Router {
    using SafeMath for uint256;
    
    uint256 public constant MAGNITUDE = 100000000000000;
    uint256 public constant PSN = 10000;
    uint256 public constant PSNH = 5000;
    
    address public tokenAddress;
    address public contractAddress;
    
    mapping (address => uint256) public hatcheryMiners;
    mapping (address => uint256) public claimedTokens;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    
    uint256 public marketTokens;
    bool public initialized = false;
    
    constructor() public {
        contractAddress = address(this);
    }
    
    function hatchTokens(address ref) public {
        require(initialized);
        
        if (ref == msg.sender || ref == address(0) || hatcheryMiners[ref] == 0) {
            ref = contractAddress;
        }
        
        if (referrals[msg.sender] == address(0)) {
            referrals[msg.sender] = ref;
        }
        
        uint256 tokensUsed = getMyTokens();
        uint256 newMiners = SafeMath.div(tokensUsed, MAGNITUDE);
        hatcheryMiners[msg.sender] = SafeMath.add(hatcheryMiners[msg.sender], newMiners);
        claimedTokens[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        
        claimedTokens[referrals[msg.sender]] = SafeMath.add(claimedTokens[referrals[msg.sender]], SafeMath.div(SafeMath.mul(tokensUsed, 8), 100));
        
        marketTokens = SafeMath.add(marketTokens, SafeMath.div(tokensUsed, 5));
    }
    
    function sellTokens() public {
        require(initialized);
        
        uint256 hasTokens = getMyTokens();
        uint256 tokenValue = calculateTokenSell(hasTokens);
        uint256 fee = devFee(tokenValue);
        
        claimedTokens[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        marketTokens = SafeMath.add(marketTokens, hasTokens);
        
        Token(tokenAddress).transfer(contractAddress, fee);
        Token(tokenAddress).transfer(msg.sender, SafeMath.sub(tokenValue, fee));
    }
    
    function buyTokens(address ref, uint256 amount) public payable {
        require(initialized);
        
        uint256 tokensBought = calculateTokenBuy(msg.value, SafeMath.sub(address(this).balance, msg.value));
        tokensBought = SafeMath.sub(tokensBought, devFee(tokensBought));
        
        uint256 fee = devFee(msg.value);
        contractAddress.transfer(fee);
        
        claimedTokens[msg.sender] = SafeMath.add(claimedTokens[msg.sender], tokensBought);
        
        hatchTokens(ref);
    }
    
    function calculateTrade(uint256 rt, uint256 rs, uint256 bs) public view returns(uint256) {
        return SafeMath.div(
            SafeMath.mul(PSN, bs), 
            SafeMath.add(
                PSNH, 
                SafeMath.div(
                    SafeMath.add(
                        SafeMath.mul(PSN, rs), 
                        SafeMath.mul(PSNH, rt)
                    ), 
                    rt
                )
            )
        );
    }
    
    function calculateTokenSell(uint256 tokens) public view returns(uint256) {
        return calculateTrade(tokens, marketTokens, address(this).balance);
    }
    
    function calculateTokenBuy(uint256 eth, uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth, contractBalance, marketTokens);
    }
    
    function calculateTokenBuySimple(uint256 eth) public view returns(uint256) {
        return calculateTokenBuy(eth, address(this).balance);
    }
    
    function devFee(uint256 amount) public pure returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount, 3), 100);
    }
    
    function seedMarket(uint256 amount) public {
        require(marketTokens == 0);
        
        Token(tokenAddress).transferFrom(msg.sender, address(this), amount);
        initialized = true;
        marketTokens = MAGNITUDE;
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMyMiners() public view returns(uint256) {
        return hatcheryMiners[msg.sender];
    }
    
    function getMyTokens() public view returns(uint256) {
        return SafeMath.add(claimedTokens[msg.sender], getTokensSinceLastHatch(msg.sender));
    }
    
    function getTokensSinceLastHatch(address adr) public view returns(uint256) {
        uint256 secondsPassed = min(MAGNITUDE, SafeMath.sub(now, lastHatch[adr]));
        return SafeMath.mul(secondsPassed, hatcheryMiners[adr]);
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
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
```