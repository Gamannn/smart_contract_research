```solidity
pragma solidity ^0.4.16;

contract Ownable {
    address public owner;
    address public storageAddress;
    address public callerAddress;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyCaller() {
        require(msg.sender == callerAddress);
        _;
    }
    
    function Ownable() public {
        owner = msg.sender;
    }
    
    function getOwner() view external returns (address) {
        return owner;
    }
    
    function getStorageAddress() view external returns (address) {
        return storageAddress;
    }
    
    function getCallerAddress() view external returns (address) {
        return callerAddress;
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    
    function setStorageAddress(address newStorageAddress) external onlyOwner {
        if (newStorageAddress != address(0)) {
            storageAddress = newStorageAddress;
        }
    }
    
    function setCallerAddress(address newCallerAddress) external onlyOwner {
        if (newCallerAddress != address(0)) {
            callerAddress = newCallerAddress;
        }
    }
}

contract CreatureCreations {
    struct Creature {
        uint16 species;
        uint8 rarity;
        uint8 element;
        uint64 creationTime;
    }
    
    Creature[] public creatures;
    mapping (uint256 => address) public creatureOwner;
    mapping (address => uint256) public ownerCreatureCount;
    
    event CreateCreature(uint256 creatureId, address indexed owner);
    event Transfer(address from, address to, uint256 creatureId);
    
    function createCreature(address owner, uint16 species, uint8 rarity, uint8 element) external onlyCaller {
        Creature memory newCreature = Creature({
            species: species,
            rarity: rarity,
            element: element,
            creationTime: uint64(now)
        });
        
        uint256 creatureId = creatures.push(newCreature) - 1;
        _transfer(0, owner, creatureId);
        CreateCreature(creatureId, owner);
    }
    
    function getCreature(uint256 creatureId) external view returns (address, uint16, uint8, uint8, uint64) {
        Creature storage creature = creatures[creatureId];
        address owner = creatureOwner[creatureId];
        return (
            owner,
            creature.species,
            creature.rarity,
            creature.element,
            creature.creationTime
        );
    }
    
    function _transfer(address from, address to, uint256 creatureId) public onlyCaller {
        creatureOwner[creatureId] = to;
        
        if (from != address(0)) {
            ownerCreatureCount[from]--;
        }
        
        ownerCreatureCount[to]++;
        Transfer(from, to, creatureId);
    }
}

contract CreatureMarket is Ownable {
    mapping (uint8 => uint256) public rarityPrices;
    
    function CreatureMarket() public {
        rarityPrices[0] = 0.10 ether;
        rarityPrices[1] = 0.25 ether;
        rarityPrices[2] = 0.12 ether;
        rarityPrices[3] = 0.50 ether;
        rarityPrices[4] = 0.10 ether;
        rarityPrices[5] = 2.0 ether;
        rarityPrices[6] = 2.0 ether;
        rarityPrices[7] = 1.0 ether;
        rarityPrices[8] = 0.01 ether;
        rarityPrices[9] = 0.025 ether;
    }
    
    function buyCreature(uint16 species, uint8 rarity, uint8 element) external payable {
        require(species == 0);
        require(rarityPrices[rarity] > 0);
        require(msg.value >= rarityPrices[rarity]);
        
        CreatureCreations creatureStorage = CreatureCreations(storageAddress);
        creatureStorage.createCreature(msg.sender, species, rarity, element);
    }
    
    function withdraw() external onlyOwner {
        owner.transfer(this.balance);
    }
}
```