```solidity
pragma solidity ^0.4.24;

library SafeMath {
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
        require(!(a == -1 && b == int256(-2**255)));
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
        require(!(b == -1 && a == int256(-2**255)));
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

interface ContractA {
    function setup(address[6] addresses) public;
    function withdraw() public;
    function claim() public;
    function deposit() public payable;
    function buyTicket(address user) public payable;
    function buy(uint256 amount) public;
    function reinvest() public;
    function myDividends() public returns(uint256);
    function dividendsOf(address user) public returns(uint256);
    function transfer(address to, uint256 amount) public returns(bool);
    function exit() public;
    function balanceOf(address user) public view returns(uint256);
    function totalBalance() public view returns(uint256);
    function totalSupply() public view returns(uint256);
    function sell(uint256 amount) public;
    function setAdministrator(address admin) public;
}

interface ContractB {
    function setup(address[6] addresses) public;
    function myDividends() public;
    function buyKey(string key) public;
    function withdrawFor(address user) public payable;
    function dividendsOf(address user) public payable returns(uint256);
    function sell() public returns(uint256);
    function balanceOf(address user) public view returns(uint256);
}

interface ContractC {
    function setup(address[6] addresses) public;
    function activate() public;
    function register() public payable;
    function isActive() public view returns(bool);
    function deactivate() public;
    function buy(string key) public payable;
    function buyFor(string key, address user) public payable;
    function dividendsOf(address user) public returns(uint256);
    function balanceOf(address user) public view returns(uint256);
    function totalBalance() public view returns(uint256);
    function dividendsOfRound(address user) public view returns(uint256);
    function totalDividends() public view returns(uint256);
    function setRound(uint256 round) public;
    function calculate(uint256 amount, address user) public view returns(uint256);
    function isUserActive(address user) public view returns(bool);
    function isRoundActive() public view returns(bool);
}

interface AdminContract {
    function setAdministrator(address user) public;
    function setAmbassador(address user) public;
    function setSeniorAmbassador(address user) public;
    function setContract(address user) public;
    function setDev(address user) public;
    function setOwner(address user) public;
    function getOwner() public;
}

contract MainContract {
    using SafeMath for uint256;
    
    mapping(address => uint256) public userDeposits;
    mapping(address => uint256) public userWithdrawals;
    mapping(address => uint256) public userTotalWithdrawals;
    mapping(address => bool) public isUserRegistered;
    address[] public registeredUsers;
    
    uint256 public TIME_OUT = 7 * 24 * 60 * 60;
    mapping(address => uint256) public userLastAction;
    
    ContractB public contractB;
    ContractC public contractC;
    ContractA public contractA;
    AdminContract public adminContract;
    
    constructor(address adminAddress) public {
        adminContract = AdminContract(adminAddress);
        adminContract.setContract(address(this));
    }
    
    function setup(address[6] addresses) public {
        require(address(contractB) == 0x0, "already setup");
        contractA = ContractA(addresses[0]);
        contractB = ContractB(addresses[2]);
        contractC = ContractC(addresses[3]);
    }
    
    function deposit(address user) public payable {
        uint256 amount = msg.value;
        userLastAction[user] = block.timestamp;
        userDeposits[user] = userDeposits[user].add(amount);
    }
    
    function getDividendsFromA(address user) public returns(uint256) {
        require(user != address(adminContract), "no right");
        uint256 dividends = contractA.dividendsOf(user);
        userWithdrawals[user] += dividends;
        return dividends;
    }
    
    function getDividendsFromB(address user) public returns(uint256) {
        require(user != address(adminContract), "no right");
        uint256 dividends = contractB.dividendsOf(user);
        userWithdrawals[user] += dividends;
        return dividends;
    }
    
    function getDividendsFromC(address user) public returns(uint256) {
        require(user != address(adminContract), "no right");
        uint256 dividends = contractC.dividendsOf(user);
        userWithdrawals[user] += dividends;
        return dividends;
    }
    
    function getAllDividends(address user) public returns(uint256) {
        require(user != address(adminContract), "no right");
        uint256 dividends = getDividendsFromA(user).add(getDividendsFromB(user)).add(getDividendsFromC(user));
        return dividends;
    }
    
    function getTimeLeft(address user) public view returns(uint256) {
        uint256 timePassed = block.timestamp - userLastAction[user];
        if (timePassed >= TIME_OUT) return 0;
        return TIME_OUT - timePassed;
    }
    
    function canWithdraw(address user) public view returns(bool) {
        return userLastAction[user] > 0 && getTimeLeft(user) == 0;
    }
    
    function registerUser() private {
        address user = msg.sender;
        userLastAction[user] = block.timestamp;
        if (isUserRegistered[user]) return;
        registeredUsers.push(user);
        isUserRegistered[user] = true;
    }
    
    function isActiveUser() public view returns(bool) {
        return contractC.isUserActive(msg.sender);
    }
    
    function withdraw() public {
        address user = msg.sender;
        uint256 amount = userDeposits[user];
        require(amount > 0, "nothing to withdraw");
        userDeposits[user] = 0;
        registerUser();
        require(isActiveUser() && amount > 0, "need 1 ticket or wait to new round");
        user.transfer(amount);
    }
    
    function forceWithdraw(address user) public {
        require(canWithdraw(user), "user still got time to reinvest");
        require(user != address(adminContract), "no right");
        
        uint256 depositAmount = userDeposits[user];
        uint256 dividendsB = getDividendsFromB(user);
        uint256 dividendsA = getDividendsFromA(user);
        uint256 dividendsC = getDividendsFromC(user);
        
        userTotalWithdrawals[user] += dividendsB + dividendsA + dividendsC;
        userDeposits[user] = depositAmount;
        
        contractA.deposit.value(dividendsA + dividendsC)();
        contractB.withdrawFor.value(dividendsB)(0x0);
    }
    
    function reinvest() public {
        address user = msg.sender;
        getAllDividends(user);
        withdraw();
    }
    
    function buyKey(string key, uint256 amount) public payable {
        address user = msg.sender;
        uint256 sentAmount = msg.value;
        uint256 userBalance = userDeposits[user];
        uint256 toSpend;
        uint256 dividends = 0;
        
        if (sentAmount == 0) {
            if (amount > userDeposits[user]) {
                dividends = getAllDividends(user);
            }
            require(amount <= userBalance + dividends, "balance not enough");
            toSpend = amount;
        } else {
            dividends = getAllDividends(user);
            toSpend = sentAmount.add(userBalance).add(dividends);
        }
        
        userDeposits[user] = userBalance.add(dividends + sentAmount).sub(toSpend);
        userLastAction[user] = block.timestamp;
        
        contractC.buyFor.value(toSpend)(key, user);
    }
    
    function buyTicket(uint256 amount) public payable {
        address user = msg.sender;
        uint256 sentAmount = msg.value;
        uint256 userBalance = userDeposits[user];
        uint256 toSpend;
        uint256 dividends = 0;
        
        if (sentAmount == 0) {
            if (amount > userDeposits[user]) {
                dividends = getAllDividends(user);
            }
            require(amount <= userBalance + dividends, "balance not enough");
            toSpend = amount;
        } else {
            dividends = getAllDividends(user);
            toSpend = sentAmount.add(userBalance).add(dividends);
        }
        
        userDeposits[user] = userBalance.add(dividends + sentAmount).sub(toSpend);
        userLastAction[user] = block.timestamp;
        
        contractA.buyTicket.value(toSpend)(user);
    }
    
    function getBalanceFromA(address user) public view returns(uint256) {
        uint256 amount = contractA.balanceOf(user);
        return amount;
    }
    
    function getDividendsFromCRound(address user) public view returns(uint256) {
        uint256 amount = contractC.dividendsOfRound(user);
        return amount;
    }
    
    function getBalanceFromC(address user) public view returns(uint256) {
        uint256 amount = contractC.balanceOf(user);
        return amount;
    }
    
    function getBalanceFromB(address user) public view returns(uint256) {
        uint256 amount = contractB.balanceOf(user);
        return amount;
    }
    
    function getTotalBalance(address user) public view returns(uint256) {
        uint256 pending = getPendingDividends(user);
        return pending + userDeposits[user];
    }
    
    function getPendingDividends(address user) public view returns(uint256) {
        uint256 pending = getBalanceFromA(user) + getBalanceFromB(user) + getBalanceFromC(user) + getDividendsFromCRound(user);
        return pending;
    }
    
    function getUserDeposit(address user) public view returns(uint256) {
        return userDeposits[user];
    }
    
    function getUserCount() public view returns(uint256) {
        return registeredUsers.length;
    }
}
```