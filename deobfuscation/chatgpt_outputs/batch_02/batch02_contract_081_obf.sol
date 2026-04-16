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
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    address private owner;
    uint256 public saleStart;
    uint256 public saleEnd;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event BuyToken(address indexed buyer, uint256 value, uint256 amount);
    event Refund();

    function SpaceICOToken(uint256 _saleEnd) public {
        owner = msg.sender;
        if (_saleEnd == 0) {
            saleStart = 1508025600; // 10.15.2017
            saleEnd = 1509408000; // 10.31.2017
        } else {
            saleStart = now;
            saleEnd = _saleEnd + 17 days;
        }
        balanceOf[owner] = 50000000 * 10 ** decimals;
        totalSupply = balanceOf[owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(now > saleEnd + 14 days);
        require(balanceOf[_from] >= _value);
        require(allowance[_from][msg.sender] >= _value);
        require(_value > 0);
        require(balanceOf[_to].add(_value) > balanceOf[_to]);

        balanceOf[_from] = balanceOf[_from].sub(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowanceOf(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowance[_owner][_spender];
    }

    function() payable public {
        buyTokens();
    }

    function buyTokens() payable public {
        require(msg.value > 0);
        require(now > saleStart && now < saleEnd);

        uint256 weiAmount = msg.value;
        uint256 tokens = weiAmount.mul(getRate()).div(1 ether);
        transfer(msg.sender, tokens);
        BuyToken(msg.sender, weiAmount, tokens);
    }

    function getRate() public constant returns (uint256) {
        return 500 * 1 ether;
    }

    function refund() public {
        require(now > saleEnd);
        uint256 balance = balanceOf[msg.sender];
        uint256 refundAmount = balance.div(1 ether);
        transfer(owner, refundAmount);
        Refund();
    }

    function withdraw() public {
        require(msg.sender == owner);
        require(now > saleEnd);
        owner.transfer(this.balance);
    }
}
```