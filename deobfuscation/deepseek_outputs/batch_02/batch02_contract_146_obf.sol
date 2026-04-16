```solidity
pragma solidity ^0.4.13;

contract Ownable {
    address public owner;
    address public operator;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyOperator() {
        require(msg.sender == operator);
        _;
    }
    
    modifier ownerOrOperator() {
        require(msg.sender == owner || msg.sender == operator);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
    
    function transferOperator(address newOperator) public onlyOwner {
        require(newOperator != address(0));
        operator = newOperator;
    }
    
    function withdrawTokens(address tokenAddress, uint256 amount) external ownerOrOperator {
        require(amount > 0);
        require(amount <= this.balance);
        require(tokenAddress != address(0));
        tokenAddress.transfer(amount);
    }
    
    function() external payable {}
}

contract Pausable is Ownable {
    bool public paused;
    
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    
    function pause() external ownerOrOperator whenNotPaused {
        paused = true;
    }
    
    function unpause() public onlyOwner {
        paused = false;
    }
}

contract TokenRecipient {
    function receiveApproval(address from, uint256 value, bytes data) public returns (bool);
}

contract ERC20Token {
    using SafeMath for uint256;
    
    string public constant name = "GoCryptobotCoin";
    string public constant symbol = "GCC";
    uint8 public constant decimals = 5;
    
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return balanceOf[account];
    }
    
    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balanceOf[msg.sender]);
        
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        
        Transfer(msg.sender, to, value);
        return true;
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowance[owner][spender];
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        
        Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }
    
    function increaseApproval(address spender, uint addedValue) public returns (bool) {
        allowance[msg.sender][spender] = allowance[msg.sender][spender].add(addedValue);
        Approval(msg.sender, spender, allowance[msg.sender][spender]);
        return true;
    }
    
    function decreaseApproval(address spender, uint subtractedValue) public returns (bool) {
        uint oldValue = allowance[msg.sender][spender];
        if (subtractedValue > oldValue) {
            allowance[msg.sender][spender] = 0;
        } else {
            allowance[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        Approval(msg.sender, spender, allowance[msg.sender][spender]);
        return true;
    }
}

contract TokenWithCallbacks is ERC20Token {
    function approveAndCall(address spender, uint256 value, bytes data) public returns (bool) {
        require(spender != address(this));
        super.approve(spender, value);
        require(spender.call(data));
        return true;
    }
    
    function transferAndCall(address to, uint256 value, bytes data) public returns (bool) {
        require(to != address(this));
        super.transfer(to, value);
        require(to.call(data));
        return true;
    }
    
    function transferFromAndCall(address from, address to, uint256 value, bytes data) public returns (bool) {
        require(to != address(this));
        super.transferFrom(from, to, value);
        require(to.call(data));
        return true;
    }
    
    function increaseApprovalAndCall(address spender, uint addedValue, bytes data) public returns (bool) {
        require(spender != address(this));
        super.increaseApproval(spender, addedValue);
        require(spender.call(data));
        return true;
    }
    
    function decreaseApprovalAndCall(address spender, uint subtractedValue, bytes data) public returns (bool) {
        require(spender != address(this));
        super.decreaseApproval(spender, subtractedValue);
        require(spender.call(data));
        return true;
    }
}

contract GoCryptobotExchange is Pausable {
    TokenRecipient internal tokenContract;
    
    event ExchangeRateChange(uint256 oldRate, uint256 newRate);
    event Withdrawal(address indexed claimant, uint256 tokens, uint256 etherAmount);
    
    uint8 constant FEE_RATE = 5;
    uint256 public exchangeRate;
    address public coinStorage;
    
    function GoCryptobotExchange() public {
        coinStorage = this;
        exchangeRate = 1000000000000 wei;
        paused = true;
        owner = msg.sender;
        operator = msg.sender;
    }
    
    function setTokenContract(address tokenAddress) external ownerOrOperator {
        TokenRecipient tokenRecipient = TokenRecipient(tokenAddress);
        tokenContract = tokenRecipient;
    }
    
    function unpause() public {
        require(tokenContract != address(0));
        super.unpause();
    }
    
    function execute(bytes data) external ownerOrOperator {
        require(tokenContract.call(data));
    }
    
    function setCoinStorage(address newCoinStorage) public ownerOrOperator {
        coinStorage = newCoinStorage;
    }
    
    function setExchangeRate(uint256 newRate) external operator {
        ExchangeRateChange(exchangeRate, newRate);
        exchangeRate = newRate;
    }
    
    function withdraw(address claimant, uint256 tokens) public whenNotPaused {
        require(tokenContract.allowance(claimant, this) >= tokens);
        require(tokenContract.transferFrom(claimant, coinStorage, tokens));
        
        uint256 etherAmount = (tokensToEther(tokens) / 100) * (100 - FEE_RATE);
        claimant.transfer(etherAmount);
        
        Withdrawal(claimant, tokens, etherAmount);
    }
    
    function tokensToEther(uint256 tokens) internal view returns (uint256) {
        return tokens * exchangeRate;
    }
    
    function() external payable {
        revert();
    }
}

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
```