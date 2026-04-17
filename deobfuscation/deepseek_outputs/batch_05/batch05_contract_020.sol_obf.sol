```solidity
pragma solidity ^0.4.20;

contract Token {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 private _decimalsMultiplier;
    uint256 public tokenReward;
    uint256 public totalSupply;
    address public owner;
    
    mapping(address => uint256) private balances;
    
    uint256 public transferLock;
    uint256 public stop_token_time;
    uint256 public start_token_time;
    string public status;
    
    event token_Burn(address indexed burner, uint256 value);
    event Deposit(address depositor, uint256 value, string status);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event change_Owner(string message);
    event change_Status(string status);
    event change_Name(string name);
    event change_Symbol(string symbol);
    event change_TokenReward(uint256 reward);
    event change_Time_Stamp(uint256 start, uint256 stop);
    
    constructor() public {
        name = "GMB";
        symbol = "MAS";
        decimals = 18;
        _decimalsMultiplier = 10 ** uint256(decimals);
        tokenReward = 0;
        totalSupply = _decimalsMultiplier * 10000000000;
        status = "Private";
        start_token_time = 1514732400;
        stop_token_time = 1546268399;
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
        transferLock = 1;
    }
    
    function () payable public {
        require(now >= start_token_time && now <= stop_token_time);
        emit Deposit(msg.sender, msg.value, status);
        
        uint256 tokens = (msg.value * tokenReward) / _decimalsMultiplier;
        
        require(balances[owner] >= tokens);
        require(balances[msg.sender] + tokens >= balances[msg.sender]);
        
        balances[msg.sender] += tokens;
        emit Transfer(owner, msg.sender, tokens);
    }
    
    function transfer(address to, uint256 value) public returns (bool) {
        require(transferLock == 0);
        require(balances[msg.sender] >= value);
        
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(balances[from] >= value * _decimalsMultiplier);
        require(balances[to] + (value * _decimalsMultiplier) >= balances[to]);
        
        balances[from] -= value * _decimalsMultiplier;
        balances[to] += value * _decimalsMultiplier;
        emit Transfer(from, to, value * _decimalsMultiplier);
        return true;
    }
    
    function approve(address spender, address to, uint256 value) public returns (bool) {
        require(balances[spender] >= value * _decimalsMultiplier);
        require(balances[to] + (value * _decimalsMultiplier) >= balances[to]);
        
        balances[spender] -= value * _decimalsMultiplier;
        balances[to] += value * _decimalsMultiplier;
        emit Transfer(spender, to, value * _decimalsMultiplier);
        return true;
    }
    
    function token_Burn(uint256 value) public returns (bool) {
        require(balances[msg.sender] >= value * _decimalsMultiplier);
        
        balances[msg.sender] -= value * _decimalsMultiplier;
        totalSupply -= value * _decimalsMultiplier;
        emit token_Burn(msg.sender, value * _decimalsMultiplier);
        return true;
    }
    
    function token_Add(uint256 value) public returns (bool) {
        require(balances[msg.sender] >= value * _decimalsMultiplier);
        
        balances[msg.sender] += value * _decimalsMultiplier;
        totalSupply += value * _decimalsMultiplier;
        emit Transfer(address(0), msg.sender, value * _decimalsMultiplier);
        return true;
    }
    
    function change_Name(string newName) public returns (bool) {
        name = newName;
        emit change_Name(name);
        return true;
    }
    
    function change_Symbol(string newSymbol) public returns (bool) {
        symbol = newSymbol;
        emit change_Symbol(symbol);
        return true;
    }
    
    function change_Status(string newStatus) public returns (bool) {
        status = newStatus;
        emit change_Status(status);
        return true;
    }
    
    function change_TokenReward(uint256 newReward) public returns (bool) {
        tokenReward = newReward;
        emit change_TokenReward(tokenReward);
        return true;
    }
    
    function withdraw(uint256 amount) public returns(bool) {
        owner.transfer(amount);
        return true;
    }
    
    function change_time_stamp(uint256 _start_token_time, uint256 _stop_token_time) public returns (bool) {
        start_token_time = _start_token_time;
        stop_token_time = _stop_token_time;
        emit change_Time_Stamp(start_token_time, stop_token_time);
        return true;
    }
    
    function change_owner(address newOwner) public returns (bool) {
        owner = newOwner;
        emit change_Owner("Owner_change");
        return true;
    }
    
    function setTransferLock(uint256 lock) public returns (bool) {
        transferLock = lock;
        return true;
    }
    
    function setTokenParameters(uint256 _start_token_time, uint256 _stop_token_time, string _status) public returns (bool) {
        start_token_time = _start_token_time;
        stop_token_time = _stop_token_time;
        status = _status;
        emit change_Time_Stamp(start_token_time, stop_token_time);
        emit change_Status(status);
        return true;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
}
```