pragma solidity ^0.4.20;

contract TokenContract {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public tokenReward;
    address public owner;
    mapping(address => uint256) public balanceOf;
    uint256 public startTime;
    uint256 public endTime;
    string public status;
    uint256 public transferLock;

    event TokenBurn(address indexed from, uint256 value);
    event Deposit(address from, uint256 value);
    event ChangeOwner(string newOwner);
    event ChangeStatus(string newStatus);
    event ChangeName(string newName);
    event ChangeSymbol(string newSymbol);
    event ChangeTokenReward(uint256 newReward);
    event ChangeTimeStamp(uint256 newStartTime, uint256 newEndTime);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function TokenContract() public {
        name = "GMB";
        symbol = "MAS";
        decimals = 18;
        totalSupply = 10 ** uint256(decimals) * 10000000000;
        status = "Private";
        startTime = 1514732400;
        endTime = 1546268399;
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        transferLock = 1;
    }

    function () payable public {
        require(now >= startTime && now <= endTime);
        uint256 amount = msg.value * tokenReward;
        require(balanceOf[owner] >= amount);
        require(balanceOf[msg.sender] + amount >= balanceOf[msg.sender]);
        balanceOf[owner] -= amount;
        balanceOf[msg.sender] += amount;
        emit Transfer(owner, msg.sender, amount);
    }

    function transfer(address to, uint256 value) public {
        require(transferLock == 0);
        require(balanceOf[msg.sender] >= value);
        require(balanceOf[to] + value >= balanceOf[to]);
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
    }

    function transferFrom(address from, address to, uint256 value) public {
        require(balanceOf[from] >= value);
        require(balanceOf[to] + value >= balanceOf[to]);
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    function burn(uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;
        totalSupply -= value;
        emit TokenBurn(msg.sender, value);
        return true;
    }

    function mint(uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] += value;
        totalSupply += value;
        emit TokenBurn(msg.sender, value);
        return true;
    }

    function changeName(string newName) public returns (bool success) {
        name = newName;
        emit ChangeName(newName);
        return true;
    }

    function changeSymbol(string newSymbol) public returns (bool success) {
        symbol = newSymbol;
        emit ChangeSymbol(newSymbol);
        return true;
    }

    function changeStatus(string newStatus) public returns (bool success) {
        status = newStatus;
        emit ChangeStatus(newStatus);
        return true;
    }

    function changeTokenReward(uint256 newReward) public returns (bool success) {
        tokenReward = newReward;
        emit ChangeTokenReward(newReward);
        return true;
    }

    function changeTimeStamp(uint256 newStartTime, uint256 newEndTime) public returns (bool success) {
        startTime = newStartTime;
        endTime = newEndTime;
        emit ChangeTimeStamp(newStartTime, newEndTime);
        return true;
    }

    function changeOwner(address newOwner) public returns (bool success) {
        owner = newOwner;
        emit ChangeOwner("Owner changed");
        return true;
    }

    function setTransferLock(uint256 lock) public returns (bool success) {
        transferLock = lock;
        return true;
    }
}