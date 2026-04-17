```solidity
pragma solidity ^0.4.24;

contract Ownable {
    address public owner;

    constructor() public payable {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
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

contract Token {
    string public constant name = "FIRST DRIVER";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public balanceOf;

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balanceOf[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowance[_owner][_spender];
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20Token is Ownable, Token {
    using SafeMath for uint256;

    uint256 internal totalTokensSold = 0;
    uint256 public tokenPrice = 800000000;
    uint256 internal constant tokenSupply = 10000000;

    function buyTokens() public payable {
        require(msg.value <= tokenPrice);
        _buyTokens(msg.sender, msg.value);
    }

    function _buyTokens(address _buyer, uint256 _value) internal {
        uint256 tokens = _value.div(tokenPrice.mul(10).div(8));
        require(tokens > 0);
        require(balanceOf[_buyer].add(tokens) > balanceOf[_buyer]);

        totalSupply = totalSupply.add(tokens);
        balanceOf[_buyer] = balanceOf[_buyer].add(tokens);

        uint256 fee = _value.div(100);
        totalTokensSold = totalTokensSold.add(fee);

        tokenPrice = totalTokensSold.div(totalSupply);

        uint256 remainder = _value % (tokenPrice.mul(10).div(8));
        require(remainder > 0);

        emit Transfer(address(this), _buyer, tokens);

        owner.transfer(fee.mul(5));
        _buyer.transfer(remainder);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        if (_to != address(this)) {
            require(balanceOf[_to].add(_value) >= balanceOf[_to]);
            balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
            balanceOf[_to] = balanceOf[_to].add(_value);
            emit Transfer(msg.sender, _to, _value);
        } else {
            balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
            uint256 etherValue = _value.mul(tokenPrice);
            require(address(this).balance >= etherValue);

            if (totalSupply > _value) {
                uint256 newPrice = (address(this).balance.sub(totalTokensSold)).div(totalSupply);
                totalTokensSold = totalTokensSold.sub(etherValue);
                totalSupply = totalSupply.sub(_value);
                totalTokensSold = totalTokensSold.add(newPrice.mul(_value));
                tokenPrice = totalTokensSold.div(totalSupply);
            }

            msg.sender.transfer(etherValue);
        }
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(allowance[_from][msg.sender] >= _value);

        if (_to != address(this)) {
            require(balanceOf[_to].add(_value) >= balanceOf[_to]);
            balanceOf[_from] = balanceOf[_from].sub(_value);
            balanceOf[_to] = balanceOf[_to].add(_value);
            allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
            emit Transfer(_from, _to, _value);
        } else {
            balanceOf[_from] = balanceOf[_from].sub(_value);
            uint256 etherValue = _value.mul(tokenPrice);
            require(address(this).balance >= etherValue);

            if (totalSupply > _value) {
                uint256 newPrice = (address(this).balance.sub(totalTokensSold)).div(totalSupply);
                totalTokensSold = totalTokensSold.sub(etherValue);
                totalSupply = totalSupply.sub(_value);
                totalTokensSold = totalTokensSold.add(newPrice.mul(_value));
                tokenPrice = totalTokensSold.div(totalSupply);
            }

            msg.sender.transfer(etherValue);
        }
        return true;
    }
}
```