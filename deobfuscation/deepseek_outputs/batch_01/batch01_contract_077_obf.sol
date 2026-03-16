```solidity
pragma solidity ^0.4.25;

contract Smartolution {
    event ParticipantAdded(address participant);
    event ParticipantRemoved(address participant);
    event ReferrerAdded(address referrerContract, address referrer);
    
    mapping (address => address) public participantContracts;
    mapping (address => bool) public isReferrer;
    
    address public owner;
    
    constructor(address _owner) public {
        owner = _owner;
    }
    
    function () external payable {
        if (participantContracts[msg.sender] == address(0)) {
            registerParticipant(msg.sender, address(0));
        } else {
            if (msg.value == 0) {
                makePayment(msg.sender);
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
        makePayment(participant);
        
        owner.send(msg.value / 33);
        
        if (referrer != address(0) && isReferrer[referrer]) {
            referrer.send(msg.value / 20);
        }
        
        emit ParticipantAdded(participant);
    }
    
    function addReferrer(address referrer) public {
        require(!isReferrer[referrer], "This address is already a referrer");
        isReferrer[referrer] = true;
        
        ReferrerContract referrerContract = new ReferrerContract();
        referrerContract.setReferrer(referrer);
        referrerContract.setMainContract(address(this));
        
        emit ReferrerAdded(address(referrerContract), referrer);
    }
    
    function makePayment(address participant) public {
        ParticipantContract participantContract = ParticipantContract(participantContracts[participant]);
        bool isCompleted = participantContract.makePayment.value(participantContract.dailyPayment())();
        
        if (isCompleted) {
            participantContracts[participant] = address(0);
            emit ParticipantRemoved(participant);
        }
    }
    
    function withdraw() public {
        require(participantContracts[msg.sender] != address(0), "You are not a participant");
        
        ParticipantContract participantContract = ParticipantContract(participantContracts[msg.sender]);
        uint dailyPayment;
        uint daysPaid;
        
        (dailyPayment, daysPaid, ) = SmartolutionData(dataContract).getUserData(address(participantContract));
        
        uint amountToWithdraw = (45 - daysPaid) * dailyPayment;
        
        if (amountToWithdraw > address(this).balance) {
            amountToWithdraw = address(this).balance;
        }
        
        participantContracts[msg.sender] = address(0);
        emit ParticipantRemoved(msg.sender);
        msg.sender.transfer(amountToWithdraw);
    }
}

contract ReferrerContract {
    address public referrer;
    address public mainContract;
    
    constructor () public {
    }
    
    function setReferrer(address _referrer) external {
        require(referrer == address(0), "Referrer can only be set once");
        referrer = _referrer;
    }
    
    function setMainContract(address _mainContract) external {
        require(mainContract == address(0), "Main contract can only be set once");
        mainContract = _mainContract;
    }
    
    function () external payable {
        if (msg.value > 0) {
            Smartolution(mainContract).registerParticipant.value(msg.value)(msg.sender, referrer);
        } else {
            Smartolution(mainContract).makePayment(msg.sender);
        }
    }
}

contract ParticipantContract {
    address public participant;
    uint public dailyPayment;
    
    constructor(address _participant, uint _dailyPayment) public {
        participant = _participant;
        dailyPayment = _dailyPayment;
    }
    
    function () external payable {}
    
    function makePayment() external payable returns (bool) {
        require(msg.value == dailyPayment, "Invalid payment amount");
        
        uint daysPaidBefore;
        uint daysPaidAfter;
        
        (, daysPaidBefore, ) = SmartolutionData(dataContract).getUserData(address(this));
        dataContract.call.value(msg.value)();
        (, daysPaidAfter, ) = SmartolutionData(dataContract).getUserData(address(this));
        
        require(daysPaidAfter != daysPaidBefore, "Smartolution rejected that payment, too soon or not enough ether");
        
        participant.send(address(this).balance);
        return daysPaidAfter == 45;
    }
}

contract SmartolutionData {
    struct User {
        uint dailyPayment;
        uint daysPaid;
        uint lastPaymentTime;
    }
    
    mapping (address => User) public getUserData;
    
    address public dataContract = 0xe0ae35fe7Df8b86eF08557b535B89bB6cb036C23;
}
```