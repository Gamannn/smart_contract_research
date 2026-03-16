```solidity
pragma solidity ^0.5.3;

interface IRegistry {
    function owner() external view returns (address);
    function exchangeProxy() external view returns (address);
    function isApproved(address trader) external view returns (bool);
    function areBothApproved(address trader1, address trader2) external view returns (bool);
    function update() external;
}

contract BaseContract {
    function getRegistry() internal pure returns (IRegistry) {
        return IRegistry(address(0x12345678982cB986Dd291B50239295E3Cb10Cdf6));
    }
}

contract Modifiers is BaseContract {
    modifier onlyOwner() {
        require(msg.sender == getRegistry().owner(), "onlyOwner: method called by non-owner.");
        _;
    }
    
    modifier onlyApprovedTrader(address trader) {
        require(msg.sender == Constants.EXCHANGE_PROXY, "onlyApprovedTrader: called not by exchange proxy.");
        require(getRegistry().isApproved(trader), "onlyApprovedTrader: requires approval of the latest contract code by trader.");
        _;
    }
    
    modifier bothTradersApproved(address trader1, address trader2) {
        require(msg.sender == Constants.EXCHANGE_PROXY, "bothTradersApproved: called not by exchange proxy.");
        require(getRegistry().areBothApproved(trader1, trader2), "bothTradersApproved: requires approval of the latest contract code by both traders.");
        _;
    }
}

interface ITreasury {
    function withdraw(address trader, address payable recipient, uint amount) external;
    function withdrawToken(uint16 tokenCode, address trader, address recipient, uint amount) external;
    function transfer(uint16 tokenCode, address from, address to, uint amount) external;
    function transferWithFee(uint16 tokenCode, address from, address recipient, uint amount, address feeRecipient, uint fee) external;
    function swap(
        uint16 tokenCodeA,
        uint16 tokenCodeB,
        address traderA,
        address traderB,
        address feeRecipient,
        uint amountA,
        uint amountB,
        uint feeA,
        uint feeB
    ) external;
}

contract Treasury is Modifiers, ITreasury {
    mapping(uint16 => address) public tokenContracts;
    mapping(uint176 => uint) public balances;
    
    mapping(address => uint) public emergencyReleaseTimestamps;
    
    event SetActive(bool active);
    event ChangeTokenInfo(uint16 tokenCode, address tokenContract);
    event StartEmergencyRelease(address trader);
    event Deposit(uint16 tokenCode, address trader, uint amount);
    event Withdrawal(uint16 tokenCode, address trader, address recipient, uint amount);
    event EmergencyRelease(uint16 tokenCode, address trader, uint amount);
    
    constructor() public {}
    
    modifier onlyActive() {
        require(Constants.ACTIVE, "onlyActive: Inactive treasury only allows withdrawals.");
        _;
    }
    
    modifier emergencyReleaseAllowed(address trader) {
        uint timestamp = emergencyReleaseTimestamps[trader];
        require(timestamp > 0 && block.timestamp > timestamp, "emergencyReleaseAllowed: Challenge should be active and timestamp expired.");
        _;
    }
    
    function setActive(bool active) external onlyOwner() {
        Constants.ACTIVE = active;
        emit SetActive(Constants.ACTIVE);
    }
    
    function setTokenContract(uint16 tokenCode, address tokenContract) external onlyOwner() {
        require(tokenCode != 0, "setTokenContract: Token code of zero is reserved for Ether.");
        require(tokenContracts[tokenCode] == address(0), "setTokenContract: Token contract address can be assigned only once.");
        tokenContracts[tokenCode] = tokenContract;
        emit ChangeTokenInfo(tokenCode, tokenContract);
    }
    
    function startEmergencyRelease() external {
        emergencyReleaseTimestamps[msg.sender] = block.timestamp + Constants.EMERGENCY_RELEASE_DELAY;
        emit StartEmergencyRelease(msg.sender);
    }
    
    function clearEmergencyRelease(address trader) private {
        if (emergencyReleaseTimestamps[trader] != 0) {
            emergencyReleaseTimestamps[trader] = 0;
        }
    }
    
    function depositEther(address trader) external payable {
        emit Deposit(0, trader, msg.value);
        _addToBalance(0, trader, msg.value);
    }
    
    function depositToken(uint176 packedData, uint amount) external {
        uint16 tokenCode = uint16(packedData >> 160);
        address tokenContract = tokenContracts[tokenCode];
        require(tokenContract != address(0), "depositToken: Registered token contract.");
        require(_transferFrom(tokenContract, msg.sender, address(this), amount), "depositToken: Could not transfer ERC-20 tokens using transferFrom.");
        
        address trader = address(packedData);
        emit Deposit(tokenCode, trader, amount);
        _addToBalance(tokenCode, trader, amount);
    }
    
    function emergencyReleaseEther() external emergencyReleaseAllowed(msg.sender) {
        uint amount = _getAndClearBalance(0, msg.sender);
        emit EmergencyRelease(0, msg.sender, amount);
        msg.sender.transfer(amount);
    }
    
    function emergencyReleaseToken(uint16 tokenCode) external emergencyReleaseAllowed(msg.sender) {
        uint amount = _getAndClearBalance(tokenCode, msg.sender);
        emit EmergencyRelease(tokenCode, msg.sender, amount);
        address tokenContract = tokenContracts[tokenCode];
        require(tokenContract != address(0), "emergencyReleaseToken: Registered token contract.");
        require(_transfer(tokenContract, msg.sender, amount), "emergencyReleaseToken: Could not transfer ERC-20 tokens using transfer.");
    }
    
    function withdraw(address trader, address payable recipient, uint amount) external onlyActive() onlyApprovedTrader(trader) {
        _subtractFromBalance(0, trader, amount);
        clearEmergencyRelease(trader);
        emit Withdrawal(0, trader, recipient, amount);
        recipient.transfer(amount);
    }
    
    function withdrawToken(uint16 tokenCode, address trader, address recipient, uint amount) external onlyActive() onlyApprovedTrader(trader) {
        _subtractFromBalance(tokenCode, trader, amount);
        clearEmergencyRelease(trader);
        address tokenContract = tokenContracts[tokenCode];
        require(tokenContract != address(0), "withdrawToken: Registered token contract.");
        require(_transfer(tokenContract, recipient, amount), "withdrawToken: Could not transfer ERC-20 tokens using transfer.");
        emit Withdrawal(tokenCode, trader, recipient, amount);
    }
    
    function transfer(uint16 tokenCode, address from, address to, uint amount) external onlyActive() onlyApprovedTrader(from) {
        clearEmergencyRelease(from);
        _subtractFromBalance(tokenCode, from, amount);
        _addToBalance(tokenCode, to, amount);
    }
    
    function transferWithFee(uint16 tokenCode, address from, address recipient, uint amount, address feeRecipient, uint fee) external onlyActive() onlyApprovedTrader(from) {
        clearEmergencyRelease(from);
        _subtractFromBalance(tokenCode, from, amount + fee);
        _addToBalance(tokenCode, recipient, amount);
        _addToBalance(tokenCode, feeRecipient, fee);
    }
    
    function swap(
        uint16 tokenCodeA,
        uint16 tokenCodeB,
        address traderA,
        address traderB,
        address feeRecipient,
        uint amountA,
        uint amountB,
        uint feeA,
        uint feeB
    ) external onlyActive() bothTradersApproved(traderA, traderB) {
        clearEmergencyRelease(traderA);
        clearEmergencyRelease(traderB);
        
        _subtractFromBalance(tokenCodeA, traderA, amountA + feeA);
        _subtractFromBalance(tokenCodeB, traderB, amountB + feeB);
        
        _addToBalance(tokenCodeA, traderB, amountA);
        _addToBalance(tokenCodeB, traderA, amountB);
        
        _addToBalance(tokenCodeA, feeRecipient, feeA);
        _addToBalance(tokenCodeB, feeRecipient, feeB);
    }
    
    function _subtractFromBalance(uint tokenCode, address trader, uint amount) private {
        uint176 key = uint176(tokenCode) << 160 | uint176(trader);
        uint currentBalance = balances[key];
        require(currentBalance >= amount, "_subtractFromBalance: Enough funds.");
        balances[key] = currentBalance - amount;
    }
    
    function _getAndClearBalance(uint tokenCode, address trader) private returns (uint amount) {
        uint176 key = uint176(tokenCode) << 160 | uint176(trader);
        amount = balances[key];
        balances[key] = 0;
    }
    
    function _addToBalance(uint tokenCode, address trader, uint amount) private {
        uint176 key = uint176(tokenCode) << 160 | uint176(trader);
        uint currentBalance = balances[key];
        require(currentBalance + amount >= currentBalance, "_addToBalance: No overflow.");
        balances[key] = currentBalance + amount;
    }
    
    function _transfer(address tokenContract, address recipient, uint amount) internal returns (bool success) {
        (bool callSuccess, bytes memory data) = tokenContract.call(abi.encodeWithSelector(0xa9059cbb, recipient, amount));
        success = false;
        if (callSuccess) {
            if (data.length == 0) {
                success = true;
            } else if (data.length == 32) {
                assembly {
                    success := mload(add(data, 0x20))
                }
            }
        }
    }
    
    function _transferFrom(address tokenContract, address from, address to, uint amount) internal returns (bool success) {
        (bool callSuccess, bytes memory data) = tokenContract.call(abi.encodeWithSelector(0x23b872dd, from, to, amount));
        success = false;
        if (callSuccess) {
            if (data.length == 0) {
                success = true;
            } else if (data.length == 32) {
                assembly {
                    success := mload(add(data, 0x20))
                }
            }
        }
    }
}

library Constants {
    bool public constant ACTIVE = false;
    uint256 public constant EMERGENCY_RELEASE_DELAY = 2 days;
    address public constant REGISTRY = 0x12345678982cB986Dd291B50239295E3Cb10Cdf6;
    address public constant TOKEN_PROXY = 0x12345678979f29eBc99E00bdc5693ddEa564cA80;
    address public constant EXCHANGE_PROXY = 0x1234567896326230a28ee368825D11fE6571Be4a;
}
```