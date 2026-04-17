pragma solidity ^0.8.0;

contract InvestmentContract {
    uint256 public currentInvestment;
    
    struct InvestmentRecord {
        uint256 amount;
        address investor;
    }
    
    InvestmentRecord public investmentRecord;
    
    function invest() public payable {
        require(msg.value > 0, "Investment must be greater than 0");
        currentInvestment += msg.value;
        investmentRecord = InvestmentRecord(msg.value, msg.sender);
    }
    
    function getInvestment() public view returns (uint256) {
        return currentInvestment;
    }
}