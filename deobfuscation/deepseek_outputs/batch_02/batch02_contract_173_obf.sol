```solidity
pragma solidity ^0.4.24;

contract Ownable {
    address public owner;
    
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    
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
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
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
    
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Bankrollable is Ownable {
    using SafeMath for uint256;
    
    event LOG_Deposit(bytes32 indexed gameId, bytes32 indexed playerId, address player, uint amount);
    event LOG_Withdraw(address player, uint amount);
    event LOG_Bankroll(address sender, uint amount);
    event LOG_OwnerWithdraw(address owner, uint amount);
    event LOG_ContractStopped();
    event LOG_ContractResumed();
    
    bool public isStopped;
    
    mapping(bytes32 => mapping(bytes32 => uint256)) public deposits;
    
    modifier whenNotStopped() {
        require(!isStopped);
        _;
    }
    
    modifier whenStopped() {
        require(isStopped);
        _;
    }
    
    constructor() public {}
    
    function() payable public {
        revert();
    }
    
    function bankroll() payable public onlyOwner {
        emit LOG_Bankroll(msg.sender, msg.value);
    }
    
    function deposit(bytes32 gameId, bytes32 playerId) payable public whenNotStopped {
        deposits[gameId][playerId] = msg.value;
        emit LOG_Deposit(gameId, playerId, msg.sender, msg.value);
    }
    
    function withdraw(address player, uint amount) public onlyOwner whenNotStopped {
        player.transfer(amount);
        emit LOG_Withdraw(player, amount);
    }
    
    function ownerWithdraw(address ownerAddress, uint amount) public onlyOwner {
        require(address(this).balance > amount);
        ownerAddress.transfer(amount);
        emit LOG_OwnerWithdraw(ownerAddress, amount);
    }
    
    function getDeposit(bytes32 gameId, bytes32 playerId) view public returns (uint256) {
        return deposits[gameId][playerId];
    }
    
    function stopContract() public onlyOwner whenNotStopped {
        isStopped = true;
        emit LOG_ContractStopped();
    }
    
    function resumeContract() public onlyOwner whenStopped {
        isStopped = false;
        emit LOG_ContractResumed();
    }
}
```