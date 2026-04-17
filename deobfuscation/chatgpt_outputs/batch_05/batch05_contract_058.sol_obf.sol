pragma solidity ^0.4.17;

contract ERC20Interface {
    uint256 public totalSupply;
    function balanceOf(address tokenOwner) public constant returns (uint256 balance);
    function transfer(address to, uint256 tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
}

contract ERC20 is ERC20Interface {
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

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

contract BasicToken is ERC20Interface {
    using SafeMath for uint256;
    mapping(address => uint256) balances;

    function transfer(address to, uint256 tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }

    function balanceOf(address tokenOwner) public constant returns (uint256 balance) {
        return balances[tokenOwner];
    }
}

contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) allowed;

    function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
        uint256 allowance = allowed[from][msg.sender];
        balances[to] = balances[to].add(tokens);
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowance.sub(tokens);
        Transfer(from, to, tokens);
        return true;
    }

    function approve(address spender, uint256 tokens) public returns (bool success) {
        require((tokens == 0) || (allowed[msg.sender][spender] == 0));
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }
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

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    function mint(address to, uint256 amount) onlyOwner canMint public returns (bool) {
        totalSupply = totalSupply.add(amount);
        balances[to] = balances[to].add(amount);
        Transfer(this, to, amount);
        return true;
    }

    function finishMinting() onlyOwner public returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
}

contract BSEToken is MintableToken {
    string public constant name = "BLACK SNAIL ENERGY";
    string public constant symbol = "BSE";
    uint32 public constant decimals = 18;
    event Burn(address indexed burner, uint256 value);

    function burn(uint256 value) public {
        require(value > 0);
        require(value <= balances[msg.sender]);
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(value);
        totalSupply = totalSupply.sub(value);
        Burn(burner, value);
    }
}

contract ReentrancyGuard {
    bool private reentrancy_lock = false;

    modifier nonReentrant() {
        require(!reentrancy_lock);
        reentrancy_lock = true;
        _;
        reentrancy_lock = false;
    }
}

contract CrowdsaleStateful {
    enum State { Init, PreIco, PreIcoPaused, PreIcoFinished, ICO, SalePaused, CrowdsaleFinished, CompanySold }
    State public state = State.Init;
    event StateChanged(State oldState, State newState);

    function changeState(State newState) internal {
        State oldState = state;
        state = newState;
        StateChanged(oldState, newState);
    }
}

contract PriceOracle {
    function getPriceUSD(uint timestamp) constant returns (uint256);
    function getPriceETH(uint timestamp) constant returns (uint256);
    function getPriceBTC(uint timestamp) constant returns (uint256);
    function getPriceLTC(uint timestamp) constant returns (uint256);
    function getPriceXRP(uint timestamp) constant returns (uint);
}

contract Crowdsale is Ownable, ReentrancyGuard, CrowdsaleStateful {
    using SafeMath for uint;
    mapping (address => uint) public preIcoBalances;
    mapping (address => uint) public icoBalances;
    BSEToken public token;
    uint256 public priceUSD;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public rate;
    uint256 public weiRaised;
    uint256 public tokensSold;
    uint256 public hardCap;
    uint256 public softCap;
    uint256 public minContribution;
    uint256 public maxContribution;
    address public wallet;
    PriceOracle public priceOracle;

    modifier isUnderHardCap() {
        require(tokensSold < hardCap);
        _;
    }

    function Crowdsale(address _wallet, uint256 _priceUSD) public {
        wallet = _wallet;
        priceUSD = _priceUSD;
        token = new BSEToken();
    }

    function startPreIco(uint256 _rate, uint256 _priceUSD) onlyOwner public {
        require(_rate > 0);
        require(state == State.Init || state == State.PreIcoPaused);
        priceUSD = _priceUSD;
        startTime = now;
        rate = _rate;
        changeState(State.PreIco);
    }

    function finishPreIco() onlyOwner public {
        require(state == State.PreIco);
        changeState(State.PreIcoFinished);
        bool multisigSent = wallet.call.gas(3000000).value(this.balance)();
        require(multisigSent);
    }

    function startIco(uint256 _rate, uint256 _priceUSD) onlyOwner public {
        require(_rate > 0);
        require(state == State.PreIco || state == State.SalePaused || state == State.PreIcoFinished);
        priceUSD = _priceUSD;
        startTime = now;
        rate = _rate;
        changeState(State.ICO);
    }

    function finishIco() onlyOwner public {
        require(state == State.ICO);
        changeState(State.CrowdsaleFinished);
        bool multisigSent = wallet.call.gas(3000000).value(this.balance)();
        require(multisigSent);
    }

    function mintTokens(address to, uint256 amount) onlyOwner public returns (bool) {
        return token.mint(to, amount);
    }

    function () payable {
        buyTokens();
    }

    function buyTokens() payable isUnderHardCap nonReentrant public {
        uint256 weiAmount = msg.value;
        uint256 tokens = weiAmount.div(priceUSD).mul(rate);
        uint256 refund = 0;

        if (tokensSold.add(tokens) > hardCap) {
            tokens = hardCap.sub(tokensSold);
            weiAmount = tokens.div(rate).mul(priceUSD);
            refund = msg.value.sub(weiAmount);
        }

        token.mint(msg.sender, tokens);
        weiRaised = weiRaised.add(weiAmount);
        tokensSold = tokensSold.add(tokens);

        if (state == State.PreIco) {
            preIcoBalances[msg.sender] = preIcoBalances[msg.sender].add(tokens);
        } else {
            icoBalances[msg.sender] = icoBalances[msg.sender].add(tokens);
        }

        if (refund > 0) {
            msg.sender.transfer(refund);
        }
    }
}