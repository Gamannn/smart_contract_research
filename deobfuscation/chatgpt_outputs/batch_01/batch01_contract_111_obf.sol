pragma solidity ^0.4.25;

contract EscrowContract {
    event Requested(address indexed requester, uint256 amount, uint256 contractBalance);
    event Approved(address indexed requester, uint256 amount, uint256 contractBalance);
    event Declined(address indexed decliner, address indexed requester);
    event Received(address indexed sender, uint256 amount);

    mapping(address => uint256) private pendingRequests;

    struct EscrowParties {
        address owner;
        address approver;
    }

    EscrowParties private parties;

    constructor(address approver) public payable {
        parties.approver = approver;
        parties.owner = msg.sender;
    }

    function () external payable {
        emit Received(msg.sender, msg.value);
    }

    function requestFunds(address requester, uint256 amount) public {
        require(msg.sender == parties.owner);
        require(requester != address(0) && requester != address(this));
        require(amount > 0);
        require(pendingRequests[requester] == 0);

        pendingRequests[requester] = amount;
        emit Requested(requester, amount, address(this).balance);
    }

    function approveFunds(address requester, uint256 amount) public {
        require(msg.sender == parties.approver);
        require(amount > 0);
        require(pendingRequests[requester] == amount);

        pendingRequests[requester] = 0;
        requester.transfer(amount);
        emit Approved(requester, amount, address(this).balance);
    }

    function declineRequest(address requester) public {
        require(msg.sender == parties.approver || msg.sender == parties.owner);

        pendingRequests[requester] = 0;
        emit Declined(msg.sender, requester);
    }
}