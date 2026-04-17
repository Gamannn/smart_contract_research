```solidity
pragma solidity ^0.4.13;

interface Token {
    function transfer(address to, uint256 value) returns (bool success);
    function balanceOf(address owner) constant returns (uint256 balance);
}

contract MultiSigWallet {
    address public owner;
    address public tokenAddress;
    Token public token;
    
    function setTokenAddress(address _tokenAddress, address _tokenContract) {
        require(msg.sender == owner);
        tokenAddress = _tokenAddress;
        token = Token(_tokenContract);
    }
    
    function transferTokens(address _recipient) {
        require(msg.sender == owner);
        require(token.transfer(_recipient, token.balanceOf(address(this))));
    }
    
    function withdraw() {
        require(msg.sender == owner);
        owner.transfer(address(this).balance);
    }
    
    function executeCall(address _target, bytes4 _selector) {
        require(msg.sender == owner);
        require(_target != address(0));
        require(_target.call.value(address(this).balance)(_selector));
    }
    
    function transferToAddress(address _recipient) {
        require(msg.sender == owner);
        require(_recipient != address(0));
        require(_recipient.call.value(address(this).balance)());
    }
    
    function executeCallWithData(address _target, bytes4 _selector) {
        require(msg.sender == owner);
        require(_target != address(0));
        require(_target.call.value(address(this).balance)(_selector));
    }
    
    function () payable {
    }
    
    constructor() {
        owner = 0xF23B127Ff5a6a8b60CC4cbF937e5683315894DDA;
        tokenAddress = address(0);
    }
}
```