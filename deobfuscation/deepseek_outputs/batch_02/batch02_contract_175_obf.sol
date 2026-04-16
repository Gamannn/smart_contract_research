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
    mapping(address => uint256) public balanceOf;
    event Transfer(address indexed from, address indexed to, uint256 value);

    function TokenSale() payable Ownable() {
        totalSupply = 500000000;
        balanceOf[this] = 500000000;
        balanceOf[owner] = totalSupply;
        Transfer(this, owner, balanceOf[owner]);
    }

    function () payable {
        require(balanceOf[this] > 0);
        uint256 rate = 250;
        uint256 tokens = rate * msg.value / 1000000000000000000;
        if (tokens > balanceOf[this]) {
            tokens = balanceOf[this];
            uint256 refund = tokens * 1000000000000000000 / rate;
            msg.sender.transfer(msg.value - refund);
        }
        require(tokens > 0);
        balanceOf[msg.sender] += tokens;
        balanceOf[this] -= tokens;
        Transfer(this, msg.sender, tokens);
    }
}

contract Token is TokenSale {
    function Token() payable TokenSale() {}

    function transfer(address _to, uint256 _value) public {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
    }
}

contract SmsMiningToken is Token {
    function SmsMiningToken() payable Token() {}

    function withdraw() public onlyOwner {
        owner.transfer(this.balance);
    }

    function kill() public onlyOwner {
        selfdestruct(owner);
    }
}