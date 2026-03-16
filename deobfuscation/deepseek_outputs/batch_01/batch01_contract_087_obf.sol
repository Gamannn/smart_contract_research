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
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public multiplier;
    uint256 public totalSupply;
    
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }
    
    constructor(string tokenName, string tokenSymbol, uint8 decimalUnits, uint256 decimalMultiplier) public {
        name = tokenName;
        symbol = tokenSymbol;
        decimals = decimalUnits;
        multiplier = decimalMultiplier;
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowance[owner][spender];
    }
    
    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function balanceOf(address owner) public view returns (uint256) {
        return balanceOf[owner];
    }
    
    function transfer(address to, uint256 value) onlyPayloadSize(2 * 32) public returns (bool) {
        require(to != address(0));
        require(value <= balanceOf[msg.sender]);
        
        if ((balanceOf[msg.sender] >= value) && (balanceOf[to].add(value) > balanceOf[to])) {
            balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
            balanceOf[to] = balanceOf[to].add(value);
            emit Transfer(msg.sender, to, value);
            return true;
        } else {
            return false;
        }
    }
    
    function transferFrom(address from, address to, uint256 value) onlyPayloadSize(3 * 32) public returns (bool) {
        require(to != address(0));
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        
        if ((balanceOf[from] >= value) && (allowance[from][msg.sender] >= value) && (balanceOf[to].add(value) > balanceOf[to])) {
            balanceOf[to] = balanceOf[to].add(value);
            balanceOf[from] = balanceOf[from].sub(value);
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
            emit Transfer(from, to, value);
            return true;
        } else {
            return false;
        }
    }
}

contract HashRushICO is Owned, HashRush {
    using SafeMath for uint256;
    
    bool public crowdsaleClosed;
    uint256 public crowdsaleTarget;
    uint256 public minimumInvestment;
    uint256 public price;
    uint256 public fixedTotalSupply;
    uint256 public stopTime;
    uint256 public startTime;
    uint256 public amountRaised;
    address public multiSigWallet;
    
    constructor() HashRush("HashRush", "RUSH", 8, 100000000) public {
        multiSigWallet = msg.sender;
        fixedTotalSupply = 70000000;
        fixedTotalSupply = fixedTotalSupply.mul(multiplier);
        crowdsaleClosed = true;
    }
    
    function () public payable {
        require(!crowdsaleClosed && (now < stopTime) && (msg.value >= minimumInvestment));
        require(totalSupply.add(msg.value.mul(price).mul(multiplier).div(1 ether)) <= fixedTotalSupply);
        require(amountRaised.add(msg.value.div(1 ether)) <= crowdsaleTarget);
        
        address recipient = msg.sender;
        amountRaised = amountRaised.add(msg.value.div(1 ether));
        uint256 tokens = msg.value.mul(price).mul(multiplier).div(1 ether);
        totalSupply = totalSupply.add(tokens);
        balanceOf[recipient] = balanceOf[recipient].add(tokens);
        emit Transfer(address(0), recipient, tokens);
    }
    
    function mintToken(address target, uint256 amount) onlyOwner public returns (bool) {
        require(amount > 0);
        require(totalSupply.add(amount) <= fixedTotalSupply);
        
        uint256 addTokens = amount;
        balanceOf[target] = balanceOf[target].add(addTokens);
        totalSupply = totalSupply.add(addTokens);
        emit Transfer(0, target, addTokens);
        return true;
    }
    
    function setPrice(uint256 newPriceperEther) onlyOwner public returns (uint256) {
        require(newPriceperEther > 0);
        price = newPriceperEther;
        return price;
    }
    
    function setMultiSigWallet(address wallet) onlyOwner public returns (bool) {
        multiSigWallet = wallet;
        return true;
    }
    
    function setMinimumInvestment(uint256 minimum) onlyOwner public returns (bool) {
        minimumInvestment = minimum;
        return true;
    }
    
    function setCrowdsaleTarget(uint256 target) onlyOwner public returns (bool) {
        crowdsaleTarget = target;
        return true;
    }
    
    function startSale(uint256 saleStart, uint256 saleStop, uint256 salePrice, address setBeneficiary, uint256 minInvestment, uint256 saleTarget) onlyOwner public returns (bool) {
        require(saleStop > now);
        startTime = saleStart;
        stopTime = saleStop;
        amountRaised = 0;
        crowdsaleClosed = false;
        setPrice(salePrice);
        setMultiSigWallet(setBeneficiary);
        setMinimumInvestment(minInvestment);
        setCrowdsaleTarget(saleTarget);
        return true;
    }
    
    function stopSale() onlyOwner public returns (bool) {
        stopTime = now;
        crowdsaleClosed = true;
        return true;
    }
}