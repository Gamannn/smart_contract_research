pragma solidity ^0.4.25;

contract ParticipantManager {
    event ParticipantAdded(address participant);
    event ParticipantRemoved(address participant);
    event ReferrerAdded(address referrer, address participant);

    mapping(address => address) public participantContracts;
    mapping(address => bool) public referrers;

    address public owner;

    constructor(address _owner) public {
        owner = _owner;
    }

    function () external payable {
        if (participantContracts[msg.sender] == address(0)) {
            registerParticipant(msg.sender, address(0));
        } else {
            require(msg.value == 0, "0 ether to manually make a payment");
            processPayment(msg.sender);
        }
    }

    function registerParticipant(address participant, address referrer) payable public {
        require(participantContracts[participant] == address(0), "This participant is already registered");
        require(msg.value >= 0.45 ether && msg.value <= 225 ether, "Deposit should be between 0.45 ether and 225 ether (45 days)");

        participantContracts[participant] = address(new ParticipantContract(participant, msg.value / 45));
        processPayment(participant);

        owner.send(msg.value / 20);

        if (referrer != address(0) && referrers[referrer]) {
            referrer.send(msg.value / 20);
        }

        emit ParticipantAdded(participant);
    }

    function addReferrer(address referrer) public {
        require(!referrers[referrer], "This address is already a referrer");
        referrers[referrer] = true;

        ReferrerContract referrerContract = new ReferrerContract(address(this));
        referrerContract.setReferrer(referrer);

        emit ReferrerAdded(address(referrerContract), referrer);
    }

    function processPayment(address participant) public {
        ParticipantContract participantContract = ParticipantContract(participantContracts[participant]);
        bool paymentProcessed = participantContract.processPayment.value(participantContract.paymentAmount())();

        if (paymentProcessed) {
            participantContracts[participant] = address(0);
            emit ParticipantRemoved(participant);
        }
    }
}

contract ReferrerContract {
    address public manager;
    address public referrer;

    constructor(address _manager) public {
        manager = _manager;
    }

    function setReferrer(address _referrer) external {
        require(referrer == address(0), "Referrer can only be set once");
        referrer = _referrer;
    }

    function () external payable {
        if (msg.value > 0) {
            ParticipantManager(manager).registerParticipant.value(msg.value)(msg.sender, referrer);
        } else {
            ParticipantManager(manager).processPayment(msg.sender);
        }
    }
}

contract ParticipantContract {
    address public participant;
    uint public paymentAmount;

    constructor(address _participant, uint _paymentAmount) public {
        participant = _participant;
        paymentAmount = _paymentAmount;
    }

    function () external payable {}

    function processPayment() external payable returns (bool) {
        require(msg.value == paymentAmount, "Invalid payment amount");

        uint previousBalance;
        uint newBalance;

        (, previousBalance, ) = PaymentValidator(manager).getUserData(address(this));
        manager.call.value(msg.value)();
        (, newBalance, ) = PaymentValidator(manager).getUserData(address(this));

        require(newBalance != previousBalance, "Payment rejected, too soon or not enough ether");

        participant.send(address(this).balance);
        return newBalance == 45;
    }
}

contract PaymentValidator {
    struct User {
        uint paymentAmount;
        uint balance;
        uint lastPayment;
    }

    mapping(address => User) public getUserData;

    struct ContractData {
        uint256 paymentAmount;
        address participant;
        address manager;
        address referrer;
        address owner;
    }

    ContractData public contractData = ContractData(0, address(0), 0xe0ae35fe7Df8b86eF08557b535B89bB6cb036C23, address(0), address(0));
}