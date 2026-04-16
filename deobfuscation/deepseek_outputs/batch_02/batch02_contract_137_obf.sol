```solidity
pragma solidity ^0.4.24;

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

interface ERC20 {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address owner) public constant returns (uint256);
    function transfer(address to, uint256 amount) public returns (bool);
    function transferFrom(address from, address to, uint256 amount) public returns (bool);
    function approve(address spender, uint256 amount) public returns (bool);
    function allowance(address owner, address spender) public constant returns (uint256);
    
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

contract Ownable {
    address public owner;
    address public newOwner;
    
    event OwnerUpdate(address indexed prevOwner, address indexed newOwner);
    
    modifier ownerOnly {
        require(msg.sender == owner);
        _;
    }
    
    constructor() public {
        owner = msg.sender;
    }
    
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract TokenSale is Ownable {
    using SafeMath for uint256;
    
    uint256 public constant COINS_PER_ETH = 12000;
    uint256 public constant BONUS_PERCENT = 25;
    
    ERC20 public token;
    
    mapping(address => uint256) public balances;
    mapping(address => uint256) public ethBalances;
    
    uint256 public ethCollected;
    uint256 public tokenSold;
    
    uint256 constant TOKEN_DECIMAL_MULTIPLIER = 1 ether;
    
    uint8 public state = 0;
    
    event SaleStart();
    event SaleClosedSuccess(uint256 tokensSold);
    event SaleClosedFail(uint256 tokensSold);
    
    constructor(address tokenAddress) public {
        token = ERC20(tokenAddress);
    }
    
    function getTokenBalance() public view returns (uint256) {
        return token.allowance(owner, address(this));
    }
    
    function() payable public {
        if ((state == 3 || state == 4) && msg.value == 0) {
            return refund();
        } else if (state == 2 && msg.value == 0) {
            return withdrawFunds();
        } else {
            return buyTokens();
        }
    }
    
    function buyTokens() payable public {
        require(isSaleActive());
        
        uint256 tokens = msg.value.mul(COINS_PER_ETH).div(1 ether).mul(TOKEN_DECIMAL_MULTIPLIER);
        tokens = applyBonus(tokens);
        
        require(tokens > 0);
        
        token.transferFrom(owner, address(this), tokens);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        ethBalances[msg.sender] = ethBalances[msg.sender].add(msg.value);
        ethCollected = ethCollected.add(msg.value);
        tokenSold = tokenSold.add(tokens);
    }
    
    function applyBonus(uint256 tokens) internal pure returns (uint256) {
        uint256 bonus = tokens.mul(BONUS_PERCENT).div(100);
        tokens = tokens.add(bonus);
        return tokens;
    }
    
    function isSaleActive() public constant returns (bool) {
        return state == 1;
    }
    
    function withdrawFunds() public {
        require(state == 2);
        
        uint256 userTokens = balances[msg.sender];
        require(userTokens > 0);
        
        uint256 userEth = ethBalances[msg.sender];
        msg.sender.transfer(userEth);
        
        token.transfer(owner, balances[msg.sender]);
        
        ethBalances[msg.sender] = 0;
        balances[msg.sender] = 0;
        
        ethCollected = ethCollected.sub(userEth);
    }
    
    function withdraw() ownerOnly public {
        require(state == 3);
        owner.transfer(ethCollected);
        ethCollected = 0;
    }
    
    function refund() public {
        require(state == 3 || state == 4);
        require(ethBalances[msg.sender] > 0);
        
        msg.sender.transfer(ethBalances[msg.sender]);
        token.transfer(owner, balances[msg.sender]);
        
        ethBalances[msg.sender] = 0;
        balances[msg.sender] = 0;
    }
    
    function startSale() ownerOnly public {
        require(state == 0);
        state = 1;
        emit SaleStart();
    }
    
    function closeSuccess() ownerOnly public {
        require(state == 1);
        state = 3;
        emit SaleClosedSuccess(tokenSold);
    }
    
    function closeFail() ownerOnly public {
        require(state == 1);
        state = 2;
        emit SaleClosedFail(tokenSold);
    }
}
```