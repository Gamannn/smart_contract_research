```solidity
pragma solidity ^0.5.4;

contract Wallet {
    address public masterContractAddress;
    uint public walletTxCount;
    uint public userAccountID;
    
    event Execution(address indexed to, uint value, bytes data);
    event ExecutionFailure(address indexed to, uint value, bytes data);
    event Deposit(address indexed sender, uint value);
    
    constructor(address _masterContractAddress) public {
        masterContractAddress = _masterContractAddress;
        walletTxCount = 0;
        userAccountID = 0;
    }
    
    function getUserControlAddress() public view returns(address) {
        MasterContract master = MasterContract(masterContractAddress);
        return master.getUserControlAddress(userAccountID);
    }
    
    function getWalletTxCount() public view returns(uint) {
        return walletTxCount;
    }
    
    modifier onlyMaster() {
        MasterContract master = MasterContract(masterContractAddress);
        require(master.isSendingKey(msg.sender) == true);
        _;
    }
    
    function() payable external {
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value);
        } else if (msg.data.length > 0) {
            MasterContract master = MasterContract(masterContractAddress);
            address contractAddress = master.getContractAddress();
            
            assembly {
                calldatacopy(0, 0, calldatasize())
                let success := staticcall(gas, contractAddress, 0, calldatasize(), 0, 0)
                returndatacopy(0, 0, returndatasize())
                switch success
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
            }
        }
    }
    
    function execute(
        bytes memory data,
        address to,
        uint value,
        bytes memory signedData
    ) public onlyMaster returns (bool) {
        address userControlAddress = getUserControlAddress();
        MasterContract master = MasterContract(masterContractAddress);
        
        bytes32 messageHash = master.getMessageHash(
            signedData,
            to,
            value,
            walletTxCount
        );
        
        address recoveredAddress = master.recoverSigner(messageHash, signedData);
        
        if (recoveredAddress == userControlAddress) {
            if (callContract(to, value, signedData.length, signedData)) {
                emit Execution(to, value, signedData);
                walletTxCount = walletTxCount + 1;
            } else {
                emit ExecutionFailure(to, value, signedData);
                walletTxCount = walletTxCount + 1;
            }
            return true;
        } else {
            return false;
        }
    }
    
    function callContract(
        address to,
        uint value,
        uint dataLength,
        bytes memory data
    ) private returns (bool) {
        bool success;
        assembly {
            let x := mload(0x40)
            let d := add(data, 32)
            success := call(
                sub(gas, 34710),
                to,
                value,
                d,
                dataLength,
                x,
                0
            )
        }
        return success;
    }
}

contract MasterContract {
    function getUserAccountID(uint accountIndex) public view returns (address);
    function isSendingKey(address key) public view returns (bool);
    function getContractAddress() public view returns (address);
    function recoverSigner(bytes32 hash, bytes memory signature) public pure returns (address);
    function getMessageHash(
        bytes memory data,
        address to,
        uint value,
        uint nonce
    ) public view returns(bytes32);
}
```