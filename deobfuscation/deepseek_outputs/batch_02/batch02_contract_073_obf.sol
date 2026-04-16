```solidity
pragma solidity ^0.4.18;

contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }
    
    function safeDiv(uint256 a, uint256 b) internal returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        require(a == b * c + a % b);
        return c;
    }
    
    function safeSub(uint256 a, uint256 b) internal returns (uint256) {
        require(b <= a);
        return a - b;
    }
    
    function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        require(c >= a && c >= b);
        return c;
    }
    
    function require(bool condition) internal {
        if (!condition) {
            revert();
        }
    }
}

interface Token {
    function transfer(address to, uint amount);
}

contract Crowdsale is SafeMath {
    address public beneficiary;
    uint public fundingGoal;
    uint public amountRaised;
    uint public deadline;
    uint public price;
    Token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;
    
    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    
    function Crowdsale(
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint durationInMinutes,
        uint etherCostOfEachToken,
        address addressOfTokenUsedAsReward
    ) {
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = 1523577600 + durationInMinutes * 1 minutes;
        price = etherCostOfEachToken * 1 ether;
        tokenReward = Token(addressOfTokenUsedAsReward);
    }
    
    function () payable {
        require(!crowdsaleClosed);
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        tokenReward.transfer(msg.sender, amount / price);
        FundTransfer(msg.sender, amount, true);
    }
    
    modifier afterDeadline() {
        require(now >= deadline);
        _;
    }
    
    function checkGoalReached() afterDeadline {
        if (amountRaised >= fundingGoal) {
            fundingGoalReached = true;
            GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }
}

contract CryptoTollBoothToken is SafeMath {
    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);
    
    function CryptoTollBoothToken(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
    ) {
        balanceOf[msg.sender] = initialSupply;
        totalSupply = initialSupply;
        name = tokenName;
        symbol = tokenSymbol;
        decimals = decimalUnits;
        owner = msg.sender;
    }
    
    function transfer(address to, uint256 value) {
        if (to == 0x0) revert();
        if (value <= 0) revert();
        if (balanceOf[msg.sender] < value) revert();
        if (balanceOf[to] + value < balanceOf[to]) revert();
        
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], value);
        balanceOf[to] = safeAdd(balanceOf[to], value);
        Transfer(msg.sender, to, value);
    }
    
    function approve(address spender, uint256 value) returns (bool success) {
        if (value <= 0) revert();
        allowance[msg.sender][spender] = value;
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) returns (bool success) {
        if (to == 0x0) revert();
        if (value <= 0) revert();
        if (balanceOf[from] < value) revert();
        if (balanceOf[to] + value < balanceOf[to]) revert();
        if (value > allowance[from][msg.sender]) revert();
        
        balanceOf[from] = safeSub(balanceOf[from], value);
        balanceOf[to] = safeAdd(balanceOf[to], value);
        allowance[from][msg.sender] = safeSub(allowance[from][msg.sender], value);
        Transfer(from, to, value);
        return true;
    }
    
    function burn(uint256 value) returns (bool success) {
        if (balanceOf[msg.sender] < value) revert();
        if (value <= 0) revert();
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], value);
        totalSupply = safeSub(totalSupply, value);
        Burn(msg.sender, value);
        return true;
    }
    
    function freeze(uint256 value) returns (bool success) {
        if (balanceOf[msg.sender] < value) revert();
        if (value <= 0) revert();
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], value);
        freezeOf[msg.sender] = safeAdd(freezeOf[msg.sender], value);
        Freeze(msg.sender, value);
        return true;
    }
    
    function unfreeze(uint256 value) returns (bool success) {
        if (freezeOf[msg.sender] < value) revert();
        if (value <= 0) revert();
        freezeOf[msg.sender] = safeSub(freezeOf[msg.sender], value);
        balanceOf[msg.sender] = safeAdd(balanceOf[msg.sender], value);
        Unfreeze(msg.sender, value);
        return true;
    }
    
    function withdrawEther(uint256 amount) {
        if (msg.sender != owner) revert();
        owner.transfer(amount);
    }
}
```