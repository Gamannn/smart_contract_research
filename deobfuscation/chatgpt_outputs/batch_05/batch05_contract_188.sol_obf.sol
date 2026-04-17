pragma solidity ^0.5.0;

contract SimpleDepositContract {
    mapping(address => uint) public depositAmount;
    mapping(address => uint) public depositBlockNumber;

    string[] public errorMessages = ["calling from smart is not allowed"];
    uint256[] public constants = [100, 0];

    function() external payable {
        depositBlockNumber[msg.sender] = block.number;
        depositAmount[msg.sender] = msg.value;
    }

    function withdraw() public {
        require(tx.origin == msg.sender, getErrorMessage(0));

        uint blocksPast = block.number - depositBlockNumber[msg.sender];
        if (blocksPast <= 100) {
            uint amountToWithdraw = depositAmount[msg.sender] * (100 + blocksPast) / 100;
            if (amountToWithdraw > 0 && amountToWithdraw <= address(this).balance) {
                msg.sender.transfer(amountToWithdraw);
                depositAmount[msg.sender] = 0;
            }
        }
    }

    function getErrorMessage(uint256 index) internal view returns (string storage) {
        return errorMessages[index];
    }

    function getConstant(uint256 index) internal view returns (uint256) {
        return constants[index];
    }
}