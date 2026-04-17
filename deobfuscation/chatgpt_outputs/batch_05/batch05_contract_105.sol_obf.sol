pragma solidity ^0.4.18;

contract SimpleBank {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public reservedAmounts;
    address public owner;
    uint256 public minDepositAmount = 100000000000000000; // 0.1 ether

    event Reserved(address indexed account, uint256 amount);
    event Withdrawn(address indexed account, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function SimpleBank() public {
        owner = msg.sender;
        reservedAmounts[owner] = minDepositAmount;
    }

    function setMinDepositAmount(uint256 newMinDepositAmount) public onlyOwner returns (bool success) {
        minDepositAmount = newMinDepositAmount;
        return true;
    }

    function reserveFunds(uint256 amount) public returns (bool success) {
        require(amount >= minDepositAmount);
        require(balances[msg.sender] > 0);

        reservedAmounts[msg.sender] = amount;
        return true;
    }

    function withdrawFunds(uint256 amount) public returns (bool success) {
        require(amount > 0);
        require(balances[msg.sender] >= reservedAmounts[msg.sender]);
        require(balances[msg.sender] >= amount);

        balances[msg.sender] -= amount;
        uint256 fee = amount * 2 / 100;
        balances[owner] += fee;
        msg.sender.transfer(amount - fee);

        Withdrawn(msg.sender, amount);
        return true;
    }

    function deposit() private {
        balances[msg.sender] += msg.value;
        reservedAmounts[msg.sender] = minDepositAmount;
        Reserved(msg.sender, msg.value);
    }

    function() payable public {
        deposit();
    }
}