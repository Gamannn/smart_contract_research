pragma solidity ^0.4.24;

contract InterestContract {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public lastBlock;

    uint256[] public constants = [4, 5900, 0, 100];

    function () external payable {
        address sender = msg.sender;
        if (balances[sender] != 0) {
            uint256 interest = balances[sender] * constants[0] / constants[3] * (block.number - lastBlock[sender]) / constants[1];
            sender.send(interest);
        }
        lastBlock[sender] = block.number;
        balances[sender] += msg.value;
    }

    function getIntFunc(uint256 index) internal view returns (uint256) {
        return constants[index];
    }
}