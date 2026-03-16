pragma solidity ^0.4.13;

contract Owned {
    address public owner;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract TokenERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transfer(address to, uint256 value) returns (bool success);
    function transferFrom(address from, address to, uint256 value) returns (bool success);
    function approve(address spender, uint256 value) returns (bool success);
    function allowance(address owner, address spender) constant returns (uint256 remaining);
    function balanceOf(address owner) constant returns (uint256 balance);
}

contract TokenNotifier {
    function receiveApproval(address from, uint256 amount, address token, bytes data);
}

contract ImmortalToken is Owned, SafeMath, TokenERC20 {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    string public constant name = "Immortal";
    string public constant symbol = "IMT";
    string public constant version = "1.0.1";

    function transfer(address to, uint256 value) returns (bool success) {
        if (balances[msg.sender] < value) {
            return false;
        }
        balances[msg.sender] = safeSub(balances[msg.sender], value);
        assert(balances[msg.sender] >= 0);
        balances[to] = safeAdd(balances[to], value);
        assert(balances[to] <= tokenData.totalSupply);
        Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) returns (bool success) {
        if (balances[from] < value || allowed[from][msg.sender] < value) {
            return false;
        }
        balances[from] = safeSub(balances[from], value);
        assert(balances[from] >= 0);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], value);
        balances[to] = safeAdd(balances[to], value);
        assert(balances[to] <= tokenData.totalSupply);
        Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) returns (bool success) {
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

    function approveAndCall(address spender, uint256 value, bytes extraData) returns (bool success) {
        if (!approve(spender, value)) {
            return false;
        }
        TokenNotifier(spender).receiveApproval(msg.sender, value, this, extraData);
        return true;
    }

    function balanceOf(address owner) constant returns (uint256 balance) {
        return balances[owner];
    }

    function allowance(address owner, address spender) constant returns (uint256 remaining) {
        return allowed[owner][spender];
    }
}

contract Immortals is ImmortalToken {
    event Assigned(address contributor, uint256 immortals);

    function () payable {
        require(tokenData.tokenAssigned < tokenData.totalSupply && msg.value >= 0.5 ether);
        uint256 immortals = msg.value / 0.5 ether;
        uint256 remainder = 0;
        if (safeAdd(tokenData.tokenAssigned, immortals) > tokenData.totalSupply) {
            immortals = tokenData.totalSupply - tokenData.tokenAssigned;
            remainder = msg.value - (immortals * 0.5 ether);
        } else {
            remainder = (msg.value % 0.5 ether);
        }
        require(safeAdd(tokenData.tokenAssigned, immortals) <= tokenData.totalSupply);
        balances[msg.sender] = safeAdd(balances[msg.sender], immortals);
        tokenData.tokenAssigned = safeAdd(tokenData.tokenAssigned, immortals);
        assert(balances[msg.sender] <= tokenData.totalSupply);
        msg.sender.transfer(remainder);
        Assigned(msg.sender, immortals);
    }

    function redeemEther(uint256 amount) onlyOwner external {
        owner.transfer(amount);
    }

    struct TokenData {
        uint256 tokenAssigned;
        uint8 totalSupply;
        uint8 decimals;
        address owner;
    }

    TokenData public tokenData = TokenData(0, 100, 0, address(0));
}