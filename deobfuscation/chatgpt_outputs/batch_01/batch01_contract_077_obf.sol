```solidity
pragma solidity ^0.4.25;

contract ParticipantManager {
    event ParticipantAdded(address participant);
    event ParticipantRemoved(address participant);
    event ReferrerAdded(address referrer, address participant);

    mapping(address => address) public participantContracts;
    mapping(address => bool) public referrers;

    constructor(address initialAddress) public {
        s2c.owner = initialAddress;
    }

    function () external payable {
        if (participantContracts[msg.sender] == address(0)) {
            registerParticipant(msg.sender, address(0));
        } else {
            if (msg.value == 0) {
                processPayment(msg.sender);
            } else if (msg.value == 0.00001111 ether) {
                withdraw();
            } else {
                revert();
            }
        }
    }

    function registerParticipant(address participant, address referrer) payable public {
        require(participantContracts[participant] == address(0), "This participant is already registered");
        require(msg.value >= 0.45 ether && msg.value <= 225 ether, "Deposit should be between 0.45 ether and 225 ether (45 days)");

        participantContracts[participant] = address(new ParticipantContract(participant, msg.value / 45));
        processPayment(participant);

        s2c.owner.send(msg.value / 33);

        if (referrer != address(0) && referrers[referrer]) {
            referrer.send(msg.value / 20);
        }

        emit ParticipantAdded(participant);
    }

    function addReferrer(address referrer) public {
        require(!referrers[referrer], "This address is already a referrer");
        referrers[referrer] = true;

        ReferrerContract referrerContract = new ReferrerContract();
        referrerContract.setReferrer(referrer);
        referrerContract.setManager(address(this));

        emit ReferrerAdded(address(referrerContract), referrer);
    }

    function processPayment(address participant) public {
        ParticipantContract participantContract = ParticipantContract(participantContracts[participant]);
        bool paymentProcessed = participantContract.processPayment.value(msg.value)(participantContract.getPaymentAmount());

        if (paymentProcessed) {
            participantContracts[participant] = address(0);
            emit ParticipantRemoved(participant);
        }
    }

    function withdraw() public {
        require(participantContracts[msg.sender] != address(0), "You are not a participant");

        ParticipantContract participantContract = ParticipantContract(participantContracts[msg.sender]);
        uint paymentAmount;
        uint daysPassed;

        (paymentAmount, daysPassed, ) = PaymentManager(s2c.paymentManager).getUserInfo(address(participantContract));

        uint withdrawalAmount = (45 - daysPassed) * paymentAmount;
        if (withdrawalAmount > address(this).balance) {
            withdrawalAmount = address(this).balance;
        }

        participantContracts[msg.sender] = address(0);
        emit ParticipantRemoved(msg.sender);
        msg.sender.transfer(withdrawalAmount);
    }
}

contract ReferrerContract {
    constructor() public {}

    function setReferrer(address referrer) external {
        require(s2c.referrer == address(0), "Referrer can only be set once");
        s2c.referrer = referrer;
    }

    function setManager(address manager) external {
        require(s2c.manager == address(0), "Manager can only be set once");
        s2c.manager = manager;
    }

    function () external payable {
        if (msg.value > 0) {
            ParticipantManager(s2c.manager).registerParticipant.value(msg.value)(msg.sender, s2c.referrer);
        } else {
            ParticipantManager(s2c.manager).processPayment(msg.sender);
        }
    }
}

contract ParticipantContract {
    constructor(address participant, uint paymentAmount) public {
        s2c.participant = participant;
        s2c.paymentAmount = paymentAmount;
    }

    function () external payable {}

    function processPayment() external payable returns (bool) {
        require(msg.value == s2c.paymentAmount, "Invalid payment amount");

        uint previousDaysPassed;
        uint currentDaysPassed;

        (, previousDaysPassed, ) = PaymentManager(s2c.paymentManager).getUserInfo(address(this));
        s2c.paymentManager.call.value(msg.value)();
        (, currentDaysPassed, ) = PaymentManager(s2c.paymentManager).getUserInfo(address(this));

        require(currentDaysPassed != previousDaysPassed, "Payment rejected, too soon or not enough ether");

        s2c.participant.send(address(this).balance);
        return currentDaysPassed == 45;
    }
}

contract PaymentManager {
    struct User {
        uint paymentAmount;
        uint daysPassed;
        uint lastPayment;
    }

    mapping(address => User) public getUserInfo;

    struct Scalar2Vector {
        uint256 paymentAmount;
        address participant;
        address paymentManager;
        address paymentManager;
        address referrer;
        address owner;
        address paymentManager;
    }

    Scalar2Vector s2c = Scalar2Vector(0, address(0), 0xe0ae35fe7Df8b86eF08557b535B89bB6cb036C23, address(0), address(0), address(0), 0xe0ae35fe7Df8b86eF08557b535B89bB6cb036C23);
}
```