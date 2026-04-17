```solidity
pragma solidity ^0.4.0;

contract Token {
    function balanceOf(address who) constant returns (uint);
    function allowance(address owner, address spender) constant returns(uint);
}

contract Ownable {
    address public owner;
    address public newOwner;
    
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }
    
    function Ownable() {
        owner = msg.sender;
    }
    
    function transferOwnership(address _newOwner) onlyOwner public {
        require(_newOwner != 0);
        newOwner = _newOwner;
    }
    
    function acceptOwnership() public {
        require(newOwner == msg.sender);
        owner = newOwner;
        delete newOwner;
    }
}

contract Crowdsale is Ownable {
    uint constant public TOTAL_TOKENS = 25000000;
    uint constant public PRESALE_LIMIT_USD = 500000;
    uint constant public BONUS_TOKENS = 1250000;
    
    address public tokenAddress;
    uint public etherPrice;
    uint public totalSupply;
    
    mapping(address => uint) public balanceOf;
    mapping(uint => address) public holders;
    mapping(address => bool) public isHolder;
    uint public numberOfHolders;
    
    enum State { Disabled, Presale, Bonuses, Enabled }
    State public state;
    
    address public presaleOwner;
    uint public collectedUSD;
    uint public totalLimitUSD = 3000000;
    uint public neurodaoTokens;
    
    modifier onlyEnabled() {
        require(state == State.Enabled);
        _;
    }
    
    event NewState(State state);
    event Transfer(address indexed from, address indexed to, uint value);
    
    function Crowdsale(address _tokenAddress, uint _etherPrice) payable {
        tokenAddress = _tokenAddress;
        etherPrice = _etherPrice;
        totalSupply = TOTAL_TOKENS;
        balanceOf[owner] = totalSupply;
        Transfer(address(0), owner, balanceOf[owner]);
    }
    
    function setEtherPrice(uint _etherPrice) public {
        require(presaleOwner == msg.sender || owner == msg.sender);
        etherPrice = _etherPrice;
    }
    
    function startPresale(address _presaleOwner) public onlyOwner {
        require(state == State.Disabled);
        presaleOwner = _presaleOwner;
        state = State.Presale;
        NewState(state);
    }
    
    function startBonuses() public onlyOwner {
        require(state == State.Presale);
        state = State.Bonuses;
        NewState(state);
    }
    
    function finishCrowdsale() public onlyOwner {
        require(state == State.Bonuses);
        state = State.Enabled;
        NewState(state);
    }
    
    function() payable {
        uint tokens;
        address source;
        
        if (state == State.Presale) {
            require(balanceOf[this] > 0);
            require(collectedUSD < totalLimitUSD);
            
            uint weiAmount = msg.value;
            uint usdAmount = weiAmount * etherPrice / 1 ether;
            
            if (collectedUSD + usdAmount > totalLimitUSD) {
                usdAmount = totalLimitUSD - collectedUSD;
                weiAmount = usdAmount * 1 ether / etherPrice;
                require(msg.sender.call.value(msg.value - weiAmount)());
                collectedUSD = totalLimitUSD;
            } else {
                collectedUSD += usdAmount;
            }
            
            uint bonusPercent;
            if (now <= 1506815999) {
                bonusPercent = 100;
            } else if (now <= 1507247999) {
                bonusPercent = 50;
            } else if (now <= 1507766399) {
                bonusPercent = 65;
            } else {
                bonusPercent = 70;
            }
            
            tokens = usdAmount * 100 / bonusPercent;
            
            if (Token(tokenAddress).balanceOf(msg.sender) >= 1000) {
                neurodaoTokens += tokens;
            }
            source = this;
        } else if (state == State.Bonuses) {
            require(!isHolder[msg.sender]);
            isHolder[msg.sender] = true;
            
            uint tokenBalance = Token(tokenAddress).balanceOf(msg.sender);
            if (tokenBalance >= 1000) {
                tokens = (BONUS_TOKENS / 10) * tokenBalance / 21000;
            } else {
                tokens = (BONUS_TOKENS / 10) * balanceOf[msg.sender] / neurodaoTokens;
            }
            source = owner;
        }
        
        require(tokens > 0);
        require(balanceOf[msg.sender] + tokens > balanceOf[msg.sender]);
        require(balanceOf[source] >= tokens);
        
        if (!isHolder[msg.sender]) {
            isHolder[msg.sender] = true;
            holders[numberOfHolders++] = msg.sender;
        }
        
        balanceOf[msg.sender] += tokens;
        balanceOf[source] -= tokens;
        Transfer(source, msg.sender, tokens);
    }
}

contract TokenContract is Crowdsale {
    string public name = 'TokenContract 0.1';
    string public symbol = 'BREMP';
    string public version = 'BREMP';
    uint8 public decimals = 0;
    
    mapping(address => mapping(address => uint)) public allowance;
    
    function TokenContract(address _tokenAddress, uint _etherPrice) payable
        Crowdsale(_tokenAddress, _etherPrice) {}
    
    function transfer(address to, uint value) public onlyEnabled returns (bool) {
        require(balanceOf[msg.sender] >= value);
        require(balanceOf[to] + value >= balanceOf[to]);
        
        if (!isHolder[to]) {
            isHolder[to] = true;
            holders[numberOfHolders++] = to;
        }
        
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public onlyEnabled returns (bool) {
        require(balanceOf[from] >= value);
        require(balanceOf[to] + value >= balanceOf[to]);
        require(allowance[from][msg.sender] >= value);
        
        if (!isHolder[to]) {
            isHolder[to] = true;
            holders[numberOfHolders++] = to;
        }
        
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint value) public onlyEnabled {
        allowance[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
    }
    
    function allowance(address owner, address spender) public constant onlyEnabled returns (uint remaining) {
        return allowance[owner][spender];
    }
    
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract MainContract is TokenContract {
    function MainContract(address _tokenAddress, uint _etherPrice) payable
        TokenContract(_tokenAddress, _etherPrice) {}
    
    function withdraw() public {
        require(presaleOwner == msg.sender || owner == msg.sender);
        msg.sender.transfer(this.balance);
    }
    
    function destroy() public onlyOwner {
        presaleOwner.transfer(this.balance);
        selfdestruct(owner);
    }
}
```