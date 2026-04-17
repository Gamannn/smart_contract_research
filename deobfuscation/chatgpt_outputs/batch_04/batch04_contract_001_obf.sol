```solidity
pragma solidity ^0.4.24;

contract ProxyContract {
    address public owner;

    constructor(address _owner) public {
        owner = _owner;
    }

    function executeTransaction(
        address target,
        uint256 value,
        uint256 gasLimit,
        bytes data
    ) external returns (bool) {
        require(msg.sender == owner);
        return target.call.value(value).gas(gasLimit)(data);
    }

    function () payable public {}
}

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

contract Scheduler {
    using SafeMath for uint256;

    address public admin;
    uint256 public fee;
    uint256 public lastFeeChange;
    uint256 public transactionCount;
    mapping(uint256 => bytes32) public scheduledTransactions;
    mapping(address => address) public proxies;

    event ExecutedCallEvent(
        address indexed executor,
        uint256 indexed transactionId,
        bool success,
        bool refundSuccess,
        bool feeTransferSuccess
    );

    event ScheduleCallEvent(
        uint256 indexed scheduleTime,
        address indexed executor,
        address target,
        uint256 value,
        uint256 gasLimit,
        uint256 gasPrice,
        uint256 fee,
        bytes data,
        uint256 indexed transactionId,
        bool isTimestamp
    );

    event CancelScheduledTxEvent(
        address indexed executor,
        uint256 value,
        bool success,
        uint256 indexed transactionId
    );

    event FeeChanged(uint256 oldFee, uint256 newFee);

    constructor() public {
        admin = msg.sender;
        fee = 500000000000000;
    }

    function changeAdmin(address newAdmin) public {
        require(msg.sender == admin);
        withdrawBalance();
        admin = newAdmin;
    }

    function createProxy() internal {
        if (proxies[msg.sender] == address(0)) {
            ProxyContract proxy = new ProxyContract(address(this));
            proxies[msg.sender] = address(proxy);
        }
    }

    function scheduleTransaction(
        uint256 scheduleTime,
        address target,
        uint256 value,
        uint256 gasLimit,
        uint256 gasPrice,
        bytes data,
        bool isTimestamp
    ) public payable returns (uint256, address) {
        require(
            msg.value == value.add(gasLimit.mul(gasPrice)).add(fee)
        );
        transactionCount = transactionCount.add(1);
        scheduledTransactions[transactionCount] = keccak256(
            abi.encodePacked(
                scheduleTime,
                msg.sender,
                target,
                value,
                gasLimit,
                gasPrice,
                fee,
                data,
                isTimestamp
            )
        );
        createProxy();
        proxies[msg.sender].transfer(msg.value);
        emit ScheduleCallEvent(
            scheduleTime,
            msg.sender,
            target,
            value,
            gasLimit,
            gasPrice,
            fee,
            data,
            transactionCount,
            isTimestamp
        );
        return (transactionCount, proxies[msg.sender]);
    }

    function executeScheduledTransaction(
        uint256 scheduleTime,
        address executor,
        address target,
        uint256 value,
        uint256 gasLimit,
        uint256 gasPrice,
        uint256 fee,
        bytes data,
        uint256 transactionId,
        bool isTimestamp
    ) external {
        require(msg.sender == admin);
        if (isTimestamp) {
            require(scheduleTime <= block.timestamp);
        } else {
            require(scheduleTime <= block.number);
        }
        require(
            scheduledTransactions[transactionId] ==
                keccak256(
                    abi.encodePacked(
                        scheduleTime,
                        executor,
                        target,
                        value,
                        gasLimit,
                        gasPrice,
                        fee,
                        data,
                        isTimestamp
                    )
                )
        );
        ProxyContract proxy = ProxyContract(proxies[executor]);
        require(
            proxy.executeTransaction(
                address(this),
                gasPrice.mul(gasLimit).add(fee),
                2100,
                hex"00"
            )
        );
        bool success = proxy.executeTransaction(
            target,
            value,
            gasleft().sub(50000),
            data
        );
        bool refundSuccess;
        if (!success && value > 0) {
            refundSuccess = proxy.executeTransaction(
                executor,
                value,
                2100,
                hex"00"
            );
        }
        delete scheduledTransactions[transactionId];
        bool feeTransferSuccess = executor.call.value(gasPrice.mul(gasLimit).mul(fee).div(100)).gas(2100)();
        emit ExecutedCallEvent(
            executor,
            transactionId,
            success,
            refundSuccess,
            feeTransferSuccess
        );
    }

    function cancelScheduledTransaction(
        uint256 scheduleTime,
        address executor,
        address target,
        uint256 value,
        uint256 gasLimit,
        uint256 gasPrice,
        uint256 fee,
        bytes data,
        uint256 transactionId,
        bool isTimestamp
    ) external returns (bool) {
        if (isTimestamp) {
            require(
                scheduleTime >= block.timestamp + 3 minutes ||
                scheduleTime <= block.timestamp - 5 minutes
            );
        } else {
            require(
                scheduleTime > block.number + 10 ||
                scheduleTime <= block.number - 20
            );
        }
        require(
            scheduledTransactions[transactionId] ==
                keccak256(
                    abi.encodePacked(
                        scheduleTime,
                        executor,
                        target,
                        value,
                        gasLimit,
                        gasPrice,
                        fee,
                        data,
                        isTimestamp
                    )
                )
        );
        require(msg.sender == executor);
        ProxyContract proxy = ProxyContract(proxies[msg.sender]);
        bool success = proxy.executeTransaction(
            executor,
            value.add(gasPrice.mul(gasLimit)).add(fee),
            3000,
            hex"00"
        );
        require(success);
        emit CancelScheduledTxEvent(
            executor,
            value.add(gasPrice.mul(gasLimit)).add(fee),
            success,
            transactionId
        );
        delete scheduledTransactions[transactionId];
        return true;
    }

    function withdrawBalance() public {
        require(msg.sender == admin);
        admin.transfer(address(this).balance);
    }

    function changeFee(uint256 newFee) public {
        require(msg.sender == admin);
        require(lastFeeChange < block.timestamp);
        uint256 oldFee = fee;
        if (newFee > fee) {
            require(
                newFee.sub(fee).mul(100).div(fee) <= 10
            );
            fee = newFee;
        }
        lastFeeChange = block.timestamp + 1 days;
        emit FeeChanged(oldFee, fee);
    }

    function () public payable {}
}
```