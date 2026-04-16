```solidity
pragma solidity ^0.4.16;

library AddressUtils {
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

contract BasicAccessControl {
    address public owner;
    mapping(address => bool) public moderators;
    uint16 public totalModerators;
    bool public isMaintaining = false;
    
    function BasicAccessControl() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyModerators {
        require(msg.sender == owner || moderators[msg.sender] == true);
        _;
    }
    
    modifier isActive {
        require(!isMaintaining);
        _;
    }
    
    function changeOwner(address _newOwner) onlyOwner public {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }
    
    function addModerator(address _newModerator) onlyOwner public {
        if (moderators[_newModerator] == false) {
            moderators[_newModerator] = true;
            totalModerators += 1;
        }
    }
    
    function removeModerator(address _oldModerator) onlyOwner public {
        if (moderators[_oldModerator] == true) {
            moderators[_oldModerator] = false;
            totalModerators -= 1;
        }
    }
    
    function updateMaintenance(bool _isMaintaining) onlyOwner public {
        isMaintaining = _isMaintaining;
    }
}

contract EtheremonEnum {
    enum ResultCode {
        SUCCESS,
        ERROR_CLASS_NOT_FOUND,
        ERROR_LOW_BALANCE,
        ERROR_SEND_FAIL,
        ERROR_NOT_TRAINER,
        ERROR_NOT_ENOUGH_MONEY,
        ERROR_INVALID_AMOUNT
    }
    
    enum ArrayType {
        CLASS_TYPE,
        STAT_STEP,
        STAT_START,
        STAT_BASE,
        OBJ_SKILL
    }
    
    enum PropertyType {
        ANCESTOR,
        XFACTOR
    }
}

interface EtheremonDataBase {
    function getMonsterClass(uint32 _classId) constant external returns(
        uint32 classId,
        uint256 price,
        uint256 returnPrice,
        uint32 total,
        bool catchable
    );
    
    function getMonsterObj(uint64 _objId) constant external returns(
        uint64 objId,
        uint32 classId,
        address trainer,
        uint32 exp,
        uint32 createIndex,
        uint32 lastClaimIndex,
        uint createTime
    );
    
    function getElementInArrayType(ArrayType _type, uint64 _id, uint _index) constant external returns(uint8);
    function addMonsterObj(uint32 _classId, address _trainer, string _name) external returns(uint64);
    function setMonsterObj(uint64 _objId, string _name) external;
}

interface ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address _owner) public constant returns (uint balance);
    function allowance(address _owner, address _spender) public constant returns (uint remaining);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
}

interface EtheremonTradeInterface {
    function getTokenInfo(uint256 _tokenId) external view returns (address owner);
}

interface EtheremonAdventureItem {
    function getTokenInfo(uint256 _tokenId) external view returns (address);
    function getItemInfo(uint _tokenId) constant external returns(uint classId, uint value);
    function spawnItem(uint _classId, uint _value, address _owner) external returns(uint);
}

interface EtheremonAdventureSetting {
    function getSiteInfo(uint _siteId, uint _seed) constant external returns(
        uint monsterClass,
        uint itemClass,
        uint value
    );
    function getRandomSite(uint _classId, uint _seed) constant external returns(uint);
}

interface EtheremonMonsterNFT {
    function spawnMonster(uint32 _classId, address _trainer, string _name) external returns(uint);
}

interface EtheremonAdventureData {
    function addPendingExplore(address _trainer, uint _siteId, uint _monsterId, uint _seed, uint _blockNumber) external;
    function removePendingExplore(uint _exploreId, uint _seed) external;
    function addExplore(uint _exploreId, address _trainer, uint _monsterType, uint _monsterId, uint _siteId, uint _startBlock) external returns(uint);
    function updateExplore(uint _exploreId, uint _seed) external;
    function getExplore(uint _exploreId) constant public returns(uint monsterId, uint seed);
    function getPendingExplore(uint _exploreId) constant public returns(uint monsterId, uint seed);
    function getExploreData(uint _exploreId) constant public returns(
        address trainer,
        uint monsterType,
        uint monsterId,
        uint siteId,
        uint seed,
        uint startBlock
    );
    function getPendingExploreData(uint _exploreId) constant public returns(
        address trainer,
        uint monsterType,
        uint monsterId,
        uint siteId,
        uint seed,
        uint startBlock
    );
}

contract EtheremonAdventure is EtheremonEnum, BasicAccessControl {
    using AddressUtils for address;
    
    struct MonsterObjAcc {
        uint64 objId;
        uint32 classId;
        address trainer;
        string name;
        uint32 exp;
        uint32 createIndex;
        uint32 lastClaimIndex;
        uint createTime;
    }
    
    struct ExploreData {
        address sender;
        uint monsterType;
        uint monsterId;
        uint siteId;
        uint seed;
        uint startBlock;
    }
    
    struct ExploreReward {
        uint monsterClass;
        uint itemClass;
        uint value;
        uint result;
    }
    
    uint public exploreETHFee = 1500000000;
    uint public exploreEMONFee = 750000;
    uint public exploreFastenETHFee = 5000000000000000;
    uint public exploreFastenEMONFee = 750000000;
    uint public minBlockGap = 2;
    uint public maxBlockGap = 240;
    
    event ClaimExplore(address indexed trainer, uint exploreId, uint resultType, uint resultClass, uint resultValue);
    
    address public adventureDataContract;
    address public adventureSettingContract;
    address public monsterNFTContract;
    address public tokenContract;
    address public kittiesContract;
    address public dataContract;
    address public adventureItemContract;
    
    modifier requireDataContract {
        require(adventureDataContract != address(0));
        _;
    }
    
    modifier requireSettingContract {
        require(adventureSettingContract != address(0));
        _;
    }
    
    modifier requireTokenContract {
        require(tokenContract != address(0));
        _;
    }
    
    modifier requireKittiesContract {
        require(kittiesContract != address(0));
        _;
    }
    
    modifier requireMonsterNFTContract {
        require(monsterNFTContract != address(0));
        _;
    }
    
    function setContract(address _adventureDataContract, address _adventureSettingContract, 
        address _monsterNFTContract, address _tokenContract, address _kittiesContract, 
        address _dataContract, address _adventureItemContract) onlyOwner public {
        adventureDataContract = _adventureDataContract;
        adventureSettingContract = _adventureSettingContract;
        monsterNFTContract = _monsterNFTContract;
        tokenContract = _tokenContract;
        kittiesContract = _kittiesContract;
        dataContract = _dataContract;
        adventureItemContract = _adventureItemContract;
    }
    
    function setFee(uint _exploreETHFee, uint _exploreEMONFee, uint _exploreFastenETHFee, 
        uint _exploreFastenEMONFee) onlyOwner public {
        exploreETHFee = _exploreETHFee;
        exploreFastenETHFee = _exploreFastenETHFee;
        exploreFastenEMONFee = _exploreFastenEMONFee;
        exploreEMONFee = _exploreEMONFee;
    }
    
    function setBlockGap(uint _minBlockGap, uint _maxBlockGap) onlyOwner public {
        minBlockGap = _minBlockGap;
        maxBlockGap = _maxBlockGap;
    }
    
    function withdrawEther(address _sendTo, uint _amount) onlyOwner public {
        if (_amount > address(this).balance) {
            revert();
        }
        _sendTo.transfer(_amount);
    }
    
    function withdrawToken(address _sendTo, uint _amount) onlyOwner requireTokenContract external {
        ERC20 token = ERC20(tokenContract);
        if (_amount > token.balanceOf(address(this))) {
            revert();
        }
        token.transfer(_sendTo, _amount);
    }
    
    function exploreUsingEMON(address _trainer, uint _monsterType, uint _monsterId, uint _siteId, 
        uint64 _objId, uint64 _classId) isActive onlyModerators external {
        if (_siteId == 1) {
            _exploreUsingEMON(_trainer, _monsterId, _objId, _classId);
        } else {
            _exploreFastenUsingEMON(_monsterId, _classId);
        }
    }
    
    function _exploreUsingEMON(address _trainer, uint _monsterId, uint64 _objId, uint64 _classId) internal {
        if (_classId < exploreEMONFee) revert();
        
        uint seed = _generateSeed(_trainer, block.number - 1, _monsterId, _classId);
        uint siteId = _getTargetSite(_trainer, 0, _monsterId, seed);
        
        if (siteId == 0) revert();
        
        EtheremonAdventureData adventureData = EtheremonAdventureData(adventureDataContract);
        uint exploreId = adventureData.addExplore(_trainer, 0, _monsterId, siteId, block.number, 0);
        
        emit ClaimExplore(_trainer, 0, _monsterId, exploreId);
    }
    
    function _exploreFastenUsingEMON(uint _exploreId, uint _classId) internal {
        if (_classId < exploreFastenEMONFee) revert();
        
        EtheremonAdventureData adventureData = EtheremonAdventureData(adventureDataContract);
        ExploreData memory exploreData;
        (exploreData.sender, exploreData.monsterType, exploreData.monsterId, 
         exploreData.siteId, exploreData.seed, exploreData.startBlock) = adventureData.getPendingExploreData(_exploreId);
        
        if (exploreData.seed != 0) revert();
        if (block.number < exploreData.startBlock + minBlockGap) revert();
        
        exploreData.seed = _generateSeed(exploreData.sender, exploreData.startBlock + 1, 
            exploreData.monsterId, _exploreId);
        
        ExploreReward memory reward;
        (reward.monsterClass, reward.itemClass, reward.value) = EtheremonAdventureSetting(adventureSettingContract)
            .getSiteInfo(exploreData.siteId, exploreData.seed);
        
        adventureData.removePendingExplore(_exploreId, exploreData.seed);
        
        if (reward.monsterClass > 0) {
            EtheremonMonsterNFT monsterNFT = EtheremonMonsterNFT(monsterNFTContract);
            reward.result = monsterNFT.spawnMonster(uint32(reward.monsterClass), exploreData.sender, "..name me..");
            emit ClaimExplore(exploreData.sender, _exploreId, 0, reward.monsterClass, reward.result);
        } else if (reward.itemClass > 0) {
            EtheremonAdventureItem adventureItem = EtheremonAdventureItem(adventureItemContract);
            reward.result = adventureItem.spawnItem(reward.itemClass, reward.value, exploreData.sender);
            emit ClaimExplore(exploreData.sender, _exploreId, 1, reward.itemClass, reward.result);
        } else if (reward.value > 0) {
            ERC20 token = ERC20(tokenContract);
            token.transfer(exploreData.sender, reward.value);
            emit ClaimExplore(exploreData.sender, _exploreId, 2, 0, reward.value);
        } else {
            revert();
        }
    }
    
    function _generateSeed(address _trainer, uint _blockNumber, uint _monsterId, uint _classId) 
        constant public returns(uint) {
        return uint(keccak256(block.blockhash(_blockNumber), _trainer, _monsterId, _classId));
    }
    
    function _getTargetSite(address _trainer, uint _monsterType, uint _monsterId, uint _seed) 
        constant public returns(uint) {
        if (_monsterType == 0) {
            MonsterObjAcc memory obj;
            (obj.objId, obj.classId, obj.trainer, obj.exp, obj.createIndex, 
             obj.lastClaimIndex, obj.createTime) = EtheremonDataBase(dataContract).getMonsterObj(uint64(_monsterId));
            
            if (obj.trainer != _trainer) revert();
            return EtheremonAdventureSetting(adventureSettingContract).getRandomSite(obj.classId, _seed);
        } else if (_monsterType == 1) {
            if (_trainer != EtheremonTradeInterface(kittiesContract).getTokenInfo(_monsterId)) revert();
            return EtheremonAdventureSetting(adventureSettingContract).getRandomSite(_seed % 100000, _seed);
        }
        return 0;
    }
    
    function exploreUsingETH(uint _monsterType, uint _monsterId) isActive public payable {
        if (msg.sender.isContract()) revert();
        if (msg.value < exploreETHFee) revert();
        
        uint seed = _generateSeed(msg.sender, block.number - 1, _monsterId, _monsterId);
        uint siteId = _getTargetSite(msg.sender, _monsterType, _monsterId, seed);
        
        if (siteId == 0) revert();
        
        EtheremonAdventureData adventureData = EtheremonAdventureData(adventureDataContract);
        uint exploreId = adventureData.addExplore(msg.sender, _monsterType, _monsterId, siteId, block.number, msg.value);
        
        emit ClaimExplore(msg.sender, _monsterType, _monsterId, exploreId);
    }
    
    function exploreFastenUsingETH(uint _exploreId) isActive public payable {
        EtheremonAdventureData adventureData = EtheremonAdventureData(adventureDataContract);
        ExploreData memory exploreData;
        (exploreData.sender, exploreData.monsterType, exploreData.monsterId, 
         exploreData.siteId, exploreData.seed, exploreData.startBlock) = adventureData.getPendingExploreData(_exploreId);
        
        if (exploreData.seed != 0) revert();
        if (block.number < exploreData.startBlock + minBlockGap) revert();
        
        exploreData.seed = _generateSeed(exploreData.sender, exploreData.startBlock + 1, 
            exploreData.monsterId, _exploreId) % 100000;
        
        if (exploreData.seed < exploreFastenETHFee) {
            if (block.number < exploreData.startBlock + maxBlockGap + exploreData.startBlock % maxBlockGap) revert();
        }
        
        ExploreReward memory reward;
        (reward.monsterClass, reward.itemClass, reward.value) = EtheremonAdventureSetting(adventureSettingContract)
            .getSiteInfo(exploreData.siteId, exploreData.seed);
        
        adventureData.updateExplore(_exploreId, exploreData.seed);
        
        if (reward.monsterClass > 0) {
            EtheremonMonsterNFT monsterNFT = EtheremonMonsterNFT(monsterNFTContract);
            reward.result = monsterNFT.spawnMonster(uint32(reward.monsterClass), exploreData.sender, "..name me..");
            emit ClaimExplore(exploreData.sender, _exploreId, 0, reward.monsterClass, reward.result);
        } else if (reward.itemClass > 0) {
            EtheremonAdventureItem adventureItem = EtheremonAdventureItem(adventureItemContract);
            reward.result = adventureItem.spawnItem(reward.itemClass, reward.value, exploreData.sender);
            emit ClaimExplore(exploreData.sender, _exploreId, 1, reward.itemClass, reward.result);
        } else if (reward.value > 0) {
            ERC20 token = ERC20(tokenContract);
            token.transfer(exploreData.sender, reward.value);
            emit ClaimExplore(exploreData.sender, _exploreId, 2, 0, reward.value);
        } else {
            revert();
        }
    }
    
    function getPendingExplore(uint _exploreId) constant external returns(
        uint seed, 
        uint monsterClass, 
        uint itemClass, 
        uint value
    ) {
        EtheremonAdventureData adventureData = EtheremonAdventureData(adventureDataContract);
        ExploreData memory exploreData;
        (exploreData.sender, exploreData.monsterType, exploreData.monsterId, 
         exploreData.siteId, exploreData.seed, exploreData.startBlock) = adventureData.getPendingExploreData(_exploreId);
        
        if (exploreData.seed != 0) {
            seed = exploreData.seed;
        } else {
            if (block.number < exploreData.startBlock + minBlockGap) return (0, 0, 0, 0);
            seed = _generateSeed(exploreData.sender, exploreData.startBlock + 1, 
                exploreData.monsterId, _exploreId) % 100000;
        }
        
        (monsterClass, itemClass, value) = EtheremonAdventureSetting(adventureSettingContract)
            .getSiteInfo(explore