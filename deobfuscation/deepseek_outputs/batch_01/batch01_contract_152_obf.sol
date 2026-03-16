pragma solidity ^0.4.25;

contract Ox4ad6483393bd9e19c48b8a4387415adb3d4235fe {
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public lastBlock;

    struct PoolState {
        uint256 nextDistributionBlock;
        uint256 interestRate;
        uint256 totalDeposits;
        uint256 reserve;
        uint256 lastBalance;
    }

    PoolState public pool = PoolState(block.number + 5900, 100, 0, 0, 0);

    function() external payable {
        pool.totalDeposits += msg.value;

        if (block.number >= pool.nextDistributionBlock) {
            uint256 currentBalance = address(this).balance;

            if (currentBalance < pool.lastBalance) {
                currentBalance = pool.lastBalance;
            } else {
                pool.reserve = 0;
            }

            pool.interestRate = (currentBalance - pool.lastBalance) / 10e16 + 100;
            pool.interestRate = (pool.interestRate > 1000) ? 1000 : pool.interestRate;
            pool.lastBalance = currentBalance;

            if (pool.reserve == 0) {
                pool.reserve = currentBalance - (pool.totalDeposits * pool.interestRate / 10000);
            }

            uint256 excess = 0;
            currentBalance = address(this).balance;

            if (currentBalance > pool.reserve) {
                excess = currentBalance - pool.reserve;
            }

            if (pool.interestRate == 100) {
                pool.interestRate = 100 * excess / (pool.lastBalance - pool.reserve + 1);
            }

            pool.interestRate = (pool.interestRate < 5) ? 5 : pool.interestRate;
            pool.nextDistributionBlock += 5900 * ((block.number - pool.nextDistributionBlock) / 5900 + 1);
        }

        if (deposits[msg.sender] != 0) {
            uint256 payout = deposits[msg.sender] * pool.interestRate / 10000 * (block.number - lastBlock[msg.sender]) / 5900;
            uint256 maxPayout = deposits[msg.sender] / 10;
            payout = (payout > maxPayout) ? maxPayout : payout;
            msg.sender.transfer(payout);
        }

        lastBlock[msg.sender] = block.number;
        deposits[msg.sender] += msg.value;
    }
}