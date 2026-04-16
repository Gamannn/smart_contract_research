```solidity
pragma solidity ^0.4.24;

contract TokenTransferHelper {
    function safeTransfer(
        address token,
        address to,
        uint256 amount
    ) internal returns (bool success) {
        bytes memory data = abi.encodeWithSignature(
            "transfer(address,uint256)",
            to,
            amount
        );
        
        assembly {
            let callSuccess := call(
                sub(gas, 10000),
                token,
                0,
                add(data, 0x20),
                mload(data),
                0,
                0
            )
            
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, returndatasize)
            
            switch returndatasize
                case 0 {
                    success := callSuccess
                }
                case 0x20 {
                    success := iszero(
                        or(
                            iszero(callSuccess),
                            iszero(mload(ptr))
                        )
                    )
                }
                default {
                    success := 0
                }
        }
    }
}

contract MasterCopy {
    address public masterCopy;
    
    constructor(address _masterCopy) public {
        require(_masterCopy != address(0), "Invalid master copy address provided");
        masterCopy = _masterCopy;
    }
    
    function () external payable {
        assembly {
            let mc := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)
            calldatacopy(0, 0, calldatasize)
            let success := delegatecall(gas, mc, 0, calldatasize, 0, 0)
            returndatacopy(0, 0, returndatasize)
            
            if eq(success, 0) {
                revert(0, returndatasize)
            }
            
            return(0, returndatasize)
        }
    }
    
    function getMasterCopy() public view returns (address) {
        return masterCopy;
    }
    
    function getVersion() public pure returns (uint256) {
        return 2;
    }
}

contract ProxyWithSetup is MasterCopy {
    constructor(
        address _masterCopy,
        bytes memory setupData
    ) MasterCopy(_masterCopy) public {
        if (setupData.length > 0) {
            assembly {
                let mc := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)
                let success := delegatecall(
                    sub(gas, 10000),
                    mc,
                    add(setupData, 0x20),
                    mload(setupData),
                    0,
                    0
                )
                
                let ptr := mload(0x40)
                returndatacopy(ptr, 0, returndatasize)
                
                if eq(success, 0) {
                    revert(ptr, returndatasize)
                }
            }
        }
    }
}

contract ProxyWithPayment is ProxyWithSetup, TokenTransferHelper {
    constructor(
        address _masterCopy,
        bytes memory setupData,
        address paymentReceiver,
        address paymentToken,
        uint256 paymentAmount
    ) ProxyWithSetup(_masterCopy, setupData) public {
        if (paymentAmount > 0) {
            if (paymentToken == address(0)) {
                require(
                    paymentReceiver.send(paymentAmount),
                    "Could not pay safe creation with ether"
                );
            } else {
                require(
                    safeTransfer(paymentToken, paymentReceiver, paymentAmount),
                    "Could not pay safe creation with token"
                );
            }
        }
    }
}
```