```solidity
pragma solidity ^0.5.2;

library AddressUtils {
    function toAddress(uint256 value) internal pure returns(address payable) {
        return address(value);
    }
    
    function toAddress(bytes memory data) internal pure returns(address payable result) {
        assembly {
            result := mload(add(data, 0x14))
        }
        return result;
    }
    
    function isContract(address addr) internal view returns(bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
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

interface ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address owner) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event EtherTransfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Interface {
    using SafeMath for uint;
    using AddressUtils for *;
    
    string constant public name = "MarketCoin";
    string constant public symbol = "MarketCoin";
    uint8 constant internal decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) balances;
    
    function balanceOf(address owner) public view returns (uint256 balance) {
        return balances[owner];
    }
    
    function totalSupply() public view returns (uint256 supply) {
        supply = totalSupply;
    }
}

contract DividendToken is ERC20 {
    uint8 public constant dividendPercent = 10;
    uint16 public constant dividendInterval = 6000;
    uint256 public dividendPool;
    mapping(address => uint256) lastDividendBlock;
    
    event SendOnDividend(address indexed customerAddress, uint256 dividendAmount);
    event WithdrawDividends(address indexed customer, uint256 dividendAmount);
    
    constructor() public {}
    
    function withdrawDividends() external payable returns(bool success) {
        require(msg.sender.isContract(), "the contract can not hold tokens");
        uint256 tokenBalance = balanceOf(msg.sender);
        require(tokenBalance > 0, "cannot pass 0 value");
        require(lastDividendBlock[msg.sender] > 0, "withdraw dividends, please wait");
        
        uint256 dividends = calculateDividends(tokenBalance);
        require(dividends > 0, "dividend amount > 0");
        
        dividendPool = dividendPool.sub(dividends);
        msg.sender.transfer(dividends);
        emit WithdrawDividends(msg.sender, dividends);
        return true;
    }
    
    function getDividends(address customer) public view returns(uint256 dividendAmount) {
        uint256 tokenBalance = balanceOf(customer);
        dividendAmount = calculateDividends(tokenBalance);
    }
    
    function calculatePercentage(uint256 amount, uint8 percent) internal pure returns(uint256 result) {
        return amount.mul(percent).div(100);
    }
    
    function calculateDividends(uint256 tokens) internal view returns(uint256 dividends) {
        if (tokens == 0) {
            return 0;
        }
        uint256 scaledTokens = tokens.mul(10**18);
        uint256 dividendPercentage = getDividendPercentage(scaledTokens);
        dividends = dividendPool.mul(dividendPercentage).div(100);
        dividends = dividends.div(10**18);
    }
    
    function getDividendPercentage(uint256 scaledTokens) internal view returns(uint256 percentage) {
        if (scaledTokens == 0) {
            return 0;
        }
        uint256 blocksSinceLastDividend = getBlocksSinceLastDividend();
        if (blocksSinceLastDividend > 100) {
            blocksSinceLastDividend = 100;
        }
        percentage = scaledTokens.mul(blocksSinceLastDividend).div(totalSupply);
    }
    
    function getBlocksSinceLastDividend() private view returns(uint256 blocks) {
        if (lastDividendBlock[msg.sender] == 0) {
            blocks = 0;
        } else {
            blocks = block.number.sub(lastDividendBlock[msg.sender]).div(dividendInterval);
        }
    }
}

contract MarketCoin is ERC20, DividendToken {
    uint128 constant MIN_PRICE = 0.00000000001 ether;
    uint128 public constant MAX_INVESTMENT = 15 ether;
    uint8 public constant FEE_PERCENT = 5;
    uint8 public constant REFERRAL_PERCENT = 2;
    uint8 public constant WITHDRAW_FEE_PERCENT = 3;
    address payable constant FEE_ADDRESS = 0x4d332E1f9d55d9B89dc2a8457B693Beaa7b36b2e;
    
    event WithdrawTokens(address indexed customer, uint256 amount);
    event ReverseAccess(uint256 amount);
    event ForReferral(uint256 amount);
    
    constructor() public {}
    
    function() external payable {
        require(msg.sender.isContract(), "the contract can not hold tokens");
        address payable referrer = msg.data.toAddress();
        uint256 investment = msg.value;
        uint256 referralBonus;
        uint256 refund;
        
        if (investment > MAX_INVESTMENT) {
            refund = investment.sub(MAX_INVESTMENT);
            investment = MAX_INVESTMENT;
        }
        
        uint256 tokenPrice = getTokenPrice();
        uint256 pendingDividends = getDividends(msg.sender);
        uint256 fee = investment.mul(FEE_PERCENT).div(100);
        uint256 dividends = calculatePercentage(investment, dividendPercent);
        
        if (referrer != address(0)) {
            referralBonus = investment.mul(REFERRAL_PERCENT).div(100);
            fee = fee.sub(referralBonus);
        }
        
        investment = investment.sub(dividends).sub(fee).sub(referralBonus);
        
        require(investment >= tokenPrice, "the amount of ether is not enough");
        
        (uint256 tokens, uint256 remainder) = calculateTokens(investment, tokenPrice);
        FEE_ADDRESS.transfer(fee);
        
        refund = refund.add(remainder);
        if (refund > 0) {
            msg.sender.transfer(refund);
            emit ReverseAccess(refund);
        }
        
        if (referralBonus > 0 && referrer != address(0)) {
            referrer.transfer(referralBonus);
            emit ForReferral(referralBonus);
        }
        
        if (pendingDividends > tokenPrice) {
            reinvestDividends();
        }
        
        lastDividendBlock[msg.sender] = block.number;
        balances[msg.sender] = balances[msg.sender].add(tokens);
        totalSupply = totalSupply.add(tokens);
        dividendPool = dividendPool.add(dividends);
        
        emit EtherTransfer(msg.sender, FEE_ADDRESS, fee);
        emit Transfer(address(0), msg.sender, tokens);
        emit SendOnDividend(msg.sender, dividends);
    }
    
    function getTokenPrice() public view returns(uint256 price) {
        uint256 contractBalance = address(this).balance;
        if (totalSupply == 0 || contractBalance == 0) {
            return MIN_PRICE;
        }
        return contractBalance.div(totalSupply).mul(4).div(3);
    }
    
    function sellTokens(uint256 tokens) external payable returns(bool success) {
        require(msg.sender.isContract(), "the contract can not hold tokens");
        uint256 tokenBalance = balanceOf(msg.sender);
        require(tokens > 0, "cannot pass 0 value");
        require(tokenBalance >= tokens, "you do not have so many tokens");
        
        uint256 tokenPrice = getTokenPrice();
        uint256 etherAmount = calculateEther(tokens, tokenPrice);
        uint256 contractBalance = address(this).balance;
        uint256 fee = calculatePercentage(etherAmount, WITHDRAW_FEE_PERCENT);
        uint256 dividends = getDividends(msg.sender);
        
        etherAmount = etherAmount.sub(fee);
        
        if (dividends > 0) {
            dividendPool = dividendPool.sub(dividends);
            etherAmount = etherAmount.add(dividends);
            emit WithdrawDividends(msg.sender, dividends);
        }
        
        if (tokenBalance == tokens) {
            lastDividendBlock[msg.sender] = 0;
            balances[msg.sender] = 0;
        } else {
            lastDividendBlock[msg.sender] = block.number;
            balances[msg.sender] = balances[msg.sender].sub(tokens);
        }
        
        if (etherAmount > contractBalance) {
            etherAmount = contractBalance;
        }
        
        msg.sender.transfer(etherAmount);
        emit WithdrawTokens(msg.sender, etherAmount);
        emit SendOnDividend(address(0), fee);
        return true;
    }
    
    function reinvestDividends() public payable returns(bool success) {
        require(msg.sender.isContract(), "the contract can not hold tokens");
        uint256 dividends = getDividends(msg.sender);
        uint256 tokenPrice = getTokenPrice();
        require(dividends >= tokenPrice, "not enough dividends");
        
        (uint256 tokens, uint256 remainder) = calculateTokens(dividends, tokenPrice);
        require(tokens > 0, "token amount not zero");
        
        dividendPool = dividendPool.sub(dividends.sub(remainder));
        balances[msg.sender] = balances[msg.sender].add(tokens);
        totalSupply = totalSupply.add(tokens);
        lastDividendBlock[msg.sender] = block.number;
        
        emit Transfer(address(0), msg.sender, tokens);
        return true;
    }
    
    function calculateTokens(uint256 etherAmount, uint256 tokenPrice) private pure returns(uint256 tokens, uint256 remainder) {
        require(etherAmount >= tokenPrice, "input ether > token price");
        tokens = etherAmount.div(tokenPrice);
        require(tokens > 0, "you can not buy 0 tokens");
        remainder = etherAmount.sub(tokens.mul(tokenPrice));
    }
    
    function calculateEther(uint256 tokens, uint256 tokenPrice) private pure returns(uint256 etherAmount) {
        require(tokens > 0, "0 tokens cannot be counted");
        etherAmount = tokenPrice.mul(tokens);
    }
}
```