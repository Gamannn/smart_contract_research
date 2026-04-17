```solidity
pragma solidity ^0.4.11;

library SafeMath {
    function mul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function div(uint a, uint b) internal returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }
    
    function sub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
    
    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a >= b ? a : b;
    }
    
    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a < b ? a : b;
    }
    
    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a >= b ? a : b;
    }
    
    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
    }
    
    function assert(bool condition) internal {
        if (!condition) {
            throw;
        }
    }
}

contract ERC20 {
    function totalSupply() constant returns (uint totalSupply);
    function balanceOf(address who) constant returns (uint balance);
    function allowance(address owner, address spender) constant returns (uint remaining);
    function transfer(address to, uint value) returns (bool success);
    function transferFrom(address from, address to, uint value) returns (bool success);
    function approve(address spender, uint value) returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract RockToken is ERC20 {
    using SafeMath for uint;
    
    uint public totalSupply = 16500000;
    string public name = "ROCK";
    string public symbol = "ROCK";
    uint8 public decimals = 8;
    
    address public owner;
    uint public saleStartTime;
    bool public burned;
    bool public preSale;
    uint public USDExchangeRate = 300;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    function totalSupply() constant returns (uint256) {
        return totalSupply;
    }
    
    function balanceOf(address who) constant returns (uint256 balance) {
        return balances[who];
    }
    
    function allowance(address owner, address spender) constant returns (uint256 remaining) {
        return allowed[owner][spender];
    }
    
    function transfer(address to, uint value) returns (bool success) {
        if (balances[msg.sender] >= value && value > 0) {
            balances[msg.sender] -= value;
            balances[to] += value;
            Transfer(msg.sender, to, value);
            return true;
        } else {
            return false;
        }
    }
    
    function transferFrom(address from, address to, uint value) returns (bool success) {
        if (balances[from] >= value && allowed[from][msg.sender] >= value && value > 0) {
            balances[to] += value;
            balances[from] -= value;
            allowed[from][msg.sender] -= value;
            Transfer(from, to, value);
            return true;
        } else {
            return false;
        }
    }
    
    function currentPriceModifier() returns (uint) {
        if (preSale) return 5;
        if (balances[owner] > 11500000) return 8;
        if (balances[owner] > 6500000) return 10;
        if (balances[owner] > 1500000) return 12;
        return 0;
    }
    
    function setUSDExchangeRate(uint value) onlyOwner {
        USDExchangeRate = value;
    }
    
    function stopPreSale() onlyOwner {
        if (preSale) {
            saleStartTime = now;
        }
        preSale = false;
    }
    
    function approve(address spender, uint value) returns (bool success) {
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }
    
    function burnUnsold() returns (bool) {
        if (preSale && saleStartTime + 5 weeks < now && !burned) {
            uint remainingTokens = totalSupply - balances[owner];
            uint toHolder = remainingTokens.div(2);
            uint toBurn = balances[owner] - toHolder;
            balances[owner] = toHolder;
            totalSupply -= toBurn;
            Burn(toBurn);
            burned = true;
            return true;
        }
        return false;
    }
    
    function RockToken() {
        owner = msg.sender;
        uint devFee = 7000;
        balances[owner] = totalSupply;
        address devAddress = 0xB0416874d4253E12C95C5FAC8F069F9BFf18D1bf;
        balances[devAddress] = devFee;
        transfer(owner, devAddress, devFee);
    }
    
    function buyTokens() payable {
        uint USDollars = SafeMath.div(SafeMath.mul(msg.value, USDExchangeRate), 10**18);
        uint currentPriceMod = currentPriceModifier();
        uint valueToPass = SafeMath.div(SafeMath.mul(USDollars, 10), currentPriceMod);
        
        if (preSale && balances[owner] < 14500000) {
            stopPreSale();
        }
        
        if (balances[owner] >= valueToPass) {
            balances[msg.sender] = SafeMath.add(balances[msg.sender], valueToPass);
            balances[owner] = SafeMath.sub(balances[owner], valueToPass);
            Transfer(owner, msg.sender, valueToPass);
        }
    }
    
    function withdraw(uint amount) onlyOwner {
        owner.transfer(amount);
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    event Burn(uint amount);
}
```