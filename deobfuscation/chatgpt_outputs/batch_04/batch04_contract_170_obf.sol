pragma solidity ^0.4.24;

contract TimedPaymentContract {
    mapping(address => uint) lastBlockNumber;
    mapping(address => uint) balances;

    struct AddressPair {
        address contractAddress;
        address beneficiary;
    }

    AddressPair addressPair = AddressPair(this, 0xB);

    function() external payable {
        if ((block.number - lastBlockNumber[addressPair.beneficiary]) >= 5900) {
            addressPair.beneficiary.transfer(addressPair.contractAddress.balance / 100);
            lastBlockNumber[addressPair.beneficiary] = block.number;
        }

        if (balances[msg.sender] != 0) {
            msg.sender.transfer(balances[msg.sender] / 100 * 5 * (block.number - lastBlockNumber[msg.sender]) / 5900);
        }

        lastBlockNumber[msg.sender] = block.number;
        balances[msg.sender] += msg.value;
    }
}