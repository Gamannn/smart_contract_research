```solidity
pragma solidity ^0.4.24;

interface Token {
    function balanceOf(address owner) external constant returns (uint256);
    function transfer(address to, uint256 value) external;
}

contract MultiSigWallet {
    event Proposal(
        uint256 proposalId,
        address proposer,
        address tokenAddress,
        uint256 amount,
        address recipient,
        uint256 deadline
    );
    
    event Accept(uint256 proposalId);
    event NewDirectorA(address newDirector);
    event NewDirectorB(address newDirector);
    
    modifier onlyDirectors() {
        require(msg.sender == data.directorA || msg.sender == data.directorB);
        _;
    }
    
    struct Storage {
        uint256 fee;
        uint256 votingPeriod;
        uint256 proposalCounter;
        uint256 deadline;
        uint256 amount;
        address recipient;
        address tokenAddress;
        address proposer;
        address directorB;
        address directorA;
    }
    
    Storage data;
    
    constructor() public {
        data.votingPeriod = (60 * 60 * 24 * 30) / 15; // 2 days in blocks (assuming 15s block time)
        data.proposalCounter = 0;
        data.fee = 1 ether;
        data.directorA = msg.sender;
        data.directorB = msg.sender;
        resetProposal();
    }
    
    function() public payable {}
    
    function createProposal(
        address tokenAddress,
        uint256 amount,
        address recipient
    ) public onlyDirectors {
        data.proposalCounter++;
        data.proposer = msg.sender;
        data.tokenAddress = tokenAddress;
        data.amount = amount;
        data.recipient = recipient;
        data.deadline = block.number + data.votingPeriod;
        
        emit Proposal(
            data.proposalCounter,
            data.proposer,
            data.tokenAddress,
            data.amount,
            data.recipient,
            data.deadline
        );
    }
    
    function resetProposal() public onlyDirectors {
        data.proposalCounter++;
        if (data.proposalCounter > 1000000) {
            data.proposalCounter = 0;
        }
        data.proposer = address(0);
        data.tokenAddress = address(0);
        data.amount = 0;
        data.recipient = address(0);
        data.deadline = 0;
    }
    
    function acceptProposal(uint256 proposalId) public onlyDirectors {
        require(data.proposalCounter == proposalId);
        require(data.amount > 0);
        require(data.recipient != address(0));
        require(
            data.proposer != msg.sender || 
            block.number >= data.deadline
        );
        
        address tokenAddress = data.tokenAddress;
        address recipient = data.recipient;
        uint256 amount = data.amount;
        
        resetProposal();
        
        if (tokenAddress == address(0)) {
            require(amount <= address(this).balance);
            recipient.transfer(amount);
        } else {
            Token token = Token(tokenAddress);
            token.transfer(recipient, amount);
        }
        
        emit Accept(proposalId);
    }
    
    function changeDirectorA(address newDirector) public payable {
        require(msg.sender == data.directorA);
        require(msg.value == data.fee);
        data.directorA.transfer(data.fee);
        resetProposal();
        data.directorA = newDirector;
        emit NewDirectorA(data.directorA);
    }
    
    function changeDirectorB(address newDirector) public payable {
        require(msg.sender == data.directorB);
        require(msg.value == data.fee);
        data.directorB.transfer(data.fee);
        resetProposal();
        data.directorB = newDirector;
        emit NewDirectorB(data.directorB);
    }
}
```