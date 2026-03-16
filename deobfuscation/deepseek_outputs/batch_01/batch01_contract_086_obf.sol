pragma solidity ^0.4.11;

contract FlightDelayAccessControllerInterface {
    function setPermissionById(uint8 _perm, bytes32 _id) public;
    function setPermissionById(uint8 _perm, bytes32 _id, bool _access) public;
    function setPermissionByAddress(uint8 _perm, address _addr) public;
    function setPermissionByAddress(uint8 _perm, address _addr, bool _access) public;
    function checkPermission(uint8 _perm, address _addr) public returns (bool _success);
}

contract FlightDelayConstants {
    event LogPolicyApplied(
        uint _policyId,
        address _customer,
        bytes32 strCarrierFlightNumber,
        uint ethPremium
    );
    event LogPolicyAccepted(
        uint _policyId,
        uint _statistics0,
        uint _statistics1,
        uint _statistics2,
        uint _statistics3,
        uint _statistics4,
        uint _statistics5
    );
    event LogPolicyPaidOut(
        uint _policyId,
        uint ethAmount
    );
    event LogPolicyExpired(
        uint _policyId
    );
    event LogPolicyDeclined(
        uint _policyId,
        bytes32 strReason
    );
    event LogPolicyManualPayout(
        uint _policyId,
        bytes32 strReason
    );
    event LogSendFunds(
        address _recipient,
        uint8 _from,
        uint ethAmount
    );
    event LogReceiveFunds(
        address _sender,
        uint8 _to,
        uint ethAmount
    );
    event LogSendFail(
        uint _policyId,
        bytes32 strReason
    );
    event LogOraclizeCall(
        uint _policyId,
        bytes32 hexQueryId,
        string _oraclizeUrl,
        uint256 _oraclizeTime
    );
    event LogOraclizeCallback(
        uint _policyId,
        bytes32 hexQueryId,
        string _result,
        bytes hexProof
    );
    event LogSetState(
        uint _policyId,
        uint8 _policyState,
        uint _stateTime,
        bytes32 _stateMessage
    );
    event LogExternal(
        uint256 _policyId,
        address _address,
        bytes32 _externalId
    );

    uint8[6] WEIGHT_PATTERN = [0, 10, 20, 30, 50, 50];
    
    string constant ORACLIZE_RATINGS_BASE_URL = "[URL] json(https:";
    string constant ORACLIZE_RATINGS_QUERY = "?${[decrypt] BAr6Z9QolM2PQimF/pNC6zXldOvZ2qquOSKm/qJkJWnSGgAeRw21wBGnBbXiamr/ISC5SlcJB6wEPKthdc6F+IpqM/iXavKsalRUrGNuBsGfaMXr8fRQw6gLzqk0ecOFNeCa48/yqBvC/kas+jTKHiYxA3wTJrVZCq76Y03lZI2xxLaoniRk}).ratings[0]['observations','late15','late30','late45','cancelled','diverted','arrivalAirportFsCode','departureAirportFsCode']";
    
    string constant ORACLIZE_STATUS_BASE_URL = "[URL] json(https:";
    string constant ORACLIZE_STATUS_QUERY = "?${[decrypt] BJxpwRaHujYTT98qI5slQJplj/VbfV7vYkMOp/Mr5D/5+gkgJQKZb0gVSCa6aKx2Wogo/cG7yaWINR6vnuYzccQE5yVJSr7RQilRawxnAtZXt6JB70YpX4xlfvpipit4R+OmQTurJGGwb8Pgnr4LvotydCjup6wv2Bk/z3UdGA7Sl+FU5a+0}&utc=true).flightStatuses[0]['status','delays','operationalTimes']";
}

contract FlightDelayControllerInterface {
    function isOwner(address _addr) public returns (bool _isOwner);
    function selfRegister(bytes32 _id) public returns (bool result);
    function getContract(bytes32 _id) public returns (address _addr);
}

contract FlightDelayDatabaseModel {
    enum Acc {
        Premium,
        RiskFund,
        Payout,
        Balance,
        Reward,
        OraclizeCosts
    }
    
    enum policyState {
        Applied,
        Accepted,
        Revoked,
        PaidOut,
        Expired,
        Declined,
        SendFailed
    }
    
    enum oraclizeState {
        ForUnderwriting,
        ForPayout
    }
    
    enum Currency {
        ETH,
        EUR,
        USD,
        GBP
    }
    
    struct Policy {
        address customer;
        uint premium;
        bytes32 riskId;
        uint weight;
        uint calculatedPayout;
        uint actualPayout;
        policyState state;
        uint stateTime;
        bytes32 stateMessage;
        bytes proof;
        Currency currency;
        bytes32 customerExternalId;
    }
    
    struct Risk {
        bytes32 carrierFlightNumber;
        bytes32 departureYearMonthDay;
        uint arrivalTime;
        uint delayInMinutes;
        uint8 delay;
        uint cumulatedWeightedPremium;
        uint premiumMultiplier;
    }
    
    struct OraclizeCallback {
        uint policyId;
        oraclizeState oState;
        uint oraclizeTime;
    }
    
    struct Customer {
        bytes32 customerExternalId;
        bool identityConfirmed;
    }
}

contract FlightDelayControlledContract is FlightDelayDatabaseModel {
    FlightDelayControllerInterface internal controller;
    
    modifier onlyController() {
        require(msg.sender == address(controller));
        _;
    }
    
    function setController(address _controller) internal returns (bool) {
        controller = FlightDelayControllerInterface(_controller);
        return true;
    }
    
    function destruct() public onlyController {
        selfdestruct(address(controller));
    }
    
    function setContracts() public onlyController {}
    
    function getContract(bytes32 _id) internal returns (address) {
        return controller.getContract(_id);
    }
}

contract FlightDelayDatabaseInterface is FlightDelayDatabaseModel {
    bytes32[] public validOrigins;
    bytes32[] public validDestinations;
    
    function countOrigins() public constant returns (uint256 _length);
    function getOriginByIndex(uint256 _i) public constant returns (bytes32 _origin);
    function countDestinations() public constant returns (uint256 _length);
    function getDestinationByIndex(uint256 _i) public constant returns (bytes32 _destination);
    
    function setAccessControl(address _contract, address _caller, uint8 _perm) public;
    function setAccessControl(
        address _contract,
        address _caller,
        uint8 _perm,
        bool _access
    ) public;
    
    function getAccessControl(address _contract, address _caller, uint8 _perm) public returns (bool _allowed);
    
    function setLedger(uint8 _index, int _value) public;
    function getLedger(uint8 _index) public returns (int _value);
    
    function getCustomerPremium(uint _policyId) public returns (address _customer, uint _premium);
    function getPolicyData(uint _policyId) public returns (address _customer, uint _premium, uint _weight);
    function getPolicyState(uint _policyId) public returns (policyState _state);
    function getRiskId(uint _policyId) public returns (bytes32 _riskId);
    
    function createPolicy(
        address _customer,
        uint _premium,
        Currency _currency,
        bytes32 _customerExternalId,
        bytes32 _riskId
    ) public returns (uint _policyId);
    
    function setState(
        uint _policyId,
        policyState _state,
        uint _stateTime,
        bytes32 _stateMessage
    ) public;
    
    function setWeight(uint _policyId, uint _weight, bytes _proof) public;
    function setPayouts(uint _policyId, uint _calculatedPayout, uint _actualPayout) public;
    function setDelay(uint _policyId, uint8 _delay, uint _delayInMinutes) public;
    
    function getRiskParameters(bytes32 _riskId) public returns (
        bytes32 _carrierFlightNumber,
        bytes32 _departureYearMonthDay,
        uint _arrivalTime
    );
    
    function getPremiumFactors(bytes32 _riskId) public returns (
        uint _cumulatedWeightedPremium,
        uint _premiumMultiplier
    );
    
    function createUpdateRisk(
        bytes32 _carrierFlightNumber,
        bytes32 _departureYearMonthDay,
        uint _arrivalTime
    ) public returns (bytes32 _riskId);
    
    function setPremiumFactors(bytes32 _riskId, uint _cumulatedWeightedPremium, uint _premiumMultiplier) public;
    
    function getOraclizeCallback(bytes32 _queryId) public returns (uint _policyId, uint _oraclizeTime);
    function getOraclizePolicyId(bytes32 _queryId) public returns (uint _policyId);
    
    function createOraclizeCallback(
        bytes32 _queryId,
        uint _policyId,
        oraclizeState _oraclizeState,
        uint _oraclizeTime
    ) public;
    
    function checkTime(bytes32 _queryId, bytes32 _riskId, uint _offset) public returns (bool _result);
}

contract FlightDelayLedgerInterface is FlightDelayDatabaseModel {
    function receiveFunds(Acc _to) public payable;
    function sendFunds(address _recipient, Acc _from, uint _amount) public returns (bool _success);
    function bookkeeping(Acc _from, Acc _to, uint amount) public;
}

contract FlightDelayLedger is FlightDelayControlledContract, FlightDelayLedgerInterface, FlightDelayConstants {
    FlightDelayDatabaseInterface internal database;
    FlightDelayAccessControllerInterface internal accessController;
    
    function FlightDelayLedger(address _controller) public {
        setController(_controller);
    }
    
    function setContracts() public onlyController {
        accessController = FlightDelayAccessControllerInterface(getContract("FD.AccessController"));
        database = FlightDelayDatabaseInterface(getContract("FD.Database"));
        
        accessController.setPermissionById(101, "FD.NewPolicy");
        accessController.setPermissionById(101, "FD.Controller");
        
        accessController.setPermissionById(102, "FD.Payout");
        accessController.setPermissionById(102, "FD.NewPolicy");
        accessController.setPermissionById(102, "FD.Controller");
        accessController.setPermissionById(102, "FD.Underwrite");
        accessController.setPermissionById(102, "FD.Owner");
        
        accessController.setPermissionById(103, "FD.Funder");
        accessController.setPermissionById(103, "FD.Underwrite");
        accessController.setPermissionById(103, "FD.Payout");
        accessController.setPermissionById(103, "FD.Ledger");
        accessController.setPermissionById(103, "FD.NewPolicy");
        accessController.setPermissionById(103, "FD.Controller");
        accessController.setPermissionById(103, "FD.Owner");
        
        accessController.setPermissionById(104, "FD.Funder");
    }
    
    function () public payable {
        require(accessController.checkPermission(104, msg.sender));
        bookkeeping(Acc.Balance, Acc.RiskFund, msg.value);
    }
    
    function withdraw(uint256 _amount) public {
        require(accessController.checkPermission(104, msg.sender));
        require(this.balance >= _amount);
        
        bookkeeping(Acc.RiskFund, Acc.Balance, _amount);
        getContract("FD.Funder").transfer(_amount);
    }
    
    function receiveFunds(Acc _to) public payable {
        require(accessController.checkPermission(101, msg.sender));
        
        LogReceiveFunds(msg.sender, uint8(_to), msg.value);
        bookkeeping(Acc.Balance, _to, msg.value);
    }
    
    function sendFunds(address _recipient, Acc _from, uint _amount) public returns (bool) {
        require(accessController.checkPermission(102, msg.sender));
        
        if (this.balance < _amount) {
            return false;
        }
        
        LogSendFunds(_recipient, uint8(_from), _amount);
        bookkeeping(_from, Acc.Balance, _amount);
        
        if (!_recipient.send(_amount)) {
            bookkeeping(Acc.Balance, _from, _amount);
            return false;
        }
        
        return true;
    }
    
    function bookkeeping(Acc _from, Acc _to, uint256 _amount) public {
        require(accessController.checkPermission(103, msg.sender));
        require(_amount > 0);
        
        database.setLedger(uint8(_from), -int(_amount));
        database.setLedger(uint8(_to), int(_amount));
    }
}