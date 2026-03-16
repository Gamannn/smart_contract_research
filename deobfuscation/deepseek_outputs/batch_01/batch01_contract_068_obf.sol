pragma solidity ^0.4.25;

contract MainContract {
    event ParticipantAdded(address participant);
    event ParticipantRemoved(address participant);
    event ReferrerAdded(address referrerContract, address referrer);

    mapping(address => address) public participantContracts;
    mapping(address => bool) public isReferrer;

    address public owner;

    constructor(address _owner) public {
        owner = _owner;
    }

    function() external payable {
        if (participantContracts[msg.sender] == address(0)) {
            registerParticipant(msg.sender, address(0));
        } else {
            require(msg.value == 0, "0 ether to manually make a daily payment");
            makeDailyPayment(msg.sender);
        }
    }

    function registerParticipant(address participant, address referrer) payable public {
        require(participantContracts[participant] == address(0), "This participant is already registered");
        require(msg.value >= 0.45 ether && msg.value <= 225 ether, "Deposit should be between 0.45 ether and 225 ether (45 days)");

        participantContracts[participant] = address(new ParticipantContract(participant, msg.value / 45));
        makeDailyPayment(participant);

        owner.send(msg.value / 20);

        if (referrer != address(0) && isReferrer[referrer]) {
            referrer.send(msg.value / 20);
        }

        emit ParticipantAdded(participant);
    }

    function addReferrer(address referrer) public {
        require(!isReferrer[referrer], "This address is already a referrer");
        isReferrer[referrer] = true;

        ReferrerContract newReferrerContract = new ReferrerContract(address(this));
        newReferrerContract.setReferrer(referrer);

        emit ReferrerAdded(address(newReferrerContract), referrer);
    }

    function makeDailyPayment(address participant) public {
        ParticipantContract participantContract = ParticipantContract(participantContracts[participant]);
        bool isCompleted = participantContract.makeDailyPayment.value(participantContract.dailyAmount())();

        if (isCompleted) {
            participantContracts[participant] = address(0);
            emit ParticipantRemoved(participant);
        }
    }
}

contract ReferrerContract {
    address public mainContract;
    address public referrer;

    constructor(address _mainContract) public {
        mainContract = _mainContract;
    }

    function setReferrer(address _referrer) external {
        require(referrer == address(0), "Referrer can only be set once");
        referrer = _referrer;
    }

    function() external payable {
        if (msg.value > 0) {
            MainContract(mainContract).registerParticipant.value(msg.value)(msg.sender, referrer);
        } else {
            MainContract(mainContract).makeDailyPayment(msg.sender);
        }
    }
}

contract ParticipantContract {
    address public participant;
    uint256 public dailyAmount;

    constructor(address _participant, uint256 _dailyAmount) public {
        participant = _participant;
        dailyAmount = _dailyAmount;
    }

    function() external payable {}

    function makeDailyPayment() external payable returns (bool) {
        require(msg.value == dailyAmount, "Invalid amount");

        uint256 initialDay;
        uint256 finalDay;
        (, initialDay, ) = SmartolutionContract(0xe0ae35fe7Df8b86eF08557b535B89bB6cb036C23).users(address(this));
        
        0xe0ae35fe7Df8b86eF08557b535B89bB6cb036C23.call.value(msg.value)();
        
        (, finalDay, ) = SmartolutionContract(0xe0ae35fe7Df8b86eF08557b535B89bB6cb036C23).users(address(this));
        
        require(finalDay != initialDay, "Smartolution rejected that payment, too soon or not enough ether");
        
        participant.send(address(this).balance);
        return finalDay == 45;
    }
}

contract SmartolutionContract {
    struct User {
        uint256 balance;
        uint256 day;
        uint256 checkpoint;
    }
    
    mapping(address => User) public users;
}