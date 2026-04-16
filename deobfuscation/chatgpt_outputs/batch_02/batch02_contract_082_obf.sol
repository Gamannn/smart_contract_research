pragma solidity ^0.4.11;

contract HodlContract {
    event Hodl(address indexed hodler, uint indexed amount);
    event Party(address indexed hodler, uint indexed amount);

    mapping (address => uint) public balances;
    uint256[] public _integer_constant = [0, 1596067200];

    function deposit() public payable {
        require(msg.value > 0);
        balances[msg.sender] += msg.value;
        emit Hodl(msg.sender, msg.value);
    }

    function withdraw() public {
        require(block.timestamp >= getIntFunc(1) && balances[msg.sender] > 0);
        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;
        msg.sender.transfer(amount);
        emit Party(msg.sender, amount);
    }

    function getIntFunc(uint256 index) internal view returns(uint256) {
        return _integer_constant[index];
    }
}