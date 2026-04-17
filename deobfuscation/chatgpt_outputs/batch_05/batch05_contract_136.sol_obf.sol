pragma solidity ^0.4.25;

contract InvestmentContract {
    mapping(address => uint256) public userBalances;
    mapping(address => uint256) public userLastBlock;
    
    address public techSupportAddress = 0x6366303f11bD1176DA860FD6571C5983F707854F;
    address public defaultReferrer = 0x6366303f11bD1176DA860FD6571C5983F707854F;
    
    uint256 public techSupportPercent = 2;
    uint256 public defaultReferrerPercent = 2;
    
    function calculateInterestRate(uint investment) private pure returns (uint) {
        if (investment >= 1e22) return 50;
        if (investment >= 7e21) return 47;
        if (investment >= 5e21) return 45;
        if (investment >= 3e21) return 42;
        if (investment >= 1e21) return 40;
        if (investment >= 5e20) return 35;
        if (investment >= 2e20) return 30;
        if (investment >= 1e20) return 27;
        return 25;
    }
    
    function transferToTechSupport(uint amount) private {
        techSupportAddress.transfer(amount * techSupportPercent / 100);
    }
    
    function extractAddressFromBytes(bytes data) private pure returns (address extractedAddress) {
        assembly {
            extractedAddress := mload(add(data, 20))
        }
    }
    
    function distributeReferralRewards(uint amount, address referrer) private {
        if (msg.data.length != 0) {
            address extractedReferrer = extractAddressFromBytes(msg.data);
            if (extractedReferrer != referrer) {
                referrer.transfer(amount * defaultReferrerPercent / 100);
                extractedReferrer.transfer(amount * defaultReferrerPercent / 100);
            } else {
                defaultReferrer.transfer(amount * defaultReferrerPercent / 100);
            }
        }
    }
    
    function () external payable {
        if (userBalances[msg.sender] != 0) {
            uint contractBalance = address(this).balance;
            uint interest = userBalances[msg.sender] * calculateInterestRate(contractBalance) / 1000 * (block.number - userLastBlock[msg.sender]) / 6100;
            msg.sender.transfer(interest);
        }
        
        if (msg.value > 0) {
            transferToTechSupport(msg.value);
            distributeReferralRewards(msg.value, msg.sender);
        }
        
        userLastBlock[msg.sender] = block.number;
        userBalances[msg.sender] += msg.value;
    }
}