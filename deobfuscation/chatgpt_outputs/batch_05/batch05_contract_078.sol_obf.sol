```solidity
pragma solidity ^0.4.18;

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

library ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

library TokenReceiver {
    function tokenFallback(address from, uint256 value, address token, bytes data) public;
}

contract Owned {
    address public owner;

    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract Crowdsale is Owned {
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    event Transfer(address indexed from, address indexed to, uint256 value);

    function Crowdsale() payable Owned() public {
        totalSupply = 10000000000 * 1 ether;
        balanceOf[owner] = totalSupply - balanceOf[this];
        Transfer(this, owner, totalSupply);
    }

    function () payable public {
        require(balanceOf[this] > 0);
        uint256 tokensPerEther = 21222 * 1 ether;
        uint256 tokens = tokensPerEther * msg.value / 1 ether;
        if (tokens > balanceOf[this]) {
            tokens = balanceOf[this];
            uint refund = tokens * 1 ether / tokensPerEther;
            msg.sender.transfer(msg.value - refund);
        }
        require(tokens > 0);
        balanceOf[msg.sender] += tokens;
        balanceOf[this] -= tokens;
        Transfer(this, msg.sender, tokens);
    }
}

contract Token is Crowdsale {
    using SafeMath for uint256;
    string public name = 'Token';
    string public symbol = 'TKN';
    string public standard = 'Token 1.0';
    uint8 public decimals = 18;
    mapping(address => mapping(address => uint256)) internal allowed;

    function Token() payable Crowdsale() public {}

    function transfer(address to, uint256 value) public {
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        Transfer(msg.sender, to, value);
    }
}

contract FinalizableToken is Token {
    function FinalizableToken() payable Token() {}

    function finalize() onlyOwner public {
        owner.transfer(this.balance);
    }

    function destroy() onlyOwner public {
        selfdestruct(owner);
    }
}
```