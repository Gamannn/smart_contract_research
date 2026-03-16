pragma solidity ^0.4.24;

library MathLibrary {
    function multiply(uint256 a, uint256 b) internal pure returns (uint256 result) {
        if (a == 0) {
            return 0;
        }
        result = a * b;
        assert(result / a == b);
        return result;
    }

    function divide(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function subtract(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 result) {
        result = a + b;
        assert(result >= a);
        return result;
    }

    function sqrt(uint256 x) internal pure returns (uint256 result) {
        uint256 z = (add(x, 1)) / 2;
        result = x;
        while (z < result) {
            result = z;
            z = (add((x / z), z)) / 2;
        }
    }

    function square(uint256 x) internal pure returns (uint256) {
        return multiply(x, x);
    }

    function power(uint256 base, uint256 exponent) internal pure returns (uint256) {
        if (base == 0) return 0;
        else if (exponent == 0) return 1;
        else {
            uint256 result = base;
            for (uint256 i = 1; i < exponent; i++) {
                result = multiply(result, base);
            }
            return result;
        }
    }
}

contract Wallet {
    using MathLibrary for *;

    event BalanceRecharge(address indexed user, uint256 amount, uint64 timestamp);
    event BalanceWithdraw(address indexed user, uint256 amount, bytes data, uint64 timestamp);

    mapping(address => uint) public balances;
    mapping(address => uint) public withdrawals;

    modifier onlyOwner() {
        require(config.owner == msg.sender, "Only owner can operate.");
        _;
    }

    modifier onlyAdmin() {
        require(config.admin == msg.sender, "Only admin can operate.");
        _;
    }

    modifier serviceOpen() {
        require(config.serviceOpen == true, "The service is closed.");
        _;
    }

    struct Config {
        address gameAddress;
        address admin;
        address owner;
        bool serviceOpen;
        uint256 minRecharge;
        uint256 minWithdraw;
        string contractName;
        string contractSymbol;
    }

    Config config = Config(address(0), address(0), address(0), true, 0.1 ether, 0.1 ether, "Wallet", "WLT");

    constructor(address adminAddress) public {
        config.owner = msg.sender;
        config.admin = adminAddress;
    }

    function recharge() public payable serviceOpen {
        require(msg.value >= config.minRecharge, "The minimum recharge amount does not meet the requirements.");
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        emit BalanceRecharge(msg.sender, msg.value, uint64(now));
    }

    function() public payable serviceOpen {
        require(msg.sender == config.gameAddress, "Only receive ETH from game address");
    }

    function setGameAddress(address gameAddress) public onlyAdmin {
        config.gameAddress = gameAddress;
    }

    function withdraw(address to, uint amount, bytes data) public onlyAdmin serviceOpen {
        require(address(this).balance >= amount, "Insufficient balance.");
        to.transfer(amount);
        withdrawals[to] = withdrawals[to].add(amount);
        emit BalanceWithdraw(to, amount, data, uint64(now));
    }

    function withdrawToOwner(uint amount) public onlyAdmin {
        require(address(this).balance >= amount, "Insufficient balance.");
        config.owner.transfer(amount);
    }

    function setMinAmounts(uint minRecharge, uint minWithdraw) public onlyAdmin {
        config.minRecharge = minRecharge;
        config.minWithdraw = minWithdraw;
    }

    function setServiceOpen(bool open) public onlyAdmin {
        config.serviceOpen = open;
    }

    function changeOwner(address newOwner) public onlyOwner {
        config.owner = newOwner;
    }

    function changeAdmin(address newAdmin) public onlyOwner {
        config.admin = newAdmin;
    }
}