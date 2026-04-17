```solidity
pragma solidity ^0.4.24;

contract Token {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);
    
    constructor() public {
        name = "Yellow Better";
        symbol = "YBT";
        decimals = 18;
        totalSupply = 2000000000000000000000000000;
        balanceOf[msg.sender] = totalSupply;
    }
    
    function safeSub(uint256 a, uint256 b) private pure returns (uint256) {
        require(a >= b);
        return a - b;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return balanceOf[account];
    }
    
    function transfer(address to, uint256 value) public returns (bool) {
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], value);
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        balanceOf[from] = safeSub(balanceOf[from], value);
        allowance[from][msg.sender] = safeSub(allowance[from][msg.sender], value);
        balanceOf[to] += value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowance[owner][spender];
    }
    
    function burn(uint256 value) public {
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], value);
        totalSupply -= value;
        emit Burn(msg.sender, value);
    }
}

contract Crowdsale {
    address public creator;
    address public beneficiary;
    uint256 public deadline;
    uint256 public tokenPrice;
    Token public tokenContract;
    
    constructor(address tokenAddress) public {
        creator = msg.sender;
        beneficiary = msg.sender;
        tokenContract = Token(tokenAddress);
    }
    
    function setPrice(uint256 price) public {
        require(msg.sender == creator);
        tokenPrice = price;
    }
    
    function setDeadline(uint256 timestamp) public {
        require(msg.sender == creator);
        deadline = timestamp;
    }
    
    function buyTokens(address beneficiary) public payable {
        require(block.timestamp < deadline && tokenPrice > 0);
        require(tokenContract.transfer(beneficiary, 1000000000000000000 * msg.value / tokenPrice));
    }
    
    function withdraw() public {
        require(msg.sender == creator);
        creator.transfer(address(this).balance);
    }
}
```