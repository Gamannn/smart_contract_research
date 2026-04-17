pragma solidity ^0.4.21;

contract EtherReceiver {
    function receiveEther() external payable {}
}

contract UpgradeableContract {
    bool isUpgraded;
    address owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    event LogEtherReceived(address sender, uint value, uint timestamp);
    event LogUpgrade(address newOwner, uint timestamp, uint blockNumber);

    function UpgradeableContract(address initialOwner) {
        owner = initialOwner;
    }

    function receiveEther() payable external {
        emit LogEtherReceived(msg.sender, msg.value, now);
    }

    function upgradeOwner(address newOwner) onlyOwner external {
        owner = newOwner;
    }

    function destroyContract(address recipient) onlyOwner {
        require(isUpgraded);
        selfdestruct(recipient);
    }

    function () payable external {}

    function getBoolFunc(uint256 index) internal view returns(bool) {
        return _bool_constant[index];
    }

    bool[] public _bool_constant = [true];

    struct Scalar2Vector {
        address etheraffles;
        bool isUpgraded;
    }

    Scalar2Vector s2c = Scalar2Vector(address(0), false);
}