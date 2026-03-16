pragma solidity ^0.5.3;

contract BaseContract {
    function getOwner() internal pure returns (OwnerInterface) {
        return OwnerInterface(contractData.ownerAddress);
    }
}

interface OwnerInterface {
    function getOwnerAddress() external view returns (address);
    function getExchangeProxy() external view returns (address);
    function isApprovedContract(address contractAddress) external view returns (bool);
    function areBothTradersApproved(address trader1, address trader2) external view returns (bool);
    function execute() external;
}

contract AccessControl is BaseContract {
    modifier onlyOwner() {
        require(msg.sender == getOwner().getOwnerAddress(), "Only owner can call this function.");
        _;
    }

    modifier onlyExchangeProxy(address contractAddress) {
        require(msg.sender == contractData.exchangeProxy, "Function called not by exchange proxy.");
        require(getOwner().isApprovedContract(contractAddress), "Contract not approved by the latest contract code.");
        _;
    }

    modifier onlyApprovedTraders(address trader1, address trader2) {
        require(msg.sender == contractData.exchangeProxy, "Function called not by exchange proxy.");
        require(getOwner().areBothTradersApproved(trader1, trader2), "Both traders must approve the latest contract code.");
        _;
    }
}

interface TreasuryInterface {
    function deposit(address token, address payable recipient, uint amount) external;
    function withdraw(uint16 tokenCode, address token, address recipient, uint amount) external;
    function emergencyWithdraw(uint16 tokenCode, address trader, address recipient, uint amount) external;
    function transfer(uint16 tokenCode, address trader, address recipient, uint amount, address feeRecipient, uint feeAmount) external;
    function multiTransfer(uint16 tokenCode1, uint16 tokenCode2, address trader1, address trader2, address feeRecipient, uint amount1, uint amount2, uint feeAmount1, uint feeAmount2) external;
}

contract Treasury is AccessControl, TreasuryInterface {
    mapping (uint16 => address) public tokenContracts;
    mapping (uint176 => uint) public balances;
    event SetActive(bool isActive);
    event ChangeTokenInfo(uint16 tokenCode, address tokenContract);
    event StartEmergencyRelease(address trader);
    event Deposit(uint16 tokenCode, address trader, uint amount);
    event Withdrawal(uint16 tokenCode, address token, address recipient, uint amount);
    event EmergencyRelease(uint16 tokenCode, address trader, uint amount);
    mapping (address => uint) public emergencyReleaseTimestamps;

    constructor () public { }

    modifier onlyActive() {
        require(contractData.isActive, "Inactive treasury only allows withdrawals.");
        _;
    }

    modifier onlyAfterChallenge(address trader) {
        uint challengeTimestamp = emergencyReleaseTimestamps[trader];
        require(challengeTimestamp > 0 && block.timestamp > challengeTimestamp, "Challenge must be active and expired.");
        _;
    }

    function setActive(bool isActive) external onlyOwner() {
        contractData.isActive = isActive;
        emit SetActive(contractData.isActive);
    }

    function changeTokenInfo(uint16 tokenCode, address tokenContract) external onlyOwner() {
        require(tokenCode != 0, "Token code of zero is reserved for Ether.");
        require(tokenContracts[tokenCode] == address(0), "Token contract address can be assigned only once.");
        tokenContracts[tokenCode] = tokenContract;
        emit ChangeTokenInfo(tokenCode, tokenContract);
    }

    function startEmergencyRelease() external {
        emergencyReleaseTimestamps[msg.sender] = block.timestamp + contractData.challengeDuration;
        emit StartEmergencyRelease(msg.sender);
    }

    function resetEmergencyRelease(address trader) private {
        if (emergencyReleaseTimestamps[trader] != 0) {
            emergencyReleaseTimestamps[trader] = 0;
        }
    }

    function depositEther(address trader) external payable {
        emit Deposit(0, trader, msg.value);
        updateBalance(0, trader, msg.value);
    }

    function depositToken(uint176 tokenTrader, uint amount) external {
        uint16 tokenCode = uint16(tokenTrader >> 160);
        address tokenContract = tokenContracts[tokenCode];
        require(tokenContract != address(0), "Registered token contract.");
        require(transferFrom(tokenContract, msg.sender, address(this), amount), "Could not transfer ERC-20 tokens using transferFrom.");
        address trader = address(tokenTrader);
        emit Deposit(tokenCode, trader, amount);
        updateBalance(tokenCode, trader, amount);
    }

    function emergencyWithdrawEther() external onlyAfterChallenge(msg.sender) {
        uint amount = getBalance(0, msg.sender);
        emit EmergencyRelease(0, msg.sender, amount);
        msg.sender.transfer(amount);
    }

    function emergencyWithdrawToken(uint16 tokenCode) external onlyAfterChallenge(msg.sender) {
        uint amount = getBalance(tokenCode, msg.sender);
        emit EmergencyRelease(tokenCode, msg.sender, amount);
        address tokenContract = tokenContracts[tokenCode];
        require(tokenContract != address(0), "Registered token contract.");
        require(transfer(tokenContract, msg.sender, amount), "Could not transfer ERC-20 tokens using transfer.");
    }

    function withdraw(uint16 tokenCode, address token, address payable recipient, uint amount) external onlyActive() onlyExchangeProxy(token) {
        decreaseBalance(tokenCode, token, amount);
        resetEmergencyRelease(token);
        emit Withdrawal(tokenCode, token, recipient, amount);
        recipient.transfer(amount);
    }

    function withdrawToken(uint16 tokenCode, address token, address recipient, uint amount) external onlyActive() onlyExchangeProxy(token) {
        decreaseBalance(tokenCode, token, amount);
        resetEmergencyRelease(token);
        address tokenContract = tokenContracts[tokenCode];
        require(tokenContract != address(0), "Registered token contract.");
        require(transfer(tokenContract, recipient, amount), "Could not transfer ERC-20 tokens using transfer.");
        emit Withdrawal(tokenCode, token, recipient, amount);
    }

    function emergencyWithdraw(uint16 tokenCode, address trader, address recipient, uint amount) external onlyActive() onlyExchangeProxy(trader) {
        resetEmergencyRelease(trader);
        decreaseBalance(tokenCode, trader, amount);
        updateBalance(tokenCode, recipient, amount);
    }

    function transfer(uint16 tokenCode, address trader, address recipient, uint amount, address feeRecipient, uint feeAmount) external onlyActive() onlyExchangeProxy(trader) {
        resetEmergencyRelease(trader);
        decreaseBalance(tokenCode, trader, amount + feeAmount);
        updateBalance(tokenCode, recipient, amount);
        updateBalance(tokenCode, feeRecipient, feeAmount);
    }

    function multiTransfer(uint16 tokenCode1, uint16 tokenCode2, address trader1, address trader2, address feeRecipient, uint amount1, uint amount2, uint feeAmount1, uint feeAmount2) external onlyActive() onlyApprovedTraders(trader1, trader2) {
        resetEmergencyRelease(trader1);
        resetEmergencyRelease(trader2);
        decreaseBalance(tokenCode1, trader1, amount1 + feeAmount1);
        decreaseBalance(tokenCode2, trader2, amount2 + feeAmount2);
        updateBalance(tokenCode1, trader2, amount1);
        updateBalance(tokenCode2, trader1, amount2);
        updateBalance(tokenCode1, feeRecipient, feeAmount1);
        updateBalance(tokenCode2, feeRecipient, feeAmount2);
    }

    function decreaseBalance(uint tokenCode, address trader, uint amount) private {
        uint176 tokenTrader = uint176(tokenCode) << 160 | uint176(trader);
        uint currentBalance = balances[tokenTrader];
        require(currentBalance >= amount, "Insufficient funds.");
        balances[tokenTrader] = currentBalance - amount;
    }

    function getBalance(uint tokenCode, address trader) private returns (uint amount) {
        uint176 tokenTrader = uint176(tokenCode) << 160 | uint176(trader);
        amount = balances[tokenTrader];
        balances[tokenTrader] = 0;
    }

    function updateBalance(uint tokenCode, address trader, uint amount) private {
        uint176 tokenTrader = uint176(tokenCode) << 160 | uint176(trader);
        uint currentBalance = balances[tokenTrader];
        require(currentBalance + amount >= currentBalance, "Overflow error.");
        balances[tokenTrader] = currentBalance + amount;
    }

    function transfer(address tokenContract, address recipient, uint amount) internal returns (bool success) {
        (bool callSuccess, bytes memory returnData) = tokenContract.call(abi.encodeWithSelector(0xa9059cbb, recipient, amount));
        success = false;
        if (callSuccess) {
            if (returnData.length == 0) {
                success = true;
            } else if (returnData.length == 32) {
                assembly {
                    success := mload(add(returnData, 0x20))
                }
            }
        }
    }

    function transferFrom(address tokenContract, address from, address to, uint amount) internal returns (bool success) {
        (bool callSuccess, bytes memory returnData) = tokenContract.call(abi.encodeWithSelector(0x23b872dd, from, to, amount));
        success = false;
        if (callSuccess) {
            if (returnData.length == 0) {
                success = true;
            } else if (returnData.length == 32) {
                assembly {
                    success := mload(add(returnData, 0x20))
                }
            }
        }
    }

    struct ContractData {
        bool isActive;
        uint256 challengeDuration;
        address ownerAddress;
        address exchangeProxy;
        address treasuryAddress;
    }

    ContractData contractData = ContractData(
        false,
        2 days,
        0x12345678982cB986Dd291B50239295E3Cb10Cdf6,
        0x12345678979f29eBc99E00bdc5693ddEa564cA80,
        0x1234567896326230a28ee368825D11fE6571Be4a
    );
}