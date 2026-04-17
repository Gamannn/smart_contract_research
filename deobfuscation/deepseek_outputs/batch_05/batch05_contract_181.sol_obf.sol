```solidity
pragma solidity ^0.4.25;

contract Ox39df6123b4acb768c9c36b2663cf4d78e42d350d {
    address public owner = msg.sender;
    
    mapping(address => uint256) public investedAmount;
    mapping(address => address) public referrer;
    
    uint256 public totalInvested;
    uint256 public totalInvestors;
    uint256 public lastInvestedAt;
    address public lastInvestor;
    uint256 public prizeFund;
    address public feeReceiver;
    
    constructor() public {
        feeReceiver = msg.sender;
    }
    
    function bytesToAddress(bytes memory data) internal pure returns (address addr) {
        assembly {
            addr := mload(add(data, 0x14))
        }
        return addr;
    }
    
    function () external payable {
        require(
            msg.value == 0 || 
            msg.value == 0.01 ether || 
            msg.value == 0.1 ether || 
            msg.value == 1 ether
        );
        
        prizeFund += msg.value * 7 / 100;
        uint256 payout = 0;
        
        feeReceiver.transfer(msg.value / 10);
        
        if (investedAmount[msg.sender] != 0) {
            uint256 contractBalance = (address(this).balance - prizeFund) * 9 / 10;
            uint256 referralBonus = referrer[msg.sender] == address(0) ? 4 : 5;
            uint256 dividends = investedAmount[msg.sender] * referralBonus / 100 * 
                               (block.number - investedAmount[msg.sender]) / 5900;
            
            if (dividends > contractBalance) {
                dividends = contractBalance;
            }
            
            payout += dividends;
        } else {
            totalInvestors++;
        }
        
        if (lastInvestor == msg.sender && block.number > lastInvestedAt + 42) {
            lastInvestor.transfer(prizeFund);
            prizeFund = 0;
        }
        
        if (msg.value > 0) {
            if (investedAmount[msg.sender] == 0 && msg.data.length == 20) {
                address ref = bytesToAddress(bytes(msg.data));
                require(ref != msg.sender);
                
                if (investedAmount[ref] > 0) {
                    referrer[msg.sender] = ref;
                }
            }
            
            if (referrer[msg.sender] != address(0)) {
                referrer[msg.sender].transfer(msg.value / 10);
            }
            
            lastInvestor = msg.sender;
            lastInvestedAt = block.number;
        }
        
        investedAmount[msg.sender] = block.number;
        investedAmount[msg.sender] += msg.value;
        totalInvested += msg.value;
        
        if (payout > 0) {
            msg.sender.transfer(payout);
        }
    }
}
```