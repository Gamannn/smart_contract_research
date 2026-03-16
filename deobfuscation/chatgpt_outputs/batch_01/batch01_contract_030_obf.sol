pragma solidity 0.4.25;

contract Ownable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    address private owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract SimpleWallet is Ownable {
    event Deposit(address indexed sender, uint256 amount);
    event Withdraw(address indexed recipient, uint256 amount);

    function () payable public {
        require(msg.value > 0);
        require(msg.sender != address(0));
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(address recipient, uint256 amount) public onlyOwner {
        require(amount > 0);
        require(address(this).balance >= amount);
        require(recipient != address(0));
        recipient.transfer(amount);
        emit Withdraw(recipient, amount);
    }
}