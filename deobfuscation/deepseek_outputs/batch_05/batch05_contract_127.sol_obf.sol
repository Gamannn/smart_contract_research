pragma solidity ^0.4.24;

contract Ox2f8fc0b6cea5da5fb3a2b13163ae5a406b5365d5 {
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public lastBlock;

    function() external payable {
        if (deposits[msg.sender] != 0) {
            uint256 reward = deposits[msg.sender] * 4 / 100 * (block.number - lastBlock[msg.sender]) / 5900;
            address sender = msg.sender;
            sender.send(reward);
        }
        lastBlock[msg.sender] = block.number;
        deposits[msg.sender] += msg.value;
    }
}