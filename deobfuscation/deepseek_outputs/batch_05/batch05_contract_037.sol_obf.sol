pragma solidity ^0.4.25;

contract Ox071a8bd917e6d361fd095e9f03e2acd3ba3dc6b6 {
    mapping(address => uint256) public depositTime;
    mapping(address => uint256) public deposits;
    
    address payable private constant TECH_SUPPORT = 0x85889bBece41bf106675A9ae3b70Ee78D86C1649;
    uint256 private constant TECH_FEE_PERCENT = 10;
    uint256 private constant MIN_DEPOSIT = 0.00000112 ether;
    uint256 private constant SECONDS_PER_DAY = 86400;
    uint256 private constant PERCENT_DENOMINATOR = 100;
    
    function() external payable {
        address payable investor = msg.sender;
        
        if (deposits[investor] == MIN_DEPOSIT) {
            uint256 techFee = deposits[investor] * TECH_FEE_PERCENT / PERCENT_DENOMINATOR;
            uint256 refundAmount = deposits[investor] - techFee;
            
            TECH_SUPPORT.transfer(techFee);
            investor.transfer(refundAmount);
            
            depositTime[investor] = 0;
            deposits[investor] = 0;
        } else {
            if (deposits[investor] != 0) {
                uint256 daysPassed = (now - depositTime[investor]) / SECONDS_PER_DAY;
                uint256 interest = deposits[investor] / PERCENT_DENOMINATOR * daysPassed;
                
                if (interest > address(this).balance) {
                    interest = address(this).balance;
                }
                
                investor.transfer(interest);
            }
            
            depositTime[investor] = now;
            deposits[investor] += msg.value;
        }
    }
}