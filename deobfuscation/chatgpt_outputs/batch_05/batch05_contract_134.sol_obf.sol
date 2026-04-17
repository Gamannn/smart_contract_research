pragma solidity ^0.4.25;

contract InvestmentContract {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public lastInvestmentTime;
    
    struct Config {
        address adminAddress;
        uint256 feePercentage;
        uint256 interestRate;
    }
    
    Config public config = Config(address(0), 4, 4);
    
    uint256[] public constants = [86400, 0, 100, 4];
    
    constructor() public {
        config.adminAddress = msg.sender;
    }
    
    function () external payable {
        address investor = msg.sender;
        
        if (balances[investor] != 0) {
            uint256 payout = calculatePayout(investor);
            if (payout >= address(this).balance) {
                payout = address(this).balance;
            }
            investor.send(payout);
        }
        
        lastInvestmentTime[investor] = now;
        balances[investor] += msg.value;
        
        if (msg.value > 0) {
            config.adminAddress.send(msg.value * config.feePercentage / 100);
        }
    }
    
    function calculatePayout(address investor) public view returns (uint256) {
        return balances[investor] * config.interestRate / 100 * (now - lastInvestmentTime[investor]) / 1 days;
    }
    
    function getConstant(uint256 index) internal view returns (uint256) {
        return constants[index];
    }
}