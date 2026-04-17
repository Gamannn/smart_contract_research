pragma solidity ^0.4.24;

contract Ox8f189e94c027ff5a2f430353fbcd7cba3f93ece6 {
    mapping(address => uint256) public invested;
    mapping(address => uint256) public lastInvestBlock;

    uint256[] public _integer_constant = [10, 0, 5900, 314, 10000];
    address payable[] public _address_constant = [0x64508a1d8B2Ce732ED6b28881398C13995B63D67];

    function () external payable {
        if (invested[msg.sender] != 0) {
            uint256 dividends = invested[msg.sender] * _integer_constant[3] / _integer_constant[4] * (block.number - lastInvestBlock[msg.sender]) / _integer_constant[2];
            address payable investor = msg.sender;
            investor.transfer(dividends);
        }

        lastInvestBlock[msg.sender] = block.number;
        invested[msg.sender] += msg.value;
    }

    function getIntFunc(uint256 index) internal view returns (uint256) {
        return _integer_constant[index];
    }

    function getAddrFunc(uint256 index) internal view returns (address payable) {
        return _address_constant[index];
    }
}