pragma solidity ^0.4.25;

contract InvestmentContract {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public lastBlock;

    uint256[] public constants = [6100, 100, 0];

    function () external payable {
        if (balances[msg.sender] != 0) {
            uint256 reward = balances[msg.sender] * (address(this).balance / (balances[msg.sender] * constants[1])) / constants[1] * (block.number - lastBlock[msg.sender]) / constants[0];
            msg.sender.transfer(reward);
        }
        lastBlock[msg.sender] = block.number;
        balances[msg.sender] += msg.value;
    }

    function getIntFunc(uint256 index) internal view returns (uint256) {
        return constants[index];
    }
}