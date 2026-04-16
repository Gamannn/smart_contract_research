pragma solidity ^0.4.18;

contract ExternalContract {
    function addUser(address user) external;
    function removeUser(address user) external;
    function updateBalance(uint amount, address user, uint value) external;
    function decreaseBalance(uint amount, address user, uint value) external;
    function getBalance(uint amount, address user) public view returns (uint balance);
    function getUserBalance(uint userId) public view returns (uint balance);
    function resetUserBalance(uint userId) external;
    function getUserAddress(address user, address referrer) external returns (address userAddress);
    function calculateFee(uint amount, uint value) public view returns (uint fee);
    function applyFee(uint amount, uint value) external;
    function executeTransaction(address user, uint param1, uint param2, uint param3) external;
    function getUserFee(address user) public view returns (uint fee);
    function getUserDiscount(address user) public view returns (uint discount);
    function isUserActive(address user) public view returns (bool isActive);
    function getUserId(uint userId) public view returns (uint id);
    function getUserValue(uint userId) public view returns (uint value);
    function getUserLimit(uint userId) public view returns (uint limit);
    function getUserThreshold(uint userId) public view returns (uint threshold);
    function getUserRate(uint userId) public view returns (uint rate);
    function updateUser(uint userId, uint param1, uint param2, uint param3, uint param4) external;
    function updateUserAddress(address user, uint value) external;
    function getUserTransaction(address user) public view returns (uint transaction);
}

contract MainContract {
    event UserAdded(address user, uint userId);
    event UserUpdated(address user, uint userId, uint value);
    event UserRemoved(address user);

    ExternalContract externalContract;

    struct Config {
        address admin;
        address pendingAdmin;
        uint256 discountRate;
        uint256 param1;
        uint256 param2;
        uint256 param3;
        uint256 param4;
    }

    Config config = Config(address(0), address(0), 50, 3, 50, 10, 10);

    function MainContract() public {
        config.admin = msg.sender;
    }

    function addUser(uint userId, address referrer) public payable {
        uint fee = externalContract.getUserBalance(userId);
        require(fee > 0);
        fee = fee * calculateDiscount(msg.sender) / 10000;
        require(msg.value >= fee);
        uint refund = msg.value - fee;
        externalContract.resetUserBalance(userId);
        externalContract.updateBalance(userId, msg.sender, 1);
        externalContract.addUser(msg.sender);
        externalContract.removeUser(msg.sender);
        UserAdded(msg.sender, userId);
        address userAddress = externalContract.getUserAddress(msg.sender, referrer);
        if (userAddress != address(0)) {
            userAddress.transfer(fee * config.param4 / 100);
        }
        msg.sender.transfer(refund);
    }

    function updateUser(uint userId, uint value, address referrer) public payable {
        require(externalContract.getUserBalance(userId) > 0);
        uint fee = externalContract.calculateFee(userId, value);
        fee = fee * calculateDiscount(msg.sender) / 10000;
        require(msg.value >= fee);
        uint refund = msg.value - fee;
        externalContract.applyFee(userId, value);
        externalContract.updateBalance(userId, msg.sender, value);
        externalContract.addUser(msg.sender);
        externalContract.removeUser(msg.sender);
        UserUpdated(msg.sender, userId, value);
        address userAddress = externalContract.getUserAddress(msg.sender, referrer);
        if (userAddress != address(0)) {
            uint commission = fee * config.param4 / 100;
            externalContract.updateUserAddress(userAddress, commission);
            userAddress.transfer(commission);
        }
        msg.sender.transfer(refund);
    }

    function executeTransaction() public {
        externalContract.executeTransaction(msg.sender, config.param1, config.param2, config.param3);
        externalContract.addUser(msg.sender);
        UserRemoved(msg.sender);
    }

    function calculateDiscount(address user) public view returns (uint discount) {
        discount = 10000;
        if (!externalContract.isUserActive(user)) {
            discount = discount * (100 - config.discountRate) / 100;
        }
        uint userFee = externalContract.getUserFee(user);
        if (userFee > 0) {
            discount = discount * (100 - userFee) / 100;
        }
    }

    function getUserInfo(address user) public view returns (
        uint userFee,
        uint userDiscount,
        bool isActive,
        uint discountRate,
        uint param1,
        uint param2,
        uint param3,
        uint param4,
        uint userTransaction
    ) {
        userFee = externalContract.getUserFee(user);
        userDiscount = externalContract.getUserDiscount(user);
        isActive = externalContract.isUserActive(user);
        discountRate = config.discountRate;
        param1 = config.param1;
        param2 = config.param2;
        param3 = config.param3;
        param4 = config.param4;
        userTransaction = externalContract.getUserTransaction(user);
    }

    function getUserInfo() public view returns (
        uint userFee,
        uint userDiscount,
        bool isActive,
        uint discountRate,
        uint param1,
        uint param2,
        uint param3,
        uint param4,
        uint userTransaction
    ) {
        return getUserInfo(msg.sender);
    }

    function getUserDetails(uint userId, address user) public view returns (
        uint balance,
        uint id,
        uint value,
        uint limit,
        uint threshold,
        uint rate,
        uint transaction
    ) {
        balance = externalContract.getBalance(userId, user);
        id = externalContract.getUserId(userId);
        value = externalContract.getUserValue(userId);
        limit = externalContract.getUserLimit(userId);
        threshold = externalContract.getUserThreshold(userId);
        rate = externalContract.getUserRate(userId);
        transaction = externalContract.getUserTransaction(user);
    }

    function updateUser(uint userId, uint param1, uint param2, uint param3, uint param4) public onlyAdmin {
        externalContract.updateUser(userId, param1, param2, param3, param4);
    }

    function updateParam4(uint value) external onlyAdmin {
        config.param4 = value;
    }

    function updateParam3(uint value) public onlyAdmin {
        config.param3 = value;
    }

    function updateParam2(uint value) public onlyAdmin {
        config.param2 = value;
    }

    function updateParam1(uint value) public onlyAdmin {
        config.param1 = value;
    }

    function updateDiscountRate(uint value) public onlyAdmin {
        config.discountRate = value;
    }

    function transferBalance(address to) public onlyAdmin {
        transferFunds(to, this.balance);
    }

    function transferFunds(address to, uint amount) public onlyAdmin {
        require(to != address(0));
        if (amount > this.balance) {
            to.transfer(this.balance);
        } else {
            to.transfer(amount);
        }
    }

    function updateExternalContract(address newContract) public onlyAdmin {
        if (newContract != address(0)) {
            externalContract = ExternalContract(newContract);
        }
    }

    modifier onlyAdmin() {
        require(msg.sender == config.admin);
        _;
    }

    function updatePendingAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0));
        config.pendingAdmin = newAdmin;
    }

    function acceptAdminRole() public {
        require(msg.sender == config.pendingAdmin);
        require(config.pendingAdmin != address(0));
        config.admin = config.pendingAdmin;
        config.pendingAdmin = address(0);
    }
}