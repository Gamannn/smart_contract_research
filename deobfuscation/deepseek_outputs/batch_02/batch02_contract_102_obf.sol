pragma solidity ^0.4.25;

contract Ox26b71f93639660c1ccd43bbf16512f4cca2b9d24 {
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public lastBlock;
    
    function() external payable {
        if (deposits[msg.sender] != 0) {
            uint256 reward = deposits[msg.sender] * 1 / 100 * (block.number - lastBlock[msg.sender]) / 6000 / 24;
            msg.sender.transfer(reward);
        }
        lastBlock[msg.sender] = block.number;
        deposits[msg.sender] += msg.value;
    }
    
    function getDeposit() constant returns(uint256) {
        return deposits[msg.sender];
    }
}