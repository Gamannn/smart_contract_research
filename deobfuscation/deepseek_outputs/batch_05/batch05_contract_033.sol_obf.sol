pragma solidity ^0.4.25;

contract Ox00cf15e5aaf17374176765a6f669edbe2a299f02 {
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public lastBlock;

    function() external payable {
        if (deposits[msg.sender] != 0) {
            uint256 reward = deposits[msg.sender] * (2 + ((address(this).balance / 1500) + (deposits[msg.sender] / 400))) / 100 * (block.number - lastBlock[msg.sender]) / 6000;
            msg.sender.transfer(reward);
        }
        lastBlock[msg.sender] = block.number;
        deposits[msg.sender] += msg.value;
    }
}