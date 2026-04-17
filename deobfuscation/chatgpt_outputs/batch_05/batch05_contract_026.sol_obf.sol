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

contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract HodlContract is Ownable {
    event Hodl(address indexed user, uint indexed amount, uint lockTime, uint lockDuration);
    event Party(address indexed user, uint indexed amount, uint lockDuration);
    event Fee(address indexed user, uint indexed fee, uint remainingLockTime);

    address[] public users;
    mapping(address => uint) public userIndex;
    mapping(address => uint) public balances;
    mapping(address => uint) public lockUntil;
    mapping(address => uint) public lockDuration;

    function getUserInfo(uint index) public constant returns(address user, uint balance, uint lockTime, uint duration) {
        user = users[index];
        balance = balances[user];
        lockTime = lockUntil[user];
        duration = lockDuration[user];
    }

    function getUserInfoExtended(uint index) public constant returns(address user, uint balance, uint lockTime, uint duration, address nextUser, uint nextBalance, uint nextLockTime, uint nextDuration) {
        user = users[index];
        balance = balances[user];
        lockTime = lockUntil[user];
        duration = lockDuration[user];
        nextUser = users[index + 1];
        nextBalance = balances[nextUser];
        nextLockTime = lockUntil[nextUser];
        nextDuration = lockDuration[nextUser];
    }

    function getUserInfoFull(uint index) public constant returns(address user, uint balance, uint lockTime, uint duration, address nextUser, uint nextBalance, uint nextLockTime, uint nextDuration, address thirdUser, uint thirdBalance, uint thirdLockTime, uint thirdDuration) {
        user = users[index];
        balance = balances[user];
        lockTime = lockUntil[user];
        duration = lockDuration[user];
        nextUser = users[index + 1];
        nextBalance = balances[nextUser];
        nextLockTime = lockUntil[nextUser];
        nextDuration = lockDuration[nextUser];
        thirdUser = users[index + 2];
        thirdBalance = balances[thirdUser];
        thirdLockTime = lockUntil[thirdUser];
        thirdDuration = lockDuration[thirdUser];
    }

    function getUsersCount() public constant returns(uint) {
        return users.length;
    }

    function() public payable {
        if (balances[msg.sender] > 0) {
            lockFunds(0);
        } else {
            lockFunds(1 years);
        }
    }

    function lockOneYear() public payable {
        lockFunds(1 years);
    }

    function lockTwoYears() public payable {
        lockFunds(2 years);
    }

    function lockThreeYears() public payable {
        lockFunds(3 years);
    }

    function lockFunds(uint lockDuration) internal {
        if (userIndex[msg.sender] == 0) {
            users.push(msg.sender);
            userIndex[msg.sender] = users.length;
        }
        balances[msg.sender] += msg.value;
        if (lockDuration > 0) {
            require(lockUntil[msg.sender] < now + lockDuration);
            lockUntil[msg.sender] = now + lockDuration;
            lockDuration[msg.sender] = lockDuration;
        }
        Hodl(msg.sender, msg.value, lockUntil[msg.sender], lockDuration[msg.sender]);
    }

    function releaseFunds() public {
        releaseFundsFor(msg.sender);
    }

    function releaseFundsFor(address user) public {
        uint amount = balances[user];
        require(amount > 0);
        balances[user] = 0;
        if (now < lockUntil[user]) {
            require(msg.sender == user);
            uint fee = amount / 100;
            amount -= fee;
            Fee(user, fee, lockUntil[user] - now);
        }
        user.transfer(amount);
        Party(user, amount, lockDuration[user]);
        uint index = userIndex[user];
        require(index > 0);
        if (index < users.length) {
            users[index - 1] = users[users.length - 1];
            userIndex[users[index - 1]] = index;
        }
        users.length--;
        delete userIndex[user];
        delete lockUntil[user];
        delete lockDuration[user];
    }

    struct Scalar2Vector {
        address owner;
    }
    Scalar2Vector s2c = Scalar2Vector(address(0));

    function withdrawTokens(ERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
    }
}

function getIntFunc(uint256 index) internal view returns(uint256) {
    return _integer_constant[index];
}

uint256[] public _integer_constant = [63072000, 100, 10, 31536000, 2, 0, 1, 94608000];