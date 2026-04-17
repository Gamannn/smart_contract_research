pragma solidity ^0.4.21;

contract SimpleWallet {
    struct Owner {
        address ownerAddress;
    }

    Owner owner;

    function SimpleWallet() public {
        owner.ownerAddress = msg.sender;
    }

    function deposit() public payable {}

    function withdraw() public {
        require(msg.sender == owner.ownerAddress);
        owner.ownerAddress.transfer(this.balance);
    }
}