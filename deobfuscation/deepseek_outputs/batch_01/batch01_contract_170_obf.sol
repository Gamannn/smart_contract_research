```solidity
pragma solidity ^0.4.23;

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
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

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) balances;

    function totalSupply() public view returns (uint256) {
        return s2c.totalSupply;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }
}

contract StandardToken is ERC20, BasicToken {
    mapping(address => mapping(address => uint256)) internal allowed;

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balances[from]);
        require(value <= allowed[from][msg.sender]);

        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

    function increaseApproval(address spender, uint addedValue) public returns (bool) {
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function decreaseApproval(address spender, uint subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][spender];
        if (subtractedValue > oldValue) {
            allowed[msg.sender][spender] = 0;
        } else {
            allowed[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
}

contract Ownable {
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        s2c.owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == s2c.owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(s2c.owner, newOwner);
        s2c.owner = newOwner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(s2c.owner);
        s2c.owner = address(0);
    }
}

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    modifier canMint() {
        require(!s2c.mintingFinished);
        _;
    }

    function mint(address to, uint256 amount) onlyOwner canMint public returns (bool) {
        s2c.totalSupply = s2c.totalSupply.add(amount);
        balances[to] = balances[to].add(amount);
        emit Mint(to, amount);
        emit Transfer(address(0), to, amount);
        return true;
    }

    function finishMinting() onlyOwner canMint public returns (bool) {
        s2c.mintingFinished = true;
        emit MintFinished();
        return true;
    }
}

contract CappedToken is MintableToken {
    constructor(uint256 cap) public {
        require(cap > 0);
        s2c.cap = cap;
    }

    function mint(address to, uint256 amount) onlyOwner canMint public returns (bool) {
        require(s2c.totalSupply.add(amount) <= s2c.cap);
        return super.mint(to, amount);
    }
}

contract BurnableToken is CappedToken {
    mapping(address => uint256) public burnBalances;

    function addBurnBalance(address beneficiary, uint256 amount) onlyOwner public {
        burnBalances[beneficiary] = burnBalances[beneficiary].add(amount);
        s2c.totalBurned = s2c.totalBurned.add(amount);
    }

    function transfer(address to, uint256 value) public returns (bool) {
        uint256 senderBalance = balances[msg.sender];
        bool success = super.transfer(to, value);
        uint256 burnAmount = burnBalances[msg.sender].mul(value).div(senderBalance);
        burnBalances[msg.sender] = burnBalances[msg.sender].sub(burnAmount);
        burnBalances[to] = burnBalances[to].add(burnAmount);
        return success;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        uint256 fromBalance = balances[from];
        bool success = super.transferFrom(from, to, value);
        uint256 burnAmount = burnBalances[from].mul(value).div(fromBalance);
        burnBalances[from] = burnBalances[from].sub(burnAmount);
        burnBalances[to] = burnBalances[to].add(burnAmount);
        return success;
    }
}

contract ICSToken is BurnableToken {
    constructor() public CappedToken(5e8 * 1e18) {}
}

contract HICSToken is BurnableToken {
    constructor() public CappedToken(5e7 * 1e18) {}
}

contract ReentrancyGuard {
    modifier nonReentrant() {
        require(!s2c.locked);
        s2c.locked = true;
        _;
        s2c.locked = false;
    }
}

contract Crowdsale is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    ERC20 public t4tToken;
    ICSToken public icsToken;
    HICSToken public hicsToken;

    mapping(address => uint) public contributions;
    mapping(address => uint) etherContributions;
    mapping(address => uint) tokenContributions;

    event IcsTokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 amount);
    event HicsTokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 amount);

    constructor(
        address wallet,
        address icsTokenAddress,
        address hicsTokenAddress,
        address t4tTokenAddress
    ) public {
        require(wallet != address(0));
        require(icsTokenAddress != address(0));
        require(hicsTokenAddress != address(0));
        require(t4tTokenAddress != address(0));

        s2c.startTime = 1528675200;
        s2c.bonus1EndTime = 1529107200;
        s2c.bonus2EndTime = 1529798400;
        s2c.bonus3EndTime = 1530489600;
        s2c.endTime = 1531353600;

        bool validTimestamps = now < s2c.startTime && 
                              s2c.startTime < s2c.bonus1EndTime && 
                              s2c.bonus1EndTime < s2c.bonus2EndTime && 
                              s2c.bonus2EndTime < s2c.bonus3EndTime && 
                              s2c.bonus3EndTime < s2c.endTime;
        require(validTimestamps);

        s2c.wallet = wallet;
        icsToken = ICSToken(icsTokenAddress);
        hicsToken = HICSToken(hicsTokenAddress);
        t4tToken = ERC20(t4tTokenAddress);

        s2c.t4tMultiplier = 4;
        s2c.minInvestment = 4 * 1e18;
        s2c.minInvestmentForHics = 2e4 * 1e18;
        s2c.rate = 2720;
        s2c.softCap = 4e6 * 1e18;
        s2c.hicsHardCap = 15e6 * 1e18;
    }

    modifier saleActive() {
        bool active = now >= s2c.startTime && now <= s2c.endTime;
        require(active);
        _;
    }

    modifier saleFailed() {
        require(s2c.weiRaised < s2c.softCap && now > s2c.endTime);
        _;
    }

    function hasEnded() public view returns (bool) {
        return now > s2c.endTime;
    }

    function claimRefund() public saleFailed nonReentrant {
        uint256 refundAmount = etherContributions[msg.sender];
        etherContributions[msg.sender] = 0;
        s2c.totalEtherRefunded = s2c.totalEtherRefunded.sub(refundAmount);
        msg.sender.transfer(refundAmount);
    }

    function claimTokenRefund() public saleFailed nonReentrant {
        uint256 refundAmount = tokenContributions[msg.sender];
        tokenContributions[msg.sender] = 0;
        s2c.totalTokenRefunded = s2c.totalTokenRefunded.sub(refundAmount);
        t4tToken.transfer(msg.sender, refundAmount);
    }

    function getBonusPercentage() internal view returns(uint256) {
        if (now < s2c.bonus1EndTime) {
            return 40;
        }
        if (now < s2c.bonus2EndTime) {
            return 25;
        }
        if (now < s2c.bonus3EndTime) {
            return 20;
        }
        return 15;
    }

    function calculateTokens(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.add(weiAmount.mul(getBonusPercentage()).div(100));
    }

    function forwardEther(uint256 amount) internal {
        s2c.wallet.transfer(amount);
    }

    function forwardTokens(uint256 amount) internal {
        t4tToken.transfer(s2c.wallet, amount);
    }

    function withdrawEther() public onlyOwner {
        require(s2c.weiRaised >= s2c.softCap);
        forwardEther(address(this).balance);
    }

    function withdrawTokens() public onlyOwner {
        require(s2c.weiRaised >= s2c.softCap);
        forwardTokens(t4tToken.balanceOf(address(this)));
    }

    function finalize() public onlyOwner {
        require(s2c.weiRaised >= s2c.softCap);
        require(now > s2c.endTime);
        forwardEther(address(this).balance);
        forwardTokens(t4tToken.balanceOf(address(this)));
        icsToken.transferOwnership(s2c.owner);
        hicsToken.transferOwnership(s2c.owner);
    }

    function transferTokenOwnership() public onlyOwner {
        require(now > s2c.endTime);
        icsToken.transferOwnership(s2c.owner);
        hicsToken.transferOwnership(s2c.owner);
    }

    function setRate(uint256 newRate) internal {
        require(newRate != 0);
        s2c.rate = newRate;
    }

    function mintIcsTokens(address beneficiary, uint256 weiAmount) internal {
        uint256 tokens = calculateTokens(weiAmount);
        icsToken.mint(beneficiary, tokens);
        emit IcsTokenPurchase(msg.sender, beneficiary, tokens);
    }

    function mintHicsTokens(address beneficiary, uint256 weiAmount) internal {
        uint256 tokens = calculateTokens(weiAmount);
        hicsToken.mint(beneficiary, tokens);
        emit HicsTokenPurchase(msg.sender, beneficiary, tokens);
    }

    function processPurchase(address beneficiary, uint256 weiAmount) internal {
        uint256 hicsAmount = weiAmount.div(5);
        if (weiAmount >= s2c.minInvestmentForHics && 
            hicsToken.totalSupply().add(calculateTokens(hicsAmount)) < s2c.hicsHardCap) {
            mintIcsTokens(beneficiary, weiAmount.sub(hicsAmount));
            mintHicsTokens(beneficiary, hicsAmount);
        } else {
            mintIcsTokens(beneficiary, weiAmount);
        }

        uint256 tokens = calculateTokens(weiAmount);
        s2c.totalTokensMinted = s2c.totalTokensMinted.add(tokens);
        contributions[beneficiary] = contributions[beneficiary].add(tokens);
        s2c.weiRaised = s2c.weiRaised.add(weiAmount);
    }

    function buyWithTokens(address beneficiary) public saleActive {
        require(beneficiary != address(0));
        uint256 allowance = t4tToken.allowance(beneficiary, address(this));
        uint256 weiAmount = allowance.mul(s2c.t4tMultiplier);
        require(weiAmount >= s2c.minInvestment);
        require(t4tToken.transferFrom(beneficiary, address(this), allowance));

        processPurchase(beneficiary, weiAmount);
        s2c.totalTokenRefunded = s2c.totalTokenRefunded.add(allowance);
        tokenContributions[beneficiary] = tokenContributions[beneficiary].add(allowance);
    }

    function mintTokens(address beneficiary, uint256 weiAmount) public saleActive onlyOwner {
        require(beneficiary != address(0));
        require(weiAmount >= s2c.minInvestment);
        processPurchase(beneficiary, weiAmount);
    }

    function buyTokensWithRate(address beneficiary, uint256 newRate) public saleActive onlyOwner payable {
        setRate(newRate);
        buyTokens(beneficiary);
    }

    function buyTokens(address beneficiary) saleActive public payable {
        require(beneficiary != address(0));
        uint256 weiAmount = msg.value;
        uint256 tokenAmount = weiAmount.mul(s2c.rate);
        require(tokenAmount >= s2c.minInvestment);

        processPurchase(beneficiary, tokenAmount);
        s2c.totalEtherRefunded = s2c.totalEtherRefunded.add(weiAmount);
        etherContributions[beneficiary] = etherContributions[beneficiary].add(weiAmount);
    }

    function() external payable {
        buyTokens(msg.sender);
    }
}

struct Storage {
    uint256 weiRaised;
    uint256 totalTokensMinted;
    uint256 totalTokenRefunded;
    uint256 totalEtherRefunded;
    uint256 softCap;
    uint256 hicsHardCap;
    uint256 minInvestmentForHics;
    uint256 minInvestment;
    uint256 t4tMultiplier;
    uint256 rate;
    address wallet;
    uint64 bonus3EndTime;
    uint64 bonus2EndTime;
    uint64 bonus1EndTime;
    uint64 endTime;
    uint64 startTime;
    bool locked;
    uint8 icsDecimals;
    string icsSymbol;
    string icsName;
    uint8 hicsDecimals;
    string hicsSymbol;
    string hicsName;
    uint256 totalBurned;
    uint256 cap;
    bool mintingFinished;
    address owner;
    uint256 totalSupply;
}

Storage s2c = Storage(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, address(0), 0, 0, 0, 0, 0, false, 18, "HICS", "Interexchange Crypstock System Heritage Token", 18, "ICS", "Interexchange Crypstock System", 0, 0, false, address(0), 0);
```