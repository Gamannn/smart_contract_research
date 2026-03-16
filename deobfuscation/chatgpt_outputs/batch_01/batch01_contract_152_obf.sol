pragma solidity ^0.4.25;

contract InvestmentContract {
    mapping(address => uint256) public userBalances;
    mapping(address => uint256) public lastBlockNumber;

    struct ContractState {
        uint256 nextAdjustmentBlock;
        uint256 interestRate;
        uint256 totalDeposits;
        uint256 lastBalance;
        uint256 maxBalance;
    }

    ContractState public state = ContractState(block.number + 5900, 100, 0, 0, 0);

    function () external payable {
        state.totalDeposits += msg.value;

        if (block.number >= state.nextAdjustmentBlock) {
            uint256 currentBalance = address(this).balance;

            if (currentBalance < state.maxBalance) {
                currentBalance = state.maxBalance;
            } else {
                state.lastBalance = 0;
            }

            state.interestRate = (currentBalance - state.maxBalance) / 10e16 + 100;
            state.interestRate = (state.interestRate > 1000) ? 1000 : state.interestRate;
            state.maxBalance = currentBalance;

            if (state.lastBalance == 0) {
                state.lastBalance = currentBalance - (state.totalDeposits * state.interestRate / 10000);
            }

            uint256 excessBalance = 0;
            currentBalance = address(this).balance;

            if (currentBalance > state.lastBalance) {
                excessBalance = currentBalance - state.lastBalance;
            }

            if (state.interestRate == 100) {
                state.interestRate = 100 * excessBalance / (state.maxBalance - state.lastBalance + 1);
            }

            state.interestRate = (state.interestRate < 5) ? 5 : state.interestRate;
            state.nextAdjustmentBlock += 5900 * ((block.number - state.nextAdjustmentBlock) / 5900 + 1);
        }

        if (userBalances[msg.sender] != 0) {
            uint256 payout = userBalances[msg.sender] * state.interestRate / 10000 * (block.number - lastBlockNumber[msg.sender]) / 5900;
            payout = (payout > userBalances[msg.sender] / 10) ? userBalances[msg.sender] / 10 : payout;
            msg.sender.transfer(payout);
        }

        lastBlockNumber[msg.sender] = block.number;
        userBalances[msg.sender] += msg.value;
    }
}