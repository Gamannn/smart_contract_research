pragma solidity ^0.4.25;

contract Ox8637082bd548ee4ada85b94452c321a8f2eae667 {
    event Requested(address indexed requester, uint256 amount, uint256 contractBalance);
    event Approved(address indexed requester, uint256 amount, uint256 contractBalance);
    event Declined(address indexed decliner, address indexed requester);
    event Received(address indexed sender, uint256 amount);

    mapping(address => uint256) private pendingRequests;

    struct Roles {
        address owner;
        address approver;
    }

    Roles private roles;

    constructor(address approver) public payable {
        roles.approver = approver;
        roles.owner = msg.sender;
    }

    function() external payable {
        emit Received(msg.sender, msg.value);
    }

    function requestWithdrawal(address requester, uint256 amount) public {
        require(msg.sender == roles.owner);
        require(requester != address(0) && requester != address(this));
        require(amount > 0);
        require(pendingRequests[requester] == 0);

        pendingRequests[requester] = amount;
        emit Requested(requester, amount, address(this).balance);
    }

    function approveWithdrawal(address requester, uint256 amount) public {
        require(msg.sender == roles.approver);
        require(amount > 0);
        require(pendingRequests[requester] == amount);

        pendingRequests[requester] = 0;
        requester.transfer(amount);
        emit Approved(requester, amount, address(this).balance);
    }

    function declineRequest(address requester) public {
        require(msg.sender == roles.approver || msg.sender == roles.owner);
        pendingRequests[requester] = 0;
        emit Declined(msg.sender, requester);
    }
}