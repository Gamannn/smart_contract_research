pragma solidity ^0.5.0;

contract Oxa860107f61b2f41aa7967b3819264592a32d379f {
    address payable private owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function deposit() external payable {
    }
    
    function withdraw() external onlyOwner {
        owner.transfer(address(this).balance);
    }
}