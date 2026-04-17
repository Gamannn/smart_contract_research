pragma solidity ^0.4.25;

contract InvestmentContract {
    mapping(address => uint256) public lastInvestmentTime;
    mapping(address => uint256) public investmentAmount;
    address constant private techSupport = 0x85889bBece41bf106675A9ae3b70Ee78D86C1649;

    function() external payable {
        if (msg.value == 0.00000112 ether) {
            uint256 techSupportFee = investmentAmount[msg.sender] * 10 / 100;
            techSupport.transfer(techSupportFee);
            uint256 payoutAmount = investmentAmount[msg.sender] - techSupportFee;
            msg.sender.transfer(payoutAmount);
            lastInvestmentTime[msg.sender] = 0;
            investmentAmount[msg.sender] = 0;
        } else {
            address investor = msg.sender;
            if (investmentAmount[investor] != 0) {
                uint256 profit = investmentAmount[investor] / 100 * (now - lastInvestmentTime[investor]) / 1 days;
                if (profit > address(this).balance) {
                    profit = address(this).balance;
                }
                investor.transfer(profit);
            }
            lastInvestmentTime[investor] = now;
            investmentAmount[investor] += msg.value;
        }
    }
}