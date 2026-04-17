```solidity
pragma solidity ^0.4.13;

contract Ownable {
    address public owner;
    mapping(address => bool) public admins;
    
    function Ownable() {
        owner = msg.sender;
        admins[msg.sender] = true;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyAdmin() {
        require(admins[msg.sender] == true);
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
    
    function setAdmin(address adminAddress, bool isAdmin) onlyOwner {
        admins[adminAddress] = isAdmin;
    }
}

interface TokenRecipient {
    function receiveApproval(address from, uint256 value, address tokenContract, bytes extraData);
}

contract GoldRewardToken is Ownable {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public minBalanceForAccounts;
    bool public usersCanFreeze;
    bool public usersCanUnfreeze;
    bool public tradingEnabled = true;
    
    mapping(address => bool) public frozenAccount;
    modifier notFrozen() {
        require(frozenAccount[msg.sender] || !tradingEnabled);
        _;
    }
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public frozen;
    mapping(address => bool) public usersCanTrade;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Reward(address from, address to, uint256 value, string note, uint256 timestamp);
    event Burn(address indexed from, uint256 value);
    event Frozen(address indexed target, bool frozen);
    event Unlock(address indexed target, address from, uint256 value);
    
    mapping(address => uint256) public lockedRewards;
    mapping(address => mapping(address => uint256)) public rewardsOf;
    mapping(address => mapping(uint32 => address)) public rewarders;
    mapping(address => mapping(address => uint32)) public rewarderIndex;
    mapping(address => uint32) public rewarderCount;
    mapping(address => uint256) public totalLockedRewards;
    
    uint256 public sellPrice = 608;
    uint256 public buyPrice = 760;
    
    function GoldRewardToken() {
        uint256 initialSupply = 20000000000000000000000000;
        balanceOf[msg.sender] = initialSupply;
        totalSupply = initialSupply;
        name = "Gold Reward Token";
        symbol = "GRT";
        decimals = 18;
        minBalanceForAccounts = 1000000000000000;
        usersCanFreeze = false;
        usersCanUnfreeze = false;
        tradingEnabled = true;
        frozenAccount[msg.sender] = false;
        usersCanTrade[msg.sender] = true;
    }
    
    function mintToken(address target, uint256 mintedAmount) onlyOwner {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, owner, mintedAmount);
        Transfer(owner, target, mintedAmount);
    }
    
    function setUsersCanFreeze(bool canFreeze) {
        usersCanFreeze = canFreeze;
    }
    
    function setMinBalance(uint256 minimumBalanceInWei) onlyOwner {
        minBalanceForAccounts = minimumBalanceInWei;
    }
    
    function freezeAccount(address target, uint256 value) onlyAdmin {
        _transfer(msg.sender, target, value);
        freeze(target, true);
    }
    
    function freeze(address target, bool freezeStatus) internal {
        frozen[target] = freezeStatus;
        Frozen(target, freezeStatus);
    }
    
    function setFrozenStatus(address target, bool freezeStatus) {
        if(freezeStatus || (!freezeStatus && !usersCanFreeze)) {
            require(admins[msg.sender]);
        }
        freeze(target, freezeStatus);
    }
    
    function _transfer(address from, address to, uint256 value) internal {
        require(to != 0x0);
        require(!frozen[from]);
        require(balanceOf[from] >= value);
        require(balanceOf[to] + value > balanceOf[to]);
        
        balanceOf[from] -= value;
        balanceOf[to] += value;
        Transfer(from, to, value);
    }
    
    function transfer(address to, uint256 value) notFrozen {
        require(!frozen[msg.sender]);
        if (msg.sender.balance < minBalanceForAccounts) {
            sell((minBalanceForAccounts - msg.sender.balance) * sellPrice);
        }
        _transfer(msg.sender, to, value);
    }
    
    function reward(address to, uint256 value, bool lockReward, string note) {
        require(to != 0x0);
        require(!frozen[msg.sender]);
        
        if (msg.sender.balance < minBalanceForAccounts) {
            sell((minBalanceForAccounts - msg.sender.balance) * sellPrice);
        }
        
        if(!lockReward) {
            _transfer(msg.sender, to, value);
        } else {
            require(balanceOf[msg.sender] >= value);
            require(lockedRewards[to] + value > lockedRewards[to]);
            
            balanceOf[msg.sender] -= value;
            lockedRewards[to] += value;
            rewardsOf[to][msg.sender] += value;
            
            if(rewarderIndex[to][msg.sender] == 0) {
                rewarderCount[to] += 1;
                rewarders[to][rewarderCount[to]] = msg.sender;
            }
            rewarderIndex[to][msg.sender] += 1;
            totalLockedRewards[msg.sender] += value;
            Transfer(msg.sender, to, value);
        }
        Reward(msg.sender, to, value, note, now);
    }
    
    function unlockReward(address to, uint256 value) {
        require(!frozen[msg.sender]);
        require(rewardsOf[msg.sender][to] >= value);
        require(lockedRewards[msg.sender] >= value);
        
        if (msg.sender.balance < minBalanceForAccounts) {
            sell((minBalanceForAccounts - msg.sender.balance) * sellPrice);
        }
        
        lockedRewards[msg.sender] -= value;
        rewardsOf[msg.sender][to] -= value;
        balanceOf[to] += value;
        Transfer(msg.sender, to, value);
    }
    
    function unlock(address target, uint256 value) {
        require(lockedRewards[target] > value);
        require(rewardsOf[target][msg.sender] >= value);
        
        if(value == 0) {
            value = rewardsOf[target][msg.sender];
        }
        
        if (msg.sender.balance < minBalanceForAccounts) {
            sell((minBalanceForAccounts - msg.sender.balance) * sellPrice);
        }
        
        lockedRewards[target] -= value;
        rewardsOf[target][msg.sender] -= value;
        balanceOf[target] += value;
        Unlock(target, msg.sender, value);
    }
    
    function transferFrom(address from, address to, uint256 value) returns (bool success) {
        require(!frozen[from]);
        require(value <= allowance[from][msg.sender]);
        allowance[from][msg.sender] -= value;
        _transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) returns (bool success) {
        allowance[msg.sender][spender] = value;
        return true;
    }
    
    function approveAndCall(address spender, uint256 value, bytes extraData) onlyOwner returns (bool success) {
        TokenRecipient tokenRecipient = TokenRecipient(spender);
        if (approve(spender, value)) {
            tokenRecipient.receiveApproval(msg.sender, value, this, extraData);
            return true;
        }
    }
    
    function burn(uint256 value) onlyOwner returns (bool success) {
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;
        totalSupply -= value;
        Burn(msg.sender, value);
        return true;
    }
    
    function burnFrom(address from, uint256 value) returns (bool success) {
        require(balanceOf[from] >= value);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;
        allowance[from][msg.sender] -= value;
        totalSupply -= value;
        Burn(from, value);
        return true;
    }
    
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }
    
    function enableTrading(bool enable) onlyOwner {
        tradingEnabled = enable;
    }
    
    function setUserCanTrade(address user, bool canTrade) onlyOwner {
        usersCanTrade[user] = canTrade;
    }
    
    function buy() payable returns (uint256 amount) {
        if(!tradingEnabled && !usersCanTrade[msg.sender]) revert();
        amount = msg.value * buyPrice;
        require(balanceOf[this] >= amount);
        balanceOf[msg.sender] += amount;
        balanceOf[this] -= amount;
        Transfer(this, msg.sender, amount);
        return amount;
    }
    
    function sell(uint256 amount) returns (uint256 revenue) {
        require(!frozen[msg.sender]);
        if(!tradingEnabled && !usersCanTrade[msg.sender]) {
            require(minBalanceForAccounts > amount / sellPrice);
        }
        require(balanceOf[msg.sender] >= amount);
        balanceOf[this] += amount;
        balanceOf[msg.sender] -= amount;
        revenue = amount / sellPrice;
        require(msg.sender.send(revenue));
        Transfer(msg.sender, this, amount);
        return revenue;
    }
    
    function() payable {
    }
    
    event Withdrawn(address indexed to, uint256 value);
    
    function withdraw(address to, uint256 value) onlyOwner {
        to.transfer(value);
        Withdrawn(to, value);
    }
    
    function setFrozenAccount(address target, bool freezeStatus) onlyOwner {
        frozenAccount[target] = freezeStatus;
    }
    
    function setTradingEnabled(bool enable) onlyOwner {
        tradingEnabled = enable;
    }
}
```