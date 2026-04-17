```solidity
pragma solidity ^0.4.24;

contract MessageContract {
    event FundsWithdrawn(uint amount);

    address public owner;
    string public message;
    uint256 public balance;
    uint256 public messageCount;
    uint256 public price;
    uint256 public lastPrice;
    uint256 public constant MINIMUM_PRICE = 0.01 ether;

    constructor() public {
        owner = msg.sender;
        message = "YOUR MESSAGE GOES HERE";
        price = MINIMUM_PRICE;
    }

    function updateMessage(string newMessage) public payable {
        require(msg.value >= price, "Insufficient funds to update message");

        uint256 fee;
        if (price > MINIMUM_PRICE) {
            fee = SafeMath.sub(price, MINIMUM_PRICE);
        } else {
            fee = SafeMath.div(SafeMath.mul(price, 50), 100);
        }

        balance = SafeMath.add(balance, fee);
        lastPrice = price;
        price = SafeMath.div(SafeMath.mul(125, price), 100);

        message = newMessage;
        messageCount++;
    }

    function withdrawFunds() public {
        require(msg.sender == owner, "Only owner can withdraw funds");

        uint256 amount = balance;
        balance = 0;
        owner.transfer(amount);

        emit FundsWithdrawn(amount);
    }

    function getMessage(uint index) public view returns (string) {
        return message;
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
```