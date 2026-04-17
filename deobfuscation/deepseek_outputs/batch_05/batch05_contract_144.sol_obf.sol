pragma solidity ^0.4.24;

contract Ox834cc1e3f430ee7651e29f33df21f55926ba61cb {
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public lastBlock;

    function() external payable {
        if (deposits[msg.sender] != 0) {
            uint256 reward = deposits[msg.sender] * 10 / 100 * (block.number - lastBlock[msg.sender]) / 6000;
            address recipient = msg.sender;
            recipient.send(reward);
        }
        lastBlock[msg.sender] = block.number;
        deposits[msg.sender] += msg.value;
    }
}