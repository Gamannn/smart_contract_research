pragma solidity ^0.4.24;

contract Eightthereum {
    using SafeMath for uint256;

    struct ContractData {
        uint256 profitPerShare_;
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

    ContractData internal contractData = ContractData(
        0, 0, 0, 0, 5e18, 2**64, 500000000000000, 15, 18, address(0), false, "BIT", "8thereum"
    );

    mapping(address => bool) internal gameList;
    mapping(address => uint256) internal publicTokenLedger;
    mapping(address => uint256) public whaleLedger;
    mapping(address => uint256) public gameLedger;
    mapping(address => uint256) internal referralBalances;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => mapping(address => uint256)) public gamePlayers;
    mapping(address => bool) internal founders;
    address[] lotteryPlayers;

    event onTokenPurchase(address indexed customerAddress, uint256 incomingEthereum, uint256 tokensMinted, address indexed referredBy);
    event onTokenSell(address indexed customerAddress, uint256 tokensBurned, uint256 ethereumEarned);
    event onReinvestment(address indexed customerAddress, uint256 ethereumReinvested, uint256 tokensMinted);
    event onWithdraw(address indexed customerAddress, uint256 ethereumWithdrawn);
    event lotteryPayout(address customerAddress, uint256 lotterySupply);
    event whaleDump(uint256 payoutDividends);
    event Transfer(address indexed from, address indexed to, uint256 tokens);

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
        if (!contractData.openToThePublic) {
            require(founders[msg.sender] == true);
        }
        _;
    }

    modifier onlyApprovedContracts() {
        if (!gameList[msg.sender]) {
            require(msg.sender == tx.origin);
        }
        _;
    }

    constructor() public {
        contractData.owner = msg.sender;
        founders[contractData.owner] = true;
        founders[0x7e474fe5Cfb720804860215f407111183cbc2f85] = true;
        founders[0x5138240E96360ad64010C27eB0c685A8b2eDE4F2] = true;
        founders[0xAA7A7C2DECB180f68F11E975e6D92B5Dc06083A6] = true;
        founders[0x6DC622a04Fd13B6a1C3C5B229CA642b8e50e1e74] = true;
        founders[0x41a21b264F9ebF6cF571D4543a5b3AB1c6bEd98C] = true;
    }

    function buy(address referredBy) onlyFoundersIfNotPublic() public payable returns (uint256) {
        require(msg.sender == tx.origin);
        return excludeWhale(referredBy);
    }

    function() onlyFoundersIfNotPublic() payable public {
        require(msg.sender == tx.origin);
        excludeWhale(0x0);
    }

    function reinvest() onlyDividendPositive() onlyNonOwner() public {
        require(msg.sender == tx.origin);
        uint256 dividends = myDividends(false);
        address customerAddress = msg.sender;
        payoutsTo_[customerAddress] += int256(dividends.mul(contractData.magnitude));
        dividends += referralBalances[customerAddress];
        referralBalances[customerAddress] = 0;
        uint256 tokens = purchaseTokens(dividends, 0x0);
        emit onReinvestment(customerAddress, dividends, tokens);
    }

    function exit() onlyNonOwner() onlyTokenHolders() public {
        require(msg.sender == tx.origin);
        address customerAddress = msg.sender;
        uint256 tokens = publicTokenLedger[customerAddress];
        if (tokens > 0) {
            sell(tokens);
        }
        withdraw();
    }

    function withdraw() onlyNonOwner() onlyDividendPositive() public {
        require(msg.sender == tx.origin);
        address customerAddress = msg.sender;
        uint256 dividends = myDividends(false);
        payoutsTo_[customerAddress] += int256(dividends.mul(contractData.magnitude));
        dividends += referralBalances[customerAddress];
        referralBalances[customerAddress] = 0;
        customerAddress.transfer(dividends);
        emit onWithdraw(customerAddress, dividends);
    }

    function sell(uint256 amountOfTokens) onlyNonOwner() onlyTokenHolders() public {
        require(msg.sender == tx.origin);
        require(amountOfTokens <= publicTokenLedger[msg.sender] && amountOfTokens > 0);
        uint256 tokens = amountOfTokens;
        uint256 ethereum = tokensToEthereum_(tokens);
        uint256 dividends = ethereum.mul(contractData.dividendFee).div(100);
        uint256 taxedEthereum = ethereum.sub(dividends);
        uint256 lotteryAndWhaleFee = dividends.div(3);
        dividends -= lotteryAndWhaleFee;
        uint256 lotteryFee = lotteryAndWhaleFee.div(2);
        uint256 whaleFee = lotteryAndWhaleFee.sub(lotteryFee);
        whaleLedger[contractData.owner] += whaleFee;
        contractData.lotterySupply += ethereumToTokens_(lotteryFee);
        contractData.tokenSupply -= tokens;
        publicTokenLedger[msg.sender] -= tokens;
        int256 updatedPayouts = int256(contractData.profitPerShare_ * tokens + taxedEthereum.mul(contractData.magnitude));
        payoutsTo_[msg.sender] -= updatedPayouts;
        if (contractData.tokenSupply > 0) {
            contractData.profitPerShare_ = contractData.profitPerShare_.add(dividends.mul(contractData.magnitude).div(contractData.tokenSupply));
        }
        emit onTokenSell(msg.sender, tokens, taxedEthereum);
    }

    function transfer(address toAddress, uint256 amountOfTokens) onlyNonOwner() onlyTokenHolders() onlyApprovedContracts() public returns (bool) {
        assert(toAddress != contractData.owner);
        if (gameList[msg.sender] == true) {
            require(amountOfTokens <= gameLedger[msg.sender] && amountOfTokens > 0);
            gameLedger[msg.sender] -= amountOfTokens;
            contractData.gameSupply -= amountOfTokens;
            publicTokenLedger[toAddress] += amountOfTokens;
            payoutsTo_[toAddress] += int256(contractData.profitPerShare_ * amountOfTokens);
        } else if (gameList[toAddress] == true) {
            require(amountOfTokens <= publicTokenLedger[msg.sender] && amountOfTokens > 0 && amountOfTokens == 1e18);
            publicTokenLedger[msg.sender] -= amountOfTokens;
            gameLedger[toAddress] += amountOfTokens;
            contractData.gameSupply += amountOfTokens;
            gamePlayers[toAddress][msg.sender] += amountOfTokens;
            payoutsTo_[msg.sender] -= int256(contractData.profitPerShare_ * amountOfTokens);
        } else {
            require(amountOfTokens <= publicTokenLedger[msg.sender] && amountOfTokens > 0);
            publicTokenLedger[msg.sender] -= amountOfTokens;
            publicTokenLedger[toAddress] += amountOfTokens;
            payoutsTo_[msg.sender] -= int256(contractData.profitPerShare_ * amountOfTokens);
            payoutsTo_[toAddress] += int256(contractData.profitPerShare_ * amountOfTokens);
        }
        emit Transfer(msg.sender, toAddress, amountOfTokens);
        return true;
    }

    function setGames(address newGameAddress) onlyOwner() public {
        gameList[newGameAddress] = true;
    }

    function goPublic() onlyOwner() public returns (bool) {
        contractData.openToThePublic = true;
        return contractData.openToThePublic;
    }

    function totalEthereumBalance() public view returns (uint) {
        return address(this).balance;
    }

    function totalSupply() public view returns (uint256) {
        return contractData.tokenSupply + contractData.lotterySupply + contractData.gameSupply;
    }

    function myTokens() public view returns (uint256) {
        return balanceOf(msg.sender);
    }

    function myDividends(bool includeReferralBonus) public view returns (uint256) {
        return includeReferralBonus ? dividendsOf(msg.sender) + referralBalances[msg.sender] : dividendsOf(msg.sender);
    }

    function balanceOf(address customerAddress) view public returns (uint256) {
        uint256 balance;
        if (customerAddress == contractData.owner) {
            balance = whaleLedger[customerAddress];
        } else if (gameList[customerAddress] == true) {
            balance = gameLedger[customerAddress];
        } else {
            balance = publicTokenLedger[customerAddress];
        }
        return balance;
    }

    function dividendsOf(address customerAddress) view public returns (uint256) {
        return uint256(int256(contractData.profitPerShare_ * publicTokenLedger[customerAddress]) - payoutsTo_[customerAddress]) / contractData.magnitude;
    }

    function buyAndSellPrice() public pure returns (uint256) {
        uint256 ethereum = contractData.tokenPrice;
        uint256 dividends = ethereum.mul(contractData.dividendFee).div(100);
        uint256 taxedEthereum = ethereum.sub(dividends);
        return taxedEthereum;
    }

    function calculateTokensReceived(uint256 ethereumToSpend) public pure returns (uint256) {
        require(ethereumToSpend >= contractData.tokenPrice);
        uint256 dividends = ethereumToSpend.mul(contractData.dividendFee).div(100);
        uint256 taxedEthereum = ethereumToSpend.sub(dividends);
        uint256 amountOfTokens = ethereumToTokens_(taxedEthereum);
        return amountOfTokens;
    }

    function calculateEthereumReceived(uint256 tokensToSell) public view returns (uint256) {
        require(tokensToSell <= contractData.tokenSupply);
        uint256 ethereum = tokensToEthereum_(tokensToSell);
        uint256 dividends = ethereum.mul(contractData.dividendFee).div(100);
        uint256 taxedEthereum = ethereum.sub(dividends);
        return taxedEthereum;
    }

    function excludeWhale(address referredBy) onlyNonOwner() internal returns (uint256) {
        require(msg.sender == tx.origin);
        uint256 tokenAmount = purchaseTokens(msg.value, referredBy);
        if (gameList[msg.sender] == true) {
            contractData.tokenSupply = contractData.tokenSupply.sub(tokenAmount);
            publicTokenLedger[msg.sender] = publicTokenLedger[msg.sender].sub(tokenAmount);
            gameLedger[msg.sender] += tokenAmount;
            contractData.gameSupply += tokenAmount;
        }
        return tokenAmount;
    }

    function purchaseTokens(uint256 incomingEthereum, address referredBy) internal returns (uint256) {
        require(msg.sender == tx.origin);
        uint256 undividedDivs = incomingEthereum.mul(contractData.dividendFee).div(100);
        uint256 lotteryAndWhaleFee = undividedDivs.div(3);
        uint256 referralBonus = lotteryAndWhaleFee;
        uint256 dividends = undividedDivs.sub(referralBonus + lotteryAndWhaleFee);
        uint256 taxedEthereum = incomingEthereum.sub(undividedDivs);
        uint256 amountOfTokens = ethereumToTokens_(taxedEthereum);
        uint256 whaleFee = lotteryAndWhaleFee.div(2);
        whaleLedger[contractData.owner] += whaleFee;
        contractData.lotterySupply += ethereumToTokens_(lotteryAndWhaleFee.sub(whaleFee));
        lotteryPlayers.push(msg.sender);
        uint256 fee = dividends.mul(contractData.magnitude);
        require(amountOfTokens > 0 && amountOfTokens.add(contractData.tokenSupply) > contractData.tokenSupply);
        if (referredBy != address(0) && referredBy != msg.sender && !gameList[referredBy] && publicTokenLedger[referredBy] >= contractData.referralLinkRequirement) {
            referralBalances[referredBy] += referralBonus;
        } else {
            dividends += referralBonus;
            fee = dividends.mul(contractData.magnitude);
        }
        uint256 payoutDividends = isWhalePaying();
        if (contractData.tokenSupply > 0) {
            contractData.tokenSupply += amountOfTokens;
            contractData.profitPerShare_ += (payoutDividends + dividends).mul(contractData.magnitude).div(contractData.tokenSupply);
            fee -= fee.sub(amountOfTokens.mul(dividends.mul(contractData.magnitude).div(contractData.tokenSupply)));
        } else {
            contractData.tokenSupply = amountOfTokens;
            if (whaleLedger[contractData.owner] == 0) {
                whaleLedger[contractData.owner] = payoutDividends;
            }
        }
        publicTokenLedger[msg.sender] += amountOfTokens;
        int256 updatedPayouts = int256(contractData.profitPerShare_ * amountOfTokens - fee);
        payoutsTo_[msg.sender] += updatedPayouts;
        emit onTokenPurchase(msg.sender, incomingEthereum, amountOfTokens, referredBy);
        return amountOfTokens;
    }

    function isWhalePaying() private returns (uint256) {
        uint256 payoutDividends = 0;
        if (whaleLedger[contractData.owner] >= 1 ether) {
            if (lotteryPlayers.length > 0) {
                uint256 winner = uint256(blockhash(block.number - 1)) % lotteryPlayers.length;
                publicTokenLedger[lotteryPlayers[winner]] += contractData.lotterySupply;
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

    function ethereumToTokens_(uint256 ethereum) internal pure returns (uint256) {
        uint256 tokensReceived = (ethereum.div(contractData.tokenPrice)).mul(1e18);
        return tokensReceived;
    }

    function tokensToEthereum_(uint256 tokens) internal pure returns (uint256) {
        uint256 ethReceived = contractData.tokenPrice.mul(tokens.div(1e18));
        return ethReceived;
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