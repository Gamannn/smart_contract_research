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

library TokenFallback {
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
    mapping(address => uint256) public balances;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function Crowdsale() payable public {
        totalSupply = 10000000000 * 1 ether;
        balances[owner] = totalSupply - balances[this];
        Transfer(this, owner, totalSupply);
    }

    function () payable public {
        require(balances[this] > 0);
        uint256 tokensPerEther = 100000 * 1 ether;
        uint256 tokens = tokensPerEther * msg.value / 1 ether;

        if (tokens > balances[this]) {
            tokens = balances[this];
            uint refund = tokens * 1 ether / tokensPerEther;
            msg.sender.transfer(msg.value - refund);
        }

        require(tokens > 0);
        balances[msg.sender] += tokens;
        balances[this] -= tokens;
        Transfer(this, msg.sender, tokens);
    }
}

contract Token is Crowdsale {
    using SafeMath for uint256;

    string public name = 'Token';
    string public symbol = 'TKN';

    function Token() payable Crowdsale() {}

    function withdraw() onlyOwner public {
        owner.transfer(this.balance);
    }

    function destroy() onlyOwner public {
        selfdestruct(owner);
    }
}