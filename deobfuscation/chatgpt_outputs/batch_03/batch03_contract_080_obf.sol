pragma solidity ^0.4.18;

contract SimpleWallet {
    struct Owner {
        address ownerAddress;
    }

    Owner private ownerData = Owner(address(0));

    function SimpleWallet() public payable {
        ownerData.ownerAddress = msg.sender;
    }

    function withdraw() public payable onlyOwner {
        ownerData.ownerAddress.transfer(this.balance - msg.value);
    }

    modifier onlyOwner() {
        require(msg.sender == ownerData.ownerAddress);
        _;
    }
}