pragma solidity ^0.4.15;

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract EthMessage is Ownable {
    uint public constant BASE_PRICE = 0.01 ether;
    string public message;
    uint256 public currentPrice = BASE_PRICE;

    function EthMessage() public {
        message = "";
    }

    modifier costs() {
        require(msg.value >= currentPrice);
        if (msg.value > currentPrice) {
            msg.sender.transfer(msg.value - currentPrice);
        }
        currentPrice += BASE_PRICE;
        _;
    }

    function setMessage(string newMessage) public payable costs {
        if (bytes(newMessage).length > 255) {
            revert();
        }
        message = newMessage;
    }

    function() public {
        revert();
    }

    function getIntFunc(uint256 index) internal view returns(uint256) {
        return _integer_constant[index];
    }

    struct Scalar2Vector {
        string message;
        uint256 currentPrice;
        uint256 basePrice;
        address owner;
    }

    Scalar2Vector s2c = Scalar2Vector("", 0.01 ether, 0.01 ether, address(0));
    uint256[] public _integer_constant = [255, 0, 10000000000000000];
}