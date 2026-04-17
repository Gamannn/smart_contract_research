```solidity
pragma solidity ^0.4.23;

contract ERC20Token {
    address public owner;
    address public feeAddress;
    
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    
    string public name = "chuangjiu";
    string public symbol = "CJ";
    uint8 public decimals = 18;
    
    uint256 private totalSupply_;
    uint256 private maxSupply;
    
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );
    
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    
    event Burn(address indexed burner, uint256 value);
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    
    bool public transfersEnabled = true;
    uint256 public directDropRate = 1000;
    address public directDropAddress = 0x587b13913F4c708A4F033318056E4b6BA956A6F5;
    address public withdrawAddress = 0x587b13913F4c708A4F033318056E4b6BA956A6F5;
    
    bool public directDropEnabled = false;
    uint256 public directDropRangeStart;
    uint256 public directDropRangeEnd;
    
    constructor() public {
        owner = msg.sender;
        maxSupply = 100000000 * (10 ** uint256(decimals));
        totalSupply_ = maxSupply;
        balances[owner] = totalSupply_;
        emit Transfer(address(0), owner, totalSupply_);
    }
    
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
    
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(transfersEnabled);
        
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowances[_from][msg.sender]);
        require(transfersEnabled);
        
        balances[_from] = safeSub(balances[_from], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        allowances[_from][msg.sender] = safeSub(allowances[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }
    
    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
        allowances[msg.sender][_spender] = safeAdd(allowances[msg.sender][_spender], _addedValue);
        emit Approval(msg.sender, _spender, allowances[msg.sender][_spender]);
        return true;
    }
    
    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
        uint256 oldValue = allowances[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowances[msg.sender][_spender] = 0;
        } else {
            allowances[msg.sender][_spender] = safeSub(oldValue, _subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowances[msg.sender][_spender]);
        return true;
    }
    
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        totalSupply_ = safeSub(totalSupply_, _value);
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
    }
    
    function burnFrom(address _from, uint256 _value) public {
        require(_value <= balances[_from]);
        require(_value <= allowances[_from][msg.sender]);
        
        balances[_from] = safeSub(balances[_from], _value);
        allowances[_from][msg.sender] = safeSub(allowances[_from][msg.sender], _value);
        totalSupply_ = safeSub(totalSupply_, _value);
        emit Burn(_from, _value);
        emit Transfer(_from, address(0), _value);
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
    
    function enableTransfers(bool _enabled) public onlyOwner returns (bool) {
        transfersEnabled = _enabled;
        return true;
    }
    
    function withdraw() public {
        require(address(this).balance > 0);
        withdrawAddress.transfer(address(this).balance);
    }
    
    function buyTokens(address _beneficiary) public payable {
        require(directDropEnabled);
        require(now >= directDropRangeStart && now <= directDropRangeEnd);
        require(msg.value > 0);
        
        uint256 tokenAmount = safeMul(msg.value, directDropRate);
        tokenAmount = safeMul(tokenAmount, 10 ** uint256(decimals));
        tokenAmount = safeDiv(tokenAmount, 1 ether);
        
        require(balances[directDropAddress] >= tokenAmount);
        
        uint256 oldBalanceSum = safeAdd(balances[directDropAddress], balances[_beneficiary]);
        balances[directDropAddress] = safeSub(balances[directDropAddress], tokenAmount);
        balances[_beneficiary] = safeAdd(balances[_beneficiary], tokenAmount);
        
        assert(oldBalanceSum == safeAdd(balances[directDropAddress], balances[_beneficiary]));
        
        emit TokenPurchase(msg.sender, _beneficiary, msg.value, tokenAmount);
    }
    
    function() external payable {
        buyTokens(msg.sender);
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
    
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
```