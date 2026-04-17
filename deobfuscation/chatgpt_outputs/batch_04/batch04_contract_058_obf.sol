```solidity
pragma solidity ^0.4.18;

contract ERC20Interface {
    function balanceOf(address tokenOwner) public constant returns (uint256 balance);
    function transfer(address to, uint256 tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
}

contract ERC20ExtendedInterface is ERC20Interface {
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

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

contract EBEHealthChain is ERC20ExtendedInterface, Ownable {
    using SafeMath for uint256;

    string public constant name = "EBE Health Chain";
    string public symbol = "EBE";
    uint256 public constant decimals = 18;
    uint256 public constant totalSupply = 2800000000 * 10**decimals;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    event GetETH(address indexed from, uint256 value);

    function EBEHealthChain() public {
        balances[msg.sender] = totalSupply;
        Transfer(0x0, msg.sender, totalSupply);
    }

    function() external payable {
        GetETH(msg.sender, msg.value);
    }

    function withdrawEther() external onlyOwner {
        if (!msg.sender.send(this.balance)) revert();
    }

    function transfer(address to, uint256 tokens) public returns (bool success) {
        require(to != address(0));
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }

    function balanceOf(address tokenOwner) public constant returns (uint256 balance) {
        return balances[tokenOwner];
    }

    function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
        require(to != address(0));
        uint256 allowance = allowed[from][msg.sender];
        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        allowed[from][msg.sender] = allowance.sub(tokens);
        Transfer(from, to, tokens);
        return true;
    }

    function approve(address spender, uint256 tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }
}
```