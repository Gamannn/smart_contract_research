pragma solidity ^0.4.15;

contract EthereumLottery {
    function admin() constant returns (address);
    function needsInitialization() constant returns (bool);
    function initLottery(uint _jackpot, uint _numTickets, uint _ticketPrice);
}

contract LotteryAdmin {
    event Deposit(address indexed sender, uint amount);

    modifier onlyOwner {
        require(msg.sender == storageData.owner);
        _;
    }

    modifier onlyAdminOrOwner {
        require(msg.sender == storageData.owner || msg.sender == storageData.admin);
        _;
    }

    struct Storage {
        uint256 nextProfile;
        uint256 lastAllowancePaymentTimestamp;
        uint256 dailyAdminAllowance;
        address ethereumLottery;
        address proposedOwner;
        address admin;
        address owner;
    }

    Storage storageData;

    function LotteryAdmin(address _ethereumLottery) {
        storageData.owner = msg.sender;
        storageData.admin = msg.sender;
        storageData.ethereumLottery = _ethereumLottery;
        storageData.dailyAdminAllowance = 50 finney;
    }

    function () payable {
        Deposit(msg.sender, msg.value);
    }

    function allowsAllowance() constant returns (bool) {
        return now - storageData.lastAllowancePaymentTimestamp >= 24 hours;
    }

    function requestAllowance() onlyAdminOrOwner {
        require(allowsAllowance());
        storageData.lastAllowancePaymentTimestamp = now;
        storageData.admin.transfer(storageData.dailyAdminAllowance);
    }

    function needsInitialization() constant returns (bool) {
        if (EthereumLottery(storageData.ethereumLottery).admin() != address(this)) {
            return false;
        }
        return EthereumLottery(storageData.ethereumLottery).needsInitialization();
    }

    function initLottery(uint _nextProfile, uint _jackpot, uint _numTickets, uint _ticketPrice) onlyAdminOrOwner {
        storageData.nextProfile = _nextProfile;
        EthereumLottery(storageData.ethereumLottery).initLottery(_jackpot, _numTickets, _ticketPrice);
    }

    function withdraw(uint amount) onlyOwner {
        storageData.owner.transfer(amount);
    }

    function setConfiguration(uint _dailyAdminAllowance) onlyOwner {
        storageData.dailyAdminAllowance = _dailyAdminAllowance;
    }

    function setLottery(address _ethereumLottery) onlyOwner {
        storageData.ethereumLottery = _ethereumLottery;
    }

    function setAdmin(address _admin) onlyOwner {
        storageData.admin = _admin;
    }

    function proposeOwner(address _owner) onlyOwner {
        storageData.proposedOwner = _owner;
    }

    function acceptOwnership() {
        require(storageData.proposedOwner != 0);
        require(msg.sender == storageData.proposedOwner);
        storageData.owner = storageData.proposedOwner;
    }

    function destruct() onlyOwner {
        selfdestruct(storageData.owner);
    }
}