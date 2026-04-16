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

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

contract CryptopusToken is ERC20Interface, Owned {
    using SafeMath for uint;
    
    address public preSaleContract;
    string public symbol;
    string public name;
    uint8 public decimals;
    uint public _totalSupply;
    uint public saleLimit;
    uint public alreadySold;
    uint public firstWavePrice;
    uint public secondWavePrice;
    uint public thirdWavePrice;
    bool public saleOngoing;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => uint8) approved;
    
    constructor() public {
        symbol = "CPP";
        name = "Cryptopus Token";
        decimals = 18;
        _totalSupply = 100000000 * 10**uint(decimals);
        saleLimit = 40000000 * 10**uint(decimals);
        alreadySold = 0;
        balances[owner] = _totalSupply;
        Transfer(address(0), owner, _totalSupply);
        
        firstWavePrice = 0.0005 ether;
        secondWavePrice = 0.0009 ether;
        thirdWavePrice = 0.001 ether;
        saleOngoing = false;
    }
    
    modifier onlyIfSaleOngoing {
        require(saleOngoing);
        _;
    }
    
    modifier onlyApproved {
        require(approved[msg.sender] != 0);
        _;
    }
    
    function setPrices(uint _firstWavePrice, uint _secondWavePrice, uint _thirdWavePrice) public onlyOwner returns (bool) {
        firstWavePrice = _firstWavePrice;
        secondWavePrice = _secondWavePrice;
        thirdWavePrice = _thirdWavePrice;
        return true;
    }
    
    function setPreSaleContract(address _preSaleContract) public onlyOwner returns (bool) {
        preSaleContract = _preSaleContract;
        return true;
    }
    
    function toggleSale() public onlyOwner returns (bool) {
        saleOngoing = !saleOngoing;
        return true;
    }
    
    function setApproved(address _address, uint8 _level) public onlyOwner returns (bool) {
        approved[_address] = _level;
        return true;
    }
    
    function totalSupply() public constant returns (uint) {
        return _totalSupply - balances[address(0)];
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
    
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
    
    function burn(uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[address(0)] = balances[address(0)].add(tokens);
        Transfer(msg.sender, address(0), tokens);
        return true;
    }
    
    function claimTokens() public returns (bool success) {
        uint tokens = ERC20Interface(preSaleContract).allowance(msg.sender, this);
        require(tokens > 0 && ERC20Interface(preSaleContract).balanceOf(msg.sender) == tokens);
        ERC20Interface(preSaleContract).transferFrom(msg.sender, address(0), tokens);
        balances[owner] = balances[owner].sub(tokens);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        Transfer(owner, msg.sender, tokens);
        return true;
    }
    
    function() public payable onlyIfSaleOngoing onlyApproved {
        uint tokenPrice;
        if(approved[msg.sender] == 1) {
            tokenPrice = firstWavePrice;
        } else if(approved[msg.sender] == 2) {
            tokenPrice = secondWavePrice;
        } else if(approved[msg.sender] == 3) {
            tokenPrice = thirdWavePrice;
        } else {
            revert();
        }
        
        require(msg.value >= tokenPrice);
        uint tokenAmount = msg.value / tokenPrice;
        require(saleOngoing && alreadySold.add(tokenAmount) <= saleLimit);
        
        balances[owner] = balances[owner].sub(tokenAmount);
        balances[msg.sender] = balances[msg.sender].add(tokenAmount);
        alreadySold = alreadySold.add(tokenAmount);
        Transfer(owner, msg.sender, tokenAmount);
    }
}
```