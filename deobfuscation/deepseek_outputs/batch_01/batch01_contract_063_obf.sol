pragma solidity ^0.4.24;

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

contract Ownable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    address public owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract ERC20Interface {
    function balanceOf(address tokenOwner) public view returns (uint256);
    function transfer(address to, uint256 tokens) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    
    function allowance(address tokenOwner, address spender) public view returns (uint256);
    function approve(address spender, uint256 tokens) public returns (bool);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract TokenRecipient {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

contract ERC20Token is Ownable, ERC20Interface {
    using SafeMath for uint256;
    
    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    
    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }
    
    function internalTransfer(address from, address to, uint256 tokens) internal returns (bool) {
        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    
    function transfer(address to, uint256 tokens) public returns (bool) {
        return internalTransfer(msg.sender, to, tokens);
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint256) {
        return allowed[tokenOwner][spender];
    }
    
    function approve(address spender, uint256 tokens) public returns (bool) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 tokens) public returns (bool) {
        require(msg.sender != from);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        return internalTransfer(from, to, tokens);
    }
    
    event Burn(address indexed burner, uint256 value);
    
    function burnFrom(address from, uint tokens) public returns (bool) {
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[from] = balances[from].sub(tokens);
        totalSupply = totalSupply.sub(tokens);
        emit Burn(from, tokens);
        return true;
    }
    
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        TokenRecipient(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
}

contract CowToken is ERC20Token {
    using SafeMath for uint256;
    
    uint256 public constant PRECISION = 821091;
    uint256 public constant MULTIPLIER = 1642182;
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    address public beefAddress = 0xbeef;
    
    constructor(uint256 initialSupply) public payable {
        totalSupply = initialSupply;
        balances[beefAddress] = initialSupply;
        name = "CowToken";
        symbol = "COW";
        decimals = 18;
    }
    
    function() public payable {}
    
    event Award(address indexed recipient, uint256 amount);
    
    function mint(address recipient, uint256 amount) public onlyOwner {
        balances[recipient] = balances[recipient].add(amount);
        balances[beefAddress] = balances[beefAddress].add(amount.div(10));
        totalSupply = totalSupply.add(amount.mul(11).div(10));
        emit Award(recipient, amount);
    }
    
    function sell(uint256 amount) public {
        uint256 etherAmount = calculateEtherValue(amount);
        internalTransfer(msg.sender, beefAddress, amount);
        etherAmount = etherAmount.sub(etherAmount.div(40));
        msg.sender.transfer(etherAmount);
    }
    
    function buy() public payable {
        uint256 tokenAmount = calculateTokenValue(msg.value, address(this).balance.sub(msg.value));
        tokenAmount = tokenAmount.sub(tokenAmount.div(40));
        internalTransfer(beefAddress, msg.sender, tokenAmount);
    }
    
    function calculateOutputAmount(uint256 inputReserve, uint256 outputReserve, uint256 inputAmount) public pure returns (uint256) {
        return MULTIPLIER.mul(inputAmount).div(PRECISION.add(MULTIPLIER.mul(inputReserve).div(inputAmount).add(outputReserve)));
    }
    
    function calculateEtherValue(uint256 tokenAmount) public view returns (uint256) {
        return calculateOutputAmount(tokenAmount, balances[beefAddress], address(this).balance);
    }
    
    function calculateTokenValue(uint256 etherAmount, uint256 contractBalance) public view returns (uint256) {
        return calculateOutputAmount(etherAmount, contractBalance, balances[beefAddress]);
    }
    
    function getBuyPrice(uint256 etherAmount) public view returns (uint256) {
        return calculateTokenValue(etherAmount, address(this).balance);
    }
    
    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function beefBalance() public view returns (uint256) {
        return balances[beefAddress];
    }
    
    function rescueTokens(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}