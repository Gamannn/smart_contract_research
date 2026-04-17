pragma solidity ^0.4.24;

contract Ox4b0bf4788ab31b9e9d68519fa07cf531c6dc552b {
    event wishMade(
        address indexed user,
        string wish,
        uint256 amount
    );

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function makeWish(string wish) public payable {
        emit wishMade(msg.sender, wish, msg.value);
    }

    function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }
}