pragma solidity ^0.4.24;

contract Oxe2349735ef546980edb530b7b0abebc0cfc8b549 {
    address public owner;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public depositBlock;
    
    uint256[] public _integer_constant = [0, 5900, 7, 100, 10];
    
    constructor() public {
        owner = msg.sender;
    }
    
    function() external payable {
        if (balances[msg.sender] != 0) {
            address user = msg.sender;
            uint256 payout = (balances[user] * _integer_constant[2] * (block.number - depositBlock[user])) / _integer_constant[3];
            user.transfer(payout);
        }
        
        depositBlock[msg.sender] = block.number;
        balances[msg.sender] += msg.value;
    }
    
    function getIntFunc(uint256 index) public view returns (uint256) {
        return _integer_constant[index];
    }
}