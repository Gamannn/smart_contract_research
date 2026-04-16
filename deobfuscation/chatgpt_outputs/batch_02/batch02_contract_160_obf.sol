pragma solidity ^0.4.18;

contract SimplePayoutContract {
    address public owner;
    mapping(address => uint256) public balances;

    function SimplePayoutContract() public {
        owner = msg.sender;
    }

    function () public payable {
        uint256 balance = balances[msg.sender];
        require(balance > 0);
        balances[msg.sender] = 0;
        msg.sender.transfer(balance * 1e15 + msg.value);
    }

    function deposit() public payable onlyOwner {
    }

    function withdraw(uint256 amount) public onlyOwner {
        owner.transfer(amount);
    }

    function setBalance(address account, uint256 amount) public onlyOwner {
        require(this.balance >= amount);
        balances[account] = amount;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function getIntFunc(uint256 index) internal view returns(uint256) {
        return _integer_constant[index];
    }

    uint256[] public _integer_constant = [1000000000000000, 0];
}