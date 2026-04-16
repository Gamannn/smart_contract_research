pragma solidity ^0.4.23;

contract TokenContract {
    address public owner = 0x0427D9929f82F8D83CFC2381050eD24D22ab0278;
    string public name = "Suter";
    uint8 public decimals = 18;
    uint256 public totalSupply = 10000000000 * (10 ** uint256(decimals));

    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balances[msg.sender]);

        balances[msg.sender] = safeSub(balances[msg.sender], value);
        balances[to] = safeAdd(balances[to], value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balances[from]);
        require(value <= allowances[from][msg.sender]);

        balances[from] = safeSub(balances[from], value);
        balances[to] = safeAdd(balances[to], value);
        allowances[from][msg.sender] = safeSub(allowances[from][msg.sender], value);
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        allowances[msg.sender][spender] = safeAdd(allowances[msg.sender][spender], addedValue);
        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = allowances[msg.sender][spender];
        if (subtractedValue > currentAllowance) {
            allowances[msg.sender][spender] = 0;
        } else {
            allowances[msg.sender][spender] = safeSub(currentAllowance, subtractedValue);
        }
        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
        return true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner returns (bool) {
        require(newOwner != address(0));
        owner = newOwner;
        return true;
    }

    function withdraw() public onlyOwner {
        require(address(this).balance > 0);
        owner.transfer(address(this).balance);
    }

    function() external payable {}

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}