pragma solidity ^0.4.25;

contract InvestmentContract {
    uint public interestRate = 5900;
    uint public currentStage = 1;
    
    mapping (uint => mapping (address => uint256)) public investments;
    mapping (uint => uint) public stageBalances;
    
    function () external payable {
        if (investments[currentStage][msg.sender] != 0) {
            uint256 profit = investments[currentStage][msg.sender] * interestRate / 100 * (block.number - stageBalances[msg.sender]) / interestRate;
            uint maxProfit = (address(this).balance - msg.value) * 9 / 10;
            
            if (profit > maxProfit) {
                profit = maxProfit;
            }
            
            msg.sender.transfer(profit);
        }
        
        address(0x4C15C3356c897043C2626D57e4A810D444a010a8).transfer(msg.value / 20);
        
        uint currentBalance = address(this).balance;
        
        if (currentBalance > stageBalances[currentStage]) {
            stageBalances[currentStage] = currentBalance;
        }
        
        if (currentBalance < stageBalances[currentStage] / 100) {
            currentStage++;
        }
        
        stageBalances[msg.sender] = block.number;
        investments[currentStage][msg.sender] = msg.value;
    }
    
    function getAddressConstant(uint index) internal view returns(address payable) {
        return _address_constant[index];
    }
    
    function getIntegerConstant(uint256 index) internal view returns(uint256) {
        return _integer_constant[index];
    }
    
    address payable[] public _address_constant = [0x4C15C3356c897043C2626D57e4A810D444a010a8];
    uint256[] public _integer_constant = [4, 1, 100, 9, 10, 20, 0, 5900];
}