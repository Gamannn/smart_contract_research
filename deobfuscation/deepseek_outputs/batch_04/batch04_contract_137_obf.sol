pragma solidity ^0.5.1;

contract Oxace5954c3b3f5701f896c7fbae8631ff1d80f26e {
    address private owner;
    
    event Deposit(uint256 amount);
    event Transfer(address recipient, uint256 amount);
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transfer(address payable recipient, uint256 amount) public onlyOwner {
        recipient.transfer(amount);
        emit Transfer(recipient, amount);
    }
    
    function deposit() payable public {
        emit Deposit(msg.value);
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}