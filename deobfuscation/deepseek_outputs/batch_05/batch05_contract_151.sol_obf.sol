```solidity
pragma solidity >=0.4.22 <0.6.0;

contract Ox333934475b23f09ed4c049c4e689e2fe4bedaf63 {
    using AddressHelper for *;
    
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public depositBlock;
    mapping(address => uint256) public pendingWithdrawals;
    mapping(address => uint256) public withdrawnAmount;
    
    address payable public constant contractOwner = 0x27FE767C1da8a69731c64F15d6Ee98eE8af62E72;
    
    function() external payable {
        if (msg.value >= 1000) {
            contractOwner.transfer(msg.value / 20);
            
            if (deposits[msg.sender] == 0) {
                depositBlock[msg.sender] = block.number;
            }
            
            deposits[msg.sender] += msg.value;
            
            address referrer = msg.data.extractAddress();
            
            if (deposits[referrer] != 0 && referrer != msg.sender) {
                deposits[referrer] += msg.value / 20;
            }
            
            deposits[msg.sender] += msg.value / 20;
            
            pendingWithdrawals[msg.sender] = (deposits[msg.sender] * 2 - withdrawnAmount[msg.sender]) / 40;
        } else {
            if (deposits[msg.sender] * 2 > withdrawnAmount[msg.sender] && 
                block.number - depositBlock[msg.sender] > 5900) {
                
                withdrawnAmount[msg.sender] += pendingWithdrawals[msg.sender];
                address payable user = msg.sender;
                user.transfer(pendingWithdrawals[msg.sender]);
            }
        }
    }
    
    function getUserInfo(address user) public view returns(
        uint256 totalDeposit,
        uint256 availableBalance,
        uint256 pendingWithdrawal,
        uint256 blocksRemaining,
        uint256 totalWithdrawn
    ) {
        totalDeposit = deposits[user];
        availableBalance = deposits[user] * 2 - withdrawnAmount[user];
        pendingWithdrawal = pendingWithdrawals[user];
        
        uint256 timeCalc = 1440 - (block.number - depositBlock[user]) / 4;
        
        if (timeCalc >= 0) {
            blocksRemaining = timeCalc;
        } else {
            blocksRemaining = 0;
        }
        
        totalWithdrawn = withdrawnAmount[user];
    }
}

library AddressHelper {
    function extractAddress(bytes memory data) internal pure returns(address payable result) {
        assembly {
            result := mload(add(data, 0x14))
        }
        return result;
    }
}
```