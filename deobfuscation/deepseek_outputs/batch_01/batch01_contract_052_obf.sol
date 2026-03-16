pragma solidity ^0.5.8;

contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "The function can only be called by the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract DepositLockerInterface {
    function slash(address _depositorToBeSlashed) public;
}

contract DepositLocker is DepositLockerInterface, Ownable {
    mapping(address => bool) public canWithdraw;

    event DepositorRegistered(address depositorAddress, uint numberOfDepositors);
    event Deposit(uint totalValue, uint valuePerDepositor, uint numberOfDepositors);
    event Withdraw(address withdrawer, uint value);
    event Slash(address slashedDepositor, uint slashedValue);

    struct State {
        uint256 valuePerDepositor;
        uint256 numberOfDepositors;
        uint256 releaseTimestamp;
        address depositorsProxy;
        address slasher;
        bool deposited;
        bool initialized;
        address owner;
    }

    State private state;

    modifier isInitialised() {
        require(state.initialized, "The contract was not initialized.");
        _;
    }

    modifier isDeposited() {
        require(state.deposited, "no deposits yet");
        _;
    }

    modifier isNotDeposited() {
        require(!state.deposited, "already deposited");
        _;
    }

    modifier onlyDepositorsProxy() {
        require(msg.sender == state.depositorsProxy, "Only the depositorsProxy can call this function.");
        _;
    }

    function() external {}

    function init(
        uint _releaseTimestamp,
        address _slasher,
        address _depositorsProxy
    ) external onlyOwner {
        require(!state.initialized, "The contract is already initialised.");
        require(_releaseTimestamp > now, "The release timestamp must be in the future");

        state.releaseTimestamp = _releaseTimestamp;
        state.slasher = _slasher;
        state.depositorsProxy = _depositorsProxy;
        state.initialized = true;
        state.owner = address(0);
    }

    function registerDepositor(address _depositor) public isInitialised isNotDeposited onlyDepositorsProxy {
        require(canWithdraw[_depositor] == false, "can only register Depositor once");
        canWithdraw[_depositor] = true;
        state.numberOfDepositors += 1;
        emit DepositorRegistered(_depositor, state.numberOfDepositors);
    }

    function deposit(uint _valuePerDepositor) public payable isInitialised isNotDeposited onlyDepositorsProxy {
        require(state.numberOfDepositors > 0, "no depositors");
        require(_valuePerDepositor > 0, "_valuePerDepositor must be positive");

        uint depositAmount = state.numberOfDepositors * _valuePerDepositor;
        require(
            _valuePerDepositor == depositAmount / state.numberOfDepositors,
            "Overflow in depositAmount calculation"
        );
        require(
            msg.value == depositAmount,
            "the deposit does not match the required value"
        );

        state.valuePerDepositor = _valuePerDepositor;
        state.deposited = true;
        emit Deposit(msg.value, state.valuePerDepositor, state.numberOfDepositors);
    }

    function withdraw() public isInitialised isDeposited {
        require(
            now >= state.releaseTimestamp,
            "The deposit cannot be withdrawn yet."
        );
        require(canWithdraw[msg.sender], "cannot withdraw from sender");

        canWithdraw[msg.sender] = false;
        msg.sender.transfer(state.valuePerDepositor);
        emit Withdraw(msg.sender, state.valuePerDepositor);
    }

    function slash(address _depositorToBeSlashed) public isInitialised isDeposited {
        require(
            msg.sender == state.slasher,
            "Only the slasher can call this function."
        );
        require(canWithdraw[_depositorToBeSlashed], "cannot slash address");

        canWithdraw[_depositorToBeSlashed] = false;
        address(0).transfer(state.valuePerDepositor);
        emit Slash(_depositorToBeSlashed, state.valuePerDepositor);
    }
}