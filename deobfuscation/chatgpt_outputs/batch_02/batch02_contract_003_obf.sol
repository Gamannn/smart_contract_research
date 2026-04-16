pragma solidity ^0.4.1;

contract Crowdfunding {
    mapping(address => uint) public contributions;
    mapping(address => uint) public refunds;
    uint public totalRaised;
    uint public goal;
    uint public amountWithdrawn;
    address public owner;
    uint public feePercentage;
    uint public creationTime;
    uint public deadlineBlock;
    bool public isActive;

    function Crowdfunding(uint _goal, address _owner, uint _deadlineBlock) public {
        if (isActive || msg.sender != owner) revert();
        if (_deadlineBlock < block.number + 40) revert();
        
        owner = _owner;
        goal = _goal;
        amountWithdrawn = 0;
        totalRaised = 0;
        feePercentage = 563;
        creationTime = now;
        deadlineBlock = _deadlineBlock;
        isActive = true;
    }

    modifier onlyActive() {
        if (block.number < deadlineBlock && isActive) _;
        else revert();
    }

    modifier onlyAfterDeadline() {
        if (block.number >= deadlineBlock && isActive) _;
        else revert();
    }

    function contribute() public payable onlyActive {
        if (msg.value != 1 ether) revert();
        if (refunds[msg.sender] == 0) {
            contributions[msg.sender] += msg.value;
            totalRaised += msg.value;
        }
    }

    function getContribution() public view returns (uint) {
        return contributions[msg.sender];
    }

    function withdrawFunds() public onlyAfterDeadline {
        if (msg.sender == owner && this.balance > totalRaised) {
            uint amount = this.balance - totalRaised;
            if (owner.send(amount)) {
                isActive = false;
            }
        }
    }

    function refund() public onlyAfterDeadline {
        uint refundAmount = 0;
        if (totalRaised < goal && refunds[msg.sender] == 0) {
            refundAmount = contributions[msg.sender];
            refunds[msg.sender] += refundAmount;
            contributions[msg.sender] = 0;
            if (!msg.sender.send(refundAmount)) {
                refunds[msg.sender] = 0;
                contributions[msg.sender] = refundAmount;
            }
        } else if (amountWithdrawn == 0) {
            uint fee = totalRaised * feePercentage / 10000;
            totalRaised -= fee;
            amountWithdrawn += refundAmount;
            if (!owner.send(refundAmount)) {
                totalRaised += fee;
            }
        } else if (msg.sender == owner && amountWithdrawn == 0) {
            selfdestruct(owner);
        }
    }

    function getBoolConstant(uint256 index) public view returns (bool) {
        return _bool_constant[index];
    }

    function getIntConstant(uint256 index) internal view returns (uint256) {
        return _integer_constant[index];
    }

    bool[] public _bool_constant = [true, false];
    uint256[] public _integer_constant = [1000000000000000000, 10000, 2, 40, 0, 563];
}