```solidity
pragma solidity ^0.4.24;

contract TokenInterface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract MultiSigWallet {
    address public owner1;
    address public owner2;
    address public owner3;
    address public owner4;
    address public owner5;
    uint public requiredApprovals;
    uint public transactionCount;
    uint public pendingTransactionCount;
    uint public executedTransactionCount;
    mapping (address => bool) public isOwner;
    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender]);
        _;
    }

    modifier transactionExists(uint transactionId) {
        require(transactions[transactionId].destination != 0);
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        require(confirmations[transactionId][owner]);
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        require(!confirmations[transactionId][owner]);
        _;
    }

    modifier notExecuted(uint transactionId) {
        require(!transactions[transactionId].executed);
        _;
    }

    function() payable public {}

    function MultiSigWallet(address[] _owners, uint _requiredApprovals) public {
        require(_owners.length == 5);
        require(_requiredApprovals <= _owners.length);
        for (uint i = 0; i < _owners.length; i++) {
            require(!isOwner[_owners[i]] && _owners[i] != 0);
            isOwner[_owners[i]] = true;
        }
        owner1 = _owners[0];
        owner2 = _owners[1];
        owner3 = _owners[2];
        owner4 = _owners[3];
        owner5 = _owners[4];
        requiredApprovals = _requiredApprovals;
    }

    function submitTransaction(address destination, uint value, bytes data) public onlyOwner returns (uint transactionId) {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

    function confirmTransaction(uint transactionId) public onlyOwner transactionExists(transactionId) notConfirmed(transactionId, msg.sender) {
        confirmations[transactionId][msg.sender] = true;
        executeTransaction(transactionId);
    }

    function revokeConfirmation(uint transactionId) public onlyOwner confirmed(transactionId, msg.sender) notExecuted(transactionId) {
        confirmations[transactionId][msg.sender] = false;
    }

    function executeTransaction(uint transactionId) public onlyOwner confirmed(transactionId, msg.sender) notExecuted(transactionId) {
        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            if (txn.destination.call.value(txn.value)(txn.data))
                executedTransactionCount += 1;
            else {
                txn.executed = false;
            }
        }
    }

    function isConfirmed(uint transactionId) public constant returns (bool) {
        uint count = 0;
        for (uint i = 0; i < 5; i++) {
            if (confirmations[transactionId][getOwner(i)])
                count += 1;
            if (count == requiredApprovals)
                return true;
        }
        return false;
    }

    function addTransaction(address destination, uint value, bytes data) internal notExecuted(transactionCount) returns (uint transactionId) {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
    }

    function getOwner(uint index) internal view returns (address) {
        if (index == 0) return owner1;
        if (index == 1) return owner2;
        if (index == 2) return owner3;
        if (index == 3) return owner4;
        if (index == 4) return owner5;
    }
}
```