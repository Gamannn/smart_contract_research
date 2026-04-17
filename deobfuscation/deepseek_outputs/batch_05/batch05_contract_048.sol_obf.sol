pragma solidity ^0.4.21;

contract MultiSigWallet {
    address public owner;
    
    function MultiSigWallet() {
        owner = msg.sender;
    }
    
    function deposit() payable {
    }
    
    function withdraw() {
        owner.transfer(this.balance);
    }
}