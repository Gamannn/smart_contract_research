```solidity
pragma solidity ^0.4.24;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BitronCoin is IERC20 {
    string public name = "Bitron Coin";
    string public symbol = "BTO";
    uint8 public decimals = 9;
    uint256 public totalSupply = 50000000 * 10 ** uint256(decimals);
    uint256 public oneEth = 10000;
    uint256 public tokens = 0;
    uint256 public icoEndDate = 1535673600;
    uint256 public minContribution = 0.02 ether;
    address public owner = address(0);
    address public ethFundMain = 0x1e6d1Fc2d934D2E4e2aE5e4882409C3fECD769dF;
    bool public stopped = false;
    
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor() public {
        owner = msg.sender;
        balances[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }
    
    function() public payable {
        require(msg.sender != owner);
        require(msg.value >= minContribution);
        require(now <= icoEndDate);
        require(stopped == false);
        
        tokens = (msg.value * oneEth) * 10 ** uint256(decimals);
        balances[msg.sender] += tokens;
        balances[owner] -= tokens;
        emit Transfer(owner, msg.sender, tokens);
        
        ethFundMain.transfer(msg.value);
    }
    
    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }
    
    function balanceOf(address who) public view returns (uint256) {
        return balances[who];
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(0));
        
        uint256 tokens = value * 10 ** uint256(decimals);
        
        require(balances[from] >= tokens);
        require(allowed[from][msg.sender] >= tokens);
        require(tokens >= 0);
        
        balances[from] -= tokens;
        allowed[from][msg.sender] -= tokens;
        balances[to] += tokens;
        
        emit Transfer(from, to, tokens);
        return true;
    }
    
    function transfer(address to, uint256 value) public returns (bool) {
        require(to != owner);
        
        uint256 tokens = value * 10 ** uint256(decimals);
        
        balances[to] = balances[to] + tokens;
        balances[owner] = balances[owner] - tokens;
        
        emit Transfer(owner, to, tokens);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool success) {
        require(spender != address(0));
        
        uint256 tokens = value * 10 ** uint256(decimals);
        allowed[msg.sender][spender] = tokens;
        
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint256) {
        require(tokenOwner != address(0) && spender != address(0));
        return allowed[tokenOwner][spender];
    }
    
    function withdrawEther() external onlyOwner {
        ethFundMain.transfer(address(this).balance);
    }
    
    function stopICO() external onlyOwner {
        stopped = true;
    }
    
    function startICO() external onlyOwner {
        stopped = false;
    }
}
```