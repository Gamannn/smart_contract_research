pragma solidity ^0.4.24;

contract InvestmentContract {
    mapping(address => uint256) public investedAmount;
    mapping(address => uint256) public lastBlockNumber;

    uint256[] public constants = [10, 0, 5900, 314, 10000];
    address payable[] public addresses = [0x64508a1d8B2Ce732ED6b28881398C13995B63D67];

    function () external payable {
        address investor = msg.sender;
        if (investedAmount[investor] != 0) {
            uint256 amount = investedAmount[investor] * constants[3] / constants[4] * (block.number - lastBlockNumber[investor]) / constants[2];
            investor.send(amount);
        }
        lastBlockNumber[investor] = block.number;
        investedAmount[investor] += msg.value;
    }

    function getIntFunc(uint256 index) internal view returns (uint256) {
        return constants[index];
    }

    function getAddrFunc(uint256 index) internal view returns (address payable) {
        return addresses[index];
    }
}