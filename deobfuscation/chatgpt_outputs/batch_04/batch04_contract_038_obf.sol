```solidity
pragma solidity ^0.4.23;

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();
    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

contract OperatorManager {
    mapping(address => bool) private operators;
    mapping(address => bool) private admins;

    constructor() public {
        operators[msg.sender] = true;
    }

    modifier onlyOperator() {
        require(operators[msg.sender]);
        _;
    }

    function isOperator(address account) public view returns (bool) {
        return operators[account];
    }

    function addOperator(address account) external onlyOperator {
        require(account != address(0));
        operators[account] = true;
    }

    function removeOperator(address account) external onlyOperator {
        delete operators[account];
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender));
        _;
    }

    function isAdmin(address account) public view returns (bool) {
        return admins[account] || operators[account];
    }

    function addAdmin(address account) external onlyOperator {
        require(account != address(0));
        admins[account] = true;
    }

    function removeAdmin(address account) external onlyOperator {
        delete admins[account];
    }
}

contract PausableOperators is OperatorManager, Pausable {
    event Pause();
    event Unpause();
    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() public onlyOperator whenNotPaused {
        paused = true;
        emit Pause();
    }

    function unpause() public onlyOperator whenPaused {
        paused = false;
        emit Unpause();
    }
}

contract CoreContract {
    function isValid() public pure returns (bool);
    function execute(address from, address to, uint256 amount) external;
    function validate(address account, uint256 amount) external view returns (bool);
}

contract MainContract is PausableOperators {
    CoreContract public coreContract;
    address public coreAddress;

    modifier onlyCore() {
        require(msg.sender == address(coreContract));
        _;
    }

    function setCoreContract(address coreAddress, address coreOperator) public onlyOperator {
        CoreContract newCoreContract = CoreContract(coreAddress);
        require(newCoreContract.isValid());
        coreContract = newCoreContract;
        coreAddress = coreOperator;
    }

    function validateTransaction(address account, uint256 amount) internal view returns (bool) {
        return coreContract.validate(account, amount);
    }

    function executeTransaction(address from, uint256 amount) internal {
        coreContract.execute(from, this, amount);
    }

    function withdraw() external {
        require(isOperator(msg.sender) || msg.sender == address(coreContract));
        internalWithdraw();
    }

    function internalWithdraw() internal {
        if (address(this).balance > 0) {
            coreContract.execute(address(this), address(this).balance);
        }
    }

    function fallback() public onlyCore {
        internalWithdraw();
    }

    function revertTransaction(uint40, uint256, address) public payable onlyCore {
        revert();
    }

    function externalRevertTransaction(uint40, uint256, address) external payable onlyCore {
        revert();
    }
}

contract FeeManager is MainContract {
    uint16 public feePercentage;

    constructor(uint16 initialFeePercentage, address coreAddress, address coreOperator) public {
        require(initialFeePercentage <= 10000);
        feePercentage = initialFeePercentage;
        super.setCoreContract(coreAddress, coreOperator);
    }

    function setFeePercentage(uint16 newFeePercentage) external onlyOperator {
        require(newFeePercentage <= 10000);
        feePercentage = newFeePercentage;
    }

    function calculateFee(uint128 amount) internal view returns (uint128) {
        return amount * feePercentage / 10000;
    }
}

contract TransferManager is FeeManager {
    event Transfer(address from, address to, uint128 amount);

    function revertTransaction(uint40, uint256, address) public payable onlyCore {
        revert();
    }

    function externalRevertTransaction(uint40, uint256 amount, address) external payable onlyCore {
        uint40 expirationTime = uint40(amount / 0x0010000000000000000000000000000000000000000);
        require(now <= expirationTime);
        uint256 fee = 96 * msg.value / 100;
        coreContract.execute(address(this), fee);
    }
}
```