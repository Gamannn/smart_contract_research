pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
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

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = ((add(x, 1)) / 2);
        y = x;
        while (z < y) {
            y = z;
            z = ((add((x / z), z)) / 2);
        }
    }

    function square(uint256 x) internal pure returns (uint256) {
        return (mul(x, x));
    }

    function power(uint256 base, uint256 exponent) internal pure returns (uint256) {
        if (base == 0) return (0);
        else if (exponent == 0) return (1);
        else {
            uint256 result = base;
            for (uint256 i = 1; i < exponent; i++) {
                result = mul(result, base);
            }
            return (result);
        }
    }
}

contract Wallet {
    using SafeMath for *;

    event BalanceRecharge(address indexed user, uint256 amount, uint64 timestamp);
    event BalanceWithdraw(address indexed user, uint256 amount, bytes data, uint64 timestamp);

    mapping(address => uint) public userBalance;
    mapping(address => uint) public userWithdrawn;

    modifier onlyOwner() {
        require(config.owner == msg.sender, "Only owner can operate.");
        _;
    }

    modifier onlyOperator() {
        require(config.operator == msg.sender, "Only operator can operate.");
        _;
    }

    modifier serviceOpen() {
        require(config.serviceOpen == true, "The service is closed.");
        _;
    }

    constructor(address operatorAddress) public {
        config.owner = msg.sender;
        config.operator = operatorAddress;
    }

    function recharge() public payable serviceOpen {
        require(msg.value >= config.minRechargeAmount, "The minimum recharge amount does not meet the requirements.");
        userBalance[msg.sender] = userBalance[msg.sender].add(msg.value);
        emit BalanceRecharge(msg.sender, msg.value, uint64(now));
    }

    function() public payable serviceOpen {
        require(msg.sender == config.gameAddress, "only receive eth from game address");
    }

    function setGameAddress(address gameAddress) public onlyOperator {
        config.gameAddress = gameAddress;
    }

    function withdraw(address user, uint amount, bytes data) public onlyOperator serviceOpen {
        require(address(this).balance >= amount, "Insufficient balance.");
        user.transfer(amount);
        userWithdrawn[user] = userWithdrawn[user].add(amount);
        emit BalanceWithdraw(user, amount, data, uint64(now));
    }

    function withdrawOwner(uint amount) public onlyOperator {
        require(address(this).balance >= amount, "Insufficient balance.");
        config.owner.transfer(amount);
    }

    function setConfig(uint minRechargeAmount, uint maxWithdrawAmount) public onlyOperator {
        config.minRechargeAmount = minRechargeAmount;
        config.maxWithdrawAmount = maxWithdrawAmount;
    }

    function setServiceOpen(bool isOpen) public onlyOperator {
        config.serviceOpen = isOpen;
    }

    function setOwner(address ownerAddress) public onlyOwner {
        config.owner = ownerAddress;
    }

    function setOperator(address operatorAddress) public onlyOwner {
        config.operator = operatorAddress;
    }

    struct Config {
        address gameAddress;
        address operator;
        address owner;
        bool serviceOpen;
        uint256 maxWithdrawAmount;
        uint256 minRechargeAmount;
        string contractName;
        string contractVersion;
    }

    Config config = Config(address(0), address(0), address(0), true, 0.1 ether, 0.1 ether, "Wallet", "Wallet");
}