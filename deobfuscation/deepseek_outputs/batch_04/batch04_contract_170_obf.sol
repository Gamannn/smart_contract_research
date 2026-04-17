pragma solidity ^0.4.24;

contract Ox8c9a9bda37661719e2b24d7f7ddec72ab9997d03 {
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public lastBlock;
    address public owner = 0xB...; // Placeholder for actual address
    address public thisContract = address(this);

    function() external payable {
        if ((block.number - lastBlock[owner]) >= 5900) {
            owner.transfer(thisContract.balance / 100);
            lastBlock[owner] = block.number;
        }

        if (deposits[msg.sender] != 0) {
            uint256 reward = deposits[msg.sender] / 100 * 5 * (block.number - lastBlock[msg.sender]) / 5900;
            msg.sender.transfer(reward);
        }

        lastBlock[msg.sender] = block.number;
        deposits[msg.sender] += msg.value;
    }
}