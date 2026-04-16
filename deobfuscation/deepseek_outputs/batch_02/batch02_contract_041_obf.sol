```solidity
pragma solidity ^0.4.20;

contract DailyDivs {
    using SafeMath for uint256;
    
    address public owner;
    address public ceoAddress;
    
    mapping(address => address) public referrer;
    mapping(address => uint256) public referralBalance;
    mapping(address => uint256) public referralCount;
    mapping(address => uint256) public tokenBalance;
    mapping(address => int256) public payouts;
    
    uint256 public totalSupply;
    uint256 public profitPerShare;
    uint256 public tokenPriceInitial;
    uint256 public magnitude;
    uint256 public dividendFee;
    
    event onTokenPurchase(
        address indexed customer,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address indexed referredBy
    );
    
    event onTokenSell(
        address indexed customer,
        uint256 tokensBurned,
        uint256 ethereumEarned
    );
    
    event onReinvestment(
        address indexed customer,
        uint256 ethereumReinvested,
        uint256 tokensMinted
    );
    
    event onWithdraw(
        address indexed customer,
        uint256 ethereumWithdrawn
    );
    
    constructor() public {
        owner = msg.sender;
        ceoAddress = 0x93c5371707D2e015aEB94DeCBC7892eC1fa8dd80;
        tokenPriceInitial = 0.0000000001 ether;
        magnitude = 2**64;
        dividendFee = 98;
    }
    
    function buyPrice() public view returns(uint256) {
        return tokenPriceInitial;
    }
    
    function sellPrice() public view returns(uint256) {
        return tokenPriceInitial;
    }
    
    function calculateTokensReceived(uint256 ethereumToSpend) public view returns(uint256) {
        uint256 dividends = ethereumToSpend.mul(dividendFee).div(100);
        uint256 taxedEthereum = ethereumToSpend.sub(dividends);
        uint256 amountOfTokens = ethereumToTokens(taxedEthereum);
        return amountOfTokens;
    }
    
    function calculateEthereumReceived(uint256 tokensToSell) public view returns(uint256) {
        require(tokensToSell <= totalSupply);
        uint256 ethereum = tokensToEther(tokensToSell);
        uint256 dividends = ethereum.mul(dividendFee).div(100);
        uint256 taxedEthereum = ethereum.sub(dividends);
        return taxedEthereum;
    }
    
    function dividendsOf(address customer) public view returns(uint256) {
        return (uint256) ((int256)(profitPerShare * tokenBalance[customer]) - payouts[customer]) / magnitude;
    }
    
    function myDividends() public view returns(uint256) {
        return dividendsOf(msg.sender);
    }
    
    function myTokens() public view returns(uint256) {
        return tokenBalance[msg.sender];
    }
    
    function balance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function sellPriceFor(address customer) public view returns(uint256) {
        return calculateEthereumReceived(tokenBalance[customer]);
    }
    
    function buy() public payable {
        purchaseTokens(msg.value, address(0));
    }
    
    function buyFor(address referredBy) public payable {
        require(referredBy != msg.sender);
        
        if (referrer[msg.sender] == address(0) && referredBy != address(0)) {
            referrer[msg.sender] = referredBy;
            referralCount[referredBy] = referralCount[referredBy].add(1);
        }
        
        purchaseTokens(msg.value, referredBy);
    }
    
    function purchaseTokens(uint256 incomingEthereum, address referredBy) private {
        address customer = msg.sender;
        uint256 dividends = incomingEthereum.mul(dividendFee).div(100);
        uint256 taxedEthereum = incomingEthereum.sub(dividends);
        uint256 amountOfTokens = ethereumToTokens(taxedEthereum);
        uint256 fee = dividends * magnitude;
        
        require(amountOfTokens > 0 && (amountOfTokens.add(totalSupply) > totalSupply));
        
        if (totalSupply > 0) {
            totalSupply = totalSupply.add(amountOfTokens);
            profitPerShare = profitPerShare.add((fee.sub(amountOfTokens.mul(profitPerShare))) / totalSupply);
        } else {
            totalSupply = amountOfTokens;
        }
        
        tokenBalance[customer] = tokenBalance[customer].add(amountOfTokens);
        payouts[customer] += (int256) (profitPerShare * amountOfTokens - fee);
        
        if (referredBy != address(0) && referredBy != customer) {
            referralBalance[referredBy] = referralBalance[referredBy].add(dividends.div(2));
        } else {
            referralBalance[ceoAddress] = referralBalance[ceoAddress].add(dividends.div(2));
        }
        
        emit onTokenPurchase(customer, incomingEthereum, amountOfTokens, referredBy);
    }
    
    function sell(uint256 amount) public {
        withdraw();
        sellTokens(amount);
        withdraw();
    }
    
    function withdraw() private {
        address customer = msg.sender;
        uint256 dividends = dividendsOf(customer);
        require(dividends > 0);
        
        payouts[customer] += (int256) (dividends * magnitude);
        customer.transfer(dividends);
        
        emit onWithdraw(customer, dividends);
    }
    
    function sellTokens(uint256 amount) private {
        address customer = msg.sender;
        require(tokenBalance[customer] > 0);
        require(amount <= tokenBalance[customer]);
        
        uint256 tokens = amount;
        uint256 ethereum = tokensToEther(tokens);
        uint256 dividends = ethereum.mul(dividendFee).div(100);
        uint256 taxedEthereum = ethereum.sub(dividends);
        
        tokenBalance[customer] = tokenBalance[customer].sub(tokens);
        int256 payoutDiff = (int256) (profitPerShare * tokens + (taxedEthereum * magnitude));
        payouts[customer] -= payoutDiff;
        
        emit onTokenSell(customer, tokens, taxedEthereum);
    }
    
    function reinvest() public {
        uint256 dividends = dividendsOf(msg.sender);
        require(dividends > 0);
        
        address customer = msg.sender;
        payouts[customer] += (int256) (dividends * magnitude);
        
        uint256 fee = dividends.div(2);
        if (referrer[customer] != address(0)) {
            referralBalance[referrer[customer]] = referralBalance[referrer[customer]].add(fee);
        } else {
            referralBalance[ceoAddress] = referralBalance[ceoAddress].add(fee);
        }
        
        uint256 taxedEthereum = dividends.sub(fee);
        purchaseTokens(taxedEthereum, referrer[customer]);
        
        emit onReinvestment(customer, dividends, taxedEthereum);
    }
    
    function ethereumToTokens(uint256 ethereum) private view returns(uint256) {
        uint256 tokens = ethereum.div(tokenPriceInitial);
        return tokens;
    }
    
    function tokensToEther(uint256 tokens) private view returns(uint256) {
        uint256 ethereum = tokens.mul(tokenPriceInitial);
        return ethereum;
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