pragma solidity ^0.4.2;

contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract Token is Ownable {
    string public name = "Luxury Token";
    string public symbol = "LUX";
    uint8 public decimals = 0;
    uint256 public totalSupply = 1;
    bool public isAllowedToPurchase = false;
    uint256 public minTokensRequiredForMessage = 10;
    mapping(address => uint256) public balanceOf;
    mapping(address => string) public messages;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event MessageAdded(address indexed from, string message, uint256 balance);

    function Token() public {}

    function transfer(address to, uint256 value) public returns (bool success) {
        if (value == 0) {
            return false;
        }
        if (balanceOf[msg.sender] < value) {
            return false;
        }
        if (balanceOf[to] + value < balanceOf[to]) {
            return false;
        }
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        Transfer(msg.sender, to, value);
        return true;
    }

    function enablePurchasing() public onlyOwner {
        isAllowedToPurchase = true;
    }

    function disablePurchasing() public onlyOwner {
        isAllowedToPurchase = false;
    }

    function () public payable {
        require(isAllowedToPurchase);
        uint256 tokens = msg.value;
        balanceOf[msg.sender] += tokens;
        Transfer(address(this), msg.sender, tokens);
    }

    function balanceOfAddress(address addr) public view returns (uint256) {
        return balanceOf[addr];
    }

    function mint(address to, uint256 value) public onlyOwner {
        balanceOf[to] += value;
        totalSupply += value;
    }

    function setMinTokensRequiredForMessage(uint256 minTokens) public onlyOwner {
        minTokensRequiredForMessage = minTokens;
    }

    function addMessage(string message) public {
        uint256 senderBalance = balanceOf[msg.sender];
        require(senderBalance >= minTokensRequiredForMessage);
        messages[msg.sender] = message;
        MessageAdded(msg.sender, message, senderBalance);
    }
}