```solidity
pragma solidity ^0.4.24;

contract InvestmentContract {
    mapping(address => uint256) public userInvestments;
    mapping(address => uint256) public userLastBlock;
    
    uint256 public minInvestment;
    address public feeRecipient;
    
    event Invested(address indexed investor, uint256 amount);
    event Withdraw(address indexed investor, uint256 amount);
    
    constructor() public {
        feeRecipient = 0x0D257779Bbe6321d8349eEbCb2f0f5a90409DB80;
        minInvestment = 0.01 ether;
    }
    
    function calculateInterestRate(address investor) internal view returns (uint256) {
        uint256 rate = 400;
        uint256 investment = userInvestments[investor];
        
        if (investment >= 1 ether && investment < 10 ether) {
            rate = 425;
        }
        if (investment >= 10 ether && investment < 20 ether) {
            rate = 450;
        }
        if (investment >= 20 ether && investment < 40 ether) {
            rate = 475;
        }
        if (investment >= 40 ether) {
            rate = 500;
        }
        
        return rate;
    }
    
    function () external payable {
        require(
            msg.value == 0 || msg.value >= minInvestment,
            "Min Amount for investing is 0.01 Ether."
        );
        
        uint256 investmentAmount = msg.value;
        address investor = msg.sender;
        
        feeRecipient.transfer(investmentAmount / 10);
        
        if (userInvestments[investor] != 0) {
            uint256 pendingReward = userInvestments[investor] * 
                                   calculateInterestRate(investor) / 
                                   10000 * 
                                   (block.number - userLastBlock[investor]) / 
                                   5900;
            
            investor.transfer(pendingReward);
            emit Withdraw(investor, pendingReward);
        }
        
        userLastBlock[investor] = block.number;
        userInvestments[investor] += investmentAmount;
        
        if (investmentAmount > 0) {
            emit Invested(investor, investmentAmount);
        }
    }
    
    function getUserInvestment(address investor) public view returns(uint256) {
        return userInvestments[investor];
    }
    
    function getUserLastBlock(address investor) public view returns(uint256) {
        return userLastBlock[investor];
    }
    
    function calculatePendingReward(address investor) public view returns(uint256) {
        uint256 pendingReward = userInvestments[investor] * 
                               calculateInterestRate(investor) / 
                               10000 * 
                               (block.number - userLastBlock[investor]) / 
                               5900;
        return pendingReward;
    }
}
```