pragma solidity ^0.4.16;

library AddressUtils {
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}

contract Ownable {
    address public owner;
    bool public isMaintaining = false;
    mapping(address => bool) public moderators;
    uint16 public totalModerators = 0;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyOwnerOrModerator() {
        require(msg.sender == owner || moderators[msg.sender] == true);
        _;
    }

    modifier notMaintaining() {
        require(!isMaintaining);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    function addModerator(address newModerator) onlyOwner public {
        if (moderators[newModerator] == false) {
            moderators[newModerator] = true;
            totalModerators += 1;
        }
    }

    function removeModerator(address moderator) onlyOwner public {
        if (moderators[moderator] == true) {
            moderators[moderator] = false;
            totalModerators -= 1;
        }
    }

    function setMaintaining(bool _isMaintaining) onlyOwner public {
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

interface EtheremonMonsterData {
    function getMonsterObj(uint32 classId) constant external returns(uint32 classId, uint256 xfactor, uint256 classType, uint32 basicStep, bool isMonster);
    function getMonsterObj(uint64 monsterId) constant external returns(uint64 monsterId, uint32 classId, address trainer, uint32 basicStep, uint32 statStep, uint32 statStart, uint statBase);
    function getArray(ArrayType arrayType, uint64 monsterId, uint index) constant external returns(uint8);
    function createMonster(uint32 classId, address trainer, string name) external returns(uint64);
    function setArray(ArrayType arrayType, uint64 monsterId, uint8 value) external returns(uint);
}

contract EtheremonToken {
    function totalSupply() public constant returns (uint);
    function balanceOf(address _owner) public constant returns (uint balance);
    function allowance(address _owner, address _spender) public constant returns (uint remaining);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
}

interface EtheremonAdventureSetting {
    function getMonsterClass(uint256 monsterClassId) external view returns (address owner);
}

interface EtheremonMonsterNFT {
    function getMonsterClass(uint256 monsterClassId) external view returns (address);
    function getMonsterInfo(uint monsterId) constant external returns(uint classId, uint itemClass);
    function mintMonster(uint monsterClassId, uint itemClass, address trainer) external returns(uint);
}

interface EtheremonAdventureSetting2 {
    function getSiteInfo(uint siteId, uint seed) constant external returns(uint monsterClassId, uint itemClass, uint itemClassId);
    function getSiteMonsterClass(uint siteId, uint seed) constant external returns(uint);
}

interface EtheremonMonsterNFT2 {
    function createMonster(uint32 classId, address trainer, string name) external returns(uint);
}

contract EtheremonAdventureData {
    function addPendingExplore(uint trainerId, uint siteId, uint monsterClassId, uint seed, uint blockNumber, uint fee, uint itemClass) external;
    function removePendingExplore(uint exploreId, uint seed) external;
    function setExploreResult(uint exploreId, uint seed) external;
    function getExploreInfo(uint exploreId) constant public returns(uint siteId, uint seed);
    function getPendingExplore(uint exploreId) constant public returns(uint siteId, uint seed);
    function getTrainerExplore(address trainer) constant public returns(uint);
    function getTrainerExploreInfo(address trainer) constant public returns(uint exploreId, uint siteId, uint monsterClassId, uint seed, uint blockNumber, uint fee);
}

contract EtheremonAdventure is EtheremonEnum, Ownable {
    using AddressUtils for address;

    struct MonsterObjAcc {
        uint64 monsterId;
        uint32 classId;
        address trainer;
        string name;
        uint32 basicStep;
        uint32 statStep;
        uint32 statStart;
        uint statBase;
    }

    struct ExploreData {
        address sender;
        uint siteId;
        uint monsterClassId;
        uint seed;
        uint result;
        uint blockNumber;
    }

    struct ExploreReward {
        uint monsterClassId;
        uint itemClass;
        uint itemClassId;
        uint tokenId;
    }

    uint public exploreETHFee = 1500000000;

    event ClaimExplore(address indexed trainer, uint exploreId, uint rewardType, uint rewardId, uint rewardValue);

    modifier onlyDataContract() {
        require(dataContract != address(0));
        _;
    }

    modifier onlySettingContract() {
        require(adventureSettingContract != address(0));
        _;
    }

    modifier onlyMonsterNFTContract() {
        require(monsterNFTContract != address(0));
        _;
    }

    modifier onlyTokenContract() {
        require(tokenContract != address(0));
        _;
    }

    function setContracts(
        address _monsterDataContract,
        address _adventureSettingContract,
        address _adventureDataContract,
        address _adventureSettingContract2,
        address _monsterNFTContract,
        address _tokenContract,
        address _monsterNFTContract2
    ) onlyOwner public {
        monsterDataContract = _monsterDataContract;
        adventureSettingContract = _adventureSettingContract;
        adventureDataContract = _adventureDataContract;
        adventureSettingContract2 = _adventureSettingContract2;
        monsterNFTContract = _monsterNFTContract;
        tokenContract = _tokenContract;
        monsterNFTContract2 = _monsterNFTContract2;
    }

    function setExploreFee(uint _exploreETHFee, uint _exploreEMONTFee, uint _exploreFastenETHFee, uint _exploreFastenEMONTFee) onlyOwner public {
        exploreETHFee = _exploreETHFee;
        exploreEMONTFee = _exploreEMONTFee;
        exploreFastenETHFee = _exploreFastenETHFee;
        exploreFastenEMONTFee = _exploreFastenEMONTFee;
    }

    function setMinBlockGap(uint _minBlockGap, uint _minBlockGapFast) onlyOwner public {
        minBlockGap = _minBlockGap;
        minBlockGapFast = _minBlockGapFast;
    }

    function withdrawETH(address _to, uint _amount) onlyOwner public {
        if (_amount > address(this).balance) {
            revert();
        }
        _to.transfer(_amount);
    }

    function withdrawEMONT(address _to, uint _amount) onlyOwner onlyTokenContract external {
        EtheremonToken token = EtheremonToken(tokenContract);
        if (_amount > token.balanceOf(address(this))) {
            revert();
        }
        token.transfer(_to, _amount);
    }

    function exploreUsingEMONT(address _trainer, uint _monsterType, uint _seed, uint _exploreId, uint64 _monsterId, uint64 _itemClass) onlyOwnerOrModerator external {
        if (_monsterType == 1) {
            _exploreUsingEMONT(_trainer, _seed, _exploreId, _monsterId);
        } else {
            _exploreUsingEMONT2(_monsterId, _exploreId);
        }
    }

    function _exploreUsingEMONT(address _trainer, uint _seed, uint _exploreId, uint64 _monsterId) internal {
        if (_exploreId < exploreEMONTFee) revert();
        uint random = _getRandom(_trainer, block.number - 1, random, _seed);
        uint siteId = _getTargetSite(_trainer, 0, _seed, random);
        if (siteId == 0) revert();
        EtheremonAdventureData data = EtheremonAdventureData(adventureDataContract);
        uint exploreId = data.addPendingExplore(_trainer, 0, _seed, siteId, block.number, _exploreId, 0);
        ClaimExplore(_trainer, _monsterId, 0, siteId, exploreId);
    }

    function _exploreUsingEMONT2(uint _monsterId, uint _exploreId) internal {
        if (_exploreId < exploreFastenEMONTFee) revert();
        EtheremonAdventureData data = EtheremonAdventureData(adventureDataContract);
        ExploreData memory exploreData;
        (exploreData.sender, exploreData.siteId, exploreData.monsterClassId, exploreData.seed, exploreData.result, exploreData.blockNumber) = data.getPendingExplore(_monsterId);
        if (exploreData.result != 0) revert();
        if (block.number < exploreData.blockNumber + 2) revert();
        exploreData.result = _getRandom(exploreData.sender, exploreData.blockNumber + 1, exploreData.monsterClassId, _exploreId) % 1000;
        if (exploreData.result < 54) {
            if (block.number < exploreData.blockNumber + minBlockGap + exploreData.blockNumber % minBlockGap) revert();
        }
        ExploreReward memory reward;
        (reward.monsterClassId, reward.itemClass, reward.itemClassId) = EtheremonAdventureSetting2(adventureSettingContract2).getSiteInfo(exploreData.siteId, exploreData.result);
        data.removePendingExplore(_monsterId, exploreData.result);
        if (reward.monsterClassId > 0) {
            EtheremonMonsterNFT2 nft = EtheremonMonsterNFT2(monsterNFTContract2);
            reward.tokenId = nft.createMonster(uint32(reward.monsterClassId), exploreData.sender, "..Oxc2ef94109c9416eb6c7bedeb7d4da3ee4cec43ed me..");
            ClaimExplore(exploreData.sender, _monsterId, 0, reward.monsterClassId, reward.tokenId);
        } else if (reward.itemClass > 0) {
            EtheremonMonsterNFT nft = EtheremonMonsterNFT(monsterNFTContract);
            reward.tokenId = nft.mintMonster(reward.itemClass, reward.itemClassId, exploreData.sender);
            ClaimExplore(exploreData.sender, _monsterId, 1, reward.itemClass, reward.tokenId);
        } else if (reward.itemClassId > 0) {
            EtheremonToken token = EtheremonToken(tokenContract);
            token.transfer(exploreData.sender, reward.itemClassId);
            ClaimExplore(exploreData.sender, _monsterId, 2, 0, reward.itemClassId);
        } else {
            revert();
        }
    }

    function _getRandom(address _trainer, uint _blockNumber, uint _seed, uint _extra) constant public returns(uint) {
        return uint(keccak256(block.blockhash(_blockNumber), _trainer, _seed, _extra));
    }

    function _getTargetSite(address _trainer, uint _monsterType, uint _seed, uint _random) constant public returns(uint) {
        if (_monsterType == 0) {
            MonsterObjAcc memory monster;
            (monster.monsterId, monster.classId, monster.trainer, monster.basicStep, monster.statStep, monster.statStart, monster.statBase) = EtheremonMonsterData(monsterDataContract).getMonsterObj(uint64(_seed));
            if (monster.trainer != _trainer) revert();
            return EtheremonAdventureSetting(adventureSettingContract).getSiteMonsterClass(monster.classId, _random);
        } else if (_monsterType == 1) {
            if (_trainer != EtheremonAdventureSetting(adventureSettingContract).getMonsterClass(_seed)) revert();
            return EtheremonAdventureSetting2(adventureSettingContract2).getSiteMonsterClass(_random % exploreETHFee, _seed);
        }
        return 0;
    }

    function exploreUsingETH(uint _monsterType, uint _monsterId) onlyDataContract public payable {
        if (msg.sender.isContract()) revert();
        if (msg.value < exploreETHFee) revert();
        uint random = _getRandom(msg.sender, block.number - 1, random, _monsterId);
        uint siteId = _getTargetSite(msg.sender, _monsterType, _monsterId, random);
        if (siteId == 0) revert();
        EtheremonAdventureData data = EtheremonAdventureData(adventureDataContract);
        uint exploreId = data.addPendingExplore(msg.sender, _monsterType, _monsterId, siteId, block.number, 0, msg.value);
        ClaimExplore(msg.sender, _monsterType, _monsterId, exploreId, 0);
    }

    function claimExplore(uint _exploreId) onlyDataContract public payable {
        EtheremonAdventureData data = EtheremonAdventureData(adventureDataContract);
        ExploreData memory exploreData;
        (exploreData.sender, exploreData.siteId, exploreData.monsterClassId, exploreData.seed, exploreData.result, exploreData.blockNumber) = data.getPendingExplore(_exploreId);
        if (exploreData.result != 0) revert();
        if (block.number < exploreData.blockNumber + 2) revert();
        exploreData.result = _getRandom(exploreData.sender, exploreData.blockNumber + 1, exploreData.monsterClassId, _exploreId) % 1000;
        if (exploreData.result < 54) {
            if (block.number < exploreData.blockNumber + minBlockGap + exploreData.blockNumber % minBlockGap) revert();
        }
        ExploreReward memory reward;
        (reward.monsterClassId, reward.itemClass, reward.itemClassId) = EtheremonAdventureSetting2(adventureSettingContract2).getSiteInfo(exploreData.siteId, exploreData.result);
        data.removePendingExplore(_exploreId, exploreData.result);
        if (reward.monsterClassId > 0) {
            EtheremonMonsterNFT2 nft = EtheremonMonsterNFT2(monsterNFTContract2);
            reward.tokenId = nft.createMonster(uint32(reward.monsterClassId), exploreData.sender, "..Oxc2ef94109c9416eb6c7bedeb7d4da3ee4cec43ed me..");
            ClaimExplore(exploreData.sender, _exploreId, 0, reward.monsterClassId, reward.tokenId);
        } else if (reward.itemClass > 0) {
            EtheremonMonsterNFT nft = EtheremonMonsterNFT(monsterNFTContract);
            reward.tokenId = nft.mintMonster(reward.itemClass, reward.itemClassId, exploreData.sender);
            ClaimExplore(exploreData.sender, _exploreId, 1, reward.itemClass, reward.tokenId);
        } else if (reward.itemClassId > 0) {
            EtheremonToken token = EtheremonToken(tokenContract);
            token.transfer(exploreData.sender, reward.itemClassId);
            ClaimExplore(exploreData.sender, _exploreId, 2, 0, reward.itemClassId);
        } else {
            revert();
        }
    }

    function getExploreResult(uint _exploreId) constant external returns(uint result, uint monsterClassId, uint itemClass, uint itemClassId) {
        EtheremonAdventureData data = EtheremonAdventureData(adventureDataContract);
        ExploreData memory exploreData;
        (exploreData.sender, exploreData.siteId, exploreData.monsterClassId, exploreData.seed, exploreData.result, exploreData.blockNumber) = data.getPendingExplore(_exploreId);
        if (exploreData.result != 0) {
            result = exploreData.result;
        } else {
            if (block.number < exploreData.blockNumber + 2) return (0, 0, 0, 0);
            result = _getRandom(exploreData.sender, exploreData.blockNumber + 1, exploreData.monsterClassId, _exploreId) % 100000;
        }
        (monsterClassId, itemClass, itemClassId) = EtheremonAdventureSetting2(adventureSettingContract2).getSiteInfo(exploreData.siteId, result);
    }

    function getExploreInfo(uint _exploreId) constant external returns(address sender, uint siteId, uint monsterClassId, uint seed, uint result, uint blockNumber, uint rewardItemClass, uint rewardItemClassId) {
        EtheremonAdventureData data = EtheremonAdventureData(adventureDataContract);
        (sender, siteId, monsterClassId, seed, result, blockNumber) = data.getPendingExplore(_exploreId);
        if (result > 0) {
            (result, rewardItemClass, rewardItemClassId) = EtheremonAdventureSetting2(adventureSettingContract2).getSiteInfo(siteId, result);
        }
    }

    function getTrainerExplore(address _trainer) constant external returns(uint exploreId, uint siteId, uint monsterClassId, uint seed, uint result, uint blockNumber) {
        EtheremonAdventureData data = EtheremonAdventureData(adventureDataContract);
        (exploreId, siteId, monsterClassId, seed, result, blockNumber) = data.getTrainerExploreInfo(_trainer);
        if (exploreId > 0) {
            result = blockNumber + minBlockGap + blockNumber % minBlockGap;
        }
    }

    struct scalar2Vector {
        uint256 random;
        uint256 minBlockGapFast;
        uint256 minBlockGap;
        uint256 exploreFastenEMONTFee;
        uint256 exploreEMONTFee;
        uint256 exploreETHFee;
        uint256 exploreFastenETHFee;
        address adventureSettingContract;
        address tokenContract;
        address monsterNFTContract;
        address adventureSettingContract2;
        address adventureDataContract;
        address monsterNFTContract2;
        address monsterDataContract;
        uint8 totalModerators;
        uint8 isMaintaining;
        bool isMaintaining2;
        uint16 totalModerators2;
        address owner;
    }

    scalar2Vector s2c = scalar2Vector(0, 0, 0, 750000, 0.005 ether, 15000, 0.01 ether, address(0), address(0), address(0), address(0), address(0), address(0), address(0), 0, 0, false, 0, address(0));
}

function getBoolFunc(uint256 index) internal view returns(bool) {
    return _bool_constant[index];
}

function getStrFunc(uint256 index) internal view returns(string storage) {
    return _string_constant[index];
}

function getIntFunc(uint256 index) internal view returns(uint256) {
    return _integer_constant[index];
}

bool[] public _bool_constant = [true, false];
string[] public _string_constant = ["..Oxc2ef94109c9416eb6c7bedeb7d4da3ee4cec43ed me.."];
uint256[] public _integer_constant = [5000000000000000, 1500000000, 100000, 240, 750000000, 10000000000000000, 32, 0, 2, 6, 54, 1];
