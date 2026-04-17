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
}

interface TokenRecipient {
    function receiveApproval(address from, uint256 value, address token, bytes extraData) public;
}

contract Token is Ownable {
    string public name = "Token";
    string public symbol = "TKN";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public rate = 10;
    bool public released = false;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public frozenAccount;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event FrozenFunds(address target, bool frozen);

    function Token() public {}

    modifier canTransfer() {
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

    function transfer(address _to, uint256 _value) canTransfer internal {
        require(_to != 0x0);
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        require(!frozenAccount[msg.sender]);
        require(!frozenAccount[_to]);

        uint256 previousBalances = balanceOf[msg.sender] + balanceOf[_to];
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
        assert(balanceOf[msg.sender] + balanceOf[_to] == previousBalances);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        transfer(_from, _to, _value);
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

    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }

    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    function setRate(uint256 newRate) onlyOwner public {
        rate = newRate;
    }

    function () payable public {
        uint256 amount = msg.value * rate;
        transfer(this, msg.sender, amount);
    }

    function setCrowdsaleAgent(address _crowdsaleAgent) onlyOwner public {
        crowdsaleAgent = _crowdsaleAgent;
    }
}

contract Destructible is Ownable {
    function destroy() onlyOwner public {
        selfdestruct(owner);
    }
}

contract Crowdsale is Ownable, Destructible {
    Token public token;
    string public name = "Pre ICO";
    uint public startTime = 1521648000;
    uint public endTime;
    uint256 public rate = 1045;

    event EndsAtChanged(uint newEndTime);
    event RateChanged(uint oldRate, uint newRate);

    function Crowdsale(address _tokenAddress) public {
        token = Token(_tokenAddress);
    }

    function investInternal(address _beneficiary) private {
        require(!finalized);
        require(startTime <= now && endTime > now);
        require(tokensSold <= maxGoal);

        if (investedAmountOf[_beneficiary] == 0) {
            investorCount++;
        }

        uint256 tokensAmount = msg.value * rate;
        investedAmountOf[_beneficiary] += msg.value;
        tokensSold += tokensAmount;
        weiRaised += msg.value;

        token.mintToken(_beneficiary, tokensAmount);
    }

    function invest() public payable {
        investInternal(msg.sender);
    }

    function buy() public payable {
        invest();
    }

    function setEndsAt(uint _endsAt) onlyOwner public {
        require(!finalized);
        require(_endsAt >= now);
        endTime = _endsAt;
        EndsAtChanged(endTime);
    }

    function setRate(uint _rate) onlyOwner public {
        require(!finalized);
        require(_rate > 0);
        RateChanged(rate, _rate);
        rate = _rate;
    }

    function finalize() public onlyOwner {
        require(endTime < now);
        finalized = true;
        token.releaseTokenTransfer();
        token.transfer(owner, this.balance);
    }
}