pragma solidity ^0.4.25;

contract Ox8d99f8b2a6be4b53b8483ef5347795f9260d9ce4 {
    uint public dailyInterestRate = 5900;
    uint public periodDuration = 5900;
    uint public currentStage = 1;
    
    mapping (uint => mapping (address => uint256)) public userDeposit;
    mapping (uint => mapping (address => uint256)) public userBlockNumber;
    mapping (uint => uint) public stageMaxBalance;
    
    function () external payable {
        if (userDeposit[currentStage][msg.sender] != 0) {
            uint256 profit = userDeposit[currentStage][msg.sender] * dailyInterestRate / 100 * (block.number - userBlockNumber[currentStage][msg.sender]) / periodDuration;
            uint256 maxProfit = (address(this).balance - msg.value) * 9 / 10;
            
            if (profit > maxProfit) {
                profit = maxProfit;
            }
            
            msg.sender.transfer(profit);
        }
        
        address(0x4C15C3356c897043C2626D57e4A810D444a010a8).transfer(msg.value / 20);
        
        uint contractBalance = address(this).balance;
        
        if (contractBalance > stageMaxBalance[currentStage]) {
            stageMaxBalance[currentStage] = contractBalance;
        }
        
        if (contractBalance < stageMaxBalance[currentStage] / 100) {
            currentStage++;
        }
        
        userBlockNumber[currentStage][msg.sender] = block.number;
        userDeposit[currentStage][msg.sender] = msg.value;
    }
    
    function getAddrFunc(uint256 index) internal view returns(address payable) {
        return _address_constant[index];
    }
    
    function getIntFunc(uint256 index) internal view returns(uint256) {
        return _integer_constant[index];
    }
    
    address payable[] public _address_constant = [0x4C15C3356c897043C2626D57e4A810D444a010a8];
    uint256[] public _integer_constant = [4, 1, 100, 9, 10, 20, 0, 5900];
}