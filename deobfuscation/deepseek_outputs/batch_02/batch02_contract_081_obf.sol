```solidity
pragma solidity ^0.4.13;

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract SpaceICOToken {
    using SafeMath for uint256;
    
    string public name = "SpaceICO Token";
    string public symbol = "SIO";
    uint256 public decimals = 18;
    uint256 public totalSupply = 50000000 * 10**18;
    
    uint256 public saleStartTime;
    uint256 public saleEndTime;
    uint256 public tokenPrice = 500 * 1 ether;
    uint256 public minGoal = 500 * 1 ether;
    
    address private owner;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event BuyToken(address indexed buyer, uint256 amount, uint256 tokens);
    event Refund();
    
    function getSaleStartTime() constant returns (uint256) {
        return saleStartTime;
    }
    
    function getSaleEndTime() constant returns (uint256) {
        return saleEndTime;
    }
    
    function getTokenPrice() constant returns (uint256) {
        return tokenPrice;
    }
    
    function goalReached() constant returns (bool) {
        return this.balance > minGoal;
    }
    
    function saleActive() constant returns (bool) {
        return now > saleStartTime && now < saleEndTime;
    }
    
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
    
    function SpaceICOToken(uint _saleStartTime) {
        owner = msg.sender;
        
        if (_saleStartTime == 0) {
            saleStartTime = 1508025600; // Oct 15, 2017
            saleEndTime = 1509408000; // Oct 31, 2017
        } else {
            saleStartTime = _saleStartTime;
            saleEndTime = _saleStartTime + 17 days;
        }
        
        balances[owner] = totalSupply;
    }
    
    function transfer(address _to, uint256 _value) returns (bool) {
        require(_to != address(0));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require(now > saleEndTime + 14 days);
        
        if (balances[_from] >= _value &&
            allowed[_from][msg.sender] >= _value &&
            _value > 0 &&
            balances[_to].add(_value) > balances[_to]) {
            
            balances[_from] = balances[_from].sub(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            return true;
        } else {
            return false;
        }
    }
    
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        return true;
    }
    
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function() payable {
        buyTokens();
    }
    
    function buyTokens() payable {
        require(msg.value > 0);
        require(saleActive());
        
        uint256 amount = msg.value;
        uint256 price = getTokenPrice();
        uint256 tokens = price.mul(amount).div(1 ether);
        
        transfer(msg.sender, tokens);
        BuyToken(msg.sender, amount, 0);
    }
    
    function refund() {
        if (goalReached() == false && now > saleEndTime) {
            uint256 tokens = balanceOf(msg.sender);
            uint256 refundAmount = tokens.div(1 ether);
            owner.transfer(refundAmount);
            Refund();
        }
    }
    
    function withdraw() {
        require(msg.sender == owner);
        if (goalReached() == true && now > saleEndTime) {
            msg.sender.transfer(this.balance);
        }
    }
}
```