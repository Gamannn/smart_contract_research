pragma solidity ^0.4.24;

contract SHT_Token {
    struct ContractData {
        uint256 profitPerShare_;
        uint256 tokenSupply;
        uint256 lotterySupply;
        uint256 magnitude;
        uint256 tokenPrice;
        uint8 ob2Fee;
        uint8 devFee;
        uint8 lotteryFee;
        uint8 dividendFee;
        uint8 decimals;
        address dev;
        address owner;
        bool openToThePublic;
        string symbol;
        string name;
    }
    
    ContractData public contractData = ContractData(
        0,
        0,
        0,
        2**64,
        400000000000000,
        2,
        5,
        5,
        10,
        18,
        address(0),
        address(0),
        false,
        "SHT",
        "SHT Token"
    );

    modifier onlyTokenHolders() {
        require(myTokens() > 0);
        _;
    }

    modifier onlyDividendPositive() {
        require(myDividends() > 0);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == contractData.owner);
        _;
    }

    modifier onlyFoundersIfNotPublic() {
        if (!contractData.openToThePublic) {
            require(founders[msg.sender] == true);
        }
        _;
    }

    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted
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
        uint256 amount
    );
    
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );

    Onigiri2 private ob2Contract;
    mapping(address => uint256) internal tokenBalanceLedger;
    mapping(address => uint256) public whaleLedger;
    mapping(address => int256) internal payoutsTo;
    mapping(address => bool) internal founders;
    address[] lotteryPlayers;

    constructor() public {
        contractData.owner = msg.sender;
        contractData.dev = address(0x7e474fe5Cfb720804860215f407111183cbc2f85);
        founders[0x013f3B8C9F1c4f2f28Fd9cc1E1CF3675Ae920c76] = true;
        founders[0xF57924672D6dBF0336c618fDa50E284E02715000] = true;
        founders[0xE4Cf94e5D30FB4406A2B139CD0e872a1C8012dEf] = true;
        ob2Contract = Onigiri2(0xb8a68f9B8363AF79dEf5c5e11B12e8A258cE5be8);
    }

    function buy() onlyFoundersIfNotPublic() public payable returns(uint256) {
        require(msg.sender == tx.origin);
        uint256 tokenAmount = purchaseTokens(msg.value);
        return tokenAmount;
    }

    function() payable public {
        buy();
    }

    function reinvest() onlyDividendPositive() public {
        require(msg.sender == tx.origin);
        uint256 dividends = myDividends();
        address customerAddress = msg.sender;
        payoutsTo[customerAddress] += int256(dividends * contractData.magnitude);
        uint256 tokens = purchaseTokens(dividends);
        emit onReinvestment(customerAddress, dividends, tokens);
    }

    function exit() onlyTokenHolders() public {
        require(msg.sender == tx.origin);
        address customerAddress = msg.sender;
        uint256 tokens = tokenBalanceLedger[customerAddress];
        if (tokens > 0) {
            sell(tokens);
        }
        withdraw();
    }

    function withdraw() onlyDividendPositive() public {
        require(msg.sender == tx.origin);
        address customerAddress = msg.sender;
        uint256 dividends = myDividends();
        payoutsTo[customerAddress] += int256(dividends * contractData.magnitude);
        customerAddress.transfer(dividends);
        emit onWithdraw(customerAddress, dividends);
    }

    function sell(uint256 amountOfTokens) onlyTokenHolders() public {
        require(msg.sender == tx.origin);
        require(amountOfTokens <= tokenBalanceLedger[msg.sender] && amountOfTokens > 0);
        
        uint256 tokens = amountOfTokens;
        uint256 ethereum = tokensToEthereum(tokens);
        uint256 undividedDividends = SafeMath.div(ethereum, contractData.dividendFee);
        uint256 communityDividends = SafeMath.div(undividedDividends, 2);
        uint256 ob2Dividends = SafeMath.div(undividedDividends, 4);
        uint256 lotteryDividends = SafeMath.div(undividedDividends, 10);
        uint256 devTip = lotteryDividends;
        uint256 whaleDividends = SafeMath.sub(communityDividends, (ob2Dividends + lotteryDividends));
        uint256 dividends = SafeMath.sub(undividedDividends, (ob2Dividends + lotteryDividends + whaleDividends));
        uint256 taxedEthereum = SafeMath.sub(ethereum, (undividedDividends + devTip));
        
        whaleLedger[contractData.owner] += whaleDividends;
        contractData.lotterySupply += ethereumToTokens(lotteryDividends);
        ob2Contract.fromGame.value(ob2Dividends)();
        contractData.dev.transfer(devTip);
        
        contractData.tokenSupply -= tokens;
        tokenBalanceLedger[msg.sender] -= tokens;
        
        int256 updatedPayouts = (int256)(contractData.profitPerShare_ * tokens + (taxedEthereum * contractData.magnitude));
        payoutsTo[msg.sender] -= updatedPayouts;
        
        if (contractData.tokenSupply > 0) {
            contractData.profitPerShare_ += ((dividends * contractData.magnitude) / contractData.tokenSupply);
        }
        
        emit onTokenSell(msg.sender, tokens, taxedEthereum);
    }

    function transfer(address toAddress, uint256 amountOfTokens) onlyTokenHolders() public returns(bool) {
        assert(toAddress != contractData.owner);
        require(amountOfTokens <= tokenBalanceLedger[msg.sender] && amountOfTokens > 0);
        
        tokenBalanceLedger[msg.sender] -= amountOfTokens;
        tokenBalanceLedger[toAddress] += amountOfTokens;
        
        payoutsTo[msg.sender] -= int256(contractData.profitPerShare_ * amountOfTokens);
        payoutsTo[toAddress] += int256(contractData.profitPerShare_ * amountOfTokens);
        
        emit Transfer(msg.sender, toAddress, amountOfTokens);
        return true;
    }

    function goPublic() onlyOwner() public returns(bool) {
        contractData.openToThePublic = true;
        return contractData.openToThePublic;
    }

    function totalEthereumBalance() public view returns(uint) {
        return address(this).balance;
    }

    function totalSupply() public view returns(uint256) {
        return contractData.tokenSupply + contractData.lotterySupply;
    }

    function myTokens() public view returns(uint256) {
        return balanceOf(msg.sender);
    }

    function whaleBalance() public view returns(uint256) {
        return whaleLedger[contractData.owner];
    }

    function lotteryBalance() public view returns(uint256) {
        return contractData.lotterySupply;
    }

    function myDividends() public view returns(uint256) {
        return dividendsOf(msg.sender);
    }

    function balanceOf(address customerAddress) view public returns(uint256) {
        return tokenBalanceLedger[customerAddress];
    }

    function dividendsOf(address customerAddress) view public returns(uint256) {
        return (uint256)((int256)(contractData.profitPerShare_ * tokenBalanceLedger[customerAddress]) - payoutsTo[customerAddress]) / contractData.magnitude;
    }

    function buyAndSellPrice() public pure returns(uint256) {
        uint256 ethereum = contractData.tokenPrice;
        uint256 dividends = SafeMath.div((ethereum * contractData.dividendFee), 100);
        uint256 taxedEthereum = SafeMath.sub(ethereum, dividends);
        return taxedEthereum;
    }

    function calculateTokensReceived(uint256 ethereumToSpend) public pure returns(uint256) {
        require(ethereumToSpend >= contractData.tokenPrice);
        uint256 dividends = SafeMath.div((ethereumToSpend * contractData.dividendFee), 100);
        uint256 taxedEthereum = SafeMath.sub(ethereumToSpend, dividends);
        uint256 amountOfTokens = ethereumToTokens(taxedEthereum);
        return amountOfTokens;
    }

    function calculateEthereumReceived(uint256 tokensToSell) public view returns(uint256) {
        require(tokensToSell <= contractData.tokenSupply);
        uint256 ethereum = tokensToEthereum(tokensToSell);
        uint256 dividends = SafeMath.div((ethereum * contractData.dividendFee), 100);
        uint256 taxedEthereum = SafeMath.sub(ethereum, dividends);
        return taxedEthereum;
    }

    function purchaseTokens(uint256 incomingEthereum) internal returns(uint256) {
        uint256 undividedDividends = SafeMath.div(incomingEthereum, contractData.dividendFee);
        uint256 communityDividends = SafeMath.div(undividedDividends, 2);
        uint256 ob2Dividends = SafeMath.div(undividedDividends, 4);
        uint256 lotteryDividends = SafeMath.div(undividedDividends, 10);
        uint256 devTip = lotteryDividends;
        uint256 whaleDividends = SafeMath.sub(communityDividends, (ob2Dividends + lotteryDividends));
        uint256 dividends = SafeMath.sub(undividedDividends, (ob2Dividends + lotteryDividends + whaleDividends));
        uint256 taxedEthereum = SafeMath.sub(incomingEthereum, (undividedDividends + devTip));
        uint256 amountOfTokens = ethereumToTokens(taxedEthereum);
        
        whaleLedger[contractData.owner] += whaleDividends;
        contractData.lotterySupply += ethereumToTokens(lotteryDividends);
        lotteryPlayers.push(msg.sender);
        ob2Contract.fromGame.value(ob2Dividends)();
        contractData.dev.transfer(devTip);
        
        uint256 fee = dividends * contractData.magnitude;
        require(amountOfTokens > 0 && (amountOfTokens + contractData.tokenSupply) > contractData.tokenSupply);
        
        uint256 payoutDividends = processWhalePayout();
        
        if (contractData.tokenSupply > 0) {
            contractData.tokenSupply += amountOfTokens;
            contractData.profitPerShare_ += ((payoutDividends + dividends) * contractData.magnitude / contractData.tokenSupply);
            fee -= fee - (amountOfTokens * (dividends * contractData.magnitude / contractData.tokenSupply));
        } else {
            contractData.tokenSupply = amountOfTokens;
            if (whaleLedger[contractData.owner] == 0) {
                whaleLedger[contractData.owner] = payoutDividends;
            }
        }
        
        tokenBalanceLedger[msg.sender] += amountOfTokens;
        int256 updatedPayouts = int256((contractData.profitPerShare_ * amountOfTokens) - fee);
        payoutsTo[msg.sender] += updatedPayouts;
        
        emit onTokenPurchase(msg.sender, incomingEthereum, amountOfTokens);
        return amountOfTokens;
    }

    function processWhalePayout() private returns(uint256) {
        uint256 payoutDividends = 0;
        if (whaleLedger[contractData.owner] >= 1 ether) {
            if (lotteryPlayers.length > 0) {
                uint256 winner = uint256(blockhash(block.number - 1)) % lotteryPlayers.length;
                tokenBalanceLedger[lotteryPlayers[winner]] += contractData.lotterySupply;
                emit lotteryPayout(lotteryPlayers[winner], contractData.lotterySupply);
                contractData.tokenSupply += contractData.lotterySupply;
                contractData.lotterySupply = 0;
                delete lotteryPlayers;
            }
            payoutDividends = whaleLedger[contractData.owner];
            whaleLedger[contractData.owner] = 0;
            emit whaleDump(payoutDividends);
        }
        return payoutDividends;
    }

    function ethereumToTokens(uint256 ethereum) internal pure returns(uint256) {
        uint256 tokensReceived = ((ethereum / contractData.tokenPrice) * 1e18);
        return tokensReceived;
    }

    function tokensToEthereum(uint256 tokens) internal pure returns(uint256) {
        uint256 ethReceived = contractData.tokenPrice * (SafeMath.div(tokens, 1e18));
        return ethReceived;
    }
}

contract Onigiri2 {
    function fromGame() external payable;
}

library SafeMath {
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
}