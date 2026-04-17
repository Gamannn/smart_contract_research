```solidity
pragma solidity 0.4.19;

contract ERC20Interface {
    function totalSupply() constant public returns (uint256);
    function balanceOf(address tokenOwner) constant public returns (uint256 balance);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function allowance(address tokenOwner, address spender) constant public returns (uint256 remaining);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed owner, address indexed spender, uint256 tokens);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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

contract BNP is ERC20Interface {
    using SafeMath for uint256;
    
    string public name = "BNP";
    string public symbol = "BNP";
    uint256 public totalSupply;
    uint8 public decimals = 0;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    address public owner;
    bool public paused = false;
    
    uint256 public startTime = 1514073600;
    uint256 public endTime = 1522540799;
    uint256 public rate = 508197029870692;
    uint256 public weiRaised;
    uint256 public cap = 1000000000000000000000000;
    
    event Mint(address indexed to, uint256 amount);
    event TokenPurchase(address indexed purchaser, uint256 weiAmount, uint256 tokens);
    event Price(uint256 newPrice);
    event Pause();
    event Unpause();
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    
    modifier whenPaused() {
        require(paused);
        _;
    }
    
    function BNP() public {
        owner = msg.sender;
        balances[owner] = 50000000;
        totalSupply = 50000000;
        Transfer(address(0), owner, 50000000);
    }
    
    function totalSupply() constant public returns (uint256) {
        return totalSupply;
    }
    
    function balanceOf(address tokenOwner) constant public returns (uint256 balance) {
        return balances[tokenOwner];
    }
    
    function transfer(address to, uint256 tokens) whenNotPaused public returns (bool success) {
        require(to != address(0));
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 tokens) whenNotPaused public returns (bool success) {
        require(to != address(0));
        uint256 allowanceAmount = allowed[from][msg.sender];
        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        allowed[from][msg.sender] = allowanceAmount.sub(tokens);
        Transfer(from, to, tokens);
        return true;
    }
    
    function approve(address spender, uint256 tokens) whenNotPaused public returns (bool success) {
        require((tokens == 0) || (allowed[msg.sender][spender] == 0));
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function allowance(address tokenOwner, address spender) constant public returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function increaseApproval(address spender, uint addedValue) whenNotPaused public returns (bool success) {
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);
        Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
    
    function decreaseApproval(address spender, uint subtractedValue) whenNotPaused public returns (bool success) {
        uint oldValue = allowed[msg.sender][spender];
        if (subtractedValue > oldValue) {
            allowed[msg.sender][spender] = 0;
        } else {
            allowed[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
    
    function mint(address to, uint256 amount) onlyOwner public returns (bool success) {
        totalSupply = totalSupply.add(amount);
        balances[to] = balances[to].add(amount);
        Mint(to, amount);
        Transfer(address(0), to, amount);
        return true;
    }
    
    function () payable public {
        buyTokens(msg.sender);
    }
    
    function buyTokens(address beneficiary) payable whenNotPaused public {
        require(beneficiary != address(0));
        require(validPurchase());
        uint256 weiAmount = msg.value;
        uint256 tokens = weiAmount.mul(rate);
        weiRaised = weiRaised.add(weiAmount);
        balances[owner] = balances[owner].sub(tokens);
        balances[beneficiary] = balances[beneficiary].add(tokens);
        Transfer(owner, beneficiary, tokens);
        TokenPurchase(beneficiary, weiAmount, tokens);
    }
    
    function validPurchase() internal constant returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        bool withinCap = weiRaised.add(msg.value) <= cap;
        return withinPeriod && nonZeroPurchase && withinCap;
    }
    
    function hasEnded() public constant returns (bool) {
        bool capReached = weiRaised >= cap;
        return now > endTime || capReached;
    }
    
    function setCap(uint256 newCap) onlyOwner public {
        require(newCap > 0);
        cap = newCap;
    }
    
    function changePrice(uint256 newRate) onlyOwner public {
        rate = newRate;
        Price(rate);
    }
    
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }
    
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
    
    function destroy() onlyOwner public {
        selfdestruct(owner);
    }
    
    function destroyAndSend(address recipient) onlyOwner public {
        selfdestruct(recipient);
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
        OwnershipTransferred(owner, newOwner);
    }
    
    function reclaimToken(ERC20Interface token) external onlyOwner {
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
    }
    
    function withdrawTokens(uint256 amount) onlyOwner public {
        require(this.balanceOf(address(this)) >= amount);
        this.transfer(owner, amount);
    }
    
    function withdrawTokensTo(address to, uint256 amount) onlyOwner public {
        require(to != address(0));
        require(this.balanceOf(address(this)) >= amount);
        this.transfer(to, amount);
    }
}
```