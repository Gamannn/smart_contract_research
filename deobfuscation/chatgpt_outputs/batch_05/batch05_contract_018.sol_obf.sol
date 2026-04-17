pragma solidity^0.4.21;

contract EtherReceiver {
    function receiveEther() external payable {}
}

contract EtherManager {
    bool isActive;
    address owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    event LogEtherReceived(address sender, uint amount, uint timestamp);
    event LogUpgrade(address newOwner, uint timestamp, uint balance);

    function EtherManager(address initialOwner) public {
        owner = initialOwner;
        scalar2VectorInstance.owner = initialOwner;
        EtherReceiver(address(0)).receiveEther.value(this.balance)();
    }

    function receiveEther() payable external {
        emit LogEtherReceived(msg.sender, msg.value, now);
    }

    function updateOwner(address newOwner) onlyOwner external {
        owner = newOwner;
        scalar2VectorInstance.isActive = getBoolFunc(0);
    }

    function destroyContract(address recipient) onlyOwner public {
        require(isActive);
        selfdestruct(recipient);
    }

    function () payable external {}

    function getBoolFunc(uint256 index) internal view returns(bool) {
        return _bool_constant[index];
    }

    bool[] public _bool_constant = [true];

    struct Scalar2Vector {
        address owner;
        bool isActive;
    }

    Scalar2Vector scalar2VectorInstance = Scalar2Vector(address(0), false);
}