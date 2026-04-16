```solidity
pragma solidity ^0.4.24;

library SafeMath {
    int256 constant INT256_MIN = -2**255;

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function mul(int256 a, int256 b) internal pure returns (int256) {
        if (a == 0) {
            return 0;
        }
        require(!(a == -1 && b == INT256_MIN));
        int256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0);
        require(!(b == -1 && a == INT256_MIN));
        int256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface IToken {
    function setup(address[6] addresses) external;
    function withdraw() external;
    function deposit() external payable;
    function transfer(address to) external payable;
    function approve(address spender, uint256 value) external;
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function mint(address to, uint256 value) external;
    function burn(address from, uint256 value) external;
}

contract TokenManager {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public allowances;
    mapping(address => uint256) public deposits;
    mapping(address => bool) public isRegistered;
    address[] public registeredAddresses;
    uint256 public constant TIMEOUT = 7 * 24 * 60 * 60;
    mapping(address => uint256) public lastDepositTime;

    IToken public token;
    IToken public anotherToken;
    IToken public yetAnotherToken;

    constructor(address tokenAddress) public {
        token = IToken(tokenAddress);
        token.setup(address(this));
    }

    function setup(address[6] addresses) public {
        require(address(token) == address(0), "already setup");
        anotherToken = IToken(addresses[2]);
        yetAnotherToken = IToken(addresses[3]);
    }

    function deposit(address user) public payable {
        uint256 amount = msg.value;
        lastDepositTime[user] = block.timestamp;
        balances[user] = balances[user].add(amount);
    }

    function withdraw(address user) public returns (uint256) {
        require(user != address(token), "no right");
        uint256 amount = token.balanceOf(user);
        allowances[user] = allowances[user].add(amount);
        return amount;
    }

    function withdrawAnotherToken(address user) public returns (uint256) {
        require(user != address(token), "no right");
        uint256 amount = anotherToken.balanceOf(user);
        allowances[user] = allowances[user].add(amount);
        return amount;
    }

    function withdrawYetAnotherToken(address user) public returns (uint256) {
        require(user != address(token), "no right");
        uint256 amount = yetAnotherToken.balanceOf(user);
        allowances[user] = allowances[user].add(amount);
        return amount;
    }

    function totalWithdraw(address user) public returns (uint256) {
        require(user != address(token), "no right");
        uint256 total = withdraw(user) + withdrawAnotherToken(user) + withdrawYetAnotherToken(user);
        return total;
    }

    function timeLeft(address user) public view returns (uint256) {
        uint256 elapsed = block.timestamp - lastDepositTime[user];
        if (elapsed >= TIMEOUT) return 0;
        return TIMEOUT - elapsed;
    }

    function canWithdraw(address user) public view returns (bool) {
        return lastDepositTime[user] > 0 && timeLeft(user) == 0;
    }

    function register() private {
        address user = msg.sender;
        lastDepositTime[user] = block.timestamp;
        if (isRegistered[user]) return;
        registeredAddresses.push(user);
        isRegistered[user] = true;
    }

    function isRegisteredUser() public view returns (bool) {
        return yetAnotherToken.isRegistered(msg.sender);
    }

    function executeWithdrawal() public {
        address user = msg.sender;
        uint256 amount = balances[user];
        require(amount > 0, "nothing to withdraw");
        balances[user] = 0;
        register();
        require(isRegisteredUser() && amount > 0, "need 1 ticket or wait to new round");
        user.transfer(amount);
    }

    function claim(address user) public {
        require(canWithdraw(user), "still got time to claim");
        require(user != address(token), "no right");
        uint256 balance = balances[user];
        uint256 anotherBalance = withdrawAnotherToken(user);
        uint256 yetAnotherBalance = withdrawYetAnotherToken(user);
        deposits[user] = deposits[user].add(anotherBalance + yetAnotherBalance);
        balances[user] = balance;
        token.transfer.value(yetAnotherBalance + anotherBalance)();
        anotherToken.transfer.value(anotherBalance)(0x0);
    }

    function claim() public {
        address user = msg.sender;
        totalWithdraw(user);
        executeWithdrawal();
    }

    function depositWithMessage(string message, uint256 amount) public payable {
        address user = msg.sender;
        uint256 value = msg.value;
        uint256 balance = balances[user];
        uint256 total;
        uint256 totalWithdrawn = 0;
        if (value == 0) {
            if (amount > balances[user]) totalWithdrawn = totalWithdraw(user);
            require(amount <= balance + totalWithdrawn, "not enough balance");
            total = amount;
        } else {
            totalWithdrawn = totalWithdraw(user);
            total = value.add(balance).add(totalWithdrawn);
        }
        balances[user] = balance.add(totalWithdrawn + value).sub(total);
        lastDepositTime[user] = block.timestamp;
        yetAnotherToken.transfer.value(total)(message, user);
    }

    function deposit(uint256 amount) public payable {
        address user = msg.sender;
        uint256 value = msg.value;
        uint256 balance = balances[user];
        uint256 total;
        uint256 totalWithdrawn = 0;
        if (value == 0) {
            if (amount > balances[user]) totalWithdrawn = totalWithdraw(user);
            require(amount <= balance + totalWithdrawn, "not enough balance");
            total = amount;
        } else {
            totalWithdrawn = totalWithdraw(user);
            total = value.add(balance).add(totalWithdrawn);
        }
        balances[user] = balance.add(totalWithdrawn + value).sub(total);
        lastDepositTime[user] = block.timestamp;
        token.transfer.value(total)(user);
    }

    function getBalance(address user) public view returns (uint256) {
        uint256 balance = token.balanceOf(user);
        return balance;
    }

    function getAnotherTokenBalance(address user) public view returns (uint256) {
        uint256 balance = yetAnotherToken.balanceOf(user);
        return balance;
    }

    function getYetAnotherTokenBalance(address user) public view returns (uint256) {
        uint256 balance = yetAnotherToken.balanceOf(user);
        return balance;
    }

    function getTotalBalance(address user) public view returns (uint256) {
        uint256 total = getBalance(user) + getYetAnotherTokenBalance(user) + getAnotherTokenBalance(user) + getAnotherTokenBalance(user);
        return total;
    }

    function getDeposits(address user) public view returns (uint256) {
        return balances[user];
    }

    function getRegisteredCount() public view returns (uint256) {
        return registeredAddresses.length;
    }
}
```