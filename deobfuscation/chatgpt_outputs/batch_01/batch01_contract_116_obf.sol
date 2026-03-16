pragma solidity ^0.5.7;

contract MarginManager {
    uint256[2**160] whiteListedAddresses;
    uint256[2**160] approvedMarginCode;
    
    event MarginSetup(address indexed user, address marginAddress);
    
    constructor(address defaultCode) public payable {
        assembly {
            sstore(_manager_address_slot, caller)
            sstore(_default_code_slot, defaultCode)
            sstore(add(_white_listed_addresses_slot, caller), 1)
        }
    }
    
    function () external payable {}
    
    function setMarginApproval(address user, bool isApproved) external {
        assembly {
            if xor(caller, sload(_manager_address_slot)) {
                mstore(32, 1)
                revert(63, 1)
            }
            sstore(add(_approved_margin_code_slot, user), isApproved)
        }
    }
    
    function setDefaultMarginCode(address defaultCode) external {
        assembly {
            if xor(caller, sload(_manager_address_slot)) {
                mstore(32, 1)
                revert(63, 1)
            }
            sstore(add(_approved_margin_code_slot, defaultCode), 1)
            sstore(_default_code_slot, defaultCode)
        }
    }
    
    function executeMargin(address user) external {
        address marginAddress = calculateMarginAddress(msg.sender);
        uint256[2] memory data;
        
        assembly {
            if iszero(extcodesize(marginAddress)) {
                mstore(32, 1)
                revert(63, 1)
            }
            let isApproved := sload(add(_approved_margin_code_slot, user))
            sstore(add(_white_listed_addresses_slot, marginAddress), isApproved)
            {
                mstore(data, 0x3b1ca3b500000000000000000000000000000000000000000000000000000000)
                mstore(add(data, 0x04), user)
                let res := call(gas, marginAddress, 0, data, 0x24, 0x00, 0x00)
                if iszero(res) {
                    mstore(32, 2)
                    revert(63, 1)
                }
            }
        }
    }
    
    function proposeNewManager(address newManager) external {
        assembly {
            if xor(caller, sload(_manager_address_slot)) {
                mstore(32, 1)
                revert(63, 1)
            }
            sstore(_manager_proposed_slot, newManager)
        }
    }
    
    function acceptManagerRole() external {
        assembly {
            let proposed := sload(_manager_proposed_slot)
            if xor(caller, proposed) {
                mstore(32, 1)
                revert(63, 1)
            }
            sstore(add(_white_listed_addresses_slot, sload(_manager_address_slot)), 0)
            sstore(add(_white_listed_addresses_slot, proposed), 1)
            sstore(_manager_address_slot, proposed)
        }
    }
    
    function createMargin() external returns (address marginAddress) {
        bytes memory code = s2c.marginCode;
        uint256[2] memory data;
        
        assembly {
            let compiledBytes := mload(code)
            let contractStart := add(code, 0x20)
            let cursor := add(contractStart, compiledBytes)
            mstore(cursor, caller)
            cursor := add(cursor, 0x20)
            mstore(cursor, address)
            cursor := add(cursor, 0x20)
            mstore(0x40, cursor)
            let contractSize := sub(cursor, contractStart)
            marginAddress := create2(0, contractStart, contractSize, caller)
            if iszero(marginAddress) {
                mstore(32, 1)
                revert(63, 1)
            }
            sstore(add(_white_listed_addresses_slot, marginAddress), 1)
            {
                mstore(data, 0x3b1ca3b500000000000000000000000000000000000000000000000000000000)
                mstore(add(data, 0x04), sload(_default_code_slot))
                let res := call(gas, marginAddress, 0, data, 0x24, 0x0, 0x0)
                if iszero(res) {
                    mstore(32, 2)
                    revert(63, 1)
                }
            }
            mstore(data, marginAddress)
            log2(data, 32, 0xd1915076529a929900f0bed2467292f2d10fdeda6f13a14d8d793a45d7916eaf, caller)
        }
    }
    
    function getMarginInfo(address user) public view returns (address marginAddress, bool isWhiteListed) {
        marginAddress = calculateMarginAddress(user);
        assembly {
            isWhiteListed := sload(add(_white_listed_addresses_slot, marginAddress))
        }
    }
    
    function calculateMarginAddress(address user) public view returns (address marginAddress) {
        bytes memory code = s2c.marginCode;
        
        assembly {
            let compiledBytes := mload(code)
            let contractStart := add(code, 0x20)
            let cursor := add(contractStart, compiledBytes)
            mstore(cursor, user)
            cursor := add(cursor, 0x20)
            mstore(cursor, address)
            cursor := add(cursor, 0x20)
            mstore(0x40, cursor)
            let contractSize := sub(cursor, contractStart)
            let contractHash := keccak256(contractStart, contractSize)
            mstore(code, or(shl(0xa0, 0xff), address))
            mstore(add(code, 0x20), user)
            mstore(add(code, 0x40), contractHash)
            let addressHash := keccak256(add(code, 11), 85)
            marginAddress := and(addressHash, 0xffffffffffffffffffffffffffffffffffffffff)
        }
    }
    
    function transferFunds(address recipient, uint256 amount) external {
        uint256[3] memory data;
        uint256[1] memory resultData;
        
        assembly {
            if iszero(sload(add(_white_listed_addresses_slot, caller))) {
                mstore(32, 1)
                revert(63, 1)
            }
            let mInSize := 0
            let weiToSend := amount
            let dest := caller
            if recipient {
                mstore(data, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
                mstore(add(data, 4), caller)
                mstore(add(data, 0x24), amount)
                dest := recipient
                mInSize := 0x44
                weiToSend := 0
            }
            let result := call(gas, dest, weiToSend, data, mInSize, resultData, 32)
            if iszero(result) {
                mstore(32, 2)
                revert(63, 1)
            }
            if recipient {
                if iszero(mload(resultData)) {
                    mstore(32, 3)
                    revert(63, 1)
                }
            }
        }
    }
    
    struct Scalar2Vector {
        address addr1;
        address addr2;
        address addr3;
        bytes marginCode;
    }
    
    Scalar2Vector s2c = Scalar2Vector(
        address(0), 
        address(0), 
        address(0), 
        hex"608060405234801561001057600080fd5b506040516102963803806102968339818101604052604081101561003357600080fd5b81019080805190602001909291908051906020019092919050505081600155806002556001600355505061022a8061006c6000396000f3fe60806040526004361061003f5760003560e01c80633b1ca3b51461006657806380f76021146100b7578063893d20e81461010e578063ea87963414610165575b366000803760008036600080545af43d6000803e8060008114610061573d6000f35b3d6000fd5b34801561007257600080fd5b506100b56004803603602081101561008957600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff1690602001909291905050506101bc565b005b3480156100c357600080fd5b506100cc6101d8565b604051808273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200191505060405180910390f35b34801561011a57600080fd5b506101236101e2565b604051808273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200191505060405180910390f35b34801561017157600080fd5b5061017a6101ec565b604051808273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200191505060405180910390f35b6002543318156101d15760016020526001603ffd5b8060005550565b6000600254905090565b6000600154905090565b6000805490509056fea265627a7a72305820c1c7f4c7bd26890e7f00477b3ef68b6d45b2399e0b5eb13676dec4ad4737583e64736f6c634300050a0032"
    );
}