pragma solidity ^0.4.24;

contract TCOM_Dividend {
    string public name = "TCOM Dividend";
    string public symbol = "TCOMD";
    uint8 public decimals = 10;
    uint256 public totalSupply = 10000 * (uint256(10) ** decimals);
    
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public dividendCreditedPerToken;
    mapping(address => uint256) public lastDividendCheckpoint;
    mapping(address => mapping(address => uint256)) public allowance;
    
    uint256 public dividendPerToken;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor() public {
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    function updateDividend(address account) internal {
        uint256 dividendDelta = dividendPerToken - dividendCreditedPerToken[account];
        dividendCreditedPerToken[account] += balanceOf[account] * dividendDelta;
        lastDividendCheckpoint[account] = dividendPerToken;
    }
    
    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);
        updateDividend(msg.sender);
        updateDividend(to);
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        updateDividend(from);
        updateDividend(to);
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function withdrawDividend() public {
        updateDividend(msg.sender);
        uint256 amount = dividendCreditedPerToken[msg.sender];
        dividendCreditedPerToken[msg.sender] = 0;
        msg.sender.transfer(amount);
    }
    
    function approve(address spender, uint256 value) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function () public payable {
        dividendPerToken += msg.value / totalSupply;
    }
}