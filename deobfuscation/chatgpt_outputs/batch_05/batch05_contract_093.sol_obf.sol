```solidity
pragma solidity ^0.5.7;

contract ContractManager {
    address public comptrollerAddress;
    address public cEtherAddress;
    address public managerAddress;
    mapping(address => bool) public whiteListedAddresses;
    address public managerProposed;
    address public lastCreatedAddress;

    constructor(address _comptrollerAddress, address _cEtherAddress) public payable {
        comptrollerAddress = _comptrollerAddress;
        cEtherAddress = _cEtherAddress;
        managerAddress = msg.sender;
        whiteListedAddresses[msg.sender] = true;
    }

    function() external payable {}

    function proposeNewManager(address _newManager) external {
        require(msg.sender == managerAddress, "Only the current manager can propose a new manager");
        managerProposed = _newManager;
    }

    function acceptManagerRole() external {
        require(msg.sender == managerProposed, "Only the proposed manager can accept the role");
        whiteListedAddresses[managerAddress] = false;
        whiteListedAddresses[managerProposed] = true;
        managerAddress = managerProposed;
    }

    function deployContract(bytes memory _contractCode) public returns (address newContractAddress) {
        bytes memory contractCode = _contractCode;
        assembly {
            let compiledBytes := mload(contractCode)
            let contractStart := add(contractCode, 0x20)
            let cursor := add(contractStart, compiledBytes)
            mstore(cursor, caller)
            cursor := add(cursor, 0x20)
            mstore(cursor, address)
            cursor := add(cursor, 0x20)
            mstore(cursor, sload(comptrollerAddress_slot))
            cursor := add(cursor, 0x20)
            mstore(cursor, sload(cEtherAddress_slot))
            cursor := add(cursor, 0x20)
            mstore(0x40, cursor)
            let contractSize := sub(cursor, contractStart)
            newContractAddress := create2(0, contractStart, contractSize, caller)
            if iszero(newContractAddress) {
                mstore(32, 1)
                revert(63, 1)
            }
            sstore(lastCreatedAddress_slot, newContractAddress)
            sstore(add(whiteListedAddresses_slot, newContractAddress), 1)
        }
    }

    function getContractAddress(address _inputAddress) public view returns (address calculatedAddress, bool isWhiteListed) {
        calculatedAddress = calculateAddress(_inputAddress);
        isWhiteListed = whiteListedAddresses[calculatedAddress];
    }

    function calculateAddress(address _inputAddress) public view returns (address calculatedAddress) {
        bytes memory contractCode = new bytes(0);
        assembly {
            let compiledBytes := mload(contractCode)
            let contractStart := add(contractCode, 0x20)
            let cursor := add(contractStart, compiledBytes)
            mstore(cursor, _inputAddress)
            cursor := add(cursor, 0x20)
            mstore(cursor, address)
            cursor := add(cursor, 0x20)
            mstore(cursor, sload(comptrollerAddress_slot))
            cursor := add(cursor, 0x20)
            mstore(cursor, sload(cEtherAddress_slot))
            cursor := add(cursor, 0x20)
            mstore(0x40, cursor)
            let contractSize := sub(cursor, contractStart)
            let contractHash := keccak256(contractStart, contractSize)
            mstore(contractCode, or(shl(0xa0, 0xff), address))
            mstore(add(contractCode, 0x20), _inputAddress)
            mstore(add(contractCode, 0x40), contractHash)
            let addressHash := keccak256(add(contractCode, 11), 85)
            calculatedAddress := and(addressHash, 0xffffffffffffffffffffffffffffffffffffffff)
        }
    }

    function executeTransaction(address _to, uint256 _value) external {
        require(whiteListedAddresses[msg.sender], "Caller is not whitelisted");
        uint256[3] memory data;
        uint256[1] memory result;
        assembly {
            let m_in_size := 0
            let wei_to_send := _value
            let dest := caller
            if _to {
                mstore(data, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
                mstore(add(data, 4), caller)
                mstore(add(data, 0x24), _value)
                dest := _to
                m_in_size := 0x44
                wei_to_send := 0
            }
            let callResult := call(gas, dest, wei_to_send, data, m_in_size, result, 32)
            if iszero(callResult) {
                mstore(32, 2)
                revert(63, 1)
            }
            if _to {
                if iszero(mload(result)) {
                    mstore(32, 3)
                    revert(63, 1)
                }
            }
        }
    }
}
```