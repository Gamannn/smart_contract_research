pragma solidity ^0.4.11;

contract Oxebb7fd12dc41087ba5ab43c6a331568cfd1a48a3 {
    event Hodl(address indexed user, uint indexed amount);
    event Party(address indexed user, uint indexed amount);
    
    mapping (address => uint) public deposits;
    uint public partyTime = 1596067200;
    
    function hodl() public payable {
        require(msg.value > 0);
        deposits[msg.sender] += msg.value;
        Hodl(msg.sender, msg.value);
    }
    
    function party() public {
        require(block.timestamp >= partyTime && deposits[msg.sender] > 0);
        uint amount = deposits[msg.sender];
        deposits[msg.sender] = 0;
        msg.sender.transfer(amount);
        Party(msg.sender, amount);
    }
    
    function getIntFunc(uint256 index) internal view returns(uint256) {
        return _integer_constant[index];
    }
    
    uint256[] public _integer_constant = [0, 1596067200];
}