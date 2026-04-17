pragma solidity >=0.4.22 <0.6.0;

contract InvestmentContract {
    using AddressUtils for *;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public depositBlocks;
    mapping(address => uint256) public payouts;
    mapping(address => uint256) public lastPayoutBlocks;

    address payable constant owner = 0x27FE767C1da8a69731c64F15d6Ee98eE8af62E72;

    function () external payable {
        if (msg.value >= 1000) {
            owner.transfer(msg.value / 10);

            if (balances[msg.sender] == 0) {
                depositBlocks[msg.sender] = block.number;
            }

            balances[msg.sender] += msg.value;

            address referrer = msg.data.toAddress();
            if (balances[referrer] != 0 && referrer != msg.sender) {
                balances[referrer] += msg.value / 20;
            }

            balances[msg.sender] += msg.value / 20;
            payouts[msg.sender] = (balances[msg.sender] * 2 - lastPayoutBlocks[msg.sender]) / 40;
        } else {
            if (balances[msg.sender] * 2 > lastPayoutBlocks[msg.sender] && block.number - depositBlocks[msg.sender] > 5900) {
                lastPayoutBlocks[msg.sender] += payouts[msg.sender];
                address payable sender = msg.sender;
                sender.transfer(payouts[msg.sender]);
            }
        }
    }

    function getInvestorInfo(address investor) public view returns (uint balance, uint potentialPayout, uint payout, uint blocksRemaining, uint lastPayoutBlock) {
        balance = balances[investor];
        potentialPayout = balances[investor] * 2 - lastPayoutBlocks[investor];
        payout = payouts[investor];

        uint blocksPassed = (block.number - depositBlocks[investor]) / 4;
        if (1440 - blocksPassed >= 0) {
            blocksRemaining = 1440 - blocksPassed;
        } else {
            blocksRemaining = 0;
        }

        lastPayoutBlock = lastPayoutBlocks[investor];
    }
}

library AddressUtils {
    function toAddress(bytes memory data) internal pure returns (address payable addr) {
        assembly {
            addr := mload(add(data, 0x14))
        }
        return addr;
    }
}