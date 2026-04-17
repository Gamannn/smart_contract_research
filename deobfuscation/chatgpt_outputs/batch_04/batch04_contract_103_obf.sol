pragma solidity ^0.4.25;

contract InvestmentContract {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public lastBlock;
    uint256 public previousBalance;
    uint256 public interestRate;
    uint256 public totalBalance;
    uint256 public lastInterestCalculationBlock;
    uint256 public interestCalculationInterval = 5900;
    uint256 public minInterestRate = 5;
    uint256 public maxInterestRate = 1000;
    uint256[] public _integer_constant = [0, 5900, 100, 10000, 5, 10, 100000000000000000, 1, 1000];

    function () external payable {
        totalBalance += msg.value;

        if (block.number >= lastInterestCalculationBlock) {
            uint256 currentBalance = address(this).balance;
            uint256 calculatedLow = currentBalance < previousBalance ? currentBalance : previousBalance;
            uint256 interest = (calculatedLow - previousBalance) / 10e16 + 100;
            interest = (previousBalance == 0) ? 1000 : interest;
            uint256 calculatedInterest = 0;

            if (calculatedInterest == 0) {
                calculatedInterest = calculatedLow - (getIntFunc(0) * interest / 10000);
            }

            if (calculatedLow > calculatedInterest) {
                interest = 100 * (currentBalance - calculatedLow) / getIntFunc(2);
                interest = (interest < minInterestRate) ? minInterestRate : interest;
            }

            lastInterestCalculationBlock += interestCalculationInterval * ((block.number / interestCalculationInterval) + 1);
        }

        if (balances[msg.sender] != 0) {
            uint256 interestAmount = balances[msg.sender] * interest / 10000 * (block.number - lastBlock[msg.sender]) / interestCalculationInterval;
            interestAmount = (interestAmount > balances[msg.sender] / 10) ? balances[msg.sender] / 10 : interestAmount;
            msg.sender.transfer(interestAmount);
        }

        lastBlock[msg.sender] = block.number;
        balances[msg.sender] += msg.value;
    }

    function getIntFunc(uint256 index) internal view returns (uint256) {
        return _integer_constant[index];
    }
}