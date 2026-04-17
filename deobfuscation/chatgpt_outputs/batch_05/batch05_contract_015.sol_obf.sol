```solidity
pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract DN8Token is ERC20Interface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public name;
    uint8 public decimals;
    uint public _totalSupply;
    bool public crowdsaleEnabled;
    uint public ethPerToken;
    uint public bonusPct;
    uint public bonusMinEth;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    event Burn(address indexed burner, uint256 value);
    event Bonus(address indexed to, uint256 value);

    constructor() public {
        symbol = "DN8";
        name = "PLDGR.ORG";
        decimals = 18;
        _totalSupply = 450000000000000000000000000;
        crowdsaleEnabled = true;
        ethPerToken = 20000;
        bonusPct = 0;
        bonusMinEth = 0;
        owner = msg.sender;
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
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

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

    function () public payable {
        require(crowdsaleEnabled);
        uint ethValue = msg.value;
        uint tokens = ethValue.mul(ethPerToken);
        if (bonusPct > 0 && ethValue >= bonusMinEth) {
            uint bonusTokens = tokens.div(100).mul(bonusPct);
            emit Bonus(msg.sender, bonusTokens);
            tokens = tokens.add(bonusTokens);
        }
        balances[owner] = balances[owner].sub(tokens);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        emit Transfer(owner, msg.sender, tokens);
    }

    function endCrowdsale() public onlyOwner {
        crowdsaleEnabled = false;
    }

    function setTokenPrice(uint _ethPerToken) public onlyOwner {
        ethPerToken = _ethPerToken;
    }

    function setBonus(uint _bonusPct, uint _bonusMinEth) public onlyOwner {
        bonusPct = _bonusPct;
        bonusMinEth = _bonusMinEth;
    }

    function burn(uint256 value) public onlyOwner {
        require(value > 0);
        require(value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(value);
        _totalSupply = _totalSupply.sub(value);
        emit Burn(msg.sender, value);
    }

    function withdraw(uint amount) public onlyOwner {
        require(amount > 0);
        require(amount <= address(this).balance);
        owner.transfer(amount);
    }
}
```