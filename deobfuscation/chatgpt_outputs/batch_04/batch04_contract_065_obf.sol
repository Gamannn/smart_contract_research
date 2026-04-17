```solidity
pragma solidity ^0.4.18;

contract TokenInterface {
    uint256 function balanceOf(address owner) public constant returns (uint256);
    function allowance(address owner, address spender) public constant returns (uint256);
}

contract ERC20Interface is TokenInterface {
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MintableTokenInterface is ERC20Interface {
    event Mint(address indexed to, uint256 amount);
    function mint(address to, uint256 amount) public returns (bool);
}

contract PurchaseInterface {
    event Purchase(address indexed buyer, address token, uint256 amount, uint256 rate, uint256 value);
    event RateAdd(address token);
    event RateRemove(address token);
    function getRate(address token) constant public returns (uint256);
    function getValue(uint256 rate) constant public returns (uint256);
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
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function Ownable() public {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

contract TokenSale is PurchaseInterface, Ownable {
    using SafeMath for uint256;

    event Withdraw(address token, address to, uint256 amount);
    event Burn(address token, uint256 amount, bytes data);

    function executePurchase(address token, address buyer, uint256 amount, bytes data) internal {
        uint256 rate = getRate(token);
        require(rate > 0);
        uint256 value = getValue(rate);
        address recipient;
        if (data.length == 20) {
            recipient = address(bytes20(data));
        } else {
            require(data.length == 0);
            recipient = buyer;
        }
        processPurchase(recipient, rate, value);
        finalizePurchase(recipient, rate, value);
        Purchase(recipient, token, amount, rate, value);
        postPurchase(recipient, token, amount, rate, value);
    }

    function getRate(address token) constant public returns (uint256) {
        uint256 rate = getRate(token);
        require(rate > 0);
        return rate;
    }

    function getValue(uint256 rate) constant public returns (uint256);

    function processPurchase(address recipient, uint256 rate, uint256 value) internal;

    function finalizePurchase(address recipient, uint256 rate, uint256 value) internal { }

    function postPurchase(address recipient, address token, uint256 amount, uint256 rate, uint256 value) internal { }

    function bytesToAddress(bytes data, uint256 offset) pure internal returns (bytes20 result) {
        require(offset + 20 <= data.length);
        assembly {
            result := mload(add(data, add(0x20, offset)))
        }
    }

    function mintTokens(address to, uint256 amount) onlyOwner public {
        mintTokens(address(0), to, amount);
    }

    function mintTokens(address token, address to, uint256 amount) onlyOwner public {
        require(to != address(0));
        processMint(token, to, amount);
        if (token == address(0)) {
            to.mint(amount);
        } else {
            MintableTokenInterface(token).mint(to, amount);
        }
        Withdraw(token, to, amount);
    }

    function processMint(address token, address to, uint256 amount) internal;

    function burnTokens(address token, uint256 amount, bytes data) onlyOwner public {
        MintableTokenInterface(token).burn(amount, data);
        Burn(token, amount, data);
    }
}

contract TokenSaleWithBonus is TokenSale {
    uint256 public bonusRate;
    uint256 public bonusThreshold;

    function TokenSaleWithBonus(uint256 _bonusRate, uint256 _bonusThreshold) public {
        bonusRate = _bonusRate;
        bonusThreshold = _bonusThreshold;
    }

    function processPurchase(address recipient, uint256 rate, uint256 value) internal {
        super.processPurchase(recipient, rate, value);
        require(now > bonusRate && now < bonusThreshold);
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
        Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }

    event Pause();
    event Unpause();
}

contract TokenSaleWithCap is TokenSaleWithBonus, Pausable {
    uint256 public cap;
    uint256 public totalSold;

    function TokenSaleWithCap(uint256 _cap, uint256 _bonusRate, uint256 _bonusThreshold) public {
        cap = _cap;
        bonusRate = _bonusRate;
        bonusThreshold = _bonusThreshold;
    }

    function processPurchase(address recipient, uint256 rate, uint256 value) internal {
        super.processPurchase(recipient, rate, value);
        require(totalSold.add(value) <= cap);
        totalSold = totalSold.add(value);
    }
}

contract TokenSaleWithTimeLimit is TokenSaleWithBonus {
    uint256 public startTime;
    uint256 public endTime;

    function TokenSaleWithTimeLimit(uint256 _startTime, uint256 _endTime) public {
        startTime = _startTime;
        endTime = _endTime;
    }

    function processPurchase(address recipient, uint256 rate, uint256 value) internal {
        super.processPurchase(recipient, rate, value);
        require(now > startTime && now < endTime);
    }
}

contract TokenSaleWithRateChange is TokenSaleWithCap {
    uint256 public ethRate = 1000 * 10**18;
    uint256 public btcRate = 10 * 10**10;

    function TokenSaleWithRateChange(address token, address wallet, uint256 _startTime, uint256 _endTime, uint256 _cap) public
        TokenSaleWithBonus(_startTime, _endTime)
        TokenSaleWithCap(_cap, _startTime, _endTime)
    {
        wallet = wallet;
        RateAdd(address(0));
        RateAdd(wallet);
    }

    function setEthRate(uint256 newRate) onlyOwner public {
        ethRate = newRate;
        EthRateChange(newRate);
    }

    function setBtcRate(uint256 newRate) onlyOwner public {
        btcRate = newRate;
        BtcRateChange(newRate);
    }

    function executePurchase(address token, uint256 amount, bytes data) onlyOwner public {
        executePurchase(wallet, amount, data);
    }

    function transferOwnership(address newOwner) onlyOwner public {
        super.transferOwnership(newOwner);
    }

    function pause() onlyOwner public {
        super.pause();
    }

    function unpause() onlyOwner public {
        super.unpause();
    }

    function mintTokens(address to, uint256 amount) onlyOwner public {
        processPurchase(to, amount, 0);
        Purchase(to, address(1), 0, amount, 0);
        postPurchase(to, address(1), 0, amount, 0);
    }
}

contract TokenSaleWithDiscount is TokenSaleWithRateChange {
    function TokenSaleWithDiscount(address token, address wallet, uint256 _startTime, uint256 _endTime, uint256 _cap) public
        TokenSaleWithRateChange(token, wallet, _startTime, _endTime, _cap)
    {}

    function getValue(uint256 rate) constant public returns (uint256) {
        return calculateDiscount(rate) + calculateBonus(rate);
    }

    function calculateDiscount(uint256 rate) internal returns (uint256) {
        return rate.div(2);
    }

    function calculateBonus(uint256 rate) internal returns (uint256) {
        if (rate >= 100000 * 10**18) {
            return rate;
        } else if (rate >= 50000 * 10 ** 18) {
            return rate.mul(75).div(100);
        } else {
            return 0;
        }
    }
}
```