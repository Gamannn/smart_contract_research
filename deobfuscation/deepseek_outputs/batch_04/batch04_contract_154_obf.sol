```solidity
pragma solidity ^0.4.25;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
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
    
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract InvestmentContract {
    using SafeMath for uint256;
    
    address public constant marketingAddress = 0x2dB7088799a5594A152c8dCf05976508e4EaA3E4;
    
    mapping (address => uint256) public deposits;
    mapping (address => uint256) public referralRewards;
    mapping (address => uint256) public depositBlock;
    
    uint256 public totalDepositedWei = 0;
    uint256 public totalWithdrawnWei = 0;
    
    function() payable external {
        if (deposits[msg.sender] != 0) {
            address investor = msg.sender;
            uint256 payout = deposits[msg.sender]
                .mul(4)
                .div(100)
                .mul(block.number - depositBlock[msg.sender])
                .div(5900);
            
            investor.transfer(payout);
            
            referralRewards[msg.sender] = referralRewards[msg.sender].add(payout);
            totalWithdrawnWei = totalWithdrawnWei.add(payout);
        }
        
        address referrer = bytesToAddress(msg.data);
        uint256 referralBonus = msg.value.mul(4).div(100);
        
        if (referrer > address(0) && referrer != msg.sender) {
            referrer.transfer(referralBonus);
            referralRewards[referrer] = referralRewards[referrer].add(referralBonus);
        }
        
        depositBlock[msg.sender] = block.number;
        deposits[msg.sender] = deposits[msg.sender].add(msg.value);
        totalDepositedWei = totalDepositedWei.add(msg.value);
    }
    
    function getDeposit(address investor) public view returns (uint256) {
        return deposits[investor];
    }
    
    function getReferralRewards(address investor) public view returns (uint256) {
        return referralRewards[investor];
    }
    
    function calculatePayout(address investor) public view returns (uint256) {
        return deposits[investor]
            .mul(4)
            .div(100)
            .mul(block.number - depositBlock[investor])
            .div(5900);
    }
    
    function getDepositBlock(address investor) public view returns (uint256) {
        return depositBlock[investor];
    }
    
    function bytesToAddress(bytes data) private pure returns (address addr) {
        assembly {
            addr := mload(add(data, 20))
        }
    }
}
```