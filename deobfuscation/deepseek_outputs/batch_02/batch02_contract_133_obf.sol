```solidity
pragma solidity ^0.4.23;

contract Suterusu {
    address public admin_address = 0x0427D9929f82F8D83CFC2381050eD24D22ab0278;
    string public name = "Suter";
    string public symbol = "Suterusu";
    uint8 public decimals = 18;
    uint256 public totalSupply = 10000000000 * 10**18;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor() public {
        balanceOf[msg.sender] = totalSupply;
    }
    
    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balanceOf[msg.sender]);
        
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], value);
        balanceOf[to] = safeAdd(balanceOf[to], value);
        
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        
        balanceOf[from] = safeSub(balanceOf[from], value);
        balanceOf[to] = safeAdd(balanceOf[to], value);
        allowance[from][msg.sender] = safeSub(allowance[from][msg.sender], value);
        
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
    
    function increaseApproval(address spender, uint256 addedValue) public returns (bool) {
        allowance[msg.sender][spender] = safeAdd(allowance[msg.sender][spender], addedValue);
        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);
        return true;
    }
    
    function decreaseApproval(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 oldValue = allowance[msg.sender][spender];
        if (subtractedValue > oldValue) {
            allowance[msg.sender][spender] = 0;
        } else {
            allowance[msg.sender][spender] = safeSub(oldValue, subtractedValue);
        }
        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);
        return true;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin_address);
        _;
    }
    
    function changeAdmin(address new_admin_address) public onlyAdmin returns (bool) {
        require(new_admin_address != address(0));
        admin_address = new_admin_address;
        return true;
    }
    
    function withdraw() public onlyAdmin {
        require(address(this).balance > 0);
        admin_address.transfer(address(this).balance);
    }
    
    function() external payable {
    }
    
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}
```