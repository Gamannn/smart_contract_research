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

    function isOwner(address addr) view public returns (bool) {
        return owner == addr;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function terminate() public onlyOwner {
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
    uint256 private currentSupply;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;
    mapping(address => bool) private lockedAccounts;

    event ReceivedEth(address indexed from, uint256 value);
    event TransferredEth(address indexed to, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event DayMinted(uint256 day, uint256 value, uint256 timestamp);
    event SoldToken(address buyer, uint256 value, string note);

    function () payable public {
        emit ReceivedEth(msg.sender, msg.value);
    }

    function foundationTransfer(address to, uint256 amtEth, uint256 amtToken) public onlyOwner {
        require(address(this).balance >= amtEth && balances[this] >= amtToken);
        if (amtEth > 0) {
            to.transfer(amtEth);
            emit TransferredEth(to, amtEth);
        }
        if (amtToken > 0) {
            require(balances[to] + amtToken > balances[to]);
            balances[this] -= amtToken;
            balances[to] += amtToken;
            emit Transfer(this, to, amtToken);
        }
    }

    function EMPR() public {
        uint256 initialTotalSupply = 500000000;
        balances[this] = initialTotalSupply * (10 ** decimals);
        currentSupply = initialTotalSupply * (10 ** decimals);
        emit Transfer(address(0), this, currentSupply);
    }

    uint256 constant startTime = 1525132800;
    uint256 constant startAmt = 95000000;
    uint256 private lastDayPaid = 0;
    uint256 private currentMonth = 0;
    uint256 private factor = 10000000;

    function dailyMint() public {
        uint256 day = (now - startTime) / (60 * 60 * 24);
        require(startTime <= now);
        require(day >= lastDayPaid);

        uint256 month = lastDayPaid / 30;
        if (month > currentMonth) {
            currentMonth += 1;
            factor = (factor * 99) / 100;
        }

        uint256 todaysPayout = (((factor * startAmt) / 10000000) / 30) * (10 ** decimals);
        balances[this] += todaysPayout;
        currentSupply += todaysPayout;
        emit Transfer(address(0), this, todaysPayout);
        emit DayMinted(lastDayPaid, todaysPayout, now);
        lastDayPaid += 1;
    }

    function getLastDayPaid() public view returns (uint256) {
        return lastDayPaid;
    }

    function mintToken(uint256 amt) public onlyOwner {
        currentSupply += amt;
        balances[this] += amt;
        emit Transfer(address(0), this, amt);
    }

    function destroyToken(uint256 amt) public onlyOwner {
        require(balances[this] >= amt);
        currentSupply -= amt;
        balances[this] -= amt;
        emit Transfer(this, address(0), amt);
    }

    function buyToken(address buyer, uint256 value, string note) public onlyOwner {
        require(balances[this] >= value && balances[buyer] + value > balances[buyer]);
        emit SoldToken(buyer, value, note);
        balances[this] -= value;
        balances[buyer] += value;
        emit Transfer(this, buyer, value);
    }

    function lockAccount(address toLock) public onlyOwner {
        lockedAccounts[toLock] = true;
    }

    function unlockAccount(address toUnlock) public onlyOwner {
        delete lockedAccounts[toUnlock];
    }

    function setTradeable(bool t) public onlyOwner {
        tradeable = t;
    }

    function isTradeable() public view returns (bool) {
        return tradeable;
    }

    function totalSupply() public view returns (uint256) {
        return currentSupply;
    }

    function balanceOf(address owner) public view returns (uint256 balance) {
        return balances[owner];
    }

    function transfer(address to, uint256 value) public notLocked returns (bool success) {
        require(tradeable);
        if (balances[msg.sender] >= value && balances[to] + value > balances[to]) {
            emit Transfer(msg.sender, to, value);
            balances[msg.sender] -= value;
            balances[to] += value;
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address from, address to, uint256 value) public notLocked returns (bool success) {
        require(!lockedAccounts[from] && !lockedAccounts[to]);
        require(tradeable);
        if (balances[from] >= value && allowed[from][msg.sender] >= value && balances[to] + value > balances[to]) {
            emit Transfer(from, to, value);
            balances[from] -= value;
            allowed[from][msg.sender] -= value;
            balances[to] += value;
            return true;
        } else {
            return false;
        }
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
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