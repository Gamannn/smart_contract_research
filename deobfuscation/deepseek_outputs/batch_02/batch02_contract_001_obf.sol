pragma solidity ^0.4.18;

contract Ownable {
    address public owner;
    address public pendingOwner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

    function claimOwnership() public {
        require(msg.sender == pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }

    constructor() public {
        owner = msg.sender;
    }
}

contract Vault is Ownable {
    uint public minimumDeposit;
    mapping(address => uint) public balances;

    function initialize() public {
        owner = msg.sender;
        minimumDeposit = 1 ether;
    }

    function() public payable {
        deposit();
    }

    function deposit() payable public {
        if (msg.value >= minimumDeposit) {
            balances[msg.sender] += msg.value;
        }
    }

    function withdraw(address recipient, address token, uint amount) public onlyOwner {
        if (balances[recipient] > 0) {
            balances[recipient] = 0;
            transferToken(token, amount, recipient);
        }
    }

    function transfer(address to, uint amount) public onlyOwner payable {
        if (balances[msg.sender] > 0) {
            if (balances[to] >= amount) {
                to.call.value(amount)();
                balances[to] -= amount;
            }
        }
    }

    function getBalance() public constant returns (uint) {
        return this.balance;
    }

    function transferToken(address token, uint amount, address recipient) internal {
        // Placeholder for token transfer logic
    }
}