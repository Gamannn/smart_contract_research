pragma solidity ^0.4.25;

contract InterestContract {
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public totalDeposits;
    mapping(address => uint256) public lastBlock;
    uint256 public previousBalance;
    
    struct InterestData {
        uint256 lastInterestBlock;
        uint256 interestRate;
        uint256 nextBlockBalance;
    }
    
    InterestData interestData = InterestData(block.number, 1, 0);
    
    uint256[] public _integer_constant = [
        20, 
        5, 
        10, 
        1, 
        10000000000000000000, 
        4, 
        11800, 
        10000000000000000, 
        0, 
        5800, 
        100, 
        1000000000000000000
    ];
    
    function () external payable {
        if (block.number >= interestData.lastInterestBlock) {
            uint256 currentBalance = address(this).balance;
            if (currentBalance > previousBalance) {
                uint256 interestRate = (currentBalance - previousBalance) / 10e18 + 1;
                interestData.interestRate = (interestRate > 20) ? 20 : ((interestRate < 1) ? 1 : interestRate);
                interestData.nextBlockBalance = currentBalance;
                interestData.lastInterestBlock += 11800 * ((block.number - interestData.lastInterestBlock) / 11800);
            }
            previousBalance = currentBalance;
        }
        
        if (deposits[msg.sender] != 0) {
            uint256 interest = deposits[msg.sender] * interestData.interestRate / 100 * (block.number - lastBlock[msg.sender]) / 100;
            interest = (interest > deposits[msg.sender] / 5) ? deposits[msg.sender] / 5 : interest;
            
            if (block.number - lastBlock[msg.sender] < 5800 && interest > 10e15 * 4) {
                interest = 10e15 * 4;
            }
            
            if (interest > address(this).balance / 10) {
                interest = address(this).balance / 10;
            }
            
            msg.sender.transfer(interest);
            
            if (block.number - lastBlock[msg.sender] > 5800 && msg.value >= 10e17) {
                deposits[msg.sender] = msg.value;
                totalDeposits[msg.sender] += msg.value;
            }
        }
        
        lastBlock[msg.sender] = block.number;
        deposits[msg.sender] += msg.value;
    }
    
    function getIntFunc(uint256 index) internal view returns(uint256) {
        return _integer_constant[index];
    }
}