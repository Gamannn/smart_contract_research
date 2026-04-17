```solidity
pragma solidity ^0.5.2;

library AddressUtils {
    function toPayable(uint256 value) internal pure returns (address payable) {
        return address(value);
    }

    function toPayable(bytes memory data) internal pure returns (address payable result) {
        assembly {
            result := mload(add(data, 0x14))
        }
        return result;
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size == 0;
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract TokenInterface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address account) public view returns (uint256);
    function allowance(address owner, address spender) public view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is TokenInterface {
    using SafeMath for uint256;
    using AddressUtils for *;

    string public constant name = "Market Coin";
    string public constant symbol = "MKT";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) balances;

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function totalSupply() public view returns (uint256) {
        return address(this).balance;
    }
}

contract DividendToken is BasicToken {
    uint8 public constant dividendFee = 10;
    uint16 public constant dividendInterval = 6000;
    uint256 public totalDividends;
    mapping(address => uint256) lastDividendPoints;
    event DividendPaid(address indexed account, uint256 amount);
    event DividendWithdrawn(address indexed account, uint256 amount);

    constructor() public {}

    function payDividends() external payable returns (bool) {
        require(msg.sender.isContract(), "The contract cannot hold tokens");
        uint256 balance = balanceOf(msg.sender);
        require(balance > 0, "Cannot pass 0 value");
        require(lastDividendPoints[msg.sender] == 0, "Withdraw dividends, please wait");
        uint256 dividends = calculateDividends(balance);
        require(dividends > 0, "Dividend amount > 0");
        totalDividends = totalDividends.sub(dividends);
        msg.sender.transfer(dividends);
        emit DividendWithdrawn(msg.sender, dividends);
        return true;
    }

    function calculateDividends(uint256 balance) internal view returns (uint256) {
        if (balance == 0) {
            return 0;
        }
        uint256 dividendPoints = balance.mul(10e18);
        uint256 dividendAmount = calculateDividendAmount(dividendPoints);
        return totalDividends.mul(dividendAmount).div(100);
    }

    function calculateDividendAmount(uint256 dividendPoints) internal view returns (uint256) {
        if (dividendPoints == 0) {
            return 0;
        }
        uint256 dividendRate = getDividendRate();
        if (dividendRate > 100) {
            dividendRate = 100;
        }
        return dividendPoints.mul(dividendRate).div(totalSupply);
    }

    function getDividendRate() private view returns (uint256) {
        if (lastDividendPoints[msg.sender] == 0) {
            return 0;
        } else {
            return block.number.sub(lastDividendPoints[msg.sender]).div(dividendInterval);
        }
    }
}

contract MarketCoin is BasicToken, DividendToken {
    uint128 constant minDividend = 0.00000000001 ether;
    uint128 public constant maxDividend = 15 ether;
    uint8 public constant referralFee = 5;
    uint8 public constant referralBonus = 2;
    uint8 public constant referralDiscount = 3;
    address payable constant treasury = 0x4d332E1f9d55d9B89dc2a8457B693Beaa7b36b2e;
    event TokensWithdrawn(address indexed account, uint256 amount);
    event ReferralBonus(uint256 amount);
    event ReferralDiscount(uint256 amount);

    constructor() public {}

    function () external payable {
        require(msg.sender.isContract(), "The contract cannot hold tokens");
        address payable referrer = msg.data.toPayable();
        uint256 value = msg.value;
        uint256 referralAmount;
        uint256 refundAmount;
        if (value > maxDividend) {
            refundAmount = value.sub(maxDividend);
            value = maxDividend;
        }
        uint256 tokenPrice = getTokenPrice();
        uint256 dividends = calculateDividends(msg.sender);
        uint256 referralFeeAmount = value.mul(referralFee).div(100);
        uint256 referralBonusAmount = calculateReferralBonus(value, dividendFee);
        if (referrer != address(0)) {
            referralAmount = value.mul(referralBonus).div(100);
            referralFeeAmount = referralFeeAmount.sub(referralAmount);
        }
        value = value.sub(referralBonusAmount).sub(referralFeeAmount).sub(referralAmount);
        require(value >= tokenPrice, "The amount of ether is not enough");
        (uint256 tokensReceived, uint256 refund) = calculateTokens(value, tokenPrice);
        treasury.transfer(referralFeeAmount);
        refundAmount = refundAmount.add(refund);
        if (refundAmount > 0) {
            msg.sender.transfer(refundAmount);
            emit ReferralDiscount(refundAmount);
        }
        if (referralAmount > 0 && referrer != address(0)) {
            referrer.transfer(referralAmount);
            emit ReferralBonus(referralAmount);
        }
        if (dividends > tokenPrice) {
            withdrawDividends();
        }
        lastDividendPoints[msg.sender] = block.number;
        balances[msg.sender] = balances[msg.sender].add(tokensReceived);
        totalSupply = totalSupply.add(tokensReceived);
        totalDividends = totalDividends.add(referralBonusAmount);
        emit Transfer(address(0), msg.sender, tokensReceived);
        emit DividendPaid(msg.sender, referralBonusAmount);
    }

    function getTokenPrice() public view returns (uint256) {
        uint256 contractBalance = totalSupply();
        if (totalSupply == 0 || contractBalance == 0) {
            return minDividend;
        }
        return contractBalance.div(totalSupply).mul(4).div(3);
    }

    function withdrawTokens(uint256 amount) external payable returns (bool) {
        require(msg.sender.isContract(), "The contract cannot hold tokens");
        uint256 balance = balanceOf(msg.sender);
        require(amount > 0, "Cannot pass 0 value");
        require(balance >= amount, "You do not have enough tokens");
        uint256 tokenPrice = getTokenPrice();
        uint256 etherAmount = calculateEtherAmount(amount, tokenPrice);
        uint256 contractBalance = totalSupply();
        uint256 dividends = calculateDividends(amount, referralDiscount);
        etherAmount = etherAmount.sub(dividends);
        if (dividends > 0) {
            totalDividends = totalDividends.sub(dividends);
            etherAmount = etherAmount.add(dividends);
            emit DividendWithdrawn(msg.sender, dividends);
        }
        if (balance == amount) {
            lastDividendPoints[msg.sender] = 0;
            balances[msg.sender] = 0;
        } else {
            lastDividendPoints[msg.sender] = block.number;
            balances[msg.sender] = balances[msg.sender].sub(amount);
        }
        if (etherAmount > contractBalance) {
            etherAmount = contractBalance;
        }
        msg.sender.transfer(etherAmount);
        emit TokensWithdrawn(msg.sender, etherAmount);
        emit DividendPaid(address(0), dividends);
        return true;
    }

    function withdrawDividends() public payable returns (bool) {
        require(msg.sender.isContract(), "The contract cannot hold tokens");
        uint256 dividends = calculateDividends(msg.sender);
        uint256 tokenPrice = getTokenPrice();
        require(dividends >= tokenPrice, "Not enough dividends");
        (uint256 tokensReceived, uint256 refund) = calculateTokens(dividends, tokenPrice);
        require(tokensReceived > 0, "Token amount not zero");
        totalDividends = totalDividends.sub(dividends.sub(refund));
        balances[msg.sender] = balances[msg.sender].add(tokensReceived);
        totalSupply = totalSupply.add(tokensReceived);
        lastDividendPoints[msg.sender] = block.number;
        emit Transfer(address(0), msg.sender, tokensReceived);
        return true;
    }

    function calculateTokens(uint256 value, uint256 tokenPrice) private pure returns (uint256 tokensReceived, uint256 refund) {
        require(value >= tokenPrice, "Input ether > token price");
        tokensReceived = value.div(tokenPrice);
        require(tokensReceived > 0, "You cannot buy 0 tokens");
        refund = value.sub(tokensReceived.mul(tokenPrice));
    }

    function calculateEtherAmount(uint256 tokens, uint256 tokenPrice) private pure returns (uint256 etherAmount) {
        require(tokens > 0, "0 tokens cannot be counted");
        etherAmount = tokenPrice.mul(tokens);
    }
}
```