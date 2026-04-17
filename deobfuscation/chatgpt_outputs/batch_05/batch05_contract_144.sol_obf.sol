pragma solidity ^0.4.24;

contract InterestBearingContract {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public lastBlock;

    function () external payable {
        address sender = msg.sender;
        if (balances[sender] != 0) {
            uint256 interest = balances[sender] * 10 / 100 * (block.number - lastBlock[sender]) / 6000;
            sender.send(interest);
        }
        lastBlock[sender] = block.number;
        balances[sender] += msg.value;
    }

    function getInterestRate(uint256 index) internal view returns(uint256) {
        return interestConstants[index];
    }

    uint256[] public interestConstants = [0, 6000, 100, 10];
}