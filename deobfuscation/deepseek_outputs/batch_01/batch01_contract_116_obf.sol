pragma solidity ^0.5.7;

contract MarginFactory {
    mapping(address => bool) private approvedMarginCodes;
    mapping(address => bool) private whiteListedAddresses;
    address private manager;
    address private managerProposed;
    address private defaultCode;
    
    event MarginSetup(
        address indexed user,
        address marginAccount
    );
    
    constructor(address _defaultCode) public payable {
        manager = msg.sender;
        defaultCode = _defaultCode;
        whiteListedAddresses[msg.sender] = true;
    }
    
    function () external payable {}
    
    function setMarginCodeApproval(address code, bool approved) external {
        require(msg.sender == manager, "Unauthorized");
        approvedMarginCodes[code] = approved;
    }
    
    function setDefaultCode(address _defaultCode) external {
        require(msg.sender == manager, "Unauthorized");
        approvedMarginCodes[_defaultCode] = true;
        defaultCode = _defaultCode;
    }
    
    function setupMarginAccount(address code) external {
        address marginAccount = computeAddress(msg.sender);
        require(marginAccount.code.length > 0, "Margin account not deployed");
        
        bool approved = approvedMarginCodes[code];
        whiteListedAddresses[marginAccount] = approved;
        
        (bool success, ) = marginAccount.call(
            abi.encodeWithSignature("setMarginCode(address)", code)
        );
        require(success, "Setup failed");
    }
    
    function proposeNewManager(address newManager) external {
        require(msg.sender == manager, "Unauthorized");
        managerProposed = newManager;
    }
    
    function acceptManagerRole() external {
        require(msg.sender == managerProposed, "Unauthorized");
        whiteListedAddresses[manager] = false;
        whiteListedAddresses[managerProposed] = true;
        manager = managerProposed;
    }
    
    function createMarginAccount() external returns (address marginAccount) {
        bytes memory bytecode = s2c.marginAccountBytecode;
        bytes32 salt = bytes32(uint256(msg.sender));
        
        assembly {
            let bytecodeSize := mload(bytecode)
            let start := add(bytecode, 0x20)
            let end := add(start, bytecodeSize)
            
            mstore(end, caller())
            end := add(end, 0x20)
            mstore(end, address())
            end := add(end, 0x20)
            mstore(0x40, end)
            
            let size := sub(end, start)
            marginAccount := create2(0, start, size, salt)
            
            if iszero(marginAccount) {
                mstore(32, 1)
                revert(63, 1)
            }
            
            whiteListedAddresses[marginAccount] := 1
            
            let callData := mload(0x40)
            mstore(callData, 0x3b1ca3b500000000000000000000000000000000000000000000000000000000)
            mstore(add(callData, 0x04), sload(_default_code_slot))
            let result := call(gas, marginAccount, 0, callData, 0x24, 0, 0)
            if iszero(result) {
                mstore(32, 2)
                revert(63, 1)
            }
            
            mstore(callData, marginAccount)
            log2(callData, 32, 0xd1915076529a929900f0bed2467292f2d10fdeda6f13a14d8d793a45d7916eaf, caller())
        }
    }
    
    function getMarginAccount(address user) public view returns (address marginAccount, bool isWhiteListed) {
        marginAccount = computeAddress(user);
        isWhiteListed = whiteListedAddresses[marginAccount];
    }
    
    function computeAddress(address user) public view returns (address marginAccount) {
        bytes memory bytecode = s2c.marginAccountBytecode;
        
        assembly {
            let bytecodeSize := mload(bytecode)
            let start := add(bytecode, 0x20)
            let end := add(start, bytecodeSize)
            
            mstore(end, user)
            end := add(end, 0x20)
            mstore(end, address())
            end := add(end, 0x20)
            mstore(0x40, end)
            
            let size := sub(end, start)
            let contractHash := keccak256(start, size)
            
            let memPtr := mload(0x40)
            mstore(memPtr, or(shl(160, 0xff), address()))
            mstore(add(memPtr, 0x20), user)
            mstore(add(memPtr, 0x40), contractHash)
            
            let addressHash := keccak256(add(memPtr, 11), 85)
            marginAccount := and(addressHash, 0xffffffffffffffffffffffffffffffffffffffff)
        }
    }
    
    function withdraw(address token, uint256 amount) external {
        require(whiteListedAddresses[msg.sender], "Unauthorized");
        
        if (token == address(0)) {
            (bool success, ) = msg.sender.call.value(amount)("");
            require(success, "Transfer failed");
        } else {
            (bool success, bytes memory data) = token.call(
                abi.encodeWithSignature("transfer(address,uint256)", msg.sender, amount)
            );
            require(success, "Transfer failed");
            require(abi.decode(data, (bool)), "Transfer failed");
        }
    }
    
    struct MarginAccountData {
        address owner;
        address factory;
        address marginCode;
        bytes marginAccountBytecode;
    }
    
    MarginAccountData s2c = MarginAccountData(
        address(0),
        address(0),
        address(0),
        hex"608060405234801561001057600080fd5b506040516102963803806102968339818101604052604081101561003357600080fd5b81019080805190602001909291908051906020019092919050505081600155806002556001600355505061022a8061006c6000396000f3fe60806040526004361061003f5760003560e01c80633b1ca3b51461006657806380f76021146100b7578063893d20e81461010e578063ea87963414610165575b366000803760008036600080545af43d6000803e8060008114610061573d6000f35b3d6000fd5b34801561007257600080fd5b506100b56004803603602081101561008957600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff1690602001909291905050506101bc565b005b3480156100c357600080fd5b506100cc6101d8565b604051808273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200191505060405180910390f35b34801561011a57600080fd5b506101236101e2565b604051808273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200191505060405180910390f35b34801561017157600080fd5b5061017a6101ec565b604051808273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200191505060405180910390f35b6002543318156101d15760016020526001603ffd5b8060005550565b6000600254905090565b6000600154905090565b6000805490509056fea265627a7a72305820c1c7f4c7bd26890e7f00477b3ef68b6d45b2399e0b5eb13676dec4ad4737583e64736f6c634300050a0032"
    );
}