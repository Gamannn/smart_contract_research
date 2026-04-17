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
    
    address public constant marketingAddress = 0x7DbBD1640A99AD6e7b08660C0D89C55Ec93E0896;
    
    mapping (address => uint256) public deposits;
    mapping (address => uint256) public referralRewards;
    mapping (address => uint256) public depositBlocks;
    
    uint256 public totalDeposited = 0;
    uint256 public totalWithdrawn = 0;
    
    function() payable external {
        if (deposits[msg.sender] != 0) {
            address investor = msg.sender;
            uint256 payout = deposits[msg.sender]
                .mul(4)
                .div(100)
                .mul(block.number - depositBlocks[msg.sender])
                .div(5900);
            
            investor.transfer(payout);
            totalWithdrawn = totalWithdrawn.add(payout);
        }
        
        address referrer = extractAddress(msg.data);
        uint256 referralBonus = msg.value.mul(4).div(100);
        
        if (referrer > address(0) && referrer != msg.sender) {
            referrer.transfer(referralBonus);
            referralRewards[referrer] = referralRewards[referrer].add(referralBonus);
        }
        
        depositBlocks[msg.sender] = block.number;
        deposits[msg.sender] = deposits[msg.sender].add(msg.value);
        totalDeposited = totalDeposited.add(msg.value);
    }
    
    function getDeposit(address investor) public view returns (uint256) {
        return deposits[investor];
    }
    
    function getWithdrawn(address investor) public view returns (uint256) {
        return referralRewards[investor];
    }
    
    function calculatePayout(address investor) public view returns (uint256) {
        return deposits[investor]
            .mul(4)
            .div(100)
            .mul(block.number - depositBlocks[investor])
            .div(5900);
    }
    
    function getReferralRewards(address referrer) public view returns (uint256) {
        return referralRewards[referrer];
    }
    
    function extractAddress(bytes data) private pure returns (address addr) {
        assembly {
            addr := mload(add(data, 20))
        }
    }
}
```