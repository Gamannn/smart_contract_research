pragma solidity ^0.5.1;

contract Ox09b88df24cf5bddfe7cdd0373d3fce374ae26681 {
    address private owner;
    
    event Deposit(uint256 amount);
    event Transfer(address recipient, uint256 amount);
    
    constructor() public {
        owner = msg.sender;
    }
    
    function transfer(address payable recipient, uint256 amount) public onlyOwner {
        recipient.transfer(amount);
        emit Transfer(recipient, amount);
    }
    
    function() external payable {
        emit Deposit(msg.value);
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}