pragma solidity ^0.4.24;

contract SafeMath {
    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size * 32 + 4);
        _;
    }
}

contract ERC20 {
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PriceContract {
    struct Price {
        uint256 numerator;
        uint256 denominator;
    }
    Price public currentPrice;
    uint256 public denominatorPrice;
    address public feeWallet;

    function() payable {
        require(tx.origin == msg.sender);
        buyTokens(msg.sender);
    }

    function buyTokens(address beneficiary) public payable;
    function getPrice() public view returns (uint256);
}

contract STCDRToken is ERC20 {}

contract LiquidityPool is SafeMath {
    bool public halted;
    address public controlWallet;

    event AddLiquidity(uint256 amount);
    event RemoveLiquidity(uint256 amount);

    modifier onlyControlWallet {
        require(msg.sender == controlWallet);
        _;
    }

    function addLiquidity() external onlyControlWallet payable {
        require(msg.value > 0);
        AddLiquidity(msg.value);
    }

    function removeLiquidity(uint256 amount) external onlyControlWallet {
        require(amount <= this.balance);
        controlWallet.transfer(amount);
        RemoveLiquidity(amount);
    }

    function setControlWallet(address newControlWallet) external onlyControlWallet {
        require(newControlWallet != address(0));
        controlWallet = newControlWallet;
    }

    function halt() external onlyControlWallet {
        halted = true;
    }

    function unhalt() external onlyControlWallet {
        halted = false;
    }

    function rescueTokens(address tokenAddress) external onlyControlWallet {
        require(tokenAddress != address(0));
        ERC20 token = ERC20(tokenAddress);
        uint256 balance = token.balanceOf(this);
        token.transfer(controlWallet, balance);
    }
}

contract TokenSale is PriceContract {
    STCDRToken public token;
    ERC20 public stcToken;
    uint256 public discountEndTime;

    event TokenSwaped(
        address indexed buyer,
        uint256 stcAmount,
        uint256 tokenAmount,
        uint256 bonusAmount,
        uint256 priceNumerator,
        uint256 priceDenominator,
        uint256 discount
    );

    struct Config {
        uint256 stcToTokenRate;
        uint256 discountPercent;
        string contractName;
        address controlWallet;
        bool halted;
        address feeWallet;
        uint256 denominatorPrice;
    }

    Config config = Config(0, 0, "", address(0), false, address(0), 0);

    function TokenSale(address stcTokenAddress, address tokenAddress) public {
        controlWallet = msg.sender;
        token = STCDRToken(stcTokenAddress);
        stcToken = ERC20(tokenAddress);
    }

    function() payable {
        require(tx.origin == msg.sender);
        buyTokens(msg.sender);
    }

    function processPurchase(
        address beneficiary,
        uint256 stcAmount,
        uint256 tokenAmount,
        uint256 bonusAmount
    ) private {
        require(this.balance >= msg.value);
        require(availableTokens() > safeAdd(stcAmount, tokenAmount));
        stcToken.transferFrom(beneficiary, this, tokenAmount);
        token.transfer(controlWallet, bonusAmount);
        token.transfer(beneficiary, stcAmount);
        token.transfer(beneficiary, tokenAmount);
        feeWallet.transfer(msg.value);
    }

    function processRefund(
        address beneficiary,
        uint256 refundAmount,
        uint256 tokenAmount
    ) private {
        require(this.balance >= safeSub(msg.value, refundAmount));
        stcToken.transferFrom(beneficiary, this, tokenAmount);
        token.transfer(controlWallet, tokenAmount);
        token.buyTokens.value(safeSub(msg.value, refundAmount))(beneficiary);
    }

    function buyTokens(address beneficiary) public payable {
        require(!halted);
        require(msg.value > 0);
        uint256 allowance = getAllowance(beneficiary);
        require(allowance > 0);
        uint256 priceNumerator = getCurrentPrice();
        require(priceNumerator > 0);
        uint256 discountEnd = token.denominatorPrice();
        uint256 priceDenominator = getDenominatorPrice();
        require(priceDenominator > 0);
        uint256 maxBonus = safeMul(config.stcToTokenRate, 10000000000) / config.discountPercent;
        require(maxBonus > 0);
        uint256 stcAmount = safeMul(msg.value, priceNumerator) / priceDenominator;
        require(stcAmount > 0);
        uint256 bonusAmount = 0;
        uint256 tokenAmount = 0;
        if (stcAmount >= maxBonus) {
            bonusAmount = availableTokens();
            tokenAmount = safeSub(safeMul((maxBonus / safeSub(100, config.discountPercent)), config.discountPercent), maxBonus);
        } else {
            bonusAmount = safeMul(stcAmount, config.discountPercent) / 10000000000;
            tokenAmount = safeSub(safeMul((stcAmount / safeSub(100, config.discountPercent)), 100), stcAmount);
        }
        require(bonusAmount > 0);
        require(tokenAmount > 0);
        require(tokenAmount < stcAmount);
        if (now < discountEnd) {
            uint256 refundAmount = safeMul(tokenAmount, priceDenominator) / priceNumerator;
            processRefund(beneficiary, refundAmount, bonusAmount);
        } else {
            processPurchase(beneficiary, stcAmount, tokenAmount, bonusAmount);
        }
        TokenSwaped(beneficiary, stcAmount, tokenAmount, bonusAmount, priceNumerator, priceDenominator, config.discountPercent);
    }

    function getCurrentPrice() public view returns (uint256 numerator) {
        var (num, den) = token.currentPrice();
        return Price(num, den).numerator;
    }

    function getDenominatorPrice() public view returns (uint256 numerator) {
        return config.denominatorPrice;
    }

    function getTokenBalance() view returns (uint256 numerator) {
        return stcToken.balanceOf(controlWallet);
    }

    function getAllowance(address owner) view returns (uint256 numerator) {
        uint256 allowed = stcToken.allowance(owner, this);
        uint256 balance = stcToken.balanceOf(owner);
        if (allowed > balance) {
            return balance;
        } else {
            return allowed;
        }
    }

    function availableTokens() view returns (uint256 numerator) {
        uint256 allowed = token.allowance(controlWallet, this);
        uint256 balance = token.balanceOf(controlWallet);
        if (allowed > balance) {
            return balance;
        } else {
            return allowed;
        }
    }
}