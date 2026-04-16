pragma solidity ^0.4.21;

contract Token {
    function transfer(uint, address) payable {}
}

contract Lottery {
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    address public owner;
    Token public token;
    bool public isActive;

    constructor() public {
        owner = msg.sender;
        isActive = false;
    }

    function setToken(address tokenAddress) public onlyOwner {
        token = Token(tokenAddress);
    }

    function setActive(bool active) public onlyOwner {
        isActive = active;
    }

    function() public payable {
        if (isActive == true) {
            require(msg.value == 100000000000000000);
            token.transfer(76, msg.sender);
        } else {
            revert();
        }
    }
}