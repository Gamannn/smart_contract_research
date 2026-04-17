pragma solidity ^0.5.1;

contract Ox129777940d48ba6c14fa1794400499189b7ed2a1 {
    address public owner;
    
    event Deposit(uint256 amount);
    event Transfer(address recipient, uint256 amount);
    
    constructor() public {
        owner = msg.sender;
    }
    
    function transfer(address payable recipient, uint256 amount) public onlyOwner {
        recipient.transfer(amount);
        emit Transfer(recipient, amount);
    }
    
    function() payable external {
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