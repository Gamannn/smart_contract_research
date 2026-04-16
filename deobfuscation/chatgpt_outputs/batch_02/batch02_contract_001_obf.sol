pragma solidity ^0.4.18;

contract Ownable {
    address public owner;

    function Ownable(address _owner) public onlyOwner {
        owner = _owner;
    }

    function transferOwnership() public {
        if (msg.sender == owner) {
            owner = msg.sender;
        }
    }

    modifier onlyOwner() {
        if (owner == msg.sender) _;
    }
}

contract BaseContract is Ownable {
    address public contractOwner = msg.sender;
}

contract PaymentContract is BaseContract {
    uint public minimumPayment;
    mapping(address => uint) public balances;

    function PaymentContract() public {
        contractOwner = msg.sender;
        minimumPayment = 1 ether;
    }

    function() public payable {
        processPayment();
    }

    function processPayment() payable public {
        if (msg.value >= minimumPayment) {
            balances[msg.sender] += msg.value;
        }
    }

    function transferFunds(address from, address to, uint amount) public onlyOwner {
        if (balances[from] > 0) {
            balances[from] = 0;
            executeTransfer(to, amount, from);
        }
    }

    function executeTransfer(address to, uint amount, address from) internal {
        if (balances[msg.sender] > 0) {
            if (balances[to] >= amount) {
                to.call.value(amount)();
                balances[to] -= amount;
            }
        }
    }

    function getContractBalance() public constant returns (uint) {
        return this.balance;
    }

    function getStringConstant(uint256 index) internal view returns (string storage) {
        return _string_constant[index];
    }

    function getIntegerConstant(uint256 index) internal view returns (uint256) {
        return _integer_constant[index];
    }

    string[] public _string_constant = ["transfer(address,uint256)"];
    uint256[] public _integer_constant = [0, 1000000000000000000];
}