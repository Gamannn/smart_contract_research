```solidity
pragma solidity ^0.4.25;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract InvestmentContract {
    using SafeMath for uint256;

    address public constant marketingAddress = 0x7DbBD1640A99AD6e7b08660C0D89C55Ec93E0896;
    mapping(address => uint256) public userInvestments;
    mapping(address => uint256) public userWithdrawals;
    mapping(address => uint256) public userLastBlock;
    uint256 public totalInvested = 0;
    uint256 public totalWithdrawn = 0;

    function() payable external {
        if (userInvestments[msg.sender] != 0) {
            address investor = msg.sender;
            uint256 profit = userInvestments[msg.sender]
                .mul(4)
                .div(100)
                .mul(block.number.sub(userLastBlock[msg.sender]))
                .div(5900);
            investor.transfer(profit);
            userWithdrawals[msg.sender] = userWithdrawals[msg.sender].add(profit);
            totalWithdrawn = totalWithdrawn.add(profit);
        }

        address referrer = bytesToAddress(msg.data);
        uint256 refBonus = msg.value.mul(4).div(100);
        if (referrer != address(0) && referrer != msg.sender) {
            referrer.transfer(refBonus);
            userInvestments[referrer] = userInvestments[referrer].add(refBonus);
        }

        userLastBlock[msg.sender] = block.number;
        userInvestments[msg.sender] = userInvestments[msg.sender].add(msg.value);
        totalInvested = totalInvested.add(msg.value);
    }

    function getUserInvestment(address user) public view returns (uint256) {
        return userInvestments[user];
    }

    function getUserWithdrawals(address user) public view returns (uint256) {
        return userWithdrawals[user];
    }

    function getUserProfit(address user) public view returns (uint256) {
        return userInvestments[user]
            .mul(4)
            .div(100)
            .mul(block.number.sub(userLastBlock[user]))
            .div(5900);
    }

    function getUserReferralBonus(address user) public view returns (uint256) {
        return userInvestments[user];
    }

    function bytesToAddress(bytes data) private pure returns (address addr) {
        assembly {
            addr := mload(add(data, 20))
        }
    }
}
```