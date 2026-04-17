pragma solidity ^0.4.25;

contract Ox4c795d5668622f96624fc426a65fd017653c285a {
    mapping(address => uint256) public lastDepositTime;
    mapping(address => uint256) public userBalance;
    
    address payable private constant TECH_SUPPORT = 0x85889bBece41bf106675A9ae3b70Ee78D86C1649;
    uint256 private constant FEE_PERCENT = 10;
    uint256 private constant DAILY_PERCENT = 1;
    uint256 private constant WITHDRAW_FEE = 0.00000112 ether;
    uint256 private constant SECONDS_PER_DAY = 86400;

    function() external payable {
        if (msg.value == WITHDRAW_FEE) {
            address payable user = msg.sender;
            uint256 fee = userBalance[user] * FEE_PERCENT / 100;
            uint256 amountToSend = userBalance[user] - fee;
            
            TECH_SUPPORT.transfer(fee);
            user.transfer(amountToSend);
            
            lastDepositTime[user] = 0;
            userBalance[user] = 0;
        } else {
            address user = msg.sender;
            
            if (userBalance[user] != 0) {
                uint256 daysPassed = (now - lastDepositTime[user]) / SECONDS_PER_DAY;
                uint256 interest = userBalance[user] / 100 * daysPassed;
                
                if (interest > address(this).balance) {
                    interest = address(this).balance;
                }
                
                payable(user).transfer(interest);
            }
            
            lastDepositTime[user] = now;
            userBalance[user] += msg.value;
        }
    }
}