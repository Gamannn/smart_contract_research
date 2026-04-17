```solidity
pragma solidity ^0.4.18;

contract Ownable {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function Ownable() public {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract TokenRecipient {
    function receiveApproval(address from, uint256 value, address token, bytes extraData) public;
}

contract ERC20 {
    uint256 public totalSupply;

    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public constant returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract DSBCoin is ERC20, Ownable {
    string public constant name = "dasabi.io DSBC";
    string public constant symbol = "DSBC";
    uint8 public constant decimals = 18;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    mapping (address => bool) public blacklist;

    address public multisigAddress;
    uint256 public exchangeRate;
    uint256 public totalRemainSupply;
    uint256 public candyDropSupply;
    bool public crowdsaleIsOpen;
    bool public candyDropIsOpen;

    event MintToken(address indexed to, uint256 value);
    event BurnToken(address indexed from, uint256 value);

    function DSBCoin() public {
        owner = msg.sender;
        exchangeRate = 1000000000 * 10**decimals;
        candyDropSupply = 50000 * 10**decimals;
        totalRemainSupply = candyDropSupply;
        crowdsaleIsOpen = true;
        candyDropIsOpen = true;
    }

    function setExchangeRate(uint256 newRate) public onlyOwner {
        exchangeRate = newRate;
    }

    function setCandyDropIsOpen(bool isOpen) public onlyOwner {
        candyDropIsOpen = isOpen;
    }

    function setCrowdsaleIsOpen(bool isOpen) public onlyOwner {
        crowdsaleIsOpen = isOpen;
    }

    function totalSupply() public constant returns (uint256) {
        return candyDropSupply - totalRemainSupply;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        require(balances[_to] + _value > balances[_to]);

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);
        require(balances[_to] + _value > balances[_to]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function setMultisigAddress(address _multisigAddress) public onlyOwner {
        require(_multisigAddress != 0x0);
        multisigAddress = _multisigAddress;
    }

    function mintToken(address _to, uint256 _amount) public onlyOwner {
        require(totalRemainSupply >= _amount);

        totalRemainSupply -= _amount;
        balances[_to] += _amount;
        MintToken(_to, _amount);
        Transfer(0x0, _to, _amount);
    }

    function burnToken(uint256 _amount) public onlyOwner {
        require(balances[msg.sender] >= _amount);

        totalRemainSupply += _amount;
        balances[msg.sender] -= _amount;
        BurnToken(msg.sender, _amount);
    }

    function () payable public {
        require(crowdsaleIsOpen);

        if (msg.value > 0) {
            uint256 tokens = msg.value * exchangeRate / 1 ether;
            mintToken(msg.sender, tokens);
        }

        if (candyDropIsOpen) {
            if (!blacklist[msg.sender]) {
                uint256 candyTokens = 50 * 10**decimals;
                mintToken(msg.sender, candyTokens);
                blacklist[msg.sender] = true;
            }
        }
    }
}
```