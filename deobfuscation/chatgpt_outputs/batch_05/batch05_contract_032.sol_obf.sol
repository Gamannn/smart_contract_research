```solidity
pragma solidity ^0.4.13;

contract AdminControl {
    address public owner;
    mapping(address => bool) public admins;

    function AdminControl() public {
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

    function setOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function setAdmin(address admin, bool isAdmin) public onlyOwner {
        admins[admin] = isAdmin;
    }
}

interface TokenReceiver {
    function receiveApproval(address from, uint256 value, address token, bytes extraData) external;
}

contract GoldRewardToken is AdminControl {
    string public name;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public minBalanceForAccounts;
    bool public usersCanUnfreeze;
    bool public usersCanTrade;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;
    mapping(address => bool) public frozenAccounts;
    mapping(address => bool) public lockedAccounts;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Reward(address from, address to, uint256 value, string message, uint256 timestamp);
    event Burn(address indexed from, uint256 value);
    event Frozen(address indexed target, bool frozen);
    event Unlock(address indexed target, address from, uint256 value);

    function GoldRewardToken() public {
        uint256 initialSupply = 20000000000000000000000000;
        balances[msg.sender] = initialSupply;
        totalSupply = initialSupply;
        name = "Gold Reward Token";
        decimals = 18;
        minBalanceForAccounts = 1000000000000000;
        usersCanUnfreeze = false;
        usersCanTrade = true;
        lockedAccounts[msg.sender] = true;
    }

    function mintToken(address target, uint256 mintedAmount) public onlyOwner {
        balances[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, owner, mintedAmount);
        Transfer(owner, target, mintedAmount);
    }

    function setUsersCanUnfreeze(bool canUnfreeze) public onlyOwner {
        usersCanUnfreeze = canUnfreeze;
    }

    function setMinBalance(uint256 minimumBalanceInWei) public onlyOwner {
        minBalanceForAccounts = minimumBalanceInWei;
    }

    function transfer(address to, uint256 value) public onlyAdmin {
        _transfer(msg.sender, to, value);
        _freezeAccount(to, true);
    }

    function _freezeAccount(address target, bool freeze) internal {
        frozenAccounts[target] = freeze;
        Frozen(target, freeze);
    }

    function _freezeAccount(address target, bool freeze) public {
        if (freeze || (!freeze && !usersCanUnfreeze)) {
            require(admins[msg.sender]);
        }
        _freezeAccount(target, freeze);
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != 0x0);
        require(!frozenAccounts[from]);
        require(balances[from] >= value);
        require(balances[to] + value > balances[to]);
        balances[from] -= value;
        balances[to] += value;
        Transfer(from, to, value);
    }

    function transferFrom(address from, address to, uint256 value) public onlyAdmin {
        require(!frozenAccounts[msg.sender]);
        if (msg.sender.balance < minBalanceForAccounts) {
            _sell((minBalanceForAccounts - msg.sender.balance) * 1);
        }
        _transfer(from, to, value);
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        allowed[msg.sender][spender] = value;
        return true;
    }

    function approveAndCall(address spender, uint256 value, bytes extraData) public onlyOwner returns (bool success) {
        TokenReceiver receiver = TokenReceiver(spender);
        if (approve(spender, value)) {
            receiver.receiveApproval(msg.sender, value, this, extraData);
            return true;
        }
    }

    function burn(uint256 value) public onlyOwner returns (bool success) {
        require(balances[msg.sender] >= value);
        balances[msg.sender] -= value;
        totalSupply -= value;
        Burn(msg.sender, value);
        return true;
    }

    function burnFrom(address from, uint256 value) public returns (bool success) {
        require(balances[from] >= value);
        require(value <= allowed[from][msg.sender]);
        balances[from] -= value;
        allowed[from][msg.sender] -= value;
        totalSupply -= value;
        Burn(from, value);
        return true;
    }

    function setUsersCanTrade(bool canTrade) public onlyOwner {
        usersCanTrade = canTrade;
    }

    function buy() payable public returns (uint256 amount) {
        require(usersCanTrade || lockedAccounts[msg.sender]);
        amount = msg.value * 1;
        require(balances[this] >= amount);
        balances[msg.sender] += amount;
        balances[this] -= amount;
        Transfer(this, msg.sender, amount);
        return amount;
    }

    function sell(uint256 amount) public returns (uint revenue) {
        require(!frozenAccounts[msg.sender]);
        require(usersCanTrade || lockedAccounts[msg.sender]);
        require(balances[msg.sender] >= amount);
        balances[this] += amount;
        balances[msg.sender] -= amount;
        revenue = amount / 1;
        require(msg.sender.send(revenue));
        Transfer(msg.sender, this, amount);
        return revenue;
    }

    function() payable public {}

    event Withdrawn(address indexed to, uint256 value);

    function withdraw(address to, uint256 value) public onlyOwner {
        to.transfer(value);
        Withdrawn(to, value);
    }

    function setLockedAccount(address target, bool lock) public onlyOwner {
        lockedAccounts[target] = lock;
    }

    function setGlobalLock(bool lock) public onlyOwner {
        usersCanTrade = lock;
    }
}
```