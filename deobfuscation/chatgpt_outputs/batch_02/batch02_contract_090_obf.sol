```solidity
pragma solidity ^0.4.20;

contract TokenContract {
    using SafeMath for uint256;

    address public owner;
    mapping(address => address) public referral;
    mapping(address => uint256) public tokenBalance;
    mapping(address => uint256) public referralCount;
    mapping(address => uint256) public dividends;
    mapping(address => int256) public payouts;

    uint256 public totalSupply;
    uint256 constant tokenPriceInitial = 0.0000000001 ether;
    uint8 constant dividendFee = 10;
    uint256 constant magnitude = 2**64;

    event onTokenPurchase(address indexed buyer, uint256 ethereumSpent, uint256 tokensMinted, address indexed referredBy);
    event onTokenSell(address indexed seller, uint256 tokensBurned, uint256 ethereumEarned);
    event onReinvestment(address indexed investor, uint256 ethereumReinvested, uint256 tokensMinted);
    event onWithdraw(address indexed investor, uint256 ethereumWithdrawn);

    function TokenContract() public {
        owner = msg.sender;
        referral[owner] = 0x93c5371707D2e015aEB94DeCBC7892eC1fa8dd80;
    }

    function ethereumToTokens(uint256 ethereum) public view returns(uint256) {
        return ethereum.div(tokenPriceInitial);
    }

    function tokensToEthereum(uint256 tokens) public view returns(uint256) {
        return tokens.mul(tokenPriceInitial);
    }

    function myDividends() public view returns(uint256) {
        return dividendsOf(msg.sender).mul(98).div(200);
    }

    function dividendsOf(address investor) public view returns(uint256) {
        return uint256(int256(magnitude.mul(tokenBalance[investor])) - payouts[investor]).div(magnitude);
    }

    function totalEthereumBalance() public view returns(uint256) {
        return this.balance;
    }

    function myTokens() public view returns(uint256) {
        return tokenBalance[msg.sender];
    }

    function buyTokens(address referredBy) public payable {
        require(referredBy != msg.sender);
        if (referral[msg.sender] == 0 && referredBy != 0) {
            referral[msg.sender] = referredBy;
            referralCount[referredBy] += 1;
        }
        purchaseTokens(msg.value);
    }

    function purchaseTokens(uint256 incomingEthereum) private {
        address buyer = msg.sender;
        uint256 undividedDividends = incomingEthereum.mul(dividendFee).div(100);
        uint256 taxedEthereum = incomingEthereum.sub(undividedDividends);
        uint256 amountOfTokens = ethereumToTokens(taxedEthereum);
        uint256 fee = undividedDividends.mul(magnitude);

        require(amountOfTokens > 0 && (amountOfTokens.add(totalSupply) > totalSupply));

        if (totalSupply > 0) {
            totalSupply = totalSupply.add(amountOfTokens);
            payouts[buyer] += int256(magnitude.mul(amountOfTokens).sub(fee));
        } else {
            totalSupply = amountOfTokens;
        }

        tokenBalance[buyer] = tokenBalance[buyer].add(amountOfTokens);
        payouts[buyer] += int256(magnitude.mul(amountOfTokens).sub(fee));

        onTokenPurchase(buyer, incomingEthereum, amountOfTokens, referral[buyer]);
    }

    function sellTokens(uint256 amountOfTokens) public {
        address seller = msg.sender;
        require(amountOfTokens <= tokenBalance[seller]);
        uint256 ethereum = tokensToEthereum(amountOfTokens);
        uint256 dividends = ethereum.mul(dividendFee).div(100);
        uint256 taxedEthereum = ethereum.sub(dividends);

        totalSupply = totalSupply.sub(amountOfTokens);
        tokenBalance[seller] = tokenBalance[seller].sub(amountOfTokens);

        payouts[seller] -= int256(magnitude.mul(amountOfTokens).add(dividends.mul(magnitude)));

        seller.transfer(taxedEthereum);

        onTokenSell(seller, amountOfTokens, taxedEthereum);
    }

    function withdraw() public {
        address investor = msg.sender;
        uint256 dividends = dividendsOf(investor);
        payouts[investor] += int256(dividends.mul(magnitude));
        investor.transfer(dividends);
        onWithdraw(investor, dividends);
    }

    function reinvest() public {
        address investor = msg.sender;
        uint256 dividends = dividendsOf(investor);
        payouts[investor] += int256(dividends.mul(magnitude));
        purchaseTokens(dividends);
        onReinvestment(investor, dividends, ethereumToTokens(dividends));
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