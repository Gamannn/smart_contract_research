pragma solidity ^0.4.18;

contract Oxc37b3852ef6e0997795ef70c6c9a756891a7487c {
    mapping (address => uint256) public balances;
    address public owner;

    function Oxc37b3852ef6e0997795ef70c6c9a756891a7487c() public {
        owner = msg.sender;
    }

    function () public payable {
        uint256 balance = balances[msg.sender];
        require(balance > 0);
        balances[msg.sender] = 0;
        msg.sender.transfer(balance * 1e15 + msg.value);
    }

    function deposit() public payable onlyOwner {
    }

    function withdraw(uint256 amount) public onlyOwner {
        owner.transfer(amount);
    }

    function setBalance(address user, uint256 balance) public onlyOwner {
        require(this.balance >= balance);
        balances[user] = balance;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}