pragma solidity ^0.4.7;

contract MobaBase {
    struct ContractState {
        bool isLocked;
        address owner;
    }
    
    ContractState internal state;

    constructor() public {
        state.owner = msg.sender;
    }

    event TransferToOwnerEvent(uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == state.owner, "Only the owner can call this function");
        _;
    }

    modifier notLocked() {
        require(!state.isLocked, "Contract is currently locked");
        _;
    }

    modifier noContract() {
        address addr = msg.sender;
        uint size;
        assembly { size := extcodesize(addr) }
        require(size == 0, "Caller must not be a contract");
        require(msg.sender == tx.origin, "Caller must be the transaction origin");
        _;
    }

    function changeOwner(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            state.owner = newOwner;
        }
    }

    function transferToOwner() public onlyOwner noContract {
        uint256 totalBalance = address(this).balance;
        state.owner.transfer(totalBalance);
        emit TransferToOwnerEvent(totalBalance);
    }

    function updateLockStatus(bool newLockStatus) public onlyOwner {
        require(state.isLocked != newLockStatus, "New lock status must be different from the current status");
        state.isLocked = newLockStatus;
    }
}

contract IBRInviteData {
    function GetAddressByName(bytes32 name) public view returns (address);
}

contract IBRPerSellData {
    function GetPerSellInfo(uint16 id) public view returns (uint16, uint256 price, bool isOver);
}

contract BRPerSellControl is MobaBase {
    IBRInviteData public inviteDataContract;
    IBRPerSellData public perSellDataContract;
    mapping(address => uint16[]) public purchaseHistory;

    event UpdateInterfaceEvent();
    event BuyPerSellEvent(uint16 perSellId, bytes32 name, uint256 price);

    constructor(address inviteData, address perSellData) public {
        inviteDataContract = IBRInviteData(inviteData);
        perSellDataContract = IBRPerSellData(perSellData);
    }

    function updateInterface(address inviteData, address perSellData) public onlyOwner noContract {
        inviteDataContract = IBRInviteData(inviteData);
        perSellDataContract = IBRPerSellData(perSellData);
        emit UpdateInterfaceEvent();
    }

    function getPerSellInfo(uint16 id) public view returns (uint16 perSellId, uint256 price, bool isOver) {
        return perSellDataContract.GetPerSellInfo(id);
    }

    function buyPerSell(uint16 perSellId, bytes32 name) public payable notLocked noContract {
        uint16 id;
        uint256 price;
        bool isOver;
        (id, price, isOver) = perSellDataContract.GetPerSellInfo(perSellId);
        
        require(id == perSellId && id > 0, "Invalid perSell ID");
        require(msg.value == price, "Incorrect payment amount");
        require(!isOver, "PerSell is no longer available");

        address inviteAddress = inviteDataContract.GetAddressByName(name);
        if (inviteAddress != address(0)) {
            uint256 reward = msg.value * 10 / 100;
            inviteAddress.transfer(reward);
        }

        purchaseHistory[msg.sender].push(id);
        emit BuyPerSellEvent(perSellId, name, price);
    }

    function getPurchaseHistory(address addr) public view returns (uint16[]) {
        return purchaseHistory[addr];
    }
}