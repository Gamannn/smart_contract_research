pragma solidity ^0.4.17;

contract ERC20Interface {
    uint256 public totalSupply;
    function balanceOf(address tokenOwner) public constant returns (uint256 balance);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract TokenRecipient {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

contract StandardToken is ERC20Interface {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    function transfer(address to, uint256 tokens) public returns (bool) {
        require(to != 0x0);
        require(to != address(this));
        require(balances[msg.sender] >= tokens);
        require(balances[to] + tokens >= balances[to]);

        balances[msg.sender] -= tokens;
        balances[to] += tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint256 tokens) public returns (bool) {
        require(to != 0x0);
        require(to != address(this));
        require(balances[from] >= tokens);
        require(allowed[from][msg.sender] >= tokens);
        require(balances[to] + tokens >= balances[to]);

        balances[from] -= tokens;
        balances[to] += tokens;
        allowed[from][msg.sender] -= tokens;
        emit Transfer(from, to, tokens);
        return true;
    }

    function balanceOf(address tokenOwner) public constant returns (uint256) {
        return balances[tokenOwner];
    }

    function approve(address spender, uint256 tokens) public returns (bool) {
        require(spender != 0x0);
        require(tokens == 0 || allowed[msg.sender][spender] == 0);

        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public constant returns (uint256) {
        return allowed[tokenOwner][spender];
    }
}

contract MintableToken is StandardToken {
    string public name = "MintableToken";
    string public symbol = "MTO";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000 * 10 ** uint256(decimals);

    function MintableToken() public {
        balances[msg.sender] = totalSupply;
        emit Transfer(0x0, msg.sender, totalSupply);
    }

    function mint(uint256 amount) public {
        require(amount > 0);
        require(balances[msg.sender] >= amount);

        totalSupply += amount;
        balances[msg.sender] += amount;
        emit Transfer(0x0, msg.sender, amount);
    }

    function burn(uint256 amount) public {
        require(amount > 0);
        require(balances[msg.sender] >= amount);

        totalSupply -= amount;
        balances[msg.sender] -= amount;
        emit Transfer(msg.sender, 0x0, amount);
    }
}

contract Crowdsale {
    MintableToken public token;
    address public wallet;
    uint256 public rate;
    uint256 public weiRaised;
    uint256 public cap;
    uint256 public openingTime;
    uint256 public closingTime;
    bool public isFinalized = false;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event Finalized();

    modifier onlyWhileOpen {
        require(now >= openingTime && now <= closingTime);
        _;
    }

    function Crowdsale(uint256 _rate, address _wallet, MintableToken _token, uint256 _cap, uint256 _openingTime, uint256 _closingTime) public {
        require(_rate > 0);
        require(_wallet != 0x0);
        require(_token != address(0));
        require(_cap > 0);
        require(_openingTime >= now);
        require(_closingTime >= _openingTime);

        rate = _rate;
        wallet = _wallet;
        token = _token;
        cap = _cap;
        openingTime = _openingTime;
        closingTime = _closingTime;
    }

    function () external payable onlyWhileOpen {
        uint256 weiAmount = msg.value;
        uint256 tokens = weiAmount * rate;

        require(weiRaised + weiAmount <= cap);

        weiRaised += weiAmount;
        token.transfer(msg.sender, tokens);
        emit TokenPurchase(msg.sender, msg.sender, weiAmount, tokens);

        wallet.transfer(msg.value);
    }

    function finalize() public {
        require(!isFinalized);
        require(now > closingTime || weiRaised >= cap);

        finalization();
        emit Finalized();

        isFinalized = true;
    }

    function finalization() internal {
        // Finalization logic
    }
}