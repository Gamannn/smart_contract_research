pragma solidity ^0.4.18;

contract ERC20Basic {
    function balanceOf(address who) constant public returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant public returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BurnableToken {
    function burn(uint256 value, bytes data) public;
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) balances;

    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0));
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        Transfer(msg.sender, to, value);
        return true;
    }

    function balanceOf(address owner) constant public returns (uint256) {
        return balances[owner];
    }
}

contract TokenReceiver {
    function tokenFallback(address from, uint256 value, bytes data) public;
}

contract Ownable {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        owner = newOwner;
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();
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
}

contract Crowdsale is TokenReceiver, Pausable {
    using SafeMath for uint256;
    event BonusChange(uint256 bonus);
    event RateChange(address token, uint256 rate);
    event Purchase(address indexed beneficiary, address token, uint256 amount, uint256 tokens);
    event Withdraw(address token, address to, uint256 amount);
    event Burn(address token, uint256 amount, bytes data);

    mapping (address => uint256) rates;
    uint256 public bonus;

    function tokenFallback(address token, uint256 amount, bytes data) public {
        buyTokens(token, amount, data);
    }

    function() payable whenNotPaused public {
        buyTokensWithEther("");
    }

    function buyTokensWithEther(bytes data) payable whenNotPaused public {
        buyTokens(address(0), msg.sender, msg.value, data);
    }

    function buyTokens(address token, address buyer, uint256 amount, bytes data) internal {
        uint256 tokens = calculateTokens(token, amount);
        require(tokens > 0);
        address beneficiary;
        if (data.length == 20) {
            beneficiary = address(toBytes20(data, 0));
        } else {
            require(data.length == 0);
            beneficiary = buyer;
        }
        Purchase(beneficiary, token, amount, tokens);
        doPurchase(beneficiary, tokens);
    }

    function doPurchase(address beneficiary, uint256 tokens) internal;

    function toBytes20(bytes b, uint256 offset) pure internal returns (bytes20 result) {
        require(offset + 20 <= b.length);
        assembly {
            let start := add(offset, add(b, 0x20))
            result := mload(start)
        }
    }

    function calculateTokens(address token, uint256 amount) constant public returns (uint256) {
        uint256 rate = getRate(token);
        require(rate > 0);
        uint256 tokens = amount.mul(rate);
        return tokens.add(tokens.mul(bonus).div(100)).div(10**18);
    }

    function getRate(address token) constant public returns (uint256) {
        return rates[token];
    }

    function setRate(address token, uint256 rate) onlyOwner public {
        rates[token] = rate;
        RateChange(token, rate);
    }

    function setBonus(uint256 newBonus) onlyOwner public {
        bonus = newBonus;
        BonusChange(newBonus);
    }

    function withdraw(address token, address to, uint256 amount) onlyOwner public {
        require(to != address(0));
        internalWithdraw(token, to, amount);
        if (token == address(0)) {
            to.transfer(amount);
        } else {
            ERC20(token).transfer(to, amount);
        }
        Withdraw(token, to, amount);
    }

    function burn(address token, uint256 amount, bytes data) onlyOwner public {
        BurnableToken(token).burn(amount, data);
        Burn(token, amount, data);
    }

    function internalWithdraw(address token, address to, uint256 amount) internal {}
}

contract TokenCrowdsale is Crowdsale {
    ERC20 public token;

    function TokenCrowdsale(address tokenAddress) public {
        token = ERC20(tokenAddress);
    }

    function doPurchase(address beneficiary, uint256 tokens) internal {
        token.transfer(beneficiary, tokens);
    }

    function internalWithdraw(address token, address to, uint256 amount) internal {
        require(token != address(token));
    }
}

contract FinalizableCrowdsale is TokenCrowdsale {
    address public btcToken;
    uint256 public endTime;

    function changeParameters(uint256 newEndTime, uint256 btcRate, uint256 newBonus) onlyOwner public {
        setRate(address(0), 10);
        setRate(btcToken, btcRate);
        setBonus(newBonus);
        endTime = newEndTime;
    }

    function setBtcToken(address newBtcToken) onlyOwner public {
        btcToken = newBtcToken;
    }

    function doPurchase(address beneficiary, uint256 tokens) internal {
        require(now < endTime);
        super.doPurchase(beneficiary, tokens);
    }

    function finalize() onlyOwner public {
        require(now >= endTime);
        BurnableToken(token).burn(token.balanceOf(this));
    }
}

contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) allowed;

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(0));
        var allowance = allowed[from][msg.sender];
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowance.sub(value);
        Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require((value == 0) || (allowed[msg.sender][spender] == 0));
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) constant public returns (uint256) {
        return allowed[owner][spender];
    }

    function increaseApproval(address spender, uint addedValue) public returns (bool success) {
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);
        Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function decreaseApproval(address spender, uint subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][spender];
        if (subtractedValue > oldValue) {
            allowed[msg.sender][spender] = 0;
        } else {
            allowed[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
}

contract BurnableTokenImpl is StandardToken {
    function burn(uint256 value) public {
        require(value > 0);
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(value);
        totalSupply = totalSupply.sub(value);
        Burn(burner, value);
    }
    event Burn(address indexed burner, uint indexed value);
}