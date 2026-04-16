```solidity
pragma solidity ^0.4.1;

contract Oxbc1e7515ed8b60ebfc18b83ffcff62ee7ce9c828 {
    mapping(address => uint) public contributions;
    mapping(address => uint) public refunds;
    
    uint public amountRaised;
    uint public feeWithdrawn;
    uint public feeAmount;
    
    address public owner;
    address public beneficiary;
    
    uint public deadlineBlockNumber;
    uint public creationTime;
    
    bool public isOpen;
    
    modifier onlyOpen() {
        if ((block.number < deadlineBlockNumber) && isOpen) {
            _;
        } else {
            throw;
        }
    }
    
    modifier onlyAfterDeadline() {
        if ((block.number >= deadlineBlockNumber) && isOpen) {
            _;
        } else {
            throw;
        }
    }
    
    modifier onlyOwner() {
        if (msg.sender == owner) {
            _;
        } else {
            throw;
        }
    }
    
    function Oxbc1e7515ed8b60ebfc18b83ffcff62ee7ce9c828(
        uint _fundingGoal,
        address _beneficiary,
        uint _deadlineBlockNumber
    ) {
        if (isOpen || msg.sender != owner) {
            throw;
        }
        
        if (_deadlineBlockNumber < block.number + 40) {
            throw;
        }
        
        beneficiary = _beneficiary;
        amountRaised = 0;
        feeWithdrawn = 0;
        feeAmount = 0;
        deadlineBlockNumber = _deadlineBlockNumber;
        creationTime = now;
        isOpen = true;
    }
    
    function() payable onlyOpen {
        if (msg.value != 1 ether) {
            throw;
        }
        
        if (refunds[msg.sender] == 0) {
            contributions[msg.sender] += msg.value;
            amountRaised += msg.value;
        }
    }
    
    function getContribution() constant returns (uint contribution) {
        return contributions[msg.sender];
    }
    
    function withdrawExcess() onlyOwner {
        if ((msg.sender == owner) && (this.balance > amountRaised)) {
            uint excess = this.balance - amountRaised;
            if (owner.send(excess)) {
                isOpen = false;
            }
        }
    }
    
    function claimFunds() onlyAfterDeadline {
        uint amount = 0;
        
        if (amountRaised < _fundingGoal && refunds[msg.sender] == 0) {
            amount = contributions[msg.sender];
            refunds[msg.sender] += amount;
            contributions[msg.sender] = 0;
            
            if (!msg.sender.send(amount)) {
                refunds[msg.sender] = 0;
                contributions[msg.sender] = amount;
            }
        } else if (feeWithdrawn == 0) {
            feeAmount = amountRaised * 563 / 10000;
            amount = amountRaised - feeAmount;
            feeWithdrawn += amount;
            
            if (!beneficiary.send(amount)) {
                throw;
            }
            
            if (msg.sender == owner && feeWithdrawn == 0) {
                selfdestruct(owner);
            }
        }
    }
    
    bool[] public _bool_constant = [true, false];
    uint256[] public _integer_constant = [1000000000000000000, 10000, 2, 40, 0, 563];
}
```