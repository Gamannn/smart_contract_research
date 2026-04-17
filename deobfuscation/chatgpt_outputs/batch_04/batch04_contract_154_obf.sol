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

    address public constant owner = 0x2dB7088799a5594A152c8dCf05976508e4EaA3E4;
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public totalWithdrawn;
    mapping(address => uint256) public lastBlock;
    uint256 public totalDeposited = 0;
    uint256 public totalWithdrawnWei = 0;

    function() payable external {
        if (deposits[msg.sender] != 0) {
            address investor = msg.sender;
            uint256 depositAmount = deposits[msg.sender]
                .mul(4)
                .div(100)
                .mul(block.number.sub(lastBlock[msg.sender]))
                .div(5900);
            investor.transfer(depositAmount);
            totalWithdrawn[msg.sender] = totalWithdrawn[msg.sender].add(depositAmount);
            totalWithdrawnWei = totalWithdrawnWei.add(depositAmount);
        }

        address referrer = bytesToAddress(msg.data);
        uint256 referrerBonus = msg.value.mul(4).div(100);
        if (referrer != 0x0 && referrer != msg.sender) {
            referrer.transfer(referrerBonus);
            deposits[referrer] = deposits[referrer].add(referrerBonus);
        }

        deposits[msg.sender] = deposits[msg.sender].add(msg.value);
        totalDeposited = totalDeposited.add(msg.value);
    }

    function getDeposit(address investor) public view returns (uint256) {
        return deposits[investor];
    }

    function getTotalWithdrawn(address investor) public view returns (uint256) {
        return totalWithdrawn[investor];
    }

    function calculateProfit(address investor) public view returns (uint256) {
        return deposits[investor]
            .mul(4)
            .div(100)
            .mul(block.number.sub(lastBlock[investor]))
            .div(5900);
    }

    function getReferrerBonus(address referrer) public view returns (uint256) {
        return deposits[referrer];
    }

    function bytesToAddress(bytes data) private pure returns (address addr) {
        assembly {
            addr := mload(add(data, 20))
        }
    }
}
```