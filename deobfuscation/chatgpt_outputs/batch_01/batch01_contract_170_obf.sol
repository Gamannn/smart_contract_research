```solidity
pragma solidity ^0.4.23;

contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address tokenOwner) public view returns (uint256 balance);
    function transfer(address to, uint256 tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
}

contract ERC20ExtendedInterface is ERC20Interface {
    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
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

contract BasicToken is ERC20Interface {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    function totalSupply() public view returns (uint256) {
        return s2c.totalSupply;
    }

    function transfer(address to, uint256 tokens) public returns (bool) {
        require(to != address(0));
        require(tokens <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function balanceOf(address tokenOwner) public view returns (uint256 balance) {
        return balances[tokenOwner];
    }
}

contract StandardToken is ERC20ExtendedInterface, BasicToken {
    mapping(address => mapping(address => uint256)) internal allowed;

    function transferFrom(address from, address to, uint256 tokens) public returns (bool) {
        require(to != address(0));
        require(tokens <= balances[from]);
        require(tokens <= allowed[from][msg.sender]);

        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function approve(address spender, uint256 tokens) public returns (bool) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint256) {
        return allowed[tokenOwner][spender];
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
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
}

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished);
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
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}

contract CappedToken is MintableToken {
    uint256 public cap;

    constructor(uint256 _cap) public {
        require(_cap > 0);
        cap = _cap;
    }

    function mint(address to, uint256 amount) onlyOwner canMint public returns (bool) {
        require(s2c.totalSupply.add(amount) <= cap);
        return super.mint(to, amount);
    }
}

contract TokenA is CappedToken {
    mapping(address => uint256) public lockedBalances;

    function lockTokens(address beneficiary, uint256 amount) onlyOwner public {
        lockedBalances[beneficiary] = lockedBalances[beneficiary].add(amount);
        s2c.lockedSupply = s2c.lockedSupply.add(amount);
    }

    function transfer(address to, uint256 tokens) public returns (bool) {
        uint256 senderBalance = balances[msg.sender];
        bool success = super.transfer(to, tokens);
        uint256 lockedAmount = lockedBalances[msg.sender].mul(tokens).div(senderBalance);
        lockedBalances[msg.sender] = lockedBalances[msg.sender].sub(lockedAmount);
        lockedBalances[to] = lockedBalances[to].add(lockedAmount);
        return success;
    }

    function transferFrom(address from, address to, uint256 tokens) public returns (bool) {
        uint256 fromBalance = balances[from];
        bool success = super.transferFrom(from, to, tokens);
        uint256 lockedAmount = lockedBalances[from].mul(tokens).div(fromBalance);
        lockedBalances[from] = lockedBalances[from].sub(lockedAmount);
        lockedBalances[to] = lockedBalances[to].add(lockedAmount);
        return success;
    }
}

contract TokenB is CappedToken {
    constructor() public CappedToken(5e8 * 1e18) {}
}

contract TokenC is CappedToken {
    constructor() public CappedToken(5e7 * 1e18) {}
}

contract ReentrancyGuard {
    bool private reentrancyLock = false;

    modifier nonReentrant() {
        require(!reentrancyLock);
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }
}

contract Crowdsale is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    ERC20ExtendedInterface public token;
    TokenA public tokenA;
    TokenB public tokenB;
    mapping(address => uint) public contributions;
    mapping(address => uint) public refunds;
    mapping(address => uint) public tokenBalances;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value);
    event TokenPurchaseWithBonus(address indexed purchaser, address indexed beneficiary, uint256 value);

    constructor(
        address wallet,
        address tokenAddress,
        address tokenAAddress,
        address tokenBAddress
    ) public {
        require(wallet != address(0));
        require(tokenAddress != address(0));
        require(tokenAAddress != address(0));
        require(tokenBAddress != address(0));

        s2c.startTime = 1528675200;
        s2c.bonusEndTime1 = 1529107200;
        s2c.bonusEndTime2 = 1529798400;
        s2c.bonusEndTime3 = 1530489600;
        s2c.endTime = 1531353600;

        bool validTime = now < s2c.startTime &&
            s2c.startTime < s2c.bonusEndTime1 &&
            s2c.bonusEndTime1 < s2c.bonusEndTime2 &&
            s2c.bonusEndTime2 < s2c.bonusEndTime3 &&
            s2c.bonusEndTime3 < s2c.endTime;
        require(validTime);

        s2c.wallet = wallet;
        tokenA = TokenA(tokenAAddress);
        tokenB = TokenB(tokenBAddress);
        token = ERC20ExtendedInterface(tokenAddress);

        s2c.minContribution = 4;
        s2c.minContributionWithBonus = 4 * 1e18;
        s2c.minContributionForBonus = 2e4 * 1e18;
        s2c.tokenRate = 2720;
        s2c.softCap = 4e6 * 1e18;
        s2c.hardCap = 15e6 * 1e18;
    }

    modifier onlyWhileOpen() {
        bool isOpen = now >= s2c.startTime && now <= s2c.endTime;
        require(isOpen);
        _;
    }

    modifier onlyAfterClose() {
        require(s2c.totalRaised < s2c.softCap && now > s2c.endTime);
        _;
    }

    function hasEnded() public view returns (bool) {
        return now > s2c.endTime;
    }

    function claimRefund() public onlyAfterClose nonReentrant {
        uint256 refundAmount = refunds[msg.sender];
        refunds[msg.sender] = 0;
        s2c.refundSupply = s2c.refundSupply.sub(refundAmount);
        msg.sender.transfer(refundAmount);
    }

    function claimTokenRefund() public onlyAfterClose nonReentrant {
        uint256 refundAmount = tokenBalances[msg.sender];
        tokenBalances[msg.sender] = 0;
        s2c.tokenRefundSupply = s2c.tokenRefundSupply.sub(refundAmount);
        token.transfer(msg.sender, refundAmount);
    }

    function getBonusRate() internal view returns(uint256) {
        if (now < s2c.bonusEndTime1) {
            return 40;
        }
        if (now < s2c.bonusEndTime2) {
            return 25;
        }
        if (now < s2c.bonusEndTime3) {
            return 20;
        }
        return 15;
    }

    function calculateTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(getBonusRate()).div(100).add(weiAmount);
    }

    function forwardFunds(uint256 weiAmount) internal {
        s2c.wallet.transfer(weiAmount);
    }

    function forwardTokenFunds(uint256 tokenAmount) internal {
        token.transfer(s2c.wallet, tokenAmount);
    }

    function finalize() public onlyOwner {
        require(s2c.totalRaised >= s2c.softCap);
        forwardFunds(address(this).balance);
    }

    function finalizeToken() public onlyOwner {
        require(s2c.totalRaised >= s2c.softCap);
        forwardTokenFunds(token.balanceOf(address(this)));
    }

    function finalizeAll() public onlyOwner {
        require(s2c.totalRaised >= s2c.softCap);
        require(now > s2c.endTime);
        forwardFunds(address(this).balance);
        forwardTokenFunds(token.balanceOf(address(this)));
        tokenA.transferOwnership(owner);
        tokenB.transferOwnership(owner);
    }

    function finalizeWithoutToken() public onlyOwner {
        require(now > s2c.endTime);
        tokenA.transferOwnership(owner);
        tokenB.transferOwnership(owner);
    }

    function setTokenRate(uint256 newRate) internal {
        require(newRate != 0);
        s2c.tokenRate = newRate;
    }

    function processPurchase(address beneficiary, uint256 weiAmount) internal {
        uint256 tokenAmount = calculateTokenAmount(weiAmount);
        tokenA.mint(beneficiary, tokenAmount);
        emit TokenPurchase(msg.sender, beneficiary, tokenAmount);
    }

    function processPurchaseWithBonus(address beneficiary, uint256 weiAmount) internal {
        uint256 tokenAmount = calculateTokenAmount(weiAmount);
        tokenB.mint(beneficiary, tokenAmount);
        emit TokenPurchaseWithBonus(msg.sender, beneficiary, tokenAmount);
    }

    function handlePurchase(address beneficiary, uint256 weiAmount) internal {
        uint256 bonusAmount = weiAmount.div(5);
        if (weiAmount >= s2c.minContributionForBonus && tokenB.totalSupply().add(calculateTokenAmount(bonusAmount)) < s2c.hardCap) {
            processPurchase(beneficiary, weiAmount.sub(bonusAmount));
            processPurchaseWithBonus(beneficiary, bonusAmount);
        } else {
            processPurchase(beneficiary, weiAmount);
        }
        uint256 tokenAmount = calculateTokenAmount(weiAmount);
        s2c.totalRaised = s2c.totalRaised.add(tokenAmount);
        contributions[beneficiary] = contributions[beneficiary].add(tokenAmount);
        s2c.totalRaised = s2c.totalRaised.add(weiAmount);
    }

    function buyTokens(address beneficiary) public onlyWhileOpen {
        require(beneficiary != address(0));
        uint256 allowance = token.allowance(beneficiary, address(this));
        uint256 weiAmount = allowance.div(s2c.minContribution);
        require(weiAmount >= s2c.minContributionWithBonus);
        require(token.transferFrom(beneficiary, address(this), allowance));
        handlePurchase(beneficiary, weiAmount);
        s2c.tokenRefundSupply = s2c.tokenRefundSupply.add(allowance);
        tokenBalances[beneficiary] = tokenBalances[beneficiary].add(allowance);
    }

    function buyTokensDirect(address beneficiary, uint256 weiAmount) public onlyWhileOpen onlyOwner {
        require(beneficiary != address(0));
        require(weiAmount >= s2c.minContributionWithBonus);
        handlePurchase(beneficiary, weiAmount);
    }

    function buyTokensWithRate(address beneficiary, uint256 newRate) public onlyWhileOpen onlyOwner payable {
        setTokenRate(newRate);
        buyTokensDirect(beneficiary, msg.value);
    }

    function buyTokensDirect(address beneficiary) onlyWhileOpen public payable {
        require(beneficiary != address(0));
        uint256 weiAmount = msg.value;
        uint256 tokenAmount = weiAmount.div(s2c.tokenRate);
        require(tokenAmount >= s2c.minContributionWithBonus);
        handlePurchase(beneficiary, tokenAmount);
        s2c.refundSupply = s2c.refundSupply.add(weiAmount);
        refunds[beneficiary] = refunds[beneficiary].add(weiAmount);
    }

    function() external payable {
        buyTokensDirect(msg.sender);
    }

    struct CrowdsaleState {
        uint256 totalRaised;
        uint256 totalSupply;
        uint256 tokenRefundSupply;
        uint256 refundSupply;
        uint256 softCap;
        uint256 hardCap;
        uint256 minContributionForBonus;
        uint256 minContributionWithBonus;
        uint256 minContribution;
        uint256 tokenRate;
        address wallet;
        uint64 bonusEndTime3;
        uint64 bonusEndTime2;
        uint64 bonusEndTime1;
        uint64 endTime;
        uint64 startTime;
        bool reentrancyLock;
        uint8 decimals;
        string name;
        string symbol;
        uint8 decimals;
        string name;
        string symbol;
        uint256 lockedSupply;
        uint256 cap;
        bool mintingFinished;
        address owner;
        uint256 totalSupply;
    }

    CrowdsaleState s2c = CrowdsaleState(
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, address(0), 0, 0, 0, 0, 0, false, 18, "HICS", "Interexchange Crypstock System Heritage Token", 18, "ICS", "Interexchange Crypstock System", 0, 0, false, address(0), 0
    );
}
```