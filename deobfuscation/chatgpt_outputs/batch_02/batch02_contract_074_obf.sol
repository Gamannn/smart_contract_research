```solidity
pragma solidity ^0.4.18;

contract ERC20Interface {
    function balanceOf(address tokenOwner) public constant returns (uint256 balance);
    function transfer(address to, uint256 tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
}

contract TokenReceiver {
    function receiveApproval(uint256 amount, bytes data) public;
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

contract BasicToken is ERC20Interface {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    function transfer(address to, uint256 tokens) public returns (bool success) {
        require(to != address(0));
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }

    function balanceOf(address tokenOwner) public constant returns (uint256 balance) {
        return balances[tokenOwner];
    }
}

contract Ownable {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
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

contract Crowdsale is Pausable {
    using SafeMath for uint256;

    event BonusChange(uint256 bonus);
    event RateChange(address token, uint256 rate);
    event Purchase(address indexed purchaser, address token, uint256 value, uint256 amount);
    event Withdraw(address token, address to, uint256 amount);
    event Burn(address token, uint256 amount, bytes data);

    mapping(address => uint256) public rates;
    uint256 public bonus;

    function receiveApproval(address from, uint256 value, bytes data) public;

    function() payable public {
        buyTokens("");
    }

    function buyTokens(bytes data) payable public {
        processPurchase(address(0), msg.sender, msg.value, data);
    }

    function processPurchase(address token, address purchaser, uint256 value, bytes data) internal {
        uint256 amount = calculateAmount(token, value);
        require(amount > 0);

        address beneficiary;
        if (data.length == 20) {
            beneficiary = address(bytes20(data));
        } else {
            require(data.length == 0);
            beneficiary = purchaser;
        }

        Purchase(beneficiary, token, value, amount);
        deliverTokens(beneficiary, amount);
    }

    function deliverTokens(address beneficiary, uint256 amount) internal;

    function calculateAmount(address token, uint256 value) constant public returns (uint256) {
        uint256 rate = rates[token];
        require(rate > 0);
        uint256 amount = value.mul(rate);
        return amount.add(amount.mul(bonus).div(100)).div(10**18);
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
        if (token == address(0)) {
            to.transfer(amount);
        } else {
            ERC20Interface(token).transfer(to, amount);
        }
        Withdraw(token, to, amount);
    }

    function burn(address token, uint256 amount, bytes data) onlyOwner public {
        TokenReceiver(token).receiveApproval(amount, data);
        Burn(token, amount, data);
    }
}

contract Token is BasicToken, Crowdsale {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    function Token(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balances[msg.sender] = _totalSupply;
    }

    function deliverTokens(address beneficiary, uint256 amount) internal {
        balances[beneficiary] = balances[beneficiary].add(amount);
        balances[msg.sender] = balances[msg.sender].sub(amount);
        Transfer(msg.sender, beneficiary, amount);
    }
}
```