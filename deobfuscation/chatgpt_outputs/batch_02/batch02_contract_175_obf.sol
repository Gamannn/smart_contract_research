pragma solidity ^0.4.13;

contract Ownable {
    address public owner;
    address public newOwner;

    function Ownable() payable {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    function transferOwnership(address _newOwner) onlyOwner public {
        require(_newOwner != 0);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(newOwner == msg.sender);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract TokenSale is Ownable {
    uint256 public totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);

    function TokenSale() payable Ownable() {
        totalSupply = 500000000;
        balances[owner] = totalSupply;
        Transfer(this, owner, balances[owner]);
    }

    mapping(address => uint256) public balances;

    function () payable {
        require(balances[this] > 0);
        uint256 tokensPerEther = 250;
        uint256 tokens = tokensPerEther * msg.value / 1 ether;
        if (tokens > balances[this]) {
            tokens = balances[this];
        }
        uint256 etherUsed = tokens * 1 ether / tokensPerEther;
        msg.sender.transfer(msg.value - etherUsed);
        require(tokens > 0);
        balances[msg.sender] += tokens;
        balances[this] -= tokens;
        Transfer(this, msg.sender, tokens);
    }
}

contract Token is TokenSale {
    function Token() payable TokenSale() {}

    function transfer(address _to, uint256 _value) public {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
    }
}

contract Finalize is Token {
    function Finalize() payable Token() {}

    function finalize() public onlyOwner {
        owner.transfer(this.balance);
    }

    function destroy() public onlyOwner {
        selfdestruct(owner);
    }
}

function getIntFunc(uint256 index) internal view returns(uint256) {
    return _integer_constant[index];
}

function getStrFunc(uint256 index) internal view returns(string storage) {
    return _string_constant[index];
}

uint256[] public _integer_constant = [500000000, 0, 1000000000000000000, 250];
string[] public _string_constant = ["Sms Mining Ethereum", "SmsMiningToken", "SMT"];