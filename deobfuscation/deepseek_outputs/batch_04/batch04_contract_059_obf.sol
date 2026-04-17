```solidity
pragma solidity ^0.4.0;

contract PyramidScheme {
    event Payout(address indexed beneficiary);
    event Join(address indexed participant);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    uint public queueFront;
    uint public queueSize;
    uint public payoutAmount;
    uint public buyInAmount;
    uint public participantsUntilPayout;
    
    address public owner;
    
    mapping(uint => address) public queue;
    mapping(address => uint) public balances;
    
    function PyramidScheme() public {
        owner = msg.sender;
        buyInAmount = 0.01 ether;
        payoutAmount = 0.02 ether;
        participantsUntilPayout = 3;
    }
    
    function() public payable {
        join();
    }
    
    function withdraw() public {
        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;
        msg.sender.transfer(amount);
    }
    
    function addToQueue() internal {
        queue[queueSize] = msg.sender;
        queueSize++;
    }
    
    function processPayout() internal {
        address beneficiary = queue[queueFront];
        balances[beneficiary] += payoutAmount;
        queueFront++;
        Payout(beneficiary);
    }
    
    function shouldPayout() internal view returns (bool) {
        return queueSize % participantsUntilPayout == 0;
    }
    
    function join() internal {
        bool insufficientValue = msg.value < buyInAmount;
        if (insufficientValue) {
            return;
        }
        
        addToQueue();
        Join(msg.sender);
        
        if (shouldPayout()) {
            processPayout();
        }
    }
    
    function setBuyInAmount(uint _newBuyInAmount) public onlyOwner {
        buyInAmount = _newBuyInAmount;
    }
    
    function setParticipantsUntilPayout(uint _newParticipantsUntilPayout) public onlyOwner {
        participantsUntilPayout = _newParticipantsUntilPayout;
    }
    
    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
    
    function setPayoutAmount(uint _newPayoutAmount) public onlyOwner {
        payoutAmount = _newPayoutAmount;
    }
    
    function withdrawOwner(uint amount) public onlyOwner {
        owner.transfer(amount);
    }
}
```