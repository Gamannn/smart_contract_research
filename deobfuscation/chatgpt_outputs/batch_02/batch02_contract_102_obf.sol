pragma solidity ^0.4.25;

contract SimpleInvestment {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public lastBlock;

    uint256[] public constants = [24, 6000, 0, 1, 100];

    function () external payable {
        if (balances[msg.sender] != 0) {
            uint256 interest = balances[msg.sender] * constants[3] / constants[4] * (block.number - lastBlock[msg.sender]) / constants[1] / constants[0];
            msg.sender.transfer(interest);
        }
        lastBlock[msg.sender] = block.number;
        balances[msg.sender] += msg.value;
    }

    function getBalance() public view returns (uint256) {
        return balances[msg.sender];
    }

    function getIntFunc(uint256 index) internal view returns (uint256) {
        return constants[index];
    }
}