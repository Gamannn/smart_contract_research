pragma solidity ^0.4.18;

contract Ownable {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    function Ownable() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface Token {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract HodlContract is Ownable {
    event Hodl(address indexed holder, uint indexed amount, uint lockedUntil, uint lockPeriod);
    event Party(address indexed holder, uint indexed amount, uint lockPeriod);
    event Fee(address indexed holder, uint indexed amount, uint timeRemaining);
    
    address[] public holders;
    mapping(address => uint) public holderIndex;
    mapping(address => uint) public balances;
    mapping(address => uint) public lockedUntil;
    mapping(address => uint) public lockPeriods;
    
    function getHolder(uint index) public constant returns(
        address holder,
        uint balance,
        uint lockedUntilTime,
        uint lockPeriod
    ) {
        holder = holders[index];
        balance = balances[holder];
        lockedUntilTime = lockedUntil[holder];
        lockPeriod = lockPeriods[holder];
    }
    
    function getHolderAndNext(uint index) public constant returns(
        address holder,
        uint balance,
        uint lockedUntilTime,
        uint lockPeriod,
        address nextHolder,
        uint nextBalance,
        uint nextLockedUntil,
        uint nextLockPeriod
    ) {
        holder = holders[index];
        balance = balances[holder];
        lockedUntilTime = lockedUntil[holder];
        lockPeriod = lockPeriods[holder];
        
        nextHolder = holders[index + 1];
        nextBalance = balances[nextHolder];
        nextLockedUntil = lockedUntil[nextHolder];
        nextLockPeriod = lockPeriods[nextHolder];
    }
    
    function getHolderAndNextTwo(uint index) public constant returns(
        address holder,
        uint balance,
        uint lockedUntilTime,
        uint lockPeriod,
        address nextHolder,
        uint nextBalance,
        uint nextLockedUntil,
        uint nextLockPeriod,
        address secondNextHolder,
        uint secondNextBalance,
        uint secondNextLockedUntil,
        uint secondNextLockPeriod
    ) {
        holder = holders[index];
        balance = balances[holder];
        lockedUntilTime = lockedUntil[holder];
        lockPeriod = lockPeriods[holder];
        
        nextHolder = holders[index + 1];
        nextBalance = balances[nextHolder];
        nextLockedUntil = lockedUntil[nextHolder];
        nextLockPeriod = lockPeriods[nextHolder];
        
        secondNextHolder = holders[index + 2];
        secondNextBalance = balances[secondNextHolder];
        secondNextLockedUntil = lockedUntil[secondNextHolder];
        secondNextLockPeriod = lockPeriods[secondNextHolder];
    }
    
    function holderCount() public constant returns(uint) {
        return holders.length;
    }
    
    function() public payable {
        if (balances[msg.sender] > 0) {
            hodl(0);
        } else {
            hodl(1 years);
        }
    }
    
    function hodl1Year() public payable {
        hodl(1 years);
    }
    
    function hodl2Years() public payable {
        hodl(2 years);
    }
    
    function hodl3Years() public payable {
        hodl(3 years);
    }
    
    function hodl(uint lockTime) internal {
        if (holderIndex[msg.sender] == 0) {
            holders.push(msg.sender);
            holderIndex[msg.sender] = holders.length;
        }
        
        balances[msg.sender] += msg.value;
        
        if (lockTime > 0) {
            require(lockedUntil[msg.sender] < now + lockTime);
            lockedUntil[msg.sender] = now + lockTime;
            lockPeriods[msg.sender] = lockTime;
        }
        
        Hodl(msg.sender, msg.value, lockedUntil[msg.sender], lockPeriods[msg.sender]);
    }
    
    function party() public {
        withdraw(msg.sender);
    }
    
    function withdraw(address holder) public {
        uint amount = balances[holder];
        require(amount > 0);
        
        balances[holder] = 0;
        
        if (now < lockedUntil[holder]) {
            require(msg.sender == holder);
            uint fee = amount * 10 / 100;
            amount -= fee;
            Fee(holder, fee, lockedUntil[holder] - now);
        }
        
        holder.transfer(amount);
        Party(holder, amount, lockPeriods[holder]);
        
        uint index = holderIndex[holder];
        require(index > 0);
        
        if (index + 1 < holders.length) {
            holders[index - 1] = holders[holders.length - 1];
            holderIndex[holders[index - 1]] = index;
        }
        
        holders.length--;
        delete balances[holder];
        delete lockedUntil[holder];
        delete lockPeriods[holder];
        delete holderIndex[holder];
    }
    
    function recoverTokens(Token token) external onlyOwner {
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
    }
}