```solidity
pragma solidity ^0.4.23;

contract InvestmentContract {
    mapping(address => uint256) public userInvestments;
    mapping(address => uint256) public lastInvestmentBlock;
    
    struct FeeDistribution {
        uint256 techSupportPercent;
        uint256 advertisingPercent;
        address techSupportAddress;
        uint256 referrerPercent;
        address defaultReferrer;
        uint256 advertisingAddressPercent;
        address advertisingAddress;
    }
    
    FeeDistribution feeDistribution = FeeDistribution(
        0, 
        2, 
        0x35580368B30742C9b6fcf859803ee7EEcED5485c, 
        2, 
        0x1308C144980c92E1825fae9Ab078B1CB5AAe8B23, 
        2, 
        0x0C7223e71ee75c6801a6C8DB772A30beb403683b
    );

    uint256[] public _integer_constant = [
        100, 
        1000000000000000000000, 
        45, 
        7, 
        35, 
        7000000000000000000000, 
        10000000000000000000000, 
        1000, 
        5000000000000000000000, 
        40, 
        0, 
        2, 
        200000000000000000000, 
        6100, 
        50, 
        42, 
        3000000000000000000000, 
        100000000000000000000, 
        500000000000000000000, 
        47, 
        30, 
        25, 
        27
    ];
    
    address payable[] public _address_constant = [
        0x0C7223e71ee75c6801a6C8DB772A30beb403683b, 
        0x35580368B30742C9b6fcf859803ee7EEcED5485c, 
        0x1308C144980c92E1825fae9Ab078B1CB5AAe8B23
    ];

    function calculateReward(uint256 investment) private pure returns (uint256) {
        if (investment >= 3e21) {
            return 42;
        }
        if (investment >= 1e21) {
            return 40;
        }
        if (investment >= 5e20) {
            return 35;
        }
        if (investment >= 2e20) {
            return 30;
        }
        if (investment >= 1e20) {
            return 27;
        }
        return 25;
    }

    function distributeFees(uint256 investment) private {
        feeDistribution.techSupportAddress.transfer(investment * feeDistribution.techSupportPercent / 100);
        feeDistribution.advertisingAddress.transfer(investment * feeDistribution.advertisingPercent / 100);
    }

    function extractAddressFromBytes(bytes data) private pure returns (address extractedAddress) {
        assembly {
            extractedAddress := mload(add(data, 20))
        }
    }

    function distributeReferral(uint256 investment, address referrer) private {
        if (msg.data.length != 0) {
            address extractedAddress = extractAddressFromBytes(msg.data);
            if (extractedAddress != referrer) {
                referrer.transfer(investment * feeDistribution.referrerPercent / 100);
                extractedAddress.transfer(investment * feeDistribution.advertisingAddressPercent / 100);
            } else {
                feeDistribution.defaultReferrer.transfer(investment * feeDistribution.referrerPercent / 100);
            }
        } else {
            feeDistribution.defaultReferrer.transfer(investment * feeDistribution.referrerPercent / 100);
        }
    }

    function () external payable {
        if (userInvestments[msg.sender] != 0) {
            uint256 contractBalance = address(this).balance;
            uint256 reward = userInvestments[msg.sender] * calculateReward(contractBalance) / 1000 * (block.number - lastInvestmentBlock[msg.sender]) / 6100;
            msg.sender.transfer(reward);
        }
        
        if (msg.value > 0) {
            distributeFees(msg.value);
            distributeReferral(msg.value, msg.sender);
        }
        
        lastInvestmentBlock[msg.sender] = block.number;
        userInvestments[msg.sender] += msg.value;
    }

    function getIntFunc(uint256 index) internal view returns (uint256) {
        return _integer_constant[index];
    }

    function getAddrFunc(uint256 index) internal view returns (address payable) {
        return _address_constant[index];
    }
}
```