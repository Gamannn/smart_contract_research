pragma solidity ^0.5.4;

contract WalletContract {
    address masterContractAddress;
    uint userAccountID;
    uint walletTxCount;

    event Execution(address indexed to, uint value, bytes data);
    event ExecutionFailure(address indexed to, uint value, bytes data);
    event Deposit(address indexed sender, uint value);

    function getMasterContractAddress() public view returns(address) {
        MasterContractInterface masterContract = MasterContractInterface(masterContractAddress);
        return masterContract.getMasterContractAddress();
    }

    function getWalletTxCount() public view returns(uint) {
        return walletTxCount;
    }

    modifier onlyAuthorized() {
        MasterContractInterface masterContract = MasterContractInterface(masterContractAddress);
        require(masterContract.isAuthorized(msg.sender) == true);
        _;
    }

    function() payable external {
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value);
        } else if (msg.data.length > 0) {
            MasterContractInterface masterContract = MasterContractInterface(masterContractAddress);
            address target = masterContract.getMasterContractAddress();
            assembly {
                calldatacopy(0, 0, calldatasize())
                let result := staticcall(gas, target, 0, calldatasize(), 0, 0)
                returndatacopy(0, 0, returndatasize())
                switch result
                case 0 { revert(0, returndatasize()) }
                default { return (0, returndatasize()) }
            }
        }
    }

    function executeTransaction(bytes memory signature, address to, uint value, bytes memory data) public onlyAuthorized returns (bool) {
        address signer = getMasterContractAddress();
        MasterContractInterface masterContract = MasterContractInterface(masterContractAddress);
        bytes32 txHash = masterContract.getTransactionHash(data, walletTxCount);
        address recoveredSigner = masterContract.recoverSigner(txHash, signature);
        if (recoveredSigner == signer) {
            if (executeCall(to, value, data.length, data)) {
                emit Execution(to, value, data);
                walletTxCount += 1;
            } else {
                emit ExecutionFailure(to, value, data);
                walletTxCount += 1;
            }
            return true;
        } else {
            return false;
        }
    }

    function executeCall(address to, uint value, uint dataLength, bytes memory data) private returns (bool) {
        bool success;
        assembly {
            let x := mload(0x40)
            let d := add(data, 32)
            success := call(sub(gas, 34710), to, value, d, dataLength, x, 0)
        }
        return success;
    }
}

contract MasterContractInterface {
    function getMasterContractAddress() public view returns (address);
    function isAuthorized(address sender) public view returns (bool);
    function getTransactionHash(bytes memory data, uint walletTxCount) public view returns(bytes32);
    function recoverSigner(bytes32 txHash, bytes memory signature) public pure returns (address);
}