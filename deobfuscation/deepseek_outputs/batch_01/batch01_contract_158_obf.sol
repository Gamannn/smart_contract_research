```solidity
pragma solidity ^0.4.24;

contract _8thereum {
    struct ContractData {
        uint256 profitPerShare;
        uint256 gameSupply;
        uint256 tokenSupply;
        uint256 lotterySupply;
        uint256 referralLinkRequirement;
        uint256 magnitude;
        uint256 tokenPrice;
        uint8 dividendFee;
        uint8 decimals;
        address owner;
        bool openToThePublic;
        string symbol;
        string name;
    }
    
    ContractData public contractData = ContractData(
        0,
        0,
        0,
        0,
        5e18,
        2**64,
        500000000000000,
        15,
        18,
        address(0),
        false,
        "BIT",
        "8thereum"
    );
    
    modifier onlyTokenHolders() {
        require(myTokens() > 0);
        _;
    }
    
    modifier onlyDividendPositive() {
        require(myDividends(true) > 0);
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == contractData.owner);
        _;
    }
    
    modifier onlyNonOwner() {
        require(msg.sender != contractData.owner);
        _;
    }
    
    modifier onlyFoundersIfNotPublic() {
        if(!contractData.openToThePublic) {
            require(founders[msg.sender] == true);
        }
        _;
    }
    
    modifier onlyApprovedContracts() {
        if(!gameList[msg.sender]) {
            require(msg.sender == tx.origin);
        }
        _;
    }
    
    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address indexed referredBy
    );
    
    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 ethereumEarned
    );
    
    event onReinvestment(
        address indexed customerAddress,
        uint256 ethereumReinvested,
        uint256 tokensMinted
    );
    
    event onWithdraw(
        address indexed customerAddress,
        uint256 ethereumWithdrawn
    );
    
    event lotteryPayout(
        address customerAddress,
        uint256 lotterySupply
    );
    
    event whaleDump(
        uint256 whaleBalance
    );
    
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );
    
    mapping(address => bool) internal gameList;
    mapping(address => uint256) internal tokenBalanceLedger;
    mapping(address => uint256) public whaleBalanceLedger;
    mapping(address => uint256) public gameBalanceLedger;
    mapping(address => uint256) internal referralBalance;
    mapping(address => int256) internal payoutsTo;
    mapping(address => mapping(address => uint256)) public gamePlayers;
    mapping(address => bool) internal founders;
    
    address[] lotteryPlayers;
    
    constructor() public {
        contractData.owner = msg.sender;
        founders[contractData.owner] = true;
        founders[0x7e474fe5Cfb720804860215f407111183cbc2f85] = true;
        founders[0x5138240E96360ad64010C27eB0c685A8b2eDE4F2] = true;
        founders[0xAA7A7C2DECB180f68F11E975e6D92B5Dc06083A6] = true;
        founders[0x6DC622a04Fd13B6a1C3C5B229CA642b8e50e1e74] = true;
        founders[0x41a21b264F9ebF6cF571D4543a5b3AB1c6bEd98C] = true;
    }
    
    function buy(address referredBy) 
        onlyFoundersIfNotPublic() 
        public 
        payable 
        returns(uint256) 
    {
        require(msg.sender == tx.origin);
        return purchaseWithReferral(referredBy);
    }
    
    function() 
        onlyFoundersIfNotPublic() 
        payable 
        public 
    {
        require(msg.sender == tx.origin);
        purchaseWithReferral(address(0));
    }
    
    function reinvest() 
        onlyDividendPositive() 
        onlyNonOwner() 
        public 
    {
        require(msg.sender == tx.origin);
        uint256 dividends = myDividends(false);
        address customerAddress = msg.sender;
        
        payoutsTo[customerAddress] += int256(SafeMath.mul(dividends, contractData.magnitude));
        dividends += referralBalance[customerAddress];
        referralBalance[customerAddress] = 0;
        
        uint256 tokens = purchaseTokens(dividends, address(0));
        emit onReinvestment(customerAddress, dividends, tokens);
    }
    
    function exit() 
        onlyNonOwner() 
        onlyTokenHolders() 
        public 
    {
        require(msg.sender == tx.origin);
        address customerAddress = msg.sender;
        uint256 tokens = tokenBalanceLedger[customerAddress];
        
        if(tokens > 0) {
            sell(tokens);
        }
        withdraw();
    }
    
    function withdraw() 
        onlyNonOwner() 
        onlyDividendPositive() 
        public 
    {
        require(msg.sender == tx.origin);
        address customerAddress = msg.sender;
        uint256 dividends = myDividends(false);
        
        payoutsTo[customerAddress] += int256(SafeMath.mul(dividends, contractData.magnitude));
        dividends += referralBalance[customerAddress];
        referralBalance[customerAddress] = 0;
        
        customerAddress.transfer(dividends);
        emit onWithdraw(customerAddress, dividends);
    }
    
    function sell(uint256 amountOfTokens) 
        onlyNonOwner() 
        onlyTokenHolders() 
        public 
    {
        require(msg.sender == tx.origin);
        require(amountOfTokens <= tokenBalanceLedger[msg.sender] && amountOfTokens > 0);
        
        uint256 tokens = amountOfTokens;
        uint256 ethereum = tokensToEthereum(tokens);
        uint256 dividends = (ethereum * contractData.dividendFee) / 100;
        uint256 taxedEthereum = SafeMath.sub(ethereum, dividends);
        
        uint256 lotteryAndWhaleFee = dividends / 3;
        dividends -= lotteryAndWhaleFee;
        
        uint256 lotteryFee = lotteryAndWhaleFee / 2;
        uint256 whaleFee = lotteryAndWhaleFee - lotteryFee;
        
        whaleBalanceLedger[contractData.owner] += whaleFee;
        contractData.lotterySupply += ethereumToTokens(lotteryFee);
        
        contractData.tokenSupply -= tokens;
        tokenBalanceLedger[msg.sender] -= tokens;
        
        int256 updatedPayouts = int256(contractData.profitPerShare * tokens + (taxedEthereum * contractData.magnitude));
        payoutsTo[msg.sender] -= updatedPayouts;
        
        if (contractData.tokenSupply > 0) {
            contractData.profitPerShare = SafeMath.add(
                contractData.profitPerShare,
                (dividends * contractData.magnitude) / contractData.tokenSupply
            );
        }
        
        emit onTokenSell(msg.sender, tokens, taxedEthereum);
    }
    
    function transfer(address toAddress, uint256 amountOfTokens) 
        onlyNonOwner() 
        onlyTokenHolders() 
        onlyApprovedContracts() 
        public 
        returns(bool) 
    {
        require(toAddress != contractData.owner);
        
        if(gameList[msg.sender] == true) {
            require(amountOfTokens <= gameBalanceLedger[msg.sender] && amountOfTokens > 0);
            gameBalanceLedger[msg.sender] -= amountOfTokens;
            contractData.gameSupply -= amountOfTokens;
            tokenBalanceLedger[toAddress] += amountOfTokens;
            payoutsTo[toAddress] += int256(contractData.profitPerShare * amountOfTokens);
        } 
        else if (gameList[toAddress] == true) {
            require(
                amountOfTokens <= tokenBalanceLedger[msg.sender] && 
                amountOfTokens > 0 && 
                amountOfTokens == 1e18
            );
            tokenBalanceLedger[msg.sender] -= amountOfTokens;
            gameBalanceLedger[toAddress] += amountOfTokens;
            contractData.gameSupply += amountOfTokens;
            gamePlayers[toAddress][msg.sender] += amountOfTokens;
            payoutsTo[msg.sender] -= int256(contractData.profitPerShare * amountOfTokens);
        } 
        else {
            require(amountOfTokens <= tokenBalanceLedger[msg.sender] && amountOfTokens > 0);
            tokenBalanceLedger[msg.sender] -= amountOfTokens;
            tokenBalanceLedger[toAddress] += amountOfTokens;
            payoutsTo[msg.sender] -= int256(contractData.profitPerShare * amountOfTokens);
            payoutsTo[toAddress] += int256(contractData.profitPerShare * amountOfTokens);
        }
        
        emit Transfer(msg.sender, toAddress, amountOfTokens);
        return true;
    }
    
    function setGames(address newGameAddress) 
        onlyOwner() 
        public 
    {
        gameList[newGameAddress] = true;
    }
    
    function goPublic() 
        onlyOwner() 
        public 
        returns(bool) 
    {
        contractData.openToThePublic = true;
        return contractData.openToThePublic;
    }
    
    function totalEthereumBalance() 
        public 
        view 
        returns(uint) 
    {
        return address(this).balance;
    }
    
    function totalSupply() 
        public 
        view 
        returns(uint256) 
    {
        return contractData.tokenSupply + contractData.lotterySupply + contractData.gameSupply;
    }
    
    function myTokens() 
        public 
        view 
        returns(uint256) 
    {
        return balanceOf(msg.sender);
    }
    
    function myDividends(bool includeReferralBonus) 
        public 
        view 
        returns(uint256) 
    {
        return includeReferralBonus ? 
            dividendsOf(msg.sender) + referralBalance[msg.sender] : 
            dividendsOf(msg.sender);
    }
    
    function balanceOf(address customerAddress) 
        public 
        view 
        returns(uint256) 
    {
        if (customerAddress == contractData.owner) {
            return whaleBalanceLedger[customerAddress];
        } else if(gameList[customerAddress] == true) {
            return gameBalanceLedger[customerAddress];
        } else {
            return tokenBalanceLedger[customerAddress];
        }
    }
    
    function dividendsOf(address customerAddress) 
        public 
        view 
        returns(uint256) 
    {
        return uint256(
            int256(contractData.profitPerShare * tokenBalanceLedger[customerAddress]) - 
            payoutsTo[customerAddress]
        ) / contractData.magnitude;
    }
    
    function buyAndSellPrice() 
        public 
        pure 
        returns(uint256) 
    {
        uint256 ethereum = contractData.tokenPrice;
        uint256 dividends = (ethereum * contractData.dividendFee) / 100;
        uint256 taxedEthereum = ethereum - dividends;
        return taxedEthereum;
    }
    
    function calculateTokensReceived(uint256 ethereumToSpend) 
        public 
        pure 
        returns(uint256) 
    {
        require(ethereumToSpend >= contractData.tokenPrice);
        uint256 dividends = (ethereumToSpend * contractData.dividendFee) / 100;
        uint256 taxedEthereum = ethereumToSpend - dividends;
        uint256 amountOfTokens = ethereumToTokens(taxedEthereum);
        return amountOfTokens;
    }
    
    function calculateEthereumReceived(uint256 tokensToSell) 
        public 
        view 
        returns(uint256) 
    {
        require(tokensToSell <= contractData.tokenSupply);
        uint256 ethereum = tokensToEthereum(tokensToSell);
        uint256 dividends = (ethereum * contractData.dividendFee) / 100;
        uint256 taxedEthereum = ethereum - dividends;
        return taxedEthereum;
    }
    
    function purchaseWithReferral(address referredBy) 
        onlyNonOwner() 
        internal 
        returns(uint256) 
    {
        require(msg.sender == tx.origin);
        uint256 tokenAmount = purchaseTokens(msg.value, referredBy);
        
        if(gameList[msg.sender] == true) {
            contractData.tokenSupply = SafeMath.sub(contractData.tokenSupply, tokenAmount);
            tokenBalanceLedger[msg.sender] = SafeMath.sub(tokenBalanceLedger[msg.sender], tokenAmount);
            gameBalanceLedger[msg.sender] += tokenAmount;
            contractData.gameSupply += tokenAmount;
        }
        
        return tokenAmount;
    }
    
    function purchaseTokens(uint256 incomingEthereum, address referredBy) 
        internal 
        returns(uint256) 
    {
        require(msg.sender == tx.origin);
        
        uint256 undividedDividends = (incomingEthereum * contractData.dividendFee) / 100;
        uint256 lotteryAndWhaleFee = undividedDividends / 3;
        uint256 referralBonus = lotteryAndWhaleFee;
        uint256 dividends = undividedDividends - (referralBonus + lotteryAndWhaleFee);
        uint256 taxedEthereum = incomingEthereum - undividedDividends;
        uint256 amountOfTokens = ethereumToTokens(taxedEthereum);
        
        uint256 whaleFee = lotteryAndWhaleFee / 2;
        whaleBalanceLedger[contractData.owner] += whaleFee;
        contractData.lotterySupply += ethereumToTokens(lotteryAndWhaleFee - whaleFee);
        
        lotteryPlayers.push(msg.sender);
        
        uint256 fee = dividends * contractData.magnitude;
        require(
            amountOfTokens > 0 && 
            (amountOfTokens + contractData.tokenSupply) > contractData.tokenSupply
        );
        
        if(referredBy != address(0) && 
           referredBy != msg.sender && 
           gameList[referredBy] == false && 
           tokenBalanceLedger[referredBy] >= contractData.referralLinkRequirement) 
        {
            referralBalance[referredBy] += referralBonus;
        } else {
            dividends += referralBonus;
            fee = dividends * contractData.magnitude;
        }
        
        uint256 payoutDividends = processWhalePayout();
        
        if(contractData.tokenSupply > 0) {
            contractData.tokenSupply += amountOfTokens;
            contractData.profitPerShare += (
                (payoutDividends + dividends) * contractData.magnitude / contractData.tokenSupply
            );
            fee = fee - (amountOfTokens * (dividends * contractData.magnitude / contractData.tokenSupply));
        } else {
            contractData.tokenSupply = amountOfTokens;
            if(whaleBalanceLedger[contractData.owner] == 0) {
                whaleBalanceLedger[contractData.owner] = payoutDividends;
            }
        }
        
        tokenBalanceLedger[msg.sender] += amountOfTokens;
        int256 updatedPayouts = int256(
            (contractData.profitPerShare * amountOfTokens) - fee
        );
        payoutsTo[msg.sender] += updatedPayouts;
        
        emit onTokenPurchase(msg.sender, incomingEthereum, amountOfTokens, referredBy);
        return amountOfTokens;
    }
    
    function processWhalePayout() 
        private 
        returns(uint256) 
    {
        uint256 payoutDividends = 0;
        
        if(whaleBalanceLedger[contractData.owner] >= 1 ether) {
            if(lotteryPlayers.length > 0) {
                uint256 winner = uint256(blockhash(block.number - 1)) % lotteryPlayers.length;
                tokenBalanceLedger[lotteryPlayers[winner]] += contractData.lotterySupply;
                emit lotteryPayout(lotteryPlayers[winner], contractData.lotterySupply);
                contractData.tokenSupply += contractData.lotterySupply;
                contractData.lotterySupply = 0;
                delete lotteryPlayers;
            }
            
            payoutDividends = whaleBalanceLedger[contractData.owner];
            whaleBalanceLedger[contractData.owner] = 0;
            emit whaleDump(payoutDividends);
        }
        
        return payoutDividends;
    }
    
    function ethereumToTokens(uint256 ethereum) 
        internal 
        pure 
        returns(uint256) 
    {
        return (ethereum / contractData.tokenPrice) * 1e18;
    }
    
    function tokensToEthereum(uint256 tokens) 
        internal 
        pure 
        returns(uint256) 
    {
        return contractData.tokenPrice * (tokens / 1e18);
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
```