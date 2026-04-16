```solidity
pragma solidity ^0.4.19;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
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
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract CryptopusToken is ERC20Interface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public name;
    uint8 public decimals;
    uint public _totalSupply;
    uint public firstWavePrice;
    uint public secondWavePrice;
    uint public thirdWavePrice;
    bool public saleOngoing;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    function CryptopusToken() public {
        symbol = "CPP";
        name = "Cryptopus Token";
        decimals = 18;
        _totalSupply = 100000000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        firstWavePrice = 0.0008 ether;
        secondWavePrice = 0.0009 ether;
        thirdWavePrice = 0.001 ether;
        saleOngoing = false;
    }

    modifier onlyDuringSale() {
        require(saleOngoing);
        _;
    }

    function totalSupply() public constant returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }

    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function toggleSale() public onlyOwner returns (bool) {
        saleOngoing = !saleOngoing;
        return true;
    }

    function() public payable onlyDuringSale {
        uint tokens;
        if (msg.value >= firstWavePrice) {
            tokens = msg.value.div(firstWavePrice);
        } else if (msg.value >= secondWavePrice) {
            tokens = msg.value.div(secondWavePrice);
        } else {
            tokens = msg.value.div(thirdWavePrice);
        }
        require(tokens > 0);
        balances[owner] = balances[owner].sub(tokens);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        Transfer(owner, msg.sender, tokens);
    }
}
```