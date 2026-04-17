```solidity
pragma solidity ^0.4.11;

contract TokenInterface {
    function totalSupply() constant returns (uint256);
    function balanceOf(address owner) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    function transferFrom(address from, address to, uint256 value) returns (bool);
    function approve(address spender, uint256 value) returns (bool);
    function allowance(address owner, address spender) constant returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.4.11;

library SafeMath {
    function mul(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
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
}

contract Token is TokenInterface {
    using SafeMath for uint256;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    uint public totalSupply;
    uint public maxSupply;
    bool public isActive;
    uint8 public decimals = 18;
    address public owner;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    function Token() {
        owner = msg.sender;
        isActive = true;
    }

    function deactivate() onlyOwner {
        isActive = false;
    }

    function setOwner(address newOwner) onlyOwner {
        owner = newOwner;
    }

    function() payable {
        if (msg.sender != owner) {
            refund();
        }
    }

    function refund() payable {
        require(msg.value > 0);
        if (!isActive) revert();
        uint256 tokens = msg.value.mul(decimals);
        if (totalSupply.add(tokens) > maxSupply) {
            uint256 refundAmount = totalSupply.add(tokens).sub(maxSupply);
            balances[msg.sender] = balances[msg.sender].add(maxSupply.sub(totalSupply));
            totalSupply = maxSupply;
            msg.sender.transfer(msg.value.sub(refundAmount.div(decimals)));
        } else {
            totalSupply = totalSupply.add(tokens);
            balances[msg.sender] = balances[msg.sender].add(tokens);
        }
    }

    function totalSupply() constant returns (uint256) {
        return totalSupply;
    }

    function balanceOf(address owner) constant returns (uint256) {
        return balances[owner];
    }

    function transfer(address to, uint256 value) returns (bool) {
        require(balances[msg.sender] >= value && value > 0);
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) returns (bool) {
        require(allowed[from][msg.sender] >= value && balances[from] >= value && value > 0);
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) returns (bool) {
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) constant returns (uint256) {
        return allowed[owner][spender];
    }
}
```