```solidity
pragma solidity ^0.4.19;

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
        return a / b;
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

contract Owned {
    address private owner;
    
    function Owned() public {
        owner = msg.sender;
    }
    
    function IsOwner(address addr) view public returns(bool) {
        return owner == addr;
    }
    
    function TransferOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }
    
    function Terminate() public onlyOwner {
        selfdestruct(owner);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract EMPR is Owned {
    using SafeMath for uint256;
    
    string public constant name = "empowr";
    string public constant symbol = "EMPR";
    uint256 public constant decimals = 18;
    
    bool private tradeable;
    uint256 private totalSupply;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;
    mapping(address => bool) private lockedAccounts;
    
    event ReceivedEth(address indexed sender, uint256 amount);
    event TransferredEth(address indexed recipient, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event SoldToken(address buyer, uint256 amount, string note);
    event DayMinted(uint256 day, uint256 value, uint256 timestamp);
    
    function () payable public {
        emit ReceivedEth(msg.sender, msg.value);
    }
    
    function FoundationTransfer(address recipient, uint256 amtEth, uint256 amtToken) public onlyOwner {
        require(address(this).balance >= amtEth && balances[this] >= amtToken);
        
        if (amtEth > 0) {
            recipient.transfer(amtEth);
            emit TransferredEth(recipient, amtEth);
        }
        
        if (amtToken > 0) {
            require(balances[recipient] + amtToken > balances[recipient]);
            balances[this] -= amtToken;
            balances[recipient] += amtToken;
            emit Transfer(this, recipient, amtToken);
        }
    }
    
    function EMPR() public {
        uint256 initialTotalSupply = 500000000;
        balances[this] = initialTotalSupply * (10**decimals);
        totalSupply = initialTotalSupply * (10**decimals);
        emit Transfer(address(0), this, totalSupply);
    }
    
    uint256 constant startTime = 1525132800;
    uint256 constant startAmt = 95000000;
    uint256 private lastDayPaid = 0;
    uint256 private currentMonth = 0;
    uint256 private factor = 10000000;
    
    function DailyMint() public {
        uint256 day = (now - startTime) / (60 * 60 * 24);
        require(startTime <= now);
        require(day >= lastDayPaid);
        
        uint256 month = lastDayPaid / 30;
        if (month > currentMonth) {
            currentMonth += 1;
            factor = (factor * 99) / 100;
        }
        
        uint256 todaysPayout = (((factor * startAmt) / 10000000) / 30) * (10**decimals);
        balances[this] += todaysPayout;
        totalSupply += todaysPayout;
        
        emit Transfer(address(0), this, todaysPayout);
        emit DayMinted(lastDayPaid, todaysPayout, now);
        
        lastDayPaid += 1;
    }
    
    function getLastDayPaid() public view returns(uint256) {
        return lastDayPaid;
    }
    
    function MintToken(uint256 amount) public onlyOwner {
        totalSupply += amount;
        balances[this] += amount;
        emit Transfer(address(0), this, amount);
    }
    
    function DestroyToken(uint256 amount) public onlyOwner {
        require(balances[this] >= amount);
        totalSupply -= amount;
        balances[this] -= amount;
        emit Transfer(this, address(0), amount);
    }
    
    function BuyToken(address buyer, uint256 amount, string note) public onlyOwner {
        require(balances[this] >= amount && balances[buyer] + amount > balances[buyer]);
        emit SoldToken(buyer, amount, note);
        balances[this] -= amount;
        balances[buyer] += amount;
        emit Transfer(this, buyer, amount);
    }
    
    function LockAccount(address toLock) public onlyOwner {
        lockedAccounts[toLock] = true;
    }
    
    function UnlockAccount(address toUnlock) public onlyOwner {
        delete lockedAccounts[toUnlock];
    }
    
    function SetTradeable(bool t) public onlyOwner {
        tradeable = t;
    }
    
    function IsTradeable() public view returns(bool) {
        return tradeable;
    }
    
    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    function transfer(address to, uint256 amount) public notLocked returns (bool success) {
        require(tradeable);
        require(balances[msg.sender] >= amount && balances[to] + amount > balances[to]);
        
        emit Transfer(msg.sender, to, amount);
        balances[msg.sender] -= amount;
        balances[to] += amount;
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) public notLocked returns (bool success) {
        require(!lockedAccounts[from] && !lockedAccounts[to]);
        require(tradeable);
        require(balances[from] >= amount && allowed[from][msg.sender] >= amount && balances[to] + amount > balances[to]);
        
        emit Transfer(from, to, amount);
        balances[from] -= amount;
        allowed[from][msg.sender] -= amount;
        balances[to] += amount;
        return true;
    }
    
    function approve(address spender, uint256 amount) public returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function allowance(address _owner, address spender) public view returns (uint256) {
        return allowed[_owner][spender];
    }
    
    function increaseApproval(address spender, uint addedValue) public returns (bool) {
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
    
    function decreaseApproval(address spender, uint subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][spender];
        if (subtractedValue > oldValue) {
            allowed[msg.sender][spender] = 0;
        } else {
            allowed[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
    
    modifier notLocked() {
        require(!lockedAccounts[msg.sender]);
        _;
    }
}
```