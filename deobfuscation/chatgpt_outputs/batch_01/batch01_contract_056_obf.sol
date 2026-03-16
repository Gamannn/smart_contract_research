pragma solidity ^0.4.15;

contract EthereumLottery {
    function admin() constant returns (address);
    function needsInitialization() constant returns (bool);
    function initLottery(uint _jackpot, uint _numTickets, uint _ticketPrice);
}

contract LotteryAdmin {
    event Deposit(address indexed sender, uint amount);

    struct LotteryState {
        uint256 nextProfile;
        uint256 lastAllowancePaymentTimestamp;
        uint256 dailyAdminAllowance;
        address ethereumLottery;
        address proposedOwner;
        address admin;
        address owner;
    }

    LotteryState private state;

    modifier onlyOwner {
        require(msg.sender == state.owner);
        _;
    }

    modifier onlyAdminOrOwner {
        require(msg.sender == state.owner || msg.sender == state.admin);
        _;
    }

    function LotteryAdmin(address _ethereumLottery) {
        state.owner = msg.sender;
        state.admin = msg.sender;
        state.ethereumLottery = _ethereumLottery;
        state.dailyAdminAllowance = 50 finney;
    }

    function () payable {
        Deposit(msg.sender, msg.value);
    }

    function allowsAllowance() constant returns (bool) {
        return now - state.lastAllowancePaymentTimestamp >= 24 hours;
    }

    function requestAllowance() onlyAdminOrOwner {
        require(allowsAllowance());
        state.lastAllowancePaymentTimestamp = now;
        state.admin.transfer(state.dailyAdminAllowance);
    }

    function needsInitialization() constant returns (bool) {
        if (EthereumLottery(state.ethereumLottery).admin() != address(this)) {
            return false;
        }
        return EthereumLottery(state.ethereumLottery).needsInitialization();
    }

    function initLottery(uint _nextProfile, uint _jackpot, uint _numTickets, uint _ticketPrice) onlyAdminOrOwner {
        state.nextProfile = _nextProfile;
        EthereumLottery(state.ethereumLottery).initLottery(_jackpot, _numTickets, _ticketPrice);
    }

    function withdraw(uint amount) onlyOwner {
        state.owner.transfer(amount);
    }

    function setConfiguration(uint _dailyAdminAllowance) onlyOwner {
        state.dailyAdminAllowance = _dailyAdminAllowance;
    }

    function setLottery(address _ethereumLottery) onlyOwner {
        state.ethereumLottery = _ethereumLottery;
    }

    function setAdmin(address _admin) onlyOwner {
        state.admin = _admin;
    }

    function proposeOwner(address _owner) onlyOwner {
        state.proposedOwner = _owner;
    }

    function acceptOwnership() {
        require(state.proposedOwner != 0);
        require(msg.sender == state.proposedOwner);
        state.owner = state.proposedOwner;
    }

    function destruct() onlyOwner {
        selfdestruct(state.owner);
    }
}