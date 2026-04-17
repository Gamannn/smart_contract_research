pragma solidity ^0.4.23;

interface TokenRecipient {
    function receiveApproval(address from, uint256 value, address token, bytes extraData) external;
}

contract Token {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) internal balanceOf;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    function Token() public {
        decimals = 18;
        totalSupply = 5000000 * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        name = "Facebook Token";
        symbol = "XFBC";
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
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

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }

    function buy() public payable returns (uint256 amount) {
        amount = msg.value * getBuyPrice();
        balanceOf[msg.sender] += amount;
        balanceOf[owner] += msg.value;
        totalSupply += amount;
        return amount;
    }

    function sell(uint256 amount) public {
        require(balanceOf[msg.sender] >= amount);
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        msg.sender.transfer(amount / getSellPrice());
    }

    function getBuyPrice() public view returns (uint256) {
        return 100;
    }

    function getSellPrice() public view returns (uint256) {
        return 100;
    }

    address public owner;

    function withdraw() public {
        address myAddress = msg.sender;
        uint256 etherAmount = balanceOf[myAddress];
        balanceOf[myAddress] = 0;
        myAddress.transfer(etherAmount);
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