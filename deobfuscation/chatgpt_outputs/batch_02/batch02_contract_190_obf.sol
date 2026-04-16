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
    function isValid() pure public returns (bool);
    function getOwner(uint256 id) external view returns (address);
    function transferOwnership(address newOwner, uint256 id) external;
}

contract MainContract is PausableOperators {
    CoreContract public coreContract;
    address public adminAddress;

    modifier onlyCoreContract() {
        require(msg.sender == address(coreContract));
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == adminAddress);
        _;
    }

    function setCoreContract(address coreAddress, address adminAddr) public onlyOperator {
        CoreContract candidateContract = CoreContract(coreAddress);
        require(candidateContract.isValid());
        coreContract = candidateContract;
        adminAddress = adminAddr;
    }

    function isOwner(address account, uint256 id) internal view returns (bool) {
        return (coreContract.getOwner(id) == account);
    }

    function transferOwnership(address newOwner, uint256 id) internal {
        coreContract.transferOwnership(newOwner, id);
    }

    function withdraw() external {
        require(isOperator(msg.sender) || msg.sender == address(coreContract));
        _withdraw();
    }

    function _withdraw() internal {
        if (address(this).balance > 0) {
            coreContract.transferOwnership(address(this).balance, address(this));
        }
    }

    function emergencyWithdraw() public onlyAdmin {
        _withdraw();
    }

    function fallback() public payable onlyCoreContract {
        revert();
    }
}

contract ExtendedContract is MainContract {
    function fallback() public payable onlyAdmin {
        revert();
    }
}

function getBoolFunc(uint256 index) internal view returns (bool) {
    return _bool_constant[index];
}

function getIntFunc(uint256 index) internal view returns (uint256) {
    return _integer_constant[index];
}

bool[] public _bool_constant = [true, false];
uint256[] public _integer_constant = [0];

struct Scalar2Vector {
    address adminAddress;
    bool paused;
    bool paused;
    address owner;
}

Scalar2Vector s2c = Scalar2Vector(address(0), false, false, address(0));