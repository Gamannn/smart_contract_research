```solidity
pragma solidity ^0.4.16;

contract Ownable {
    address public owner;
    
    function Ownable() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface TokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}

contract Token is Ownable {
    string public name = "RT";
    string public symbol = "RT";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public buyPrice = 10;
    bool public released = false;
    
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;
    mapping (address => uint256) public balanceOf;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event FrozenFunds(address target, bool frozen);
    
    function Token() public {
    }
    
    modifier whenReleased() {
        require(released);
        _;
    }
    
    modifier onlyCrowdsaleAgent() {
        require(msg.sender == crowdsaleAgent);
        _;
    }
    
    function releaseTokenTransfer() public onlyCrowdsaleAgent {
        released = true;
    }
    
    function _transfer(address _from, address _to, uint _value) whenReleased internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        TokenRecipient spender = TokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
    
    function mintToken(address target, uint256 mintedAmount) onlyCrowdsaleAgent public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }
    
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
    
    function setPrices(uint256 newBuyPrice) onlyOwner public {
        buyPrice = newBuyPrice;
    }
    
    function buy() payable public {
        uint amount = msg.value * buyPrice;
        _transfer(this, msg.sender, amount);
    }
    
    function setCrowdsaleAgent(address _crowdsaleAgent) onlyOwner public {
        crowdsaleAgent = _crowdsaleAgent;
    }
    
    address public crowdsaleAgent;
}

contract Destructible is Ownable {
    function destroy() onlyOwner {
        selfdestruct(owner);
    }
}

contract Crowdsale is Ownable, Destructible {
    Token public token;
    string public name = "Pre ICO";
    uint public startsAt = 1521648000;
    uint public endsAt = 1521666000;
    uint256 public rate = 1045;
    
    event EndsAtChanged(uint newEndsAt);
    event RateChanged(uint oldRate, uint newRate);
    
    uint256 public investorCount = 0;
    uint256 public weiRaised = 0;
    uint256 public tokensSold = 0;
    bool public finalized = false;
    uint256 public MAX_GOAL = 30 * 10 ** 18;
    
    mapping(address => uint256) public investedAmountOf;
    mapping(address => uint256) public tokenAmountOf;
    
    function Crowdsale(address _token) {
        token = Token(_token);
    }
    
    function invest(address receiver) private {
        require(!finalized);
        require(startsAt <= now && endsAt > now);
        require(tokensSold <= MAX_GOAL);
        
        if(tokenAmountOf[receiver] == 0) {
            investorCount++;
        }
        
        uint256 tokensAmount = msg.value * rate;
        investedAmountOf[receiver] += msg.value;
        tokenAmountOf[receiver] += tokensAmount;
        tokensSold += tokensAmount;
        weiRaised += msg.value;
        
        token.mintToken(receiver, tokensAmount);
    }
    
    function buyTokens() public payable {
        invest(msg.sender);
    }
    
    function() payable {
        buyTokens();
    }
    
    function setEndsAt(uint time) onlyOwner {
        require(!finalized);
        require(time >= now);
        endsAt = time;
        EndsAtChanged(endsAt);
    }
    
    function setRate(uint newRate) onlyOwner {
        require(!finalized);
        require(newRate > 0);
        RateChanged(rate, newRate);
        rate = newRate;
    }
    
    function finalize(address receiver) public onlyOwner {
        require(endsAt < now);
        finalized = true;
        token.releaseTokenTransfer();
        receiver.transfer(this.balance);
    }
}
```