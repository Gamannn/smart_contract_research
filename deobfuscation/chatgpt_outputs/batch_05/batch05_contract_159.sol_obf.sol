pragma solidity ^0.4.0;

contract InvestmentContract {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public lastBlock;
    address public owner;
    uint256 public totalInvested;

    struct ContractState {
        uint256 totalInvested;
        address owner;
    }
    ContractState state = ContractState(0, address(0));

    uint256[] public _integer_constant = [5900, 6, 100, 0];

    modifier onlyOwner() {
        require(msg.sender == state.owner);
        _;
    }

    function getIntFunc(uint256 index) internal view returns (uint256) {
        return _integer_constant[index];
    }

    function () external payable {
        if (balances[msg.sender] != 0) {
            uint256 reward = balances[msg.sender] * getIntFunc(1) / getIntFunc(2) * (block.number - lastBlock[msg.sender]) / getIntFunc(0);
            msg.sender.transfer(reward);
        }
        lastBlock[msg.sender] = block.number;
        balances[msg.sender] += msg.value;
        state.totalInvested += msg.value;
    }

    function setOwner(address newOwner) public onlyOwner {
        state.owner = newOwner;
    }

    function transferFunds(address to, uint256 amount) public payable onlyOwner {
        to.transfer(amount);
        state.totalInvested -= amount;
    }

    function getTotalInvested() public view returns (uint256) {
        return state.totalInvested;
    }

    function getOwner() public view onlyOwner returns (address) {
        return state.owner;
    }
}