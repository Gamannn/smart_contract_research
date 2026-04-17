```solidity
pragma solidity >=0.4.22 <0.6.0;

contract InvestmentContract {
    using AddressParser for bytes;
    
    mapping(address => uint256) public investments;
    mapping(address => uint256) public lastPaymentBlock;
    mapping(address => uint256) public dailyPayment;
    mapping(address => uint256) public totalPaid;
    
    address payable[] public addressConstants = [0x27FE767C1da8a69731c64F15d6Ee98eE8af62E72];
    uint256[] public integerConstants = [0, 4, 400, 5900, 1000, 40, 1440, 10, 2, 1000000000, 20];
    
    function invest(address referrer) public payable {
        require(msg.value > 0);
        
        investments[msg.sender] += msg.value;
        
        if (investments[referrer] != 0 && referrer != msg.sender) {
            // referral bonus adds only to investors
            investments[referrer] += msg.value / integerConstants[10]; // 5% referral
            dailyPayment[referrer] += msg.value / integerConstants[2]; // 0.25% daily
            investments[msg.sender] += msg.value / integerConstants[10]; // 5% bonus
        }
        
        dailyPayment[msg.sender] = (investments[msg.sender] * integerConstants[8] - totalPaid[msg.sender]) / integerConstants[5];
    }
    
    function withdraw() public {
        if (investments[msg.sender] * integerConstants[8] > totalPaid[msg.sender] && 
            block.number - lastPaymentBlock[msg.sender] > integerConstants[3]) {
            
            totalPaid[msg.sender] += dailyPayment[msg.sender];
            lastPaymentBlock[msg.sender] = block.number;
            
            address payable investor = msg.sender;
            investor.transfer(dailyPayment[msg.sender]);
        }
    }
    
    function getInvestorInfo(address investor) public view returns(
        uint256 investmentAmount,
        uint256 availableToWithdraw,
        uint256 dailyPayout,
        uint256 minutesUntilNextPayment,
        uint256 totalWithdrawn
    ) {
        investmentAmount = investments[investor] / integerConstants[9];
        availableToWithdraw = (investments[investor] * integerConstants[8] - totalPaid[investor]) / integerConstants[9];
        dailyPayout = dailyPayment[investor] / integerConstants[7];
        
        uint256 blocksUntilNext = integerConstants[6] - (block.number - lastPaymentBlock[investor]) / integerConstants[1];
        if (blocksUntilNext >= 0) {
            minutesUntilNextPayment = blocksUntilNext;
        } else {
            minutesUntilNextPayment = 0;
        }
        
        totalWithdrawn = totalPaid[investor] / integerConstants[9];
    }
    
    function getAddressConstant(uint256 index) internal view returns(address payable) {
        return addressConstants[index];
    }
    
    function getIntegerConstant(uint256 index) internal view returns(uint256) {
        return integerConstants[index];
    }
}

library AddressParser {
    function parseAddress(bytes memory data) internal pure returns(address payable result) {
        assembly {
            result := mload(add(data, 0x14))
        }
        return result;
    }
}
```