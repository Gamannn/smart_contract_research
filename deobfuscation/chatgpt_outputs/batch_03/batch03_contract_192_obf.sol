pragma solidity ^0.4.24;

contract TokenTransfer {
    function transferTokens(address token, address to, uint256 amount) internal returns (bool success) {
        bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", to, amount);
        assembly {
            let callSuccess := call(sub(gas, 10000), token, 0, add(data, 0x20), mload(data), 0, 0)
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, returndatasize)
            switch returndatasize
            case 0 {
                success := callSuccess
            }
            case 0x20 {
                success := iszero(or(iszero(callSuccess), iszero(mload(ptr))))
            }
            default {
                success := 0
            }
        }
    }
}

contract Proxy {
    struct Storage {
        address masterCopy;
    }
    Storage internal s2c;

    constructor(address masterCopy) public {
        require(masterCopy != address(0), "Invalid master copy address provided");
        s2c.masterCopy = masterCopy;
    }

    function () external payable {
        assembly {
            let masterCopy := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas, masterCopy, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) { revert(0, returndatasize()) }
            return(0, returndatasize())
        }
    }

    function getMasterCopy() public view returns (address) {
        return s2c.masterCopy;
    }

    function constantFunction() public pure returns (uint256) {
        return 2;
    }
}

contract ProxyWithInitialization is Proxy {
    constructor(address masterCopy, bytes initializationData) Proxy(masterCopy) public {
        if (initializationData.length > 0) {
            assembly {
                let masterCopy := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)
                let success := delegatecall(sub(gas, 10000), masterCopy, add(initializationData, 0x20), mload(initializationData), 0, 0)
                let ptr := mload(0x40)
                returndatacopy(ptr, 0, returndatasize)
                if eq(success, 0) { revert(ptr, returndatasize) }
            }
        }
    }
}

contract SafeCreation is ProxyWithInitialization, TokenTransfer {
    constructor(
        address masterCopy,
        bytes initializationData,
        address payable recipient,
        address token,
        uint256 amount
    ) ProxyWithInitialization(masterCopy, initializationData) public {
        if (amount > 0) {
            if (token == address(0)) {
                require(recipient.send(amount), "Could not pay safe creation with ether");
            } else {
                require(transferTokens(token, recipient, amount), "Could not pay safe creation with token");
            }
        }
    }
}