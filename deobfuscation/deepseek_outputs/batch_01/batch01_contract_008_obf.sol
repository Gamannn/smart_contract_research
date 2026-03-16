```solidity
pragma solidity 0.4.20;

contract IAugur {
    function createChildUniverse(bytes32 _parentPayoutDistributionHash, uint256[] _parentPayoutNumerators, bool _parentInvalid) public returns (IUniverse);
    function isKnownUniverse(IUniverse _universe) public view returns (bool);
    function trustedTransfer(ERC20 _token, address _from, address _to, uint256 _amount) public returns (bool);
    function logMarketCreated(bytes32 _topic, string _description, string _extraInfo, IUniverse _universe, address _market, address _marketCreator, bytes32[] _outcomes, int256 _minPrice, int256 _maxPrice, IMarket.MarketType _marketType) public returns (bool);
    function logMarketCreated(bytes32 _topic, string _description, string _extraInfo, IUniverse _universe, address _market, address _marketCreator, int256 _minPrice, int256 _maxPrice, IMarket.MarketType _marketType) public returns (bool);
    function logInitialReportSubmitted(IUniverse _universe, address _reporter, address _market, uint256 _amountStaked, bool _isDesignatedReporter, uint256[] _payoutNumerators, bool _invalid) public returns (bool);
    function disputeCrowdsourcerCreated(IUniverse _universe, address _market, address _disputeCrowdsourcer, uint256[] _payoutNumerators, uint256 _size, bool _invalid) public returns (bool);
    function logDisputeCrowdsourcerContribution(IUniverse _universe, address _reporter, address _market, address _disputeCrowdsourcer, uint256 _amountStaked) public returns (bool);
    function logDisputeCrowdsourcerCompleted(IUniverse _universe, address _market, address _disputeCrowdsourcer) public returns (bool);
    function logInitialReporterRedeemed(IUniverse _universe, address _reporter, address _market, uint256 _amountRedeemed, uint256 _repReceived, uint256 _reportingFeesReceived, uint256[] _payoutNumerators) public returns (bool);
    function logDisputeCrowdsourcerRedeemed(IUniverse _universe, address _reporter, address _market, uint256 _amountRedeemed, uint256 _repReceived, uint256 _reportingFeesReceived, uint256[] _payoutNumerators) public returns (bool);
    function logFeeWindowRedeemed(IUniverse _universe, address _reporter, uint256 _amountRedeemed, uint256 _reportingFeesReceived) public returns (bool);
    function logMarketFinalized(IUniverse _universe) public returns (bool);
    function logMarketMigrated(IMarket _market, IUniverse _originalUniverse) public returns (bool);
    function logReportingParticipantDisavowed(IUniverse _universe, IMarket _market) public returns (bool);
    function logMarketParticipantsDisavowed(IUniverse _universe) public returns (bool);
    function logOrderCanceled(IUniverse _universe, address _shareToken, address _sender, bytes32 _orderId, Order.Types _orderType, uint256 _tokenRefund, uint256 _sharesRefund) public returns (bool);
    function logOrderCreated(Order.Types _orderType, uint256 _amount, uint256 _price, address _creator, uint256 _moneyEscrowed, uint256 _sharesEscrowed, bytes32 _tradeGroupId, bytes32 _orderId, IUniverse _universe, address _shareToken) public returns (bool);
    function logOrderFilled(IUniverse _universe, address _shareToken, address _filler, bytes32 _orderId, uint256 _numCreatorShares, uint256 _numCreatorTokens, uint256 _numFillerShares, uint256 _numFillerTokens, uint256 _marketCreatorFees, uint256 _reporterFees, uint256 _amountFilled, bytes32 _tradeGroupId) public returns (bool);
    function logCompleteSetsPurchased(IUniverse _universe, IMarket _market, address _account, uint256 _numCompleteSets) public returns (bool);
    function logCompleteSetsSold(IUniverse _universe, IMarket _market, address _account, uint256 _numCompleteSets) public returns (bool);
    function logTradingProceedsClaimed(IUniverse _universe, address _shareToken, address _sender, address _market, uint256 _numShares, uint256 _numPayoutTokens, uint256 _finalTokenBalance) public returns (bool);
    function logUniverseForked() public returns (bool);
    function logFeeWindowTransferred(IUniverse _universe, address _from, address _to, uint256 _value) public returns (bool);
    function logReputationTokensTransferred(IUniverse _universe, address _from, address _to, uint256 _value) public returns (bool);
    function logDisputeCrowdsourcerTokensTransferred(IUniverse _universe, address _from, address _to, uint256 _value) public returns (bool);
    function logShareTokensTransferred(IUniverse _universe, address _from, address _to, uint256 _value) public returns (bool);
    function logReputationTokenBurned(IUniverse _universe, address _target, uint256 _amount) public returns (bool);
    function logReputationTokenMinted(IUniverse _universe, address _target, uint256 _amount) public returns (bool);
    function logShareTokenBurned(IUniverse _universe, address _target, uint256 _amount) public returns (bool);
    function logShareTokenMinted(IUniverse _universe, address _target, uint256 _amount) public returns (bool);
    function logFeeWindowBurned(IUniverse _universe, address _target, uint256 _amount) public returns (bool);
    function logFeeWindowMinted(IUniverse _universe, address _target, uint256 _amount) public returns (bool);
    function logDisputeCrowdsourcerTokensBurned(IUniverse _universe, address _target, uint256 _amount) public returns (bool);
    function logDisputeCrowdsourcerTokensMinted(IUniverse _universe, address _target, uint256 _amount) public returns (bool);
    function logFeeWindowCreated(IFeeWindow _feeWindow, uint256 _id) public returns (bool);
    function logFeeTokenTransferred(IUniverse _universe, address _from, address _to, uint256 _value) public returns (bool);
    function logFeeTokenBurned(IUniverse _universe, address _target, uint256 _amount) public returns (bool);
    function logFeeTokenMinted(IUniverse _universe, address _target, uint256 _amount) public returns (bool);
    function logTimestampSet(uint256 _newTimestamp) public returns (bool);
    function logInitialReporterTransferred(IUniverse _universe, IMarket _market, address _from, address _to) public returns (bool);
    function logMarketTransferred(IUniverse _universe, address _from, address _to) public returns (bool);
    function logMarketMailboxTransferred(IUniverse _universe, IMarket _market, address _from, address _to) public returns (bool);
    function logEscapeHatchChanged(bool _isOn) public returns (bool);
}

contract IControlled {
    function getController() public view returns (IController);
    function setController(IController _controller) public returns(bool);
}

contract Controlled is IControlled {
    IController internal controller;

    modifier onlyWhitelistedCallers {
        require(controller.assertIsWhitelisted(msg.sender));
        _;
    }

    modifier onlyCaller(bytes32 _key) {
        require(msg.sender == controller.lookup(_key));
        _;
    }

    modifier onlyControllerCaller {
        require(IController(msg.sender) == controller);
        _;
    }

    modifier onlyInGoodTimes {
        require(controller.stopInEmergency());
        _;
    }

    modifier onlyInBadTimes {
        require(controller.onlyInEmergency());
        _;
    }

    function Controlled() public {
        controller = IController(msg.sender);
    }

    function getController() public view returns(IController) {
        return controller;
    }

    function setController(IController _controller) public onlyControllerCaller returns(bool) {
        controller = _controller;
        return true;
    }
}

contract IController {
    function assertIsWhitelisted(address _target) public view returns(bool);
    function lookup(bytes32 _key) public view returns(address);
    function stopInEmergency() public view returns(bool);
    function onlyInEmergency() public view returns(bool);
    function getAugur() public view returns (IAugur);
    function getTimestamp() public view returns (uint256);
}

contract DelegationTarget is Controlled {
    bytes32 public controllerLookupName;
}

contract Delegator is DelegationTarget {
    function Delegator(IController _controller, bytes32 _controllerLookupName) public {
        controller = _controller;
        controllerLookupName = _controllerLookupName;
    }

    function() external payable {
        if (controllerLookupName == 0) {
            return;
        }
        
        address _target = controller.lookup(controllerLookupName);
        assembly {
            let _calldataMemoryOffset := mload(0x40)
            let _size := add(calldatasize, 31)
            _size := and(_size, not(31))
            mstore(0x40, add(_calldataMemoryOffset, _size))
            calldatacopy(_calldataMemoryOffset, 0x0, calldatasize)
            let _retval := delegatecall(gas, _target, _calldataMemoryOffset, calldatasize, 0, 0)
            switch _retval
            case 0 {
                revert(0, 0)
            }
            default {
                let _returndataMemoryOffset := mload(0x40)
                mstore(0x40, add(_returndataMemoryOffset, returndatasize))
                returndatacopy(_returndataMemoryOffset, 0x0, returndatasize)
                return(_returndataMemoryOffset, returndatasize)
            }
        }
    }
}

contract IOwnable {
    function getOwner() public view returns (address);
    function transferOwnership(address newOwner) public returns (bool);
}

contract ITyped {
    function getTypeName() public view returns (bytes32);
}

contract Initializable {
    struct InitializationState {
        bool initialized;
    }
    
    InitializationState private initializationState;

    modifier afterInitialized {
        require(initializationState.initialized);
        _;
    }

    modifier beforeInitialized {
        require(!initializationState.initialized);
        _;
    }

    function endInitialization() internal beforeInitialized returns (bool) {
        initializationState.initialized = true;
        return true;
    }

    function getInitialized() public view returns (bool) {
        return initializationState.initialized;
    }
}

library SafeMathUint256 {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a <= b) {
            return a;
        } else {
            return b;
        }
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a >= b) {
            return a;
        } else {
            return b;
        }
    }

    function getUint256Min() internal pure returns (uint256) {
        return 0;
    }

    function getUint256Max() internal pure returns (uint256) {
        return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    }

    function isMultipleOf(uint256 a, uint256 b) internal pure returns (bool) {
        return a % b == 0;
    }

    function fxpMul(uint256 a, uint256 b, uint256 base) internal pure returns (uint256) {
        return div(mul(a, b), base);
    }

    function fxpDiv(uint256 a, uint256 b, uint256 base) internal pure returns (uint256) {
        return div(mul(a, base), b);
    }
}

contract ERC20Basic {
    event Transfer(address indexed from, address indexed to, uint256 value);

    function balanceOf(address _who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function totalSupply() public view returns (uint256);
}

contract ERC20 is ERC20Basic {
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function allowance(address _owner, address _spender) public view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
}

contract IFeeToken is ERC20, Initializable {
    function initialize(IFeeWindow _feeWindow) public returns (bool);
    function getFeeWindow() public view returns (IFeeWindow);
    function feeWindowBurn(address _target, uint256 _amount) public returns (bool);
    function mintForReportingParticipant(address _target, uint256 _amount) public returns (bool);
}

contract IFeeWindow is ITyped, ERC20 {
    function initialize(IUniverse _universe, uint256 _feeWindowId) public returns (bool);
    function getUniverse() public view returns (IUniverse);
    function getReputationToken() public view returns (IReputationToken);
    function getStartTime() public view returns (uint256);
    function getEndTime() public view returns (uint256);
    function getNumMarkets() public view returns (uint256);
    function getNumInvalidMarkets() public view returns (uint256);
    function getNumIncorrectDesignatedReportMarkets() public view returns (uint256);
    function getNumDesignatedReportNoShows() public view returns (uint256);
    function getFeeToken() public view returns (IFeeToken);
    function isActive() public view returns (bool);
    function isOver() public view returns (bool);
    function onMarketFinalized() public returns (bool);
    function buy(uint256 _attotokens) public returns (bool);
    function redeem(address _sender) public returns (bool);
    function redeemForReportingParticipant() public returns (bool);
    function mintFeeTokens(uint256 _amount) public returns (bool);
    function trustedUniverseBuy(address _buyer, uint256 _attotokens) public returns (bool);
}

contract IMailbox {
    function initialize(address _owner, IMarket _market) public returns (bool);
    function depositEther() public payable returns (bool);
}

contract IMarket is ITyped, IOwnable {
    enum MarketType {
        YES_NO,
        CATEGORICAL,
        SCALAR
    }

    function initialize(IUniverse _universe, uint256 _endTime, uint256 _feePerEthInAttoeth, ICash _cash, address _designatedReporterAddress, address _creator, uint256 _numOutcomes, uint256 _numTicks) public payable returns (bool _success);
    function derivePayoutDistributionHash(uint256[] _payoutNumerators, bool _invalid) public view returns (bytes32);
    function getUniverse() public view returns (IUniverse);
    function getFeeWindow() public view returns (IFeeWindow);
    function getNumberOfOutcomes() public view returns (uint256);
    function getNumTicks() public view returns (uint256);
    function getDenominationToken() public view returns (ICash);
    function getShareToken(uint256 _outcome) public view returns (IShareToken);
    function getMarketCreatorSettlementFeeDivisor() public view returns (uint256);
    function getForkingMarket() public view returns (IMarket _market);
    function getEndTime() public view returns (uint256);
    function getMarketCreatorMailbox() public view returns (IMailbox);
    function getWinningPayoutDistributionHash() public view returns (bytes32);
    function getWinningPayoutNumerator(uint256 _outcome) public view returns (uint256);
    function getReputationToken() public view returns (IReputationToken);
    function getFinalizationTime() public view returns (uint256);
    function getInitialReporterAddress() public view returns (address);
    function deriveMarketCreatorFeeAmount(uint256 _amount) public view returns (uint256);
    function isContainerForShareToken(IShareToken _shadyTarget) public view returns (bool);
    function isContainerForReportingParticipant(IReportingParticipant _reportingParticipant) public view returns (bool);
    function isInvalid() public view returns (bool);
    function finalize() public returns (bool);
    function designatedReporterWasCorrect() public view returns (bool);
    function designatedReporterShowed() public view returns (bool);
    function isFinalized() public view returns (bool);
    function finalizeFork() public returns (bool);
    function assertBalances() public view returns (bool);
}

contract IReportingParticipant {
    function getStake() public view returns (uint256);
    function getPayoutDistributionHash() public view returns (bytes32);
    function liquidateLosing() public returns (bool);
    function redeem(address _redeemer) public returns (bool);
    function isInvalid() public view returns (bool);
    function isDisavowed() public view returns (bool);
    function migrate() public returns (bool);
    function getPayoutNumerator(uint256 _outcome) public view returns (uint256);
    function getMarket() public view returns (IMarket);
   