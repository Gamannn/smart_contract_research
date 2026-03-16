pragma solidity ^0.4.24;

interface TokenInterface {
    function balanceOf(address account) external constant returns (uint256);
    function transfer(address to, uint256 value) external;
}

contract ProposalContract {
    event ProposalCreated(
        uint256 proposalId,
        address proposer,
        address tokenAddress,
        uint256 amount,
        address recipient,
        uint256 expirationBlock
    );
    event ProposalAccepted(uint256 proposalId);
    event DirectorAChanged(address newDirectorA);
    event DirectorBChanged(address newDirectorB);

    modifier onlyDirectors() {
        require(
            msg.sender == contractState.directorA || msg.sender == contractState.directorB
        );
        _;
    }

    struct ContractState {
        uint256 proposalFee;
        uint256 proposalExpiration;
        uint256 proposalCount;
        uint256 currentProposalId;
        uint256 proposalAmount;
        address proposalRecipient;
        address proposalToken;
        address proposer;
        address directorA;
        address directorB;
    }

    ContractState contractState;

    constructor() public {
        contractState.proposalExpiration = (60 * 60 * 24 * 30) / 15;
        contractState.proposalCount = 0;
        contractState.proposalFee = 1 ether;
        contractState.directorA = msg.sender;
        contractState.directorB = msg.sender;
        resetProposal();
    }

    function () public payable {}

    function createProposal(
        address tokenAddress,
        uint256 amount,
        address recipient
    ) public onlyDirectors {
        contractState.proposalCount++;
        contractState.proposer = msg.sender;
        contractState.proposalToken = tokenAddress;
        contractState.proposalAmount = amount;
        contractState.proposalRecipient = recipient;
        contractState.currentProposalId = block.number + contractState.proposalExpiration;

        emit ProposalCreated(
            contractState.proposalCount,
            contractState.proposer,
            contractState.proposalToken,
            contractState.proposalAmount,
            contractState.proposalRecipient,
            contractState.currentProposalId
        );
    }

    function resetProposal() public onlyDirectors {
        contractState.proposalCount++;
        if (contractState.proposalCount > 1000000) {
            contractState.proposalCount = 0;
        }
        contractState.proposer = address(0);
        contractState.proposalToken = address(0);
        contractState.proposalAmount = 0;
        contractState.proposalRecipient = address(0);
        contractState.currentProposalId = 0;
    }

    function acceptProposal(uint256 proposalId) public onlyDirectors {
        require(contractState.proposalCount == proposalId);
        require(contractState.proposalAmount > 0);
        require(contractState.proposalRecipient != address(0));
        require(
            contractState.proposer != msg.sender || block.number >= contractState.currentProposalId
        );

        address tokenAddress = contractState.proposalToken;
        address recipient = contractState.proposalRecipient;
        uint256 amount = contractState.proposalAmount;

        resetProposal();

        if (tokenAddress == address(0)) {
            require(amount <= address(this).balance);
            recipient.transfer(amount);
        } else {
            TokenInterface token = TokenInterface(tokenAddress);
            token.transfer(recipient, amount);
        }

        emit ProposalAccepted(proposalId);
    }

    function changeDirectorA(address newDirectorA) public payable {
        require(msg.sender == contractState.directorA);
        require(msg.value == contractState.proposalFee);
        contractState.directorA.transfer(contractState.proposalFee);
        resetProposal();
        contractState.directorA = newDirectorA;
        emit DirectorAChanged(contractState.directorA);
    }

    function changeDirectorB(address newDirectorB) public payable {
        require(msg.sender == contractState.directorB);
        require(msg.value == contractState.proposalFee);
        contractState.directorB.transfer(contractState.proposalFee);
        resetProposal();
        contractState.directorB = newDirectorB;
        emit DirectorBChanged(contractState.directorB);
    }
}