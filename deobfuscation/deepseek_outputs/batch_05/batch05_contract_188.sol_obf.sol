pragma solidity ^0.5;

contract Oxacecd0bf3bf30980d752e562ea5583d2627b1bc4 {
    mapping(address => uint256) public depositAmount;
    mapping(address => uint256) public depositBlock;

    string[] public _string_constant = ["calling from smart is not allowed"];
    uint256[] public _integer_constant = [100, 0];

    function() external payable {
        depositBlock[msg.sender] = block.number;
        depositAmount[msg.sender] = msg.value;
    }

    function withdraw() public {
        require(tx.origin == msg.sender, _string_constant[0]);
        uint256 blocksPassed = block.number - depositBlock[msg.sender];
        if (blocksPassed <= 100) {
            uint256 amountToWithdraw = depositAmount[msg.sender] * (100 + blocksPassed) / 100;
            if ((amountToWithdraw > 0) && (amountToWithdraw <= address(this).balance)) {
                msg.sender.transfer(amountToWithdraw);
                depositAmount[msg.sender] = 0;
            }
        }
    }
}