pragma solidity ^0.4.7;

contract BaseContract {
    struct ContractState {
        uint256 price;
        address owner;
        bool isLocked;
        address newOwner;
    }

    ContractState state = ContractState(0, address(0), false, address(0));

    modifier onlyOwner() {
        require(msg.sender == state.owner, "only owner can call this function");
        _;
    }

    modifier contractNotLocked() {
        require(state.isLocked == false, "contract is locked");
        _;
    }

    modifier onlyExternallyOwnedAccount() {
        address sender = msg.sender;
        uint codeSize;
        assembly { codeSize := extcodesize(sender) }
        require(codeSize == 0, "address must not be a contract");
        require(msg.sender == tx.origin, "msg.sender must be tx.origin");
        _;
    }

    function setNewOwner(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            state.newOwner = newOwner;
        }
    }

    function setLockStatus(bool lockStatus) public onlyOwner {
        require(state.isLocked != lockStatus, "new status == old status");
        state.isLocked = lockStatus;
    }

    function transferToOwner() public onlyExternallyOwnedAccount {
        uint256 balance = address(this).balance;
        state.owner.transfer(balance);
        emit TransferToOwner(state.owner, balance);
    }

    event TransferToOwner(address owner, uint256 amount);
}

contract ExternalContract {
    function checkName(address addr, bytes32 name) public view returns (uint8);
    function getAddressByName(bytes32 name) public view returns (address);
    function getNameByAddress(address addr) public view returns (bytes32);
}

contract MainContract is BaseContract {
    address public owner = 0x0;
    uint256 public price = 10 finney;
    mapping(bytes32 => address) public nameToAddress;
    ExternalContract externalContract;

    constructor(ExternalContract _externalContract) public {
        externalContract = _externalContract;
    }

    event CreateInviteNameEvent(address addr, bytes32 name);

    function createInviteName(bytes32 name) public payable contractNotLocked onlyExternallyOwnedAccount {
        require(msg.value == price, "Incorrect price");
        require(checkName(msg.sender, name) == 0, "Name has been used or address already has a name");
        nameToAddress[name] = msg.sender;
        emit CreateInviteNameEvent(msg.sender, name);
    }

    function checkName(address addr, bytes32 name) public view returns (uint8) {
        if (nameToAddress[name] != address(0)) {
            return 1;
        }
        if (externalContract.getNameByAddress(addr) != 0) {
            return 2;
        }
        uint8 result = externalContract.checkName(addr, name);
        if (result != 0) {
            return result;
        }
        return 0;
    }

    function getAddressByName(bytes32 name) public view returns (address) {
        address addr = externalContract.getAddressByName(name);
        if (addr != address(0)) {
            return addr;
        }
        return nameToAddress[name];
    }

    function getNameByAddress(address addr) public view returns (bytes32) {
        bytes32 name = externalContract.getNameByAddress(addr);
        if (name != 0) {
            return name;
        }
        return externalContract.getNameByAddress(addr);
    }
}