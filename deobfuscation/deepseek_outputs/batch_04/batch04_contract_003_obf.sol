pragma solidity ^0.4.25;

contract Oxa9c566421d64173b061add2f10f1b2bf4acff1fc {
    mapping(address => uint256) private userReferralBalance;
    mapping(address => uint256) public userInvested;
    mapping(address => uint256) public userLastActionTime;
    
    uint256 public totalInvestors;
    uint256 public totalInvested;
    address public administrationAddress;
    uint256 public contractStartTime;
    
    event Investment(address indexed user, uint256 amount, uint256 totalInvested);
    event Withdraw(address indexed user, uint256 amount, uint256 totalInvested);
    
    constructor() public {
        administrationAddress = address(0x97a121027a529B96f1a71135457Ab8e353060811);
        contractStartTime = 1541678400;
    }
    
    function() external payable {
        if (msg.value > 0) {
            if (contractStartTime < now) {
                if (userInvested[msg.sender] != 0) {
                    userReferralBalance[msg.sender] = calculateDividends(msg.sender);
                }
                userLastActionTime[msg.sender] = now;
            } else {
                userLastActionTime[msg.sender] = contractStartTime;
            }
            
            if (userInvested[msg.sender] == 0) {
                totalInvestors++;
            }
            
            totalInvested += msg.value;
            userInvested[msg.sender] += msg.value;
            
            administrationAddress.transfer(msg.value * 13 / 100);
            
            emit Investment(msg.sender, msg.value, userInvested[msg.sender]);
        } else {
            uint256 payout = calculatePayout(msg.sender);
            if (payout != 0) {
                emit Withdraw(msg.sender, payout, userInvested[msg.sender]);
                msg.sender.transfer(payout);
                userLastActionTime[msg.sender] = 0;
                userInvested[msg.sender] = 0;
                userReferralBalance[msg.sender] = 0;
            }
        }
    }
    
    function calculatePayout(address user) public view returns (uint256) {
        if (contractStartTime < now) {
            if (userInvested[user] != 0) {
                uint256 dividends = calculateDividends(user);
                uint256 netInvestment = userInvested[user] - userInvested[user] * 15 / 100;
                
                if (netInvestment < dividends) {
                    return dividends;
                } else {
                    return netInvestment;
                }
            } else {
                return 0;
            }
        } else {
            return 0;
        }
    }
    
    function calculateDividends(address user) private view returns (uint256) {
        return userReferralBalance[user] + calculateDailyRate(user) * (now - userLastActionTime[user]) / 1 days;
    }
    
    function calculateDailyRate(address user) public view returns (uint256) {
        if (userInvested[user] < 1 ether) {
            return userInvested[user] * 222 / 10000;
        } else if (1 ether <= userInvested[user] && userInvested[user] < 5 ether) {
            return userInvested[user] * 255 / 10000;
        } else if (userInvested[user] >= 5 ether) {
            return userInvested[user] * 288 / 10000;
        }
    }
}