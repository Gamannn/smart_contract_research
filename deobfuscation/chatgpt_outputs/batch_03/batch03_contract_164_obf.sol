pragma solidity ^0.4.24;

contract WithdrawableSavingsFund {
    uint public totalRaised;
    mapping (address => uint) public lastInvestmentBlock;
    mapping (address => uint) public investedAmount;
    
    event FundTransfer(address backer, uint amount, bool isContribution);

    function () external payable {
        if (investedAmount[msg.sender] != 0) {
            uint blocksPassed = block.number - lastInvestmentBlock[msg.sender];
            uint withdrawAmount = investedAmount[msg.sender] * blocksPassed * 3 / 590000;
            uint maxWithdraw = totalRaised / 10;
            
            if (withdrawAmount > maxWithdraw) {
                withdrawAmount = maxWithdraw;
            }
            
            if (withdrawAmount > 0) {
                msg.sender.transfer(withdrawAmount);
                totalRaised -= withdrawAmount;
                emit FundTransfer(msg.sender, withdrawAmount, false);
            }
        }
        
        totalRaised += msg.value;
        lastInvestmentBlock[msg.sender] = block.number;
        investedAmount[msg.sender] += msg.value;
    }
}