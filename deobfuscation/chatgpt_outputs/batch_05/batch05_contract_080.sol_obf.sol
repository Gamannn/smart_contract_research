pragma solidity 0.4.25;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        assert(b <= a);
        return a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        if (a == 0) return 0;
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint c) {
        return a / b;
    }
}

contract ERC20Token {
    using SafeMath for uint;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    address public owner;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        require((tokens == 0) || (allowed[msg.sender][spender] == 0));
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function increaseApproval(address spender, uint addedValue) public returns (bool success) {
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function decreaseApproval(address spender, uint subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][spender];
        if (subtractedValue > oldValue) {
            allowed[msg.sender][spender] = 0;
        } else {
            allowed[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
}

contract ICO is ERC20Token {
    uint public fundsRaised;
    uint public tokensSold;
    uint public tokenPrice;
    address public wallet;
    uint public icoEndTime;
    enum IcoState { Active, Ended }
    IcoState public state;

    constructor() public {
        owner = msg.sender;
        name = "ExampleToken";
        symbol = "EXT";
        decimals = 18;
        totalSupply = 100500 ether;
        balances[owner] = totalSupply;
        tokenPrice = 1 ether;
        state = IcoState.Active;
    }

    function() public payable {
        require(state == IcoState.Active);
        require(now < icoEndTime);
        uint tokens = msg.value.div(tokenPrice);
        require(tokensSold.add(tokens) <= totalSupply.div(2));
        balances[msg.sender] = balances[msg.sender].add(tokens);
        tokensSold = tokensSold.add(tokens);
        fundsRaised = fundsRaised.add(msg.value);
        emit Transfer(owner, msg.sender, tokens);
    }

    function endIco() public onlyOwner {
        state = IcoState.Ended;
    }

    function withdrawFunds() public {
        require(msg.sender == wallet);
        wallet.transfer(fundsRaised);
        fundsRaised = 0;
    }
}