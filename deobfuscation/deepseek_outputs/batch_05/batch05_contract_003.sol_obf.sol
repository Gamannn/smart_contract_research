```solidity
pragma solidity ^0.4.24;

contract MessageBoard {
    event Withdrawal(uint256 amount);
    
    address public owner;
    string public message;
    uint256 public authorBalance;
    uint256 public messageCount;
    uint256 public authorFeePercentage;
    uint256 public minDonation;
    address public lastAuthor;
    
    mapping(uint256 => string) public messages;
    
    constructor() public {
        owner = msg.sender;
        message = "YOUR MESSAGE GOES HERE";
        authorFeePercentage = 25;
        minDonation = 0.01 ether;
    }
    
    function donate() public payable {
        require(msg.value >= minDonation);
        
        uint256 authorFee;
        uint256 ownerFee;
        uint256 donation = msg.value;
        
        if (donation > 0.01 ether) {
            uint256 feeAmount = SafeMath.mul(donation, authorFeePercentage) / 100;
            authorFee = feeAmount;
            ownerFee = feeAmount;
        } else {
            uint256 feeGain = SafeMath.mul(donation, authorFeePercentage) / 100;
            authorFee = feeGain;
            ownerFee = 0;
        }
        
        authorBalance = SafeMath.add(authorBalance, authorFee);
        lastAuthor = msg.sender;
        
        if (donation > 0.01 ether) {
            owner.transfer(ownerFee);
        }
        
        uint256 remaining = donation - authorFee - ownerFee;
        message = messages[messageCount];
        messageCount += 1;
    }
    
    function setMessage(string memory newMessage) internal {
        message = newMessage;
    }
    
    function withdraw() public {
        require(msg.sender == owner);
        uint256 amount = authorBalance;
        authorBalance = 0;
        owner.transfer(amount);
        emit Withdrawal(amount);
    }
    
    function getMessage(uint256 index) public view returns(string memory) {
        return messages[index];
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