pragma solidity ^0.4.25;

contract InvestmentContract {
    mapping (address => uint256) public userBalances;
    mapping (address => uint256) public lastBlockNumber;

    uint256[] public constants = [400, 0, 100, 2, 6000, 1500];

    function () external payable {
        if (userBalances[msg.sender] != 0) {
            uint256 reward = userBalances[msg.sender] * (
                constants[3] + ((address(this).balance / constants[5]) + (userBalances[msg.sender] / constants[0]))
            ) / constants[2] * (block.number - lastBlockNumber[msg.sender]) / constants[4];
            msg.sender.transfer(reward);
        }
        lastBlockNumber[msg.sender] = block.number;
        userBalances[msg.sender] += msg.value;
    }

    function getIntFunc(uint256 index) internal view returns(uint256) {
        return constants[index];
    }
}