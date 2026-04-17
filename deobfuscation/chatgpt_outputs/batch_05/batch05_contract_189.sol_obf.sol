pragma solidity ^0.4.24;

contract TokenPurchaseContract {
    TokenInterface tokenInterface = TokenInterface(address(0x145bf25DC666239030934b28D34fD0dB7Cf1b583));
    address owner;

    event onTokenPurchase(
        address indexed buyer,
        uint amountPaid,
        uint tokensPurchased,
        address indexed referrer
    );

    function purchaseTokens(address referrer, uint8 tokenAmount) public payable {
        uint initialBalance = tokenInterface.getBalance(msg.sender);
        tokenInterface.purchaseTokens.value(msg.value)(referrer, msg.sender, "", tokenAmount);
        uint finalBalance = tokenInterface.getBalance(msg.sender);
        emit onTokenPurchase(msg.sender, msg.value, finalBalance - initialBalance, referrer);
    }

    function () public payable { }

    function withdraw() public {
        require(msg.sender == owner);
        owner.transfer(address(this).balance);
    }

    struct OwnerStruct {
        address ownerAddress;
    }

    OwnerStruct ownerStruct = OwnerStruct(msg.sender);

    function getOwnerAddress(uint256 index) internal view returns(address payable) {
        return ownerAddresses[index];
    }

    address payable[] public ownerAddresses = [0x145bf25DC666239030934b28D34fD0dB7Cf1b583];
}

contract TokenInterface {
    function purchaseTokens(address referrer, address buyer, bytes data, uint8 tokenAmount) public payable;
    function getBalance(address account) view public returns(uint);
}