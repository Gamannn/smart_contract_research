```solidity
pragma solidity ^0.4.17;

contract ERC20Basic {
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) returns (bool);
    function approve(address spender, uint256 value) returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length == size + 4);
        _;
    }
    
    mapping(address => uint256) balances;
    
    function transfer(address to, uint256 value) onlyPayloadSize(2 * 32) returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        Transfer(msg.sender, to, value);
        return true;
    }
    
    function balanceOf(address owner) constant returns (uint256 balance) {
        return balances[owner];
    }
}

contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) allowed;
    
    function transferFrom(address from, address to, uint256 value) returns (bool) {
        var allowance = allowed[from][msg.sender];
        balances[to] = balances[to].add(value);
        balances[from] = balances[from].sub(value);
        allowed[from][msg.sender] = allowance.sub(value);
        Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) returns (bool) {
        require((value == 0) || (allowed[msg.sender][spender] == 0));
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }
    
    function allowance(address owner, address spender) constant returns (uint256 remaining) {
        return allowed[owner][spender];
    }
}

contract Ownable {
    address public owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner {
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
    
    function mint(address to, uint256 amount) onlyOwner canMint returns (bool) {
        totalSupply = totalSupply.add(amount);
        balances[to] = balances[to].add(amount);
        Transfer(this, to, amount);
        return true;
    }
    
    function finishMinting() onlyOwner returns (bool) {
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
    bool private rentrancy_lock = false;
    
    modifier nonReentrant() {
        require(!rentrancy_lock);
        rentrancy_lock = true;
        _;
        rentrancy_lock = false;
    }
}

contract Stateful {
    enum State { Init, PreIco, PreIcoPaused, preIcoFinished, ICO, salePaused, CrowdsaleFinished, companySold }
    State public state = State.Init;
    
    event StateChanged(State oldState, State newState);
    
    function setState(State newState) internal {
        State oldState = state;
        state = newState;
        StateChanged(oldState, newState);
    }
}

contract Oracled {
    function getRate(uint period) constant returns (uint256);
    function getRateCent(uint period) constant returns (uint256);
    function getPeriod(uint period) constant returns (uint256);
    function getDay(uint period) constant returns (uint256);
    function getDayish(uint period) constant returns (uint);
}

contract Crowdsale is Ownable, Stateful, ReentrancyGuard {
    using SafeMath for uint;
    
    mapping (address => uint) preIcoBalances;
    mapping (address => uint) icoBalances;
    BSEToken public token;
    uint256 public priceUSD;
    uint256 public preIcoHardCap;
    uint256 public icoHardCap;
    uint256 public soldTokens;
    uint256 public collectedCent;
    uint256 public period;
    uint256 public startPreIco;
    uint256 public startICO;
    Oracled public oracle;
    uint256 public rateCent;
    uint256 public preIcoDuration;
    uint256 public icoDuration;
    
    modifier isUnderHardCap() {
        require(soldTokens < hardCap());
        _;
    }
    
    function hardCap() internal returns(uint256) {
        if (state == State.PreIco) {
            return preIcoHardCap;
        }
        if (state == State.ICO) {
            return icoHardCap;
        }
        return 0;
    }
    
    function Crowdsale(address multisig, uint256 initialPriceUSD) {
        priceUSD = initialPriceUSD;
        owner = multisig;
        token = new BSEToken();
    }
    
    function finalizeCompany() onlyOwner {
        require(state == State.CrowdsaleFinished);
        setState(State.companySold);
    }
    
    function manualBuy(address to, uint amountCent) onlyOwner {
        uint256 valueCent = amountCent * 100;
        uint256 tokens = oracle.mul(valueCent);
        rateCent = valueCent;
        token.mint(to, tokens);
        
        if (state == State.ICO || state == State.preIcoFinished) {
            icoBalances[to] += tokens;
        } else {
            preIcoBalances[to] += tokens;
        }
        soldTokens += tokens;
    }
    
    function pauseSale() onlyOwner {
        require(state == State.ICO);
        setState(State.salePaused);
    }
    
    function pausePreIco() onlyOwner {
        require(state == State.PreIco);
        setState(State.PreIcoPaused);
    }
    
    function startPreIco(uint256 hardCapTokens, uint256 price) onlyOwner {
        require(hardCapTokens > 0);
        require(state == State.Init || state == State.PreIcoPaused);
        priceUSD = price;
        startPreIco = now;
        preIcoHardCap = hardCapTokens * 1 ether;
        preIcoDuration = 30 days;
        setState(State.PreIco);
    }
    
    function finishPreIco() onlyOwner {
        require(state == State.PreIco);
        setState(State.preIcoFinished);
        bool sent = owner.call.gas(3000000).value(this.balance)();
        require(sent);
    }
    
    function startICO(uint256 hardCapTokens, uint256 price) onlyOwner {
        require(hardCapTokens > 0);
        require(state == State.PreIco || state == State.salePaused || state == State.preIcoFinished);
        priceUSD = price;
        startICO = now;
        icoHardCap = hardCapTokens * 1 ether;
        icoDuration = 30 days;
        setState(State.ICO);
    }
    
    function setPriceUSD(uint256 price) onlyOwner {
        priceUSD = price;
    }
    
    function finishICO() onlyOwner {
        require(state == State.ICO);
        setState(State.CrowdsaleFinished);
        bool sent = owner.call.gas(3000000).value(this.balance)();
        require(sent);
    }
    
    function finishMinting() onlyOwner {
        token.finishMinting();
    }
    
    function claimTokens() nonReentrant {
        require (state == State.ICO || state == State.companySold);
        uint256 extraTokensAmount;
        if (state == State.ICO) {
            extraTokensAmount = preIcoBalances[msg.sender];
            preIcoBalances[msg.sender] = 0;
            token.mint(msg.sender, extraTokensAmount);
            icoBalances[msg.sender] += extraTokensAmount;
        } else {
            if (state == State.companySold) {
                extraTokensAmount = preIcoBalances[msg.sender] + icoBalances[msg.sender];
                preIcoBalances[msg.sender] = 0;
                icoBalances[msg.sender] = 0;
                token.mint(msg.sender, extraTokensAmount);
            }
        }
    }
    
    function buyTokens() payable nonReentrant isUnderHardCap {
        uint256 valueWei = msg.value;
        uint256 valueCent = valueWei.div(priceUSD);
        uint256 tokens = priceUSD.mul(valueCent);
        uint256 cap = hardCap();
        
        if (soldTokens + tokens > cap) {
            tokens = cap.sub(soldTokens);
            valueCent = tokens.div(oracle);
            valueWei = valueCent.mul(priceUSD);
            uint256 change = msg.value - valueWei;
            bool sent = msg.sender.call.gas(3000000).value(change)();
            require(sent);
        }
        
        token.mint(msg.sender, tokens);
        collectedCent += valueCent;
        soldTokens += tokens;
        
        if (state == State.PreIco) {
            preIcoBalances[msg.sender] += tokens;
        } else {
            icoBalances[msg.sender] += tokens;
        }
    }
    
    function () payable {
        buyTokens();
    }
}
```