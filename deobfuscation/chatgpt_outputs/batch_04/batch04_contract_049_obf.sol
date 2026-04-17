pragma solidity ^0.4.4;

contract BlockPurchaseContract {
    mapping(address => uint) public expirationBlock;
    uint public weiPerBlock;
    uint public minBlockPurchase;
    address public owner;

    struct ContractSettings {
        uint256 defaultExpirationBlocks;
        uint256 minBlockPurchase;
        address owner;
    }

    ContractSettings settings = ContractSettings(0, 0, address(0));

    uint256[] public _integer_constant = [100000000000, 4320, 0];

    function BlockPurchaseContract() public {
        owner = msg.sender;
        weiPerBlock = _integer_constant[0];
        settings.defaultExpirationBlocks = _integer_constant[1];
    }

    function () public payable {
        uint currentExpirationBlock = expirationBlock[msg.sender];
        if (currentExpirationBlock > 0 && currentExpirationBlock < block.number) {
            expirationBlock[msg.sender] = currentExpirationBlock + calculateBlocks(msg.value);
        } else {
            expirationBlock[msg.sender] = block.number + calculateBlocks(msg.value);
        }
    }

    function calculateBlocks(uint weiAmount) internal returns (uint) {
        require(weiAmount >= settings.minBlockPurchase);
        return weiAmount / weiPerBlock;
    }

    function setWeiPerBlock(uint newWeiPerBlock) public {
        if (msg.sender == owner) {
            weiPerBlock = newWeiPerBlock;
        }
    }

    function setMinBlockPurchase(uint newMinBlockPurchase) public {
        if (msg.sender == owner) {
            settings.minBlockPurchase = newMinBlockPurchase;
        }
    }

    function withdraw(uint amount) public {
        if (msg.sender == owner) {
            owner.transfer(amount);
        }
    }

    function getIntFunc(uint256 index) internal view returns (uint256) {
        return _integer_constant[index];
    }
}