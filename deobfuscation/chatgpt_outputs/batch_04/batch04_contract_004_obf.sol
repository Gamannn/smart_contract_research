```solidity
pragma solidity ^0.4.24;

contract TokenContract {
    modifier onlyNonZero(uint256 amount) {
        address sender = msg.sender;
        require((amount > 0) && (amount <= tokenBalance[sender]));
        _;
    }

    modifier onlyPositiveBalance() {
        address sender = msg.sender;
        require(getDividendBalance(sender) > 0);
        _;
    }

    modifier onlyAmbassadors() {
        address sender = msg.sender;
        require(ambassadors[sender] == true);
        _;
    }

    modifier onlyValidPurchase() {
        uint256 value = msg.value;
        uint256 tokenPrice = (tokenPriceInitial * 100) / 85;
        require((value >= tokenPrice) && (value >= calculateTokenPrice(value)));
        _;
    }

    event OnTokenPurchase(
        address indexed buyer,
        uint256 ethereumSpent,
        uint256 tokensMinted,
        uint256 newBalance,
        uint256 totalSupply
    );

    event OnTokenSell(
        address indexed seller,
        uint256 tokensBurned,
        uint256 ethereumEarned,
        uint256 newBalance,
        uint256 totalSupply
    );

    event OnReinvestment(
        address indexed investor,
        uint256 ethereumReinvested,
        uint256 tokensMinted,
        uint256 newBalance,
        uint256 totalSupply
    );

    event OnWithdraw(
        address indexed withdrawer,
        uint256 ethereumWithdrawn
    );

    event OnTotalProfitPot(
        uint256 totalProfit
    );

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );

    uint256 constant internal tokenPriceInitial = 1e19;
    mapping(address => bool) public ambassadors;
    mapping(address => uint256) public tokenBalance;
    mapping(address => int256) internal payoutsTo;
    uint256 public totalSupply;
    uint256 public profitPerShare = 0;
    uint256 public totalProfit = 0;
    uint256 constant internal magnitude = 2**64;
    uint256 constant internal dividendFee = 10;
    uint256 constant internal communityFee = 5;
    uint256 constant internal ambassadorQuota = 1e18;

    constructor() public {
        ambassadors[0x6dAd1d9D24674bC9199237F93beb6E25b55Ec763] = true;
        ambassadors[0x64BFD8F0F51569AEbeBE6AD2a1418462bCBeD842] = true;
    }

    function buyTokens() public payable {
        uint256 value = msg.value;
        if (isAmbassador && (ambassadorAccumulatedQuota[msg.sender] + value <= ambassadorQuota)) {
            require(ambassadors[msg.sender] == true);
            ambassadorAccumulatedQuota[msg.sender] += value;
            uint256 tokens = ethereumToTokens(value);
            tokenBalance[msg.sender] += tokens;
            totalSupply += tokens;
            emit OnTokenPurchase(msg.sender, value, tokens, tokenBalance[msg.sender], totalSupply);
        } else {
            revert();
        }
    }

    function reinvest() public onlyPositiveBalance {
        address sender = msg.sender;
        uint256 dividends = getDividendBalance(sender);
        payoutsTo[sender] += int256(dividends);
        uint256 tokens = ethereumToTokens(dividends);
        tokenBalance[sender] += tokens;
        totalSupply += tokens;
        emit OnReinvestment(sender, dividends, tokens, tokenBalance[sender], totalSupply);
    }

    function withdraw() public onlyPositiveBalance {
        address sender = msg.sender;
        uint256 dividends = getDividendBalance(sender);
        payoutsTo[sender] += int256(dividends);
        sender.transfer(dividends);
        emit OnWithdraw(sender, dividends);
    }

    function sellTokens(uint256 amount) public onlyNonZero(amount) {
        address sender = msg.sender;
        uint256 tokens = amount;
        uint256 ethereum = tokensToEthereum(tokens);
        require((tokenBalance[sender] >= tokens) && (totalSupply >= tokens) && (tokens > 0));
        tokenBalance[sender] -= tokens;
        totalSupply -= tokens;
        payoutsTo[sender] -= int256(profitPerShare * tokens);
        sender.transfer(ethereum);
        emit OnTokenSell(sender, tokens, ethereum, tokenBalance[sender], totalSupply);
    }

    function transfer(address to, uint256 amount) public onlyNonZero(amount) returns (bool) {
        address sender = msg.sender;
        if (getDividendBalance(sender) > 0) withdraw();
        tokenBalance[sender] -= amount;
        tokenBalance[to] += amount;
        payoutsTo[sender] -= int256(profitPerShare * amount);
        payoutsTo[to] += int256(profitPerShare * amount);
        emit Transfer(sender, to, amount);
        return true;
    }

    function setAmbassador(address ambassador, bool status) public onlyAmbassadors {
        ambassadors[ambassador] = status;
    }

    function setName(string name) public onlyAmbassadors {
        contractName = name;
    }

    function setSymbol(string symbol) public onlyAmbassadors {
        contractSymbol = symbol;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getSoldTokens() public view returns (uint256) {
        return totalSupply;
    }

    function getTokenBalance(address account) public view returns (uint256) {
        return tokenBalance[account];
    }

    function getPayoutsTo(address account) public view returns (int256) {
        return payoutsTo[account];
    }

    function getMyTokens() public view returns (uint256) {
        return getTokenBalance(msg.sender);
    }

    function getDividendBalance(address account) public view returns (uint256) {
        uint256 balance = tokenBalance[account];
        if ((profitPerShare * balance / magnitude) - payoutsTo[account] > 0) {
            return uint256((profitPerShare * balance / magnitude) - payoutsTo[account]);
        } else {
            return 0;
        }
    }

    function calculateTokenPrice(uint256 ethereum) public pure returns (uint256) {
        uint256 dividends = (ethereum * dividendFee) / 100;
        uint256 community = (ethereum * communityFee) / 100;
        uint256 taxedEthereum = ethereum - dividends - community;
        uint256 tokens = ethereumToTokens(taxedEthereum);
        return tokens;
    }

    function calculateEthereumReceived(uint256 tokens) public pure returns (uint256) {
        uint256 ethereum = tokensToEthereum(tokens);
        return ethereum;
    }

    function ethereumToTokens(uint256 ethereum) internal pure returns (uint256) {
        require(ethereum > 0);
        uint256 tokenPrice = tokenPriceInitial;
        uint256 tokens = (ethereum * magnitude) / tokenPrice;
        return tokens;
    }

    function tokensToEthereum(uint256 tokens) internal pure returns (uint256) {
        uint256 ethereum = (tokens * tokenPriceInitial) / magnitude;
        return ethereum;
    }
}
```