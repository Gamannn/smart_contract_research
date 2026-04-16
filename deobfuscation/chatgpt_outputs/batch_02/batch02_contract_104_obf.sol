```solidity
pragma solidity ^0.4.16;

library AddressUtils {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

contract AccessControl {
    mapping(address => bool) public moderators;
    bool public isMaintaining = false;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyModerator() {
        require(msg.sender == owner || moderators[msg.sender] == true);
        _;
    }

    modifier isActive() {
        require(!isMaintaining);
        _;
    }

    function setOwner(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    function addModerator(address newModerator) onlyOwner public {
        if (moderators[newModerator] == false) {
            moderators[newModerator] = true;
        }
    }

    function removeModerator(address moderator) onlyOwner public {
        if (moderators[moderator] == true) {
            moderators[moderator] = false;
        }
    }

    function updateMaintaining(bool _isMaintaining) onlyOwner public {
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

interface EtheremonData {
    function getMonsterObj(uint64 objId) external view returns (
        uint64,
        uint32,
        address,
        uint32,
        uint32,
        uint32,
        uint
    );

    function getMonsterClass(uint32 classId) external view returns (
        uint32,
        uint256,
        uint256,
        uint32,
        bool
    );

    function getMonsterClassBasic(uint32 classId) external view returns (
        uint32,
        uint256,
        uint256,
        uint32,
        bool
    );

    function getMonsterClassProperty(uint32 classId, EtheremonEnum.PropertyType propertyType) external view returns (uint8);

    function getMonsterClassStep(uint32 classId, uint8 step) external view returns (uint);
}

interface EtheremonAdventureData {
    function getSiteItem(uint siteId, uint monsterId) external view returns (uint8);
    function getSite(uint siteId) external view returns (uint);
}

interface EtheremonMonsterNFT {
    function mintMonster(uint32 classId, address trainer, string name) external returns (uint64);
}

contract EtheremonAdventure is EtheremonEnum, AccessControl {
    using AddressUtils for address;

    struct MonsterObjAcc {
        uint64 objId;
        uint32 classId;
        address trainer;
        uint32 exp;
        uint32 createIndex;
        uint32 lastClaimIndex;
        uint32 lastClaimTime;
        uint256 createTime;
    }

    struct ExploreData {
        address trainer;
        uint monsterType;
        uint objId;
        uint siteId;
        uint startBlock;
        uint endBlock;
    }

    struct ExploreReward {
        uint monsterId;
        uint itemId;
        uint emontAmount;
        uint etherAmount;
    }

    uint public exploreETHFee = 1500000000;
    event ClaimExplore(address indexed trainer, uint monsterId, uint itemId, uint emontAmount, uint etherAmount);

    modifier requireDataContract() {
        require(dataContract != address(0));
        _;
    }

    modifier requireAdventureSettingContract() {
        require(adventureSettingContract != address(0));
        _;
    }

    modifier requireTokenContract() {
        require(tokenContract != address(0));
        _;
    }

    modifier requireKittiesContract() {
        require(kittiesContract != address(0));
        _;
    }

    modifier requireMonsterNFTContract() {
        require(monsterNFTContract != address(0));
        _;
    }

    address public adventureSettingContract;
    address public dataContract;
    address public tokenContract;
    address public kittiesContract;
    address public monsterNFTContract;

    function setContracts(
        address _adventureSettingContract,
        address _dataContract,
        address _tokenContract,
        address _kittiesContract,
        address _monsterNFTContract
    ) onlyOwner public {
        adventureSettingContract = _adventureSettingContract;
        dataContract = _dataContract;
        tokenContract = _tokenContract;
        kittiesContract = _kittiesContract;
        monsterNFTContract = _monsterNFTContract;
    }

    function setExploreFees(
        uint _exploreETHFee,
        uint _exploreEMONTFee,
        uint _exploreFastenEMONTFee
    ) onlyOwner public {
        exploreETHFee = _exploreETHFee;
    }

    function withdrawEther(address _sendTo, uint _amount) onlyOwner public {
        if (_amount > address(this).balance) {
            revert();
        }
        _sendTo.transfer(_amount);
    }

    function withdrawToken(address _sendTo, uint _amount) onlyOwner requireTokenContract external {
        EtheremonData tokenData = EtheremonData(tokenContract);
        if (_amount > tokenData.balanceOf(address(this))) {
            revert();
        }
        tokenData.transfer(_sendTo, _amount);
    }

    function exploreUsingEMONT(
        address _sender,
        uint _monsterType,
        uint _seed
    ) internal {
        if (_seed < exploreETHFee) revert();
        uint siteId = getTargetSite(_sender, _monsterType, _seed);
        if (siteId == 0) revert();
        EtheremonAdventureData adventureData = EtheremonAdventureData(dataContract);
        uint exploreId = adventureData.getSiteItem(siteId, _monsterType);
        emit ClaimExplore(_sender, _monsterType, exploreId, 0, 0);
    }

    function exploreUsingETH(
        uint _monsterType,
        uint _seed
    ) public payable {
        if (msg.value < exploreETHFee) revert();
        exploreUsingEMONT(msg.sender, _monsterType, _seed);
    }

    function getTargetSite(
        address _trainer,
        uint _monsterType,
        uint _seed
    ) public view returns (uint) {
        if (_monsterType == 0) {
            MonsterObjAcc memory monsterObj;
            (monsterObj.classId, monsterObj.trainer, monsterObj.exp, monsterObj.createIndex, monsterObj.lastClaimIndex, monsterObj.lastClaimTime, monsterObj.createTime) = EtheremonData(dataContract).getMonsterObj(uint64(_seed));
            if (monsterObj.trainer != _trainer) revert();
            return EtheremonAdventureData(adventureSettingContract).getSiteItem(monsterObj.classId, _seed);
        } else if (_monsterType == 1) {
            if (_trainer != EtheremonMonsterNFT(monsterNFTContract).getMonsterClass(uint32(_seed))) revert();
            return EtheremonAdventureData(adventureSettingContract).getSiteItem(_seed, _seed);
        }
        return 0;
    }

    function getExploreData(uint _exploreId) external view returns (
        address trainer,
        uint monsterType,
        uint objId,
        uint siteId,
        uint startBlock,
        uint endBlock
    ) {
        EtheremonAdventureData adventureData = EtheremonAdventureData(dataContract);
        (trainer, monsterType, objId, siteId, startBlock, endBlock) = adventureData.getSite(_exploreId);
    }

    function getExploreReward(uint _exploreId) external view returns (
        uint monsterId,
        uint itemId,
        uint emontAmount,
        uint etherAmount
    ) {
        EtheremonAdventureData adventureData = EtheremonAdventureData(dataContract);
        (monsterId, itemId, emontAmount, etherAmount) = adventureData.getSiteItem(_exploreId, _exploreId);
    }
}
```