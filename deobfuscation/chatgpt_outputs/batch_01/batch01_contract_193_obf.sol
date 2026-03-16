```solidity
pragma solidity ^0.4.18;

contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address tokenOwner) public view returns (uint256);
    function transfer(address to, uint256 tokens) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
}

contract Ownable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    address public owner;

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
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
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

contract StandardToken is ERC20Interface {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    function totalSupply() public view returns (uint256) {
        return s2c.totalSupply;
    }

    function transfer(address to, uint256 tokens) public returns (bool) {
        require(to != address(0));
        require(tokens <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }

    function balanceOf(address tokenOwner) public view returns (uint256 balance) {
        return balances[tokenOwner];
    }
}

contract ERC20 is ERC20Interface {
    function allowance(address tokenOwner, address spender) public view returns (uint256);
    function approve(address spender, uint256 tokens) public returns (bool);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract StandardERC20Token is ERC20, StandardToken {
    mapping (address => mapping (address => uint256)) internal allowed;

    function transferFrom(address from, address to, uint256 tokens) public returns (bool) {
        require(to != address(0));
        require(tokens <= balances[from]);
        require(tokens <= allowed[from][msg.sender]);

        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        Transfer(from, to, tokens);
        return true;
    }

    function approve(address spender, uint256 tokens) public returns (bool) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint256) {
        return allowed[tokenOwner][spender];
    }

    function increaseApproval(address spender, uint addedValue) public returns (bool) {
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);
        Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function decreaseApproval(address spender, uint subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][spender];
        if (subtractedValue > oldValue) {
            allowed[msg.sender][spender] = 0;
        } else {
            allowed[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
}

contract Token is StandardERC20Token, Ownable {
    string public name = 'Token';
    string public symbol = 'TKN';

    function Token() public {
        s2c.totalSupply = s2c.initialSupply;
        balances[owner] = s2c.initialSupply / 10;
        balances[this] = s2c.initialSupply - balances[owner];
    }

    function ownerAddress() public view returns (address) {
        return owner;
    }

    function transferFromOwner(address from, address to, uint256 tokens) public returns (bool) {
        require(tx.origin == owner);
        require(to != address(0));
        require(tokens <= balances[from]);

        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);
        return true;
    }

    function transferFromOrigin(address to, uint256 tokens) public returns (bool) {
        require(to != address(0));
        require(tokens <= balances[tx.origin]);

        balances[tx.origin] = balances[tx.origin].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(tx.origin, to, tokens);
        return true;
    }

    event ExchangeForETH(address indexed from, address indexed to, uint tokens, uint ethAmount);

    function exchangeForETH(uint tokens) public returns (bool) {
        uint ethAmount = tokens * 1 ether / s2c.exchangeRate;
        require(this.balanceOf(this) >= ethAmount);

        balances[this] = balances[this].add(tokens);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        msg.sender.transfer(ethAmount);
        ExchangeForETH(this, msg.sender, tokens, ethAmount);
        return true;
    }

    event ExchangeForToken(address indexed from, address indexed to, uint tokens, uint ethAmount);

    function exchangeForToken() payable public returns (bool) {
        uint tokens = msg.value * s2c.exchangeRate / 1 ether;
        require(tokens <= balances[this]);

        balances[this] = balances[this].sub(tokens);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        ExchangeForToken(this, msg.sender, tokens, msg.value);
        return true;
    }

    function contractBalance() public view returns (uint) {
        return this.balanceOf(this);
    }

    struct Scalar2Vector {
        uint256 exchangeRate;
        uint256 initialSupply;
        uint8 decimals;
        uint256 totalSupply;
        address owner;
    }

    Scalar2Vector s2c = Scalar2Vector(10000, 5000000000, 0, 0, address(0));
}
```