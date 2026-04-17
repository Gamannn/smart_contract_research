```solidity
pragma solidity ^0.4.23;

contract ERC20Token {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);

        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);

        emit Transfer(_from, _to, _value);
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
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}

contract BurnableToken is ERC20Token {
    event Burn(address indexed from, uint256 value);

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }
}

contract ICOContract is ERC20Token {
    uint256 public tokenPrice;
    uint256 public icoEndTime;
    address public icoWallet;

    event ICO(address indexed buyer, uint256 amountPaid, uint256 tokensBought);
    event Withdraw(address indexed owner, uint256 amount);

    modifier onlyBeforeEnd() {
        if (now > icoEndTime) {
            revert();
        }
        _;
    }

    function buyTokens() public payable onlyBeforeEnd {
        uint256 tokens = (msg.value * tokenPrice * 10 ** uint256(decimals)) / (1 ether / 1 wei);
        require(tokens > 0);
        _transfer(icoWallet, msg.sender, tokens);
        emit ICO(msg.sender, msg.value, tokens);
    }

    function withdraw() public {
        uint256 balance = address(this).balance;
        icoWallet.transfer(balance);
        emit Withdraw(msg.sender, balance);
    }
}

contract Token is ERC20Token, BurnableToken, ICOContract {
    constructor() public {
        totalSupply = 10000000000000000000000000000;
        balanceOf[0x649F543994ae132aC04FdBBcDe523F107d79d995] = totalSupply;
        name = "Torken";
        symbol = "TKI";
        decimals = 18;
        tokenPrice = 10000;
        icoEndTime = 1677668400;
        icoWallet = 0x649F543994ae132aC04FdBBcDe523F107d79d995;
    }
}
```