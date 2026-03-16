pragma solidity ^0.4.18;

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

contract ERC20Interface {
    function balanceOf(address tokenOwner) public view returns (uint256 balance);
    function transfer(address to, uint256 tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
}

contract BasicToken is ERC20Interface {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    function transfer(address to, uint256 tokens) public returns (bool success) {
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
    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) internal allowed;

    function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
        require(to != address(0));
        require(tokens <= balances[from]);
        require(tokens <= allowed[from][msg.sender]);

        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        Transfer(from, to, tokens);
        return true;
    }

    function approve(address spender, uint256 tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining) {
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

contract Token is StandardToken {
    using SafeMath for *;

    event Deposit(address indexed account, uint amount, uint tokens);
    event Withdrawal(address indexed account, uint amount, uint tokens);

    string constant public name = "Token";
    string constant public symbol = "HODL";

    function calculateTokens(uint amount) public view returns(uint) {
        return amount.mul(this.balanceOf).div(scalar2VectorInstance.rate);
    }

    function deposit() public payable {
        uint tokens;
        if(scalar2VectorInstance.rate > 0) {
            tokens = scalar2VectorInstance.rate.mul(msg.value).div(this.balanceOf - msg.value);
            tokens -= tokens.mul(scalar2VectorInstance.fee).div(100);
        } else {
            tokens = msg.value.mul(scalar2VectorInstance.baseRate);
        }
        scalar2VectorInstance.rate = scalar2VectorInstance.rate.add(tokens);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        Deposit(msg.sender, msg.value, tokens);
    }

    function() public payable {
        deposit();
    }

    function withdraw(uint amount) public {
        var tokens = calculateTokens(amount);
        scalar2VectorInstance.rate = scalar2VectorInstance.rate.sub(amount);
        balances[msg.sender] = balances[msg.sender].sub(amount);
        msg.sender.transfer(tokens);
        Withdrawal(msg.sender, tokens, amount);
    }

    struct Scalar2Vector {
        uint8 baseRate;
        uint8 fee;
        uint8 decimals;
        uint256 rate;
    }

    Scalar2Vector scalar2VectorInstance = Scalar2Vector(100, 2, 18, 0);
}