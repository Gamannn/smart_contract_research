```solidity
pragma solidity ^0.4.26;

contract DunatonMetacurrency30 {
    address public owner;
    uint256 public totalSupply;
    uint256 public incomingWei;
    uint256 public tokensPerWei;
    uint256 public tokensPerEth;
    
    mapping(address => uint256) public balanceOf;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    constructor() public {
        owner = msg.sender;
        totalSupply = 5800000 * 1 ether;
        balanceOf[owner] = totalSupply;
        Transfer(address(this), owner, totalSupply);
        tokensPerWei = 359;
        tokensPerEth = tokensPerWei * 1 ether;
    }
    
    function transfer(address to, uint256 value, bytes data) public {
        require(balanceOf[msg.sender] >= value);
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(to)
        }
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], value);
        balanceOf[to] = safeAdd(balanceOf[to], value);
        Transfer(msg.sender, to, value);
    }
    
    function transfer(address to, uint256 value) public {
        require(balanceOf[msg.sender] >= value);
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(to)
        }
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], value);
        balanceOf[to] = safeAdd(balanceOf[to], value);
        Transfer(msg.sender, to, value);
    }
    
    function() public payable {
        require(msg.value > 0);
        incomingWei = safeAdd(incomingWei, msg.value);
        uint256 tokens = safeMul(msg.value, tokensPerWei);
        require(tokens <= totalSupply);
        totalSupply = safeSub(totalSupply, tokens);
        balanceOf[msg.sender] = safeAdd(balanceOf[msg.sender], tokens);
        Transfer(address(this), msg.sender, tokens);
    }
    
    function changePayRate(uint256 newRate) public {
        require((msg.sender == owner) && (newRate >= 0));
        tokensPerWei = newRate;
        tokensPerEth = safeMul(newRate, 1 ether);
    }
    
    function withdrawEther(address recipient, uint256 weiAmount) public {
        require((msg.sender == owner));
        uint256 valueAsEth = safeDiv(weiAmount, 1 ether);
        require(valueAsEth <= incomingWei);
        recipient.transfer(valueAsEth);
    }
    
    function getBalance(address account) public constant returns (uint256) {
        return balanceOf[account];
    }
    
    function transferOwnership(address newOwner) public {
        require(msg.sender == owner);
        owner = newOwner;
    }
    
    function getTotalSupply() public constant returns (uint256) {
        return totalSupply;
    }
    
    function mint(uint256 amount) public {
        require(msg.sender == owner);
        totalSupply = safeAdd(totalSupply, amount);
    }
    
    function getWeiAmount() public constant returns (uint256) {
        return incomingWei;
    }
    
    function getIncomingWei() public constant returns (uint256) {
        return incomingWei;
    }
    
    function getTokensPerWei() public constant returns (uint256) {
        return tokensPerWei;
    }
    
    function getTokensPerEth() public constant returns (uint256) {
        return tokensPerEth;
    }
    
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }
    
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }
    
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}
```