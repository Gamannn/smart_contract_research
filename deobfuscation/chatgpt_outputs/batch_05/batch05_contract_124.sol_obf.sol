```solidity
pragma solidity ^0.4.21;

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

contract Ownable {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

interface TokenRecipient {
    function receiveApproval(address from, uint256 value, address token, bytes extraData) external;
}

contract Token {
    using SafeMath for uint256;

    uint256 public totalSupply;
    bool public transfersEnabled;

    event Burn(address indexed from, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function balanceOf(address _owner) view public returns(uint256) {
        return balanceOf[_owner];
    }

    function allowance(address _owner, address _spender) view public returns(uint256) {
        return allowance[_owner][_spender];
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(transfersEnabled);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns(bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns(bool) {
        require((_value == 0) || (allowance[msg.sender][_spender] == 0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns(bool) {
        TokenRecipient spender = TokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
        return false;
    }

    function burn(uint256 _value) public returns(bool) {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns(bool) {
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(_from, _value);
        return true;
    }
}

contract AIgathaToken is Token, Ownable {
    using SafeMath for uint256;

    string public constant name = "AIgatha Token";
    string public constant symbol = "ATH";
    uint8 public constant decimals = 18;
    uint256 public initialSupply;
    uint256 public saleCap;
    uint256 public startDate;
    uint256 public endDate;
    uint256 public rate;
    uint256 public weiRaised;
    bool public saleActive;

    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);
    event PreICOTokenPushed(address indexed to, uint256 amount);

    function AIgathaToken() public {
        owner = msg.sender;
        initialSupply = 1000000 * (10 ** uint256(decimals));
        totalSupply = initialSupply;
        balanceOf[owner] = totalSupply;
        saleCap = 500000 * (10 ** uint256(decimals));
        startDate = now;
        endDate = now + 60 days;
        rate = 10000;
        saleActive = false;
    }

    function startSale() onlyOwner public {
        require(!saleActive);
        require(now >= startDate && now <= endDate);
        saleActive = true;
    }

    function endSale() onlyOwner public {
        require(saleActive);
        saleActive = false;
    }

    function getRate(uint256 _date) public view returns(uint256) {
        if (_date < (startDate + 15 days)) {
            return 10500;
        } else {
            return 10000;
        }
    }

    function () payable public {
        buyTokens(msg.sender, msg.value);
    }

    function buyTokens(address _beneficiary, uint256 _weiAmount) internal {
        require(saleActive);
        uint256 tokens = _weiAmount.mul(getRate(now));
        require(balanceOf[owner] >= tokens);
        balanceOf[owner] = balanceOf[owner].sub(tokens);
        balanceOf[_beneficiary] = balanceOf[_beneficiary].add(tokens);
        weiRaised = weiRaised.add(_weiAmount);
        emit TokenPurchase(_beneficiary, _weiAmount, tokens);
    }

    function withdraw() onlyOwner public {
        owner.transfer(address(this).balance);
    }

    function collectUnsoldTokens() onlyOwner public {
        require(!saleActive);
        balanceOf[owner] = balanceOf[owner].add(balanceOf[address(this)]);
        balanceOf[address(this)] = 0;
        transfersEnabled = true;
    }
}
```