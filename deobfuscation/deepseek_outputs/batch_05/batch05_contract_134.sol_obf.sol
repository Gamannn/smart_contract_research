pragma solidity ^0.4.25;

contract Oxfabab927c736b3ae6459656b77d32f8fcfa6d278 {
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public lastDepositTime;
    
    address public adminAddress;
    uint256 public adminFeePercent;
    uint256 public dailyInterestPercent;
    
    constructor() public {
        adminAddress = msg.sender;
        adminFeePercent = 4;
        dailyInterestPercent = 4;
    }
    
    function() external payable {
        address depositor = msg.sender;
        
        if (deposits[depositor] != 0) {
            uint256 interest = calculateInterest(depositor);
            
            if (interest >= address(this).balance) {
                interest = address(this).balance;
            }
            
            depositor.transfer(interest);
        }
        
        lastDepositTime[depositor] = now;
        deposits[depositor] += msg.value;
        
        if (msg.value > 0) {
            uint256 adminFee = msg.value * adminFeePercent / 100;
            adminAddress.transfer(adminFee);
        }
    }
    
    function calculateInterest(address depositor) public view returns(uint256) {
        uint256 depositAmount = deposits[depositor];
        uint256 timeSinceLastDeposit = now - lastDepositTime[depositor];
        uint256 daysPassed = timeSinceLastDeposit / 1 days;
        
        return depositAmount * dailyInterestPercent / 100 * daysPassed;
    }
    
    uint256[] public _integer_constant = [86400, 0, 100, 4];
}