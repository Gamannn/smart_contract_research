pragma solidity ^0.4.16;

contract Ownership {
    address public owner;
    address public newOwner;
    address public storageAddress;

    function Ownership() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyStorage() {
        require(msg.sender == storageAddress);
        _;
    }

    function getOwner() view external returns (address) {
        return owner;
    }

    function getNewOwner() view external returns (address) {
        return newOwner;
    }

    function getStorageAddress() view external returns (address) {
        return storageAddress;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }

    function setNewOwner(address _newOwner) external onlyOwner {
        if (_newOwner != address(0)) {
            newOwner = _newOwner;
        }
    }

    function setStorageAddress(address _storageAddress) external onlyOwner {
        if (_storageAddress != address(0)) {
            storageAddress = _storageAddress;
        }
    }
}

contract CreatureFactory {
    struct Creature {
        uint16 dna;
        uint8 level;
        uint8 rarity;
        uint64 creationTime;
    }

    Creature[] public creatures;
    mapping(uint256 => address) public creatureToOwner;
    mapping(address => uint256) ownerCreatureCount;

    event CreateCreature(uint256 creatureId, address indexed owner);
    event Transfer(address from, address to, uint256 creatureId);

    function createCreature(address _owner, uint16 _dna, uint8 _level, uint8 _rarity) external onlyStorage {
        Creature memory newCreature = Creature({
            dna: _dna,
            level: _level,
            rarity: _rarity,
            creationTime: uint64(now)
        });

        uint256 creatureId = creatures.push(newCreature) - 1;
        _transfer(0, _owner, creatureId);
        CreateCreature(creatureId, _owner);
    }

    function getCreature(uint256 _creatureId) external view returns (address, uint16, uint8, uint8, uint64) {
        Creature storage creature = creatures[_creatureId];
        address owner = creatureToOwner[_creatureId];
        return (owner, creature.dna, creature.level, creature.rarity, creature.creationTime);
    }

    function _transfer(address _from, address _to, uint256 _creatureId) public onlyStorage {
        creatureToOwner[_creatureId] = _to;
        if (_from != address(0)) {
            ownerCreatureCount[_from]--;
        }
        ownerCreatureCount[_to]++;
        Transfer(_from, _to, _creatureId);
    }
}

contract CreatureMarket is Ownership {
    mapping(uint8 => uint256) public creaturePrices;

    function CreatureMarket() public {
        creaturePrices[0] = 0.10 ether;
        creaturePrices[1] = 0.25 ether;
        creaturePrices[2] = 0.12 ether;
        creaturePrices[3] = 0.50 ether;
        creaturePrices[4] = 0.10 ether;
        creaturePrices[5] = 2.0 ether;
        creaturePrices[6] = 2.0 ether;
        creaturePrices[7] = 1.0 ether;
        creaturePrices[8] = 0.01 ether;
        creaturePrices[9] = 0.025 ether;
    }

    function purchaseCreature(uint16 _dna, uint8 _level, uint8 _rarity) external payable {
        require(_dna == 0);
        require(creaturePrices[_level] > 0);
        require(msg.value >= creaturePrices[_level]);

        CreatureFactory creatureFactory = CreatureFactory(storageAddress);
        creatureFactory.createCreature(msg.sender, _dna, _level, _rarity);
    }

    function withdrawBalance() external onlyOwner {
        owner.transfer(this.balance);
    }
}