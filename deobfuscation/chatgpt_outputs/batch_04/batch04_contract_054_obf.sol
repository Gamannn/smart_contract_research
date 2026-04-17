```solidity
pragma solidity ^0.4.11;

library SafeMath {
    function mul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal returns (uint) {
        require(b > 0);
        uint c = a / b;
        require(a == b * c + a % b);
        return c;
    }

    function sub(uint a, uint b) internal returns (uint) {
        require(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        require(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
    }

    function assert(bool assertion) internal {
        if (!assertion) {
            revert();
        }
    }
}

contract ERC20 {
    function totalSupply() constant returns (uint supply);
    function balanceOf(address who) constant returns (uint value);
    function allowance(address owner, address spender) constant returns (uint remaining);
    function transfer(address to, uint value) returns (bool success);
    function transferFrom(address from, address to, uint value) returns (bool success);
    function approve(address spender, uint value) returns (bool success);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Token is ERC20 {
    using SafeMath for uint;

    uint public totalSupply = 16500000;
    string public name = "Token";
    string public symbol = "TKN";
    uint8 public decimals = 18;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    function totalSupply() constant returns (uint256) {
        return totalSupply;
    }

    function balanceOf(address owner) constant returns (uint256 balance) {
        return balances[owner];
    }

    function allowance(address owner, address spender) constant returns (uint256 remaining) {
        return allowed[owner][spender];
    }

    function transfer(address to, uint256 value) returns (bool success) {
        if (balances[msg.sender] >= value && value > 0) {
            balances[msg.sender] = balances[msg.sender].sub(value);
            balances[to] = balances[to].add(value);
            Transfer(msg.sender, to, value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address from, address to, uint256 value) returns (bool success) {
        if (balances[from] >= value && allowed[from][msg.sender] >= value && value > 0) {
            balances[to] = balances[to].add(value);
            balances[from] = balances[from].sub(value);
            allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
            Transfer(from, to, value);
            return true;
        } else {
            return false;
        }
    }

    function approve(address spender, uint256 value) returns (bool success) {
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }
}

contract MyToken is Token {
    address public owner;
    uint public constant initialSupply = 16500000;
    string public constant tokenName = "MyToken";
    string public constant tokenSymbol = "MTK";
    uint8 public constant tokenDecimals = 18;

    function MyToken() {
        owner = msg.sender;
        balances[owner] = initialSupply;
        totalSupply = initialSupply;
    }
}
```