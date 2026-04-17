pragma solidity ^0.4.18;

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract MessageContract is Ownable {
    string public message;
    uint256 public priceInWei;
    uint256 public maxLength;

    event MessageSet(string newMessage, uint256 oldPrice, uint256 newPrice, address sender);

    function MessageContract(string initialMessage, uint256 initialPrice, uint256 initialMaxLength) public {
        message = initialMessage;
        priceInWei = initialPrice;
        maxLength = initialMaxLength;
    }

    function setMessage(string newMessage) external payable {
        require(msg.value >= priceInWei);
        require(bytes(newMessage).length <= maxLength);

        uint256 newPrice = priceInWei * 2;
        MessageSet(newMessage, priceInWei, newPrice, msg.sender);

        priceInWei = newPrice;
        message = newMessage;
    }

    function withdraw(address to, uint256 amount) external onlyOwner {
        require(this.balance >= amount);
        require(to != address(0));
        to.transfer(amount);
    }
}