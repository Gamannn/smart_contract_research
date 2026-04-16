pragma solidity ^0.4.24;

contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Stoppable is Ownable {
    using SafeMath for uint;

    event Deposit(bytes32 indexed userId, bytes32 indexed currency, address indexed user, uint amount);
    event Withdraw(address indexed user, uint amount);
    event Bankroll(address indexed user, uint amount);
    event OwnerWithdraw(address indexed owner, uint amount);
    event ContractStopped();
    event ContractResumed();

    bool public stopped;
    mapping (bytes32 => mapping(bytes32 => uint)) public balances;

    modifier stopInEmergency { require(!stopped); _; }
    modifier onlyInEmergency { require(stopped); _; }

    constructor() public {}

    function() payable public {
        revert();
    }

    function bankroll() public onlyOwner {
        emit Bankroll(msg.sender, msg.value);
    }

    function deposit(bytes32 userId, bytes32 currency) payable public stopInEmergency {
        balances[userId][currency] = msg.value;
        emit Deposit(userId, currency, msg.sender, msg.value);
    }

    function withdraw(address user, uint amount) public onlyOwner stopInEmergency {
        user.transfer(amount);
        emit Withdraw(user, amount);
    }

    function ownerWithdraw(address owner, uint amount) public onlyOwner {
        require(address(this).balance > amount);
        owner.transfer(amount);
        emit OwnerWithdraw(owner, amount);
    }

    function balanceOf(bytes32 userId, bytes32 currency) view public returns (uint) {
        return balances[userId][currency];
    }

    function stopContract() public onlyOwner stopInEmergency {
        stopped = true;
        emit ContractStopped();
    }

    function resumeContract() public onlyOwner onlyInEmergency {
        stopped = false;
        emit ContractResumed();
    }
}