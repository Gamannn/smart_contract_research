pragma solidity ^0.4.24;

contract ERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function totalSupply() public view returns (uint256);
    function balanceOf(address owner) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function approve(address spender, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
}

contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        uint256 c = a - b;
        return c;
    }
}

contract HashRush is ERC20, Owned {
    using SafeMath for uint256;

    struct TokenData {
        uint8 decimals;
        uint256 multiplier;
        string symbol;
        string name;
        bool crowdsaleClosed;
        uint256 crowdsaleTarget;
        uint256 minimumInvestment;
        uint256 price;
        uint256 fixedTotalSupply;
        uint256 stopTime;
        uint256 startTime;
        uint256 amountRaised;
        address multiSigWallet;
        uint256 totalSupply_;
    }

    TokenData public tokenData;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    modifier onlyPayloadSize(uint size) {
        if (msg.data.length < size.add(4)) revert();
        _;
    }

    constructor(string tokenName, string tokenSymbol, uint8 decimalUnits, uint256 decimalMultiplier) public {
        tokenData.name = tokenName;
        tokenData.symbol = tokenSymbol;
        tokenData.decimals = decimalUnits;
        tokenData.multiplier = decimalMultiplier;
    }

    function totalSupply() public view returns (uint256) {
        return tokenData.totalSupply_;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }

    function transfer(address to, uint256 value) onlyPayloadSize(2 * 32) public returns (bool) {
        require(to != address(0));
        require(value <= balances[msg.sender]);

        if ((balances[msg.sender] >= value) && (balances[to].add(value) > balances[to])) {
            balances[msg.sender] = balances[msg.sender].sub(value);
            balances[to] = balances[to].add(value);
            emit Transfer(msg.sender, to, value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address from, address to, uint256 value) onlyPayloadSize(3 * 32) public returns (bool) {
        require(to != address(0));
        require(value <= balances[from]);
        require(value <= allowed[from][msg.sender]);

        if ((balances[from] >= value) && (allowed[from][msg.sender] >= value) && (balances[to].add(value) > balances[to])) {
            balances[to] = balances[to].add(value);
            balances[from] = balances[from].sub(value);
            allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
            emit Transfer(from, to, value);
            return true;
        } else {
            return false;
        }
    }
}

contract HashRushICO is Owned, HashRush {
    using SafeMath for uint256;

    constructor() HashRush(tokenData.name, tokenData.symbol, tokenData.decimals, tokenData.multiplier) public {
        tokenData.multiSigWallet = msg.sender;
        tokenData.fixedTotalSupply = 70000000;
        tokenData.fixedTotalSupply = tokenData.fixedTotalSupply.mul(tokenData.multiplier);
    }

    function () public payable {
        require(!tokenData.crowdsaleClosed && (now < tokenData.stopTime) && (msg.value >= tokenData.minimumInvestment) && (tokenData.totalSupply_.add(msg.value.mul(tokenData.price).mul(tokenData.multiplier).div(1 ether)) <= tokenData.fixedTotalSupply) && (tokenData.amountRaised.add(msg.value.div(1 ether)) <= tokenData.crowdsaleTarget));

        address recipient = msg.sender;
        tokenData.amountRaised = tokenData.amountRaised.add(msg.value.div(1 ether));
        uint256 tokens = msg.value.mul(tokenData.price).mul(tokenData.multiplier).div(1 ether);
        tokenData.totalSupply_ = tokenData.totalSupply_.add(tokens);
    }

    function mintToken(address target, uint256 amount) onlyOwner public returns (bool) {
        require(amount > 0);
        require(tokenData.totalSupply_.add(amount) <= tokenData.fixedTotalSupply);

        balances[target] = balances[target].add(amount);
        tokenData.totalSupply_ = tokenData.totalSupply_.add(amount);
        emit Transfer(0, target, amount);
        return true;
    }

    function setPrice(uint256 newPricePerEther) onlyOwner public returns (uint256) {
        require(newPricePerEther > 0);
        tokenData.price = newPricePerEther;
        return tokenData.price;
    }

    function setMultiSigWallet(address wallet) onlyOwner public returns (bool) {
        tokenData.multiSigWallet = wallet;
        return true;
    }

    function setMinimumInvestment(uint256 minimum) onlyOwner public returns (bool) {
        tokenData.minimumInvestment = minimum;
        return true;
    }

    function setCrowdsaleTarget(uint256 target) onlyOwner public returns (bool) {
        tokenData.crowdsaleTarget = target;
        return true;
    }

    function startSale(uint256 saleStart, uint256 saleStop, uint256 salePrice, address setBeneficiary, uint256 minInvestment, uint256 saleTarget) onlyOwner public returns (bool) {
        require(saleStop > now);
        tokenData.startTime = saleStart;
        tokenData.stopTime = saleStop;
        tokenData.amountRaised = 0;
        tokenData.crowdsaleClosed = false;
        setPrice(salePrice);
        setMultiSigWallet(setBeneficiary);
        setMinimumInvestment(minInvestment);
        setCrowdsaleTarget(saleTarget);
        return true;
    }

    function stopSale() onlyOwner public returns (bool) {
        tokenData.stopTime = now;
        tokenData.crowdsaleClosed = true;
        return true;
    }
}