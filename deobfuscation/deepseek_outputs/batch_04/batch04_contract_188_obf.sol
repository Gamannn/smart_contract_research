pragma solidity ^0.4.23;

interface Token {
    function transfer(address to, uint256 value) public returns (bool success);
    function balanceOf(address owner) public constant returns (uint256 balance);
}

contract Sale {
    Token public token;
    uint256 public price;
    uint256 public amount;
    bool public active;
    mapping(address => uint) public purchased;

    address public owner = 0x67Dc443AEcEcE8353FE158E5F562873808F12c11;
    address public tokenAddress = 0xfe417d8eef16948ba0301c05f5cba87e2c1c51c8;

    constructor() public {
        token = Token(tokenAddress);
        price = 1451;
        amount = 1000000000;
        active = true;
    }

    function () public payable {
        require(active);
        require(purchased[msg.sender] != 1);
        require(msg.value >= price);
        uint256 contract_token_balance = token.balanceOf(address(this));
        require(contract_token_balance != 0);
        require(token.transfer(msg.sender, amount));
        purchased[msg.sender] = 1;
    }

    function withdraw() public returns (bool success) {
        require(msg.sender == owner);
        uint256 contract_token_balance = token.balanceOf(address(this));
        require(contract_token_balance != 0);
        if (address(this).balance > 0) {
            msg.sender.transfer(address(this).balance);
        }
        success = true;
        return success;
    }

    function balance() public view returns (uint) {
        uint256 contract_token_balance = token.balanceOf(address(this));
        return contract_token_balance;
    }

    function setAmount(uint newAmount, uint newPrice) public returns (bool success) {
        require(msg.sender == owner);
        if (msg.sender == owner) {
            amount = newAmount;
            price = newPrice;
            success = true;
            return success;
        }
    }

    function setActive(bool _active) public returns (bool success) {
        require(msg.sender == owner);
        if (msg.sender == owner) {
            active = _active;
            success = true;
            return success;
        }
    }
}