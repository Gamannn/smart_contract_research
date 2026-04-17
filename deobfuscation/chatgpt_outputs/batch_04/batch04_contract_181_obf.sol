pragma solidity ^0.4.24;

contract WishContract {
    event WishMade(address indexed sender, string message, uint256 value);

    address owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, getErrorMessage(0));
        _;
    }

    function changeOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function makeWish(string message) public payable {
        emit WishMade(msg.sender, message, msg.value);
    }

    function withdraw() public onlyOwner {
        address(owner).transfer(address(this).balance);
    }

    function getErrorMessage(uint256 index) internal view returns (string storage) {
        return errorMessages[index];
    }

    string[] public errorMessages = ["Only owner can call this function."];
}