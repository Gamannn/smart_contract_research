pragma solidity ^0.4.25;

contract InvestmentContract {
    mapping(address => uint) private userBalances;
    mapping(address => uint) private lastInvestmentTime;
    mapping(address => uint) private totalInvested;
    uint public totalInvestors;
    uint public totalInvestedAmount;
    address public adminAddress;
    uint public contractStartTime;
    
    event Investment(address investor, uint amount, uint totalInvested);
    event Withdrawal(address investor, uint amount, uint totalInvested);

    function () external payable {
        if (msg.value > 0 ether) {
            if (contractStartTime < now) {
                if (totalInvested[msg.sender] != 0) {
                    userBalances[msg.sender] = calculateBalance(msg.sender);
                }
                lastInvestmentTime[msg.sender] = now;
            } else {
                lastInvestmentTime[msg.sender] = contractStartTime;
            }
            
            if (totalInvested[msg.sender] == 0) {
                totalInvestors++;
            }
            
            totalInvestedAmount += msg.value;
            totalInvested[msg.sender] += msg.value;
            adminAddress.transfer(msg.value * 13 / 100);
            
            emit Investment(msg.sender, msg.value, totalInvested[msg.sender]);
        } else {
            uint withdrawalAmount = calculateWithdrawal(msg.sender);
            if (withdrawalAmount != 0) {
                emit Withdrawal(msg.sender, withdrawalAmount, totalInvested[msg.sender]);
                msg.sender.transfer(withdrawalAmount);
                lastInvestmentTime[msg.sender] = 0;
                totalInvested[msg.sender] = 0;
                userBalances[msg.sender] = 0;
            }
        }
    }

    function calculateWithdrawal(address investor) public view returns (uint) {
        if (contractStartTime < now) {
            if (totalInvested[investor] != 0) {
                uint balance = calculateBalance(investor);
                uint maxWithdrawal = totalInvested[investor] - totalInvested[investor] * 15 / 100;
                if (maxWithdrawal < balance) {
                    return balance;
                } else {
                    return maxWithdrawal;
                }
            } else {
                return 0;
            }
        } else {
            return 0;
        }
    }

    function calculateBalance(address investor) private view returns (uint) {
        return userBalances[investor] + calculateDailyInterest(investor) * (now - lastInvestmentTime[investor]) / 1 days;
    }

    function calculateDailyInterest(address investor) public view returns (uint) {
        if (totalInvested[investor] < 1 ether) {
            return totalInvested[investor] * 1000000000000000000;
        } else if (1 ether <= totalInvested[investor] && totalInvested[investor] < 5 ether) {
            return totalInvested[investor] * 255 / 10000;
        } else {
            return totalInvested[investor] * 288 / 10000;
        }
    }

    function getIntFunc(uint256 index) internal view returns(uint256) {
        return _integer_constant[index];
    }

    function getAddrFunc(uint256 index) internal view returns(address payable) {
        return _address_constant[index];
    }

    uint256[] public _integer_constant = [288, 222, 0, 1000000000000000000, 15, 5000000000000000000, 10000, 100, 255, 86400, 1541678400];
    address payable[] public _address_constant = [0x97a121027a529B96f1a71135457Ab8e353060811];
}