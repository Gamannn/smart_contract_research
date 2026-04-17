pragma solidity ^0.4.24;

contract TokenProxy {
    TokenInterface public tokenContract = TokenInterface(address(0x145bf25DC666239030934b28D34fD0dB7Cf1b583));
    
    address public owner;
    
    event onTokenPurchase(
        address indexed purchaser,
        uint valueSent,
        uint tokensReceived,
        address indexed referredBy
    );
    
    constructor() public {
        owner = msg.sender;
    }
    
    function buyTokens(address referralAddress, uint8 v) public payable {
        uint initialBalance = tokenContract.balanceOf(msg.sender);
        tokenContract.buy.value(msg.value)(referralAddress, msg.sender, "", v);
        uint finalBalance = tokenContract.balanceOf(msg.sender);
        
        emit onTokenPurchase(
            msg.sender,
            msg.value,
            finalBalance - initialBalance,
            referralAddress
        );
    }
    
    function withdraw() public {
        require(msg.sender == owner);
        owner.transfer(address(this).balance);
    }
    
    function() public payable {}
}

interface TokenInterface {
    function buy(address referral, address buyer, bytes extraData, uint8 v) public payable;
    function balanceOf(address holder) view public returns(uint);
}