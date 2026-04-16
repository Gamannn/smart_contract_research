pragma solidity ^0.4.0;

contract SimpleBank {
    mapping(address => uint) private balances;
    address private owner;

    event DepositDone(string message, address accountAddress, uint amount);
    event WithdrawalDone(string message, address accountAddress, uint amount);

    function SimpleBank() public {
        owner = msg.sender;
    }

    function deposit() public payable {
        balances[msg.sender] += msg.value;
        emit DepositDone("A deposit was done", msg.sender, msg.value);
    }

    function withdraw(uint amount) public {
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        if (!msg.sender.send(amount)) {
            balances[msg.sender] += amount;
        } else {
            emit WithdrawalDone("A withdrawal was done", msg.sender, amount);
        }
    }

    function getBalance() public constant returns (uint) {
        return balances[msg.sender];
    }

    function getStrFunc(uint256 index) internal view returns (string storage) {
        return _string_constant[index];
    }

    string[] public _string_constant = ["A withdrawal was done", "A deposit was done"];
}