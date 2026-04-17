```solidity
pragma solidity ^0.4.19;

contract TokenBase {
    string public name;
    string public symbol;
    uint8 public decimals;
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

        Transfer(_from, _to, _value);
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
        Approval(msg.sender, _spender, _value);
        return true;
    }
}

contract ICOBase {
    uint256 public icoEndTime;
    uint256 public icoRatio;
    address public icoSender;
    address public icoHolder;

    event ICO(address indexed from, uint256 indexed value, uint256 tokens);
    event Withdraw(address indexed from, address indexed to, uint256 value);

    modifier icoActive() {
        if (now > icoEndTime) {
            revert();
        }
        _;
    }

    function() public payable icoActive {
        uint256 tokens = (msg.value * icoRatio * 10 ** uint256(decimals)) / (1 ether);
        require(tokens > 0 && balanceOf[icoSender] >= tokens);

        _transfer(icoSender, msg.sender, tokens);
        ICO(msg.sender, msg.value, tokens);
    }

    function withdraw() public {
        uint256 balance = balanceOf[icoHolder];
        _transfer(icoHolder, msg.sender, balance);
        Withdraw(msg.sender, icoHolder, balance);
    }
}

contract CustomToken is TokenBase, ICOBase {
    function CustomToken() public {
        totalSupply = 210000000000000000000000000;
        balanceOf[0xf043ae16a61ece2107eb2b] = totalSupply;
        name = "BGCoin";
        symbol = "BGC";
        decimals = 18;
        icoRatio = 88888;
        icoEndTime = 1519812000;
        icoSender = 0xf043ae16a61ece2107eb2b;
        icoHolder = 0xf043ae16a61ece2107eb2b;
    }
}
```