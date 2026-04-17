```solidity
pragma solidity ^0.4.25;

contract Ox993f291594573598c01273395e18bdf891100b6d {
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public totalInvested;
    mapping(address => uint256) public lastActionBlock;
    
    uint256 public previousBalance;
    uint256 public interestRate;
    uint256 public nextBlockBalance;
    uint256 public lastUpdateBlock;
    
    uint256[] public _integer_constant = [
        20,      // 0: maxInterestRate
        5,       // 1: maxWithdrawPercent
        10,      // 2: minWithdrawPercent
        1,       // 3: minInterestRate
        10000000000000000000, // 4: 10 ether
        4,       // 5: maxEarlyWithdraw
        11800,   // 6: blocksPerUpdate
        10000000000000000,    // 7: 0.01 ether
        0,       // 8: zero
        5800,    // 9: earlyWithdrawPeriod
        100,     // 10: percentageDivisor
        1000000000000000000   // 11: 1 ether
    ];
    
    function () external payable {
        if (block.number >= lastUpdateBlock) {
            uint256 currentBalance = address(this).balance;
            
            if (previousBalance < currentBalance) {
                previousBalance = nextBlockBalance;
                interestRate = ((currentBalance - nextBlockBalance) / 1e18 + 1);
                interestRate = (interestRate > 20) ? 20 : ((interestRate < 1) ? 1 : interestRate);
            }
            
            nextBlockBalance = currentBalance;
            lastUpdateBlock += 11800 * ((block.number - lastUpdateBlock) / 11800);
        }
        
        if (deposits[msg.sender] != 0) {
            uint256 payout = deposits[msg.sender] * interestRate / 100 * (block.number - lastActionBlock[msg.sender]) / 100;
            
            payout = (payout > deposits[msg.sender] / 5) ? deposits[msg.sender] / 5 : payout;
            
            if (block.number - lastActionBlock[msg.sender] < 5800 && payout > 4e16) {
                payout = 4e16;
            }
            
            if (address(this).balance / 10 < payout) {
                payout = address(this).balance / 10;
            }
            
            msg.sender.transfer(payout);
            
            if (block.number - lastActionBlock[msg.sender] > 5800 && msg.value >= 1e18) {
                deposits[msg.sender] = msg.value;
                totalInvested[msg.sender] += msg.value;
            }
        }
        
        lastActionBlock[msg.sender] = block.number;
        deposits[msg.sender] += msg.value;
    }
    
    function getIntFunc(uint256 index) internal view returns(uint256) {
        return _integer_constant[index];
    }
}
```