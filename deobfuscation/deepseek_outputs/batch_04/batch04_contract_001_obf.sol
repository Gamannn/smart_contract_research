```solidity
pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
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
}

contract ProxyWallet {
    address public owner;
    
    constructor(address _owner) public {
        owner = _owner;
    }
    
    function executeCall(address to, uint256 value, uint256 gasLimit, bytes data) external returns(bool) {
        require(msg.sender == owner);
        return to.call.value(value).gas(gasLimit)(data);
    }
    
    function () payable public {}
}

contract Scheduler {
    using SafeMath for uint256;
    
    address public admin;
    uint256 public serviceFee;
    uint256 public feeChangeInterval;
    uint256 public scheduledTxCount;
    
    mapping(address => address) public userWallets;
    mapping(uint256 => bytes32) public scheduledTxHashes;
    
    event ExecutedCallEvent(
        address indexed user,
        uint256 indexed txId,
        bool callSuccess,
        bool refundSuccess,
        bool callbackSuccess
    );
    
    event ScheduleCallEvent(
        uint256 indexed scheduleTime,
        address indexed user,
        address to,
        uint256 value,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 fee,
        bytes data,
        uint256 indexed txId,
        bool useTimestamp
    );
    
    event CancelScheduledTxEvent(
        address indexed user,
        uint256 refundAmount,
        bool refundSuccess,
        uint256 indexed txId
    );
    
    event FeeChanged(uint256 newFee, uint256 oldFee);
    
    constructor() public {
        admin = msg.sender;
        serviceFee = 500000000000000;
        feeChangeInterval = 0;
    }
    
    function changeAdmin(address newAdmin) public {
        require(msg.sender == admin);
        withdrawFees();
        admin = newAdmin;
    }
    
    function createWallet() internal {
        if (userWallets[msg.sender] == address(0)) {
            ProxyWallet wallet = new ProxyWallet(address(this));
            userWallets[msg.sender] = address(wallet);
        }
    }
    
    function scheduleCall(
        uint256 scheduleTime,
        address to,
        uint256 value,
        uint256 gasPrice,
        uint256 gasLimit,
        bytes data,
        bool useTimestamp
    ) public payable returns (uint256, address) {
        uint256 totalCost = value.add(gasPrice.mul(gasLimit)).add(serviceFee);
        require(msg.value == totalCost);
        
        createWallet();
        scheduledTxCount = scheduledTxCount.add(1);
        
        scheduledTxHashes[scheduledTxCount] = keccak256(abi.encodePacked(
            scheduleTime,
            msg.sender,
            to,
            value,
            gasPrice,
            gasLimit,
            serviceFee,
            data,
            useTimestamp
        ));
        
        userWallets[msg.sender].transfer(msg.value);
        
        emit ScheduleCallEvent(
            scheduleTime,
            msg.sender,
            to,
            value,
            gasPrice,
            gasLimit,
            serviceFee,
            data,
            scheduledTxCount,
            useTimestamp
        );
        
        return (scheduledTxCount, userWallets[msg.sender]);
    }
    
    function executeScheduledCall(
        uint256 scheduleTime,
        address user,
        address to,
        uint256 value,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 fee,
        bytes data,
        uint256 txId,
        bool useTimestamp
    ) external {
        require(msg.sender == admin);
        
        if (useTimestamp) {
            require(scheduleTime <= block.timestamp);
        } else {
            require(scheduleTime <= block.number);
        }
        
        require(scheduledTxHashes[txId] == keccak256(abi.encodePacked(
            scheduleTime,
            user,
            to,
            value,
            gasPrice,
            gasLimit,
            fee,
            data,
            useTimestamp
        )));
        
        ProxyWallet wallet = ProxyWallet(userWallets[user]);
        
        require(wallet.executeCall(address(this), gasPrice.mul(gasLimit).add(fee), 2100, hex"00"));
        
        bool callSuccess = wallet.executeCall(
            to,
            value,
            gasleft().sub(50000),
            data
        );
        
        bool refundSuccess = false;
        if (!callSuccess && value > 0) {
            refundSuccess = wallet.executeCall(user, value, 2100, hex"00");
        }
        
        delete scheduledTxHashes[txId];
        
        bool callbackSuccess = user.call.value(0).gas(2100)();
        
        emit ExecutedCallEvent(
            user,
            txId,
            callSuccess,
            refundSuccess,
            callbackSuccess
        );
    }
    
    function cancelScheduledTx(
        uint256 scheduleTime,
        address user,
        address to,
        uint256 value,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 fee,
        bytes data,
        uint256 txId,
        bool useTimestamp
    ) external returns(bool) {
        if (useTimestamp) {
            require(
                scheduleTime >= block.timestamp.add(3 minutes) ||
                scheduleTime <= block.timestamp.sub(5 minutes)
            );
        } else {
            require(
                scheduleTime > block.number.add(10) ||
                scheduleTime <= block.number.sub(20)
            );
        }
        
        require(scheduledTxHashes[txId] == keccak256(abi.encodePacked(
            scheduleTime,
            user,
            to,
            value,
            gasPrice,
            gasLimit,
            fee,
            data,
            useTimestamp
        )));
        
        require(msg.sender == user);
        
        ProxyWallet wallet = ProxyWallet(userWallets[msg.sender]);
        uint256 refundAmount = value.add(gasPrice.mul(gasLimit)).add(fee);
        bool refundSuccess = wallet.executeCall(user, refundAmount, 3000, hex"00");
        
        require(refundSuccess);
        
        emit CancelScheduledTxEvent(user, refundAmount, refundSuccess, txId);
        
        delete scheduledTxHashes[txId];
        return true;
    }
    
    function withdrawFees() public {
        require(msg.sender == admin);
        admin.transfer(address(this).balance);
    }
    
    function changeServiceFee(uint256 newFee) public {
        require(msg.sender == admin);
        require(feeChangeInterval < block.timestamp);
        
        uint256 oldFee = serviceFee;
        
        if (newFee > serviceFee) {
            uint256 increase = newFee.sub(serviceFee);
            uint256 percentageIncrease = increase.mul(100).div(serviceFee);
            require(percentageIncrease <= 10);
        }
        
        serviceFee = newFee;
        feeChangeInterval = block.timestamp.add(1 days);
        
        emit FeeChanged(newFee, oldFee);
    }
    
    function () public payable {}
}
```