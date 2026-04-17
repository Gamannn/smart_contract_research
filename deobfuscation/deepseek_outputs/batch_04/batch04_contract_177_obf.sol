```solidity
pragma solidity ^0.4.23;

contract ERC20Interface {
    uint256 public totalSupply;
    
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract SafeMath {
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert((c >= a) && (c >= b));
        return c;
    }
    
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(a >= b);
        uint256 c = a - b;
        return c;
    }
    
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert((a == 0) || (c / a == b));
        return c;
    }
    
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
}

contract Token is ERC20Interface, SafeMath {
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }
    
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract Crowdsale is Token {
    string public constant name = "LIPS";
    string public constant symbol = "LIPS";
    uint256 public constant decimals = 0;
    string public constant version = "1.0";
    
    uint256 public tokenExchangeRate = 1000;
    uint256 public tokenCrowdsaleCap = 1000000;
    uint256 public crowdsaleSupply = 0;
    uint256 public fundingStartBlock;
    uint256 public fundingEndBlock;
    bool public isFinalized = false;
    address public ethFundDeposit;
    address public tokenFundDeposit;
    
    event CreateLIPS(address indexed _to, uint256 _value);
    
    function Crowdsale() public {
        fundingStartBlock = block.number;
        fundingEndBlock = block.number + 88888;
        totalSupply = tokenCrowdsaleCap;
        balances[tokenFundDeposit] = tokenCrowdsaleCap;
        ethFundDeposit = 0x94EE3D36a7547dcb3Ff765901D81453cf1Ba67dC;
        tokenFundDeposit = msg.sender;
        emit CreateLIPS(tokenFundDeposit, tokenCrowdsaleCap);
    }
    
    function() public payable {
        createTokens();
    }
    
    function createTokens() internal {
        require(!isFinalized);
        require(block.number >= fundingStartBlock);
        require(block.number < fundingEndBlock);
        require(msg.value > 0);
        
        uint256 tokens = safeMul(msg.value, tokenExchangeRate);
        crowdsaleSupply = safeAdd(crowdsaleSupply, tokens);
        
        require(tokenCrowdsaleCap >= crowdsaleSupply);
        
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
        balances[tokenFundDeposit] = safeSub(balances[tokenFundDeposit], tokens);
        
        emit CreateLIPS(msg.sender, tokens);
    }
    
    function updateParams(
        uint256 newExchangeRate,
        uint256 newCrowdsaleCap,
        uint256 newStartBlock,
        uint256 newEndBlock
    ) external {
        assert(block.number < fundingStartBlock);
        assert(!isFinalized);
        
        tokenExchangeRate = newExchangeRate;
        tokenCrowdsaleCap = newCrowdsaleCap;
        fundingStartBlock = newStartBlock;
        fundingEndBlock = newEndBlock;
    }
    
    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function finalize(uint256 minAmount) internal {
        assert(!isFinalized);
        isFinalized = true;
        require(address(this).balance > minAmount);
        ethFundDeposit.transfer(minAmount);
    }
}
```