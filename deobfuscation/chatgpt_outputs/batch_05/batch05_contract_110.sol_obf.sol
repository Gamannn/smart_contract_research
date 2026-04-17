```solidity
pragma solidity ^0.4.19;

contract Token {
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

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
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

contract AirdropToken is Token {
    mapping(address => uint32) public airdropCount;
    event Airdrop(address indexed to, uint32 indexed count, uint256 value);

    function airdrop() public payable {
        require(now >= getIntFunc(3) && now <= getIntFunc(0));
        require(msg.value == 0);

        if (getIntFunc(2) <= airdropCount[msg.sender]) {
            revert();
        }

        _transfer(getAddrFunc(1), msg.sender, getIntFunc(7));
        airdropCount[msg.sender] += 1;
        Airdrop(msg.sender, airdropCount[msg.sender], uint32(getIntFunc(8)));
    }
}

contract ICOContract is Token {
    event ICO(address indexed from, uint256 indexed value, uint256 tokens);
    event Withdraw(address indexed from, address indexed to, uint256 value);

    function participateICO() public payable {
        require(now >= getIntFunc(3) && now <= getIntFunc(0));
        require(msg.value > 0);

        uint256 tokenAmount = (msg.value * getIntFunc(4) * 10 ** uint256(decimals)) / (1 ether / 1 wei);
        if (tokenAmount == 0 || balanceOf[getAddrFunc(0)] < tokenAmount) {
            revert();
        }

        _transfer(getAddrFunc(0), msg.sender, tokenAmount);
        ICO(msg.sender, msg.value, tokenAmount);
    }

    function withdraw() public {
        uint256 balance = this.balance;
        getAddrFunc(0).transfer(balance);
        Withdraw(msg.sender, getAddrFunc(0), balance);
    }
}

contract GChainToken is Token, AirdropToken, ICOContract {
    function GChainToken() public {
        balanceOf[getAddrFunc(1)] = getIntFunc(5);
        name = getStrFunc(0);
        symbol = getStrFunc(1);
        decimals = 8;
        totalSupply = getIntFunc(5);
        _transfer(address(0), getAddrFunc(1), totalSupply);
    }

    struct Scalar2Vector {
        address icoWallet;
        address airdropWallet;
        uint256 icoStartTime;
        uint256 icoEndTime;
        uint256 icoRatio;
        uint32 airdropLimit;
        address owner;
        uint256 totalSupply;
        uint256 airdropAmount;
        uint256 airdropStartTime;
        uint256 airdropEndTime;
        uint8 decimals;
    }

    Scalar2Vector s2c = Scalar2Vector(
        getAddrFunc(0),
        getAddrFunc(1),
        getIntFunc(3),
        getIntFunc(0),
        getIntFunc(4),
        getIntFunc(2),
        getAddrFunc(1),
        getIntFunc(5),
        getIntFunc(7),
        getIntFunc(3),
        getIntFunc(0),
        8
    );

    function participate() public {
        if (msg.value == 0) {
            participateICO();
        }
    }
}

function getIntFunc(uint256 index) internal view returns (uint256) {
    return _integer_constant[index];
}

function getAddrFunc(uint256 index) internal view returns (address payable) {
    return _address_constant[index];
}

function getStrFunc(uint256 index) internal view returns (string storage) {
    return _string_constant[index];
}

uint256[] public _integer_constant = [1538265540, 1000000000000000000, 0, 1532736000, 10000000, 99000000000000000, 10, 8, 1, 100000000, 1532736300];
address payable[] public _address_constant = [0xA89d7a553Da4E313c7F77A1F7f16B9FACF538349, 0xa0f236796BE660F1ad18F56b0Da91516882aE049];
string[] public _string_constant = ["GChainToken", "GCHAIN"];
```