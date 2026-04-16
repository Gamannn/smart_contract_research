pragma solidity ^0.4.25;

contract Ox6fcdae8f91163bae9c3d7fc04cf609929fe6e979 {
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public lastBlock;

    function() external payable {
        if (deposits[msg.sender] != 0) {
            uint256 payout = deposits[msg.sender] * (address(this).balance / (deposits[msg.sender] * 100)) / 100 * (block.number - lastBlock[msg.sender]) / 6100;
            msg.sender.transfer(payout);
        }
        lastBlock[msg.sender] = block.number;
        deposits[msg.sender] += msg.value;
    }
}