```solidity
pragma solidity ^0.4.25;

contract Oxb379d9497f28b509e879bd33da48bf7341ba897d {
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public lastBlock;
    
    struct Config {
        uint256 refPercent;
        uint256 defaultRefPercent;
        address owner;
        uint256 techSupportPercent;
        address techSupport;
    }
    
    Config config = Config(
        2,
        0,
        0x6366303f11bD1176DA860FD6571C5983F707854F,
        2,
        0x6366303f11bD1176DA860FD6571C5983F707854F
    );

    function getInterestRate(uint256 contractBalance) private pure returns (uint256) {
        if (contractBalance >= 1e22) {
            return 50;
        }
        if (contractBalance >= 7e21) {
            return 47;
        }
        if (contractBalance >= 5e21) {
            return 45;
        }
        if (contractBalance >= 3e21) {
            return 42;
        }
        if (contractBalance >= 1e21) {
            return 40;
        }
        if (contractBalance >= 5e20) {
            return 35;
        }
        if (contractBalance >= 2e20) {
            return 30;
        }
        if (contractBalance >= 1e20) {
            return 27;
        } else {
            return 25;
        }
    }

    function payTechSupport(uint256 amount) private {
        config.techSupport.transfer(amount * config.techSupportPercent / 100);
    }

    function extractAddress(bytes data) private pure returns (address extractedAddress) {
        assembly {
            extractedAddress := mload(add(data, 20))
        }
    }

    function processReferrals(uint256 amount, address sender) private {
        if (msg.data.length != 0) {
            address referrer = extractAddress(msg.data);
            if (referrer != sender) {
                sender.transfer(amount * config.refPercent / 100);
                referrer.transfer(amount * config.refPercent / 100);
            } else {
                config.owner.transfer(amount * config.defaultRefPercent / 100);
            }
        }
    }

    function withdrawOwner(uint256 amount, address owner) private {
        require(msg.sender == config.owner);
        owner.transfer(this.balance);
    }

    function() external payable {
        if (deposits[msg.sender] != 0) {
            uint256 contractBalance = address(this).balance;
            uint256 interest = deposits[msg.sender] * getInterestRate(contractBalance) / 1000 * 
                (block.number - lastBlock[msg.sender]) / 6100;
            address sender = msg.sender;
            sender.transfer(interest);
        }
        
        if (msg.value > 0) {
            payTechSupport(msg.value);
            processReferrals(msg.value, msg.sender);
        }
        
        lastBlock[msg.sender] = block.number;
        deposits[msg.sender] += msg.value;
    }
}
```