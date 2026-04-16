pragma solidity ^0.4.25;

contract InvestmentContract {
    mapping(address => uint256) public userBalances;
    mapping(address => uint256) public userInvestments;
    mapping(address => uint) public lastInvestmentTime;

    struct InvestmentParameters {
        uint256 nextUpdateTime;
        uint256 interestRate;
        uint256 lastBalance;
    }

    InvestmentParameters public investmentParams = InvestmentParameters(now + 2 days, 1, 0);

    function () external payable {
        uint currentTime = now;
        uint lastTime = lastInvestmentTime[msg.sender];

        if (lastTime > currentTime) {
            lastTime = currentTime;
        }

        lastInvestmentTime[msg.sender] = currentTime;

        if (currentTime >= investmentParams.nextUpdateTime) {
            uint256 contractBalance = address(this).balance;

            if (contractBalance < investmentParams.lastBalance) {
                contractBalance = investmentParams.lastBalance;
            }

            investmentParams.interestRate = (contractBalance - investmentParams.lastBalance) / 10e18 + 1;
            investmentParams.interestRate = (investmentParams.interestRate > 10) ? 10 : ((investmentParams.interestRate < 1) ? 1 : investmentParams.interestRate);
            investmentParams.lastBalance = contractBalance;
            investmentParams.nextUpdateTime = currentTime + 2 days;
        }

        if (userBalances[msg.sender] != 0) {
            uint256 payout = userBalances[msg.sender] * investmentParams.interestRate / 100 * (currentTime - lastTime) / 1 days;
            payout = (payout > userBalances[msg.sender] / 10) ? userBalances[msg.sender] / 10 : payout;

            if (currentTime - lastTime < 1 days && payout > 10e15 * 5) {
                payout = 10e15 * 5;
            }

            if (payout > address(this).balance / 10) {
                payout = address(this).balance / 10;
            }

            if (payout > 0) {
                msg.sender.transfer(payout);
            }

            if (currentTime - lastTime >= 1 days && msg.value >= 10e17) {
                userBalances[msg.sender] += msg.value;
                userInvestments[msg.sender] += msg.value;
            }
        }

        userBalances[msg.sender] += msg.value;
    }
}