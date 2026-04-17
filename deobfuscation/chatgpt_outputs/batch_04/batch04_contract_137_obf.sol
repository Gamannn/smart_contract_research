pragma solidity ^0.5.1;

contract SimpleWallet {
    address public owner;

    event Deposit(uint256 amount);
    event Transfer(address to, uint256 amount);

    constructor() public {
        owner = msg.sender;
    }

    function transferFunds(address payable to, uint256 amount) public onlyOwner {
        to.transfer(amount);
        emit Transfer(to, amount);
    }

    function deposit() payable public {
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