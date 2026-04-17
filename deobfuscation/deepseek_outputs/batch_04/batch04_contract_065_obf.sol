```solidity
pragma solidity ^0.4.18;

contract ERC20Basic {
    function balanceOf(address who) public constant returns (uint256);
    function allowance(address owner, address spender) public constant returns (uint256);
}

contract ERC20 is ERC20Basic {
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MintableToken is ERC20 {
    event Mint(address indexed to, uint256 amount);
    function mint(address to, uint256 amount) public returns (bool);
}

contract Sale {
    event Purchase(address indexed beneficiary, address token, uint256 tokenAmount, uint256 weiAmount, uint256 bonus);
    event RateAdd(address token);
    event RateRemove(address token);
    function getRate(address token) constant public returns (uint256);
    function calculateBonus(uint256 tokenAmount) constant public returns (uint256);
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

contract Ownable {
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function Ownable() public {
        owner = msg.sender;
    }
    
    address public owner;
    
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        owner = newOwner;
    }
}

contract BurnableToken is ERC20 {
    event Mint(address indexed to, uint256 amount, bytes data);
    event Burn(address indexed burner, uint256 amount, bytes data);
    function burn(uint256 amount, bytes data) public;
}

contract TokenReceiver {
    function tokenFallback(address from, uint256 amount, bytes data) internal;
}

contract TokenPaymentProcessor is TokenReceiver {
    function processTokenPayment(address token, uint256 amount, bytes data) public {
        ERC20 tokenContract = ERC20(token);
        tokenContract.transferFrom(msg.sender, this, amount);
        tokenFallback(token, msg.sender, amount, data);
    }
}

contract TokenWithdrawer {
    function withdrawTokens(address to, uint256 amount, bytes data) public;
}

contract TokenTransferHandler is TokenWithdrawer, TokenReceiver {
    function withdrawTokens(address to, uint256 amount, bytes data) public {
        tokenFallback(msg.sender, to, amount, data);
    }
    
    function withdrawTokensTo(address to, uint256 amount, bytes data) public {
        tokenFallback(msg.sender, to, amount, data);
    }
}

contract EthReceiver {
    function processPayment(bytes data) payable public;
}

contract EthPaymentProcessor is EthReceiver, TokenReceiver {
    function () payable public {
        processPayment("");
    }
    
    function processPayment(bytes data) payable public {
        tokenFallback(address(0), msg.sender, msg.value, data);
    }
}

contract UniversalPaymentProcessor is TokenPaymentProcessor, TokenTransferHandler, EthPaymentProcessor {}

contract BaseSale is Sale, UniversalPaymentProcessor, Ownable {
    using SafeMath for uint256;
    
    event Withdraw(address token, address to, uint256 amount);
    event Burn(address token, uint256 amount, bytes data);
    
    function tokenFallback(address token, address from, uint256 tokenAmount, bytes data) internal {
        uint256 weiAmount = calculateWeiAmount(token, tokenAmount);
        require(weiAmount > 0);
        
        uint256 bonus = calculateBonus(weiAmount);
        
        address beneficiary;
        if (data.length == 20) {
            beneficiary = address(bytesToBytes20(data, 0));
        } else {
            require(data.length == 0);
            beneficiary = from;
        }
        
        deliverTokens(beneficiary, weiAmount, bonus);
        checkPurchaseValid(beneficiary, weiAmount, bonus);
        Purchase(beneficiary, token, tokenAmount, weiAmount, bonus);
        processPurchase(beneficiary, token, tokenAmount, weiAmount, bonus);
    }
    
    function calculateWeiAmount(address token, uint256 tokenAmount) constant public returns (uint256) {
        uint256 rate = getRate(token);
        require(rate > 0);
        return tokenAmount.mul(rate).div(10**18);
    }
    
    function calculateBonus(uint256 tokenAmount) constant public returns (uint256);
    function getRate(address token) constant public returns (uint256);
    function deliverTokens(address beneficiary, uint256 tokenAmount, uint256 bonus) internal;
    function checkPurchaseValid(address beneficiary, uint256 tokenAmount, uint256 bonus) internal { }
    function processPurchase(address beneficiary, address token, uint256 tokenAmount, uint256 weiAmount, uint256 bonus) internal { }
    
    function bytesToBytes20(bytes b, uint256 offset) pure internal returns (bytes20 result) {
        require(offset + 20 <= b.length);
        assembly {
            let base := add(add(b, 0x20), offset)
            result := mload(base)
        }
    }
    
    function withdrawEth(address to, uint256 amount) onlyOwner public {
        withdraw(address(0), to, amount);
    }
    
    function withdraw(address token, address to, uint256 amount) onlyOwner public {
        require(to != address(0));
        checkWithdraw(token, to, amount);
        
        if (token == address(0)) {
            to.transfer(amount);
        } else {
            ERC20(token).transfer(to, amount);
        }
        Withdraw(token, to, amount);
    }
    
    function checkWithdraw(address token, address to, uint256 amount) internal;
    
    function burnTokens(address token, uint256 amount, bytes data) onlyOwner public {
        BurnableToken(token).burn(amount, data);
        Burn(token, amount, data);
    }
}

contract MintingSale is BaseSale {
    MintableToken public token;
    
    function MintingSale(address tokenAddress) public {
        token = MintableToken(tokenAddress);
    }
    
    function deliverTokens(address beneficiary, uint256 tokenAmount, uint256 bonus) internal {
        token.mint(beneficiary, tokenAmount.add(bonus));
    }
}

contract CappedSale is BaseSale {
    uint256 public cap;
    uint256 public initialCap;
    
    function CappedSale(uint256 _cap) public {
        cap = _cap;
        initialCap = _cap;
    }
    
    function checkPurchaseValid(address beneficiary, uint256 tokenAmount, uint256 bonus) internal {
        super.checkPurchaseValid(beneficiary, tokenAmount, bonus);
        require(cap >= tokenAmount.add(bonus));
        cap = cap.sub(tokenAmount).sub(bonus);
    }
}

contract TimedSale is BaseSale {
    uint256 public startTime;
    uint256 public endTime;
    
    function TimedSale(uint256 _startTime, uint256 _endTime) public {
        startTime = _startTime;
        endTime = _endTime;
    }
    
    function checkPurchaseValid(address beneficiary, uint256 tokenAmount, uint256 bonus) internal {
        super.checkPurchaseValid(beneficiary, tokenAmount, bonus);
        require(now > startTime && now < endTime);
    }
}

contract Pausable is Ownable {
    bool public paused = false;
    
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    
    modifier whenPaused() {
        require(paused);
        _;
    }
    
    function pause() onlyOwner whenNotPaused public {
        paused = true;
    }
    
    function unpause() onlyOwner whenPaused public {
        paused = false;
    }
}

contract GawoonSale is Ownable, MintingSale, CappedSale, TimedSale, Pausable {
    address public btcToken;
    uint256 public ethRate = 1000 * 10**18;
    uint256 public btcEthRate = 10 * 10**10;
    
    event EthRateChange(uint256 rate);
    event BtcEthRateChange(uint256 rate);
    
    function GawoonSale(
        address tokenAddress,
        address _btcToken,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _cap
    )
        MintingSale(tokenAddress)
        CappedSale(_cap)
        TimedSale(_startTime, _endTime)
    {
        btcToken = _btcToken;
        RateAdd(address(0));
        RateAdd(_btcToken);
    }
    
    function setEthRate(uint256 _ethRate) onlyOwner public {
        ethRate = _ethRate;
        EthRateChange(_ethRate);
    }
    
    function setBtcEthRate(uint256 _btcEthRate) onlyOwner public {
        btcEthRate = _btcEthRate;
        BtcEthRateChange(_btcEthRate);
    }
    
    function burnBtcTokens(bytes data, uint256 amount) onlyOwner public {
        burnTokens(btcToken, amount, data);
    }
    
    function transferTokenOwnership(address newOwner) onlyOwner public {
        Ownable(token).transferOwnership(newOwner);
    }
    
    function pauseToken() onlyOwner public {
        Pausable(token).pause();
    }
    
    function unpauseToken() onlyOwner public {
        Pausable(token).unpause();
    }
    
    function mint(address beneficiary, uint256 amount) onlyOwner public {
        deliverTokens(beneficiary, amount, 0);
        Purchase(beneficiary, address(1), 0, amount, 0);
        processPurchase(beneficiary, address(1), 0, amount, 0);
    }
}

contract GawoonBonusSale is GawoonSale {
    function GawoonBonusSale(
        address tokenAddress,
        address btcToken,
        uint256 startTime,
        uint256 endTime,
        uint256 cap
    )
        GawoonSale(tokenAddress, btcToken, startTime, endTime, cap)
    {}
    
    function calculateBonus(uint256 tokenAmount) constant public returns (uint256) {
        return calculateBaseBonus(tokenAmount).add(calculateVolumeBonus(tokenAmount));
    }
    
    function calculateBaseBonus(uint256 tokenAmount) internal returns (uint256) {
        return tokenAmount.div(2);
    }
    
    function calculateVolumeBonus(uint256 tokenAmount) internal returns (uint256) {
        if (tokenAmount >= 100000 * 10**18) {
            return tokenAmount;
        } else if (tokenAmount >= 50000 * 10**18) {
            return tokenAmount.mul(75).div(100);
        } else {
            return 0;
        }
    }
    
    function getRate(address token) constant public returns (uint256) {
        if (token == address(0)) {
            return ethRate;
        } else if (token == btcToken) {
            return btcEthRate;
        } else {
            return 0;
        }
    }
    
    function checkWithdraw(address token, address to, uint256 amount) internal {
        require(!paused);
    }
}
```