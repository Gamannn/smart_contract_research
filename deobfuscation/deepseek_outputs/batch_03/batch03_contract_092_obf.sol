```solidity
pragma solidity ^0.4.18;

interface IGameContract {
    function addToWhitelist(address user) external;
    function removeFromWhitelist(address user) external;
    function buyCard(uint cardId, address user, uint amount) external;
    function buyCardMulti(uint cardId, address user, uint amount) external;
    function getUserCardCount(uint cardId, address user) public view returns (uint);
    function getCardPrice(uint cardId) public view returns (uint);
    function removeCard(uint cardId) external;
    function getReferrer(address user, address referrer) external returns (address);
    function getCardPriceMulti(uint cardId, uint amount) public view returns (uint);
    function removeCardMulti(uint cardId, uint amount) external;
    function createUser(address user, uint param1, uint param2, uint param3) external;
    function getUserDiscount(address user) public view returns (uint);
    function getUserReferralCount(address user) public view returns (uint);
    function isUserWhitelisted(address user) public view returns (bool);
    function getCardTotalSupply(uint cardId) public view returns (uint);
    function getCardMaxSupply(uint cardId) public view returns (uint);
    function getCardRarity(uint cardId) public view returns (uint);
    function getCardType(uint cardId) public view returns (uint);
    function getCardGeneration(uint cardId) public view returns (uint);
    function createCard(uint cardId, uint param1, uint param2, uint param3, uint param4, uint param5) external;
    function addUserBalance(address user, uint amount) external;
    function getUserBalance(address user) public view returns (uint);
}

contract CardMarket {
    event CardPurchased(address indexed user, uint indexed cardId);
    event CardMultiPurchased(address indexed user, uint indexed cardId, uint amount);
    event UserCreated(address indexed user);
    
    IGameContract public gameContract;
    
    struct Config {
        address pendingOwner;
        address owner;
        uint256 whitelistDiscount;
        uint256 createUserParam1;
        uint256 createUserParam2;
        uint256 createUserParam3;
        uint256 referralBonusPercent;
    }
    
    Config public config = Config(address(0), address(0), 50, 3, 50, 10, 10);
    
    function CardMarket() public {
        config.owner = msg.sender;
    }
    
    function buyCard(uint cardId, address referrer) public payable {
        uint price = gameContract.getCardPrice(cardId);
        require(price > 0);
        
        price = price * calculateDiscount(msg.sender) / 10000;
        require(msg.value >= price);
        
        uint change = msg.value - price;
        
        gameContract.removeCard(cardId);
        gameContract.buyCard(cardId, msg.sender, 1);
        gameContract.addToWhitelist(msg.sender);
        gameContract.removeFromWhitelist(msg.sender);
        
        emit CardPurchased(msg.sender, cardId);
        
        address referrerAddress = gameContract.getReferrer(msg.sender, referrer);
        if (referrerAddress != address(0)) {
            referrerAddress.transfer(price * config.referralBonusPercent / 100);
        }
        
        msg.sender.transfer(change);
    }
    
    function buyCardMulti(uint cardId, uint amount, address referrer) public payable {
        require(gameContract.getCardPrice(cardId) > 0);
        
        uint price = gameContract.getCardPriceMulti(cardId, amount);
        price = price * calculateDiscount(msg.sender) / 10000;
        require(msg.value >= price);
        
        uint change = msg.value - price;
        
        gameContract.removeCardMulti(cardId, amount);
        gameContract.buyCardMulti(cardId, msg.sender, amount);
        gameContract.addToWhitelist(msg.sender);
        gameContract.removeFromWhitelist(msg.sender);
        
        emit CardMultiPurchased(msg.sender, cardId, amount);
        
        address referrerAddress = gameContract.getReferrer(msg.sender, referrer);
        if (referrerAddress != address(0)) {
            uint referralBonus = price * config.referralBonusPercent / 100;
            gameContract.addUserBalance(referrerAddress, referralBonus);
            referrerAddress.transfer(referralBonus);
        }
        
        msg.sender.transfer(change);
    }
    
    function createUser() public {
        gameContract.createUser(
            msg.sender,
            config.createUserParam1,
            config.createUserParam2,
            config.createUserParam3
        );
        gameContract.addToWhitelist(msg.sender);
        emit UserCreated(msg.sender);
    }
    
    function calculateDiscount(address user) public view returns (uint discount) {
        discount = 10000;
        
        if (!gameContract.isUserWhitelisted(user)) {
            discount = discount * (100 - config.whitelistDiscount) / 100;
        }
        
        uint userDiscount = gameContract.getUserDiscount(user);
        if (userDiscount > 0) {
            discount = discount * (100 - userDiscount) / 100;
        }
    }
    
    function getUserInfo(address user) public view returns (
        uint discount,
        uint referralCount,
        bool isWhitelisted,
        uint whitelistDiscount,
        uint createUserParam3,
        uint createUserParam2,
        uint createUserParam1,
        uint referralBonusPercent,
        uint balance
    ) {
        discount = gameContract.getUserDiscount(user);
        referralCount = gameContract.getUserReferralCount(user);
        isWhitelisted = gameContract.isUserWhitelisted(user);
        whitelistDiscount = config.whitelistDiscount;
        createUserParam3 = config.createUserParam3;
        createUserParam2 = config.createUserParam2;
        createUserParam1 = config.createUserParam1;
        referralBonusPercent = config.referralBonusPercent;
        balance = gameContract.getUserBalance(user);
    }
    
    function getMyInfo() public view returns (
        uint discount,
        uint referralCount,
        bool isWhitelisted,
        uint whitelistDiscount,
        uint createUserParam3,
        uint createUserParam2,
        uint createUserParam1,
        uint referralBonusPercent,
        uint balance
    ) {
        return getUserInfo(msg.sender);
    }
    
    function getCardInfo(uint cardId, address user) public view returns (
        uint userCardCount,
        uint totalSupply,
        uint price,
        uint maxSupply,
        uint rarity,
        uint cardType,
        uint generation
    ) {
        userCardCount = gameContract.getUserCardCount(cardId, user);
        totalSupply = gameContract.getCardTotalSupply(cardId);
        price = gameContract.getCardPrice(cardId);
        maxSupply = gameContract.getCardMaxSupply(cardId);
        rarity = gameContract.getCardRarity(cardId);
        cardType = gameContract.getCardType(cardId);
        generation = gameContract.getCardGeneration(cardId);
    }
    
    function createCard(
        uint cardId,
        uint param1,
        uint param2,
        uint param3,
        uint param4,
        uint param5
    ) public onlyOwner {
        gameContract.createCard(cardId, param1, param2, param3, param4, param5);
    }
    
    function setReferralBonusPercent(uint percent) external onlyOwner {
        config.referralBonusPercent = percent;
    }
    
    function setCreateUserParam3(uint value) public onlyOwner {
        config.createUserParam3 = value;
    }
    
    function setCreateUserParam2(uint value) public onlyOwner {
        config.createUserParam2 = value;
    }
    
    function setCreateUserParam1(uint value) public onlyOwner {
        config.createUserParam1 = value;
    }
    
    function setWhitelistDiscount(uint discount) public onlyOwner {
        config.whitelistDiscount = discount;
    }
    
    function withdrawAll(address recipient) public onlyOwner {
        withdraw(recipient, this.balance);
    }
    
    function withdraw(address recipient, uint amount) public onlyOwner {
        require(address(0) != recipient);
        if (amount > this.balance) {
            recipient.transfer(this.balance);
        } else {
            recipient.transfer(amount);
        }
    }
    
    function setGameContract(address newContract) public onlyOwner {
        if (newContract != address(0)) {
            gameContract = IGameContract(newContract);
        }
    }
    
    modifier onlyOwner() {
        require(msg.sender == config.owner);
        _;
    }
    
    function setPendingOwner(address pendingOwner) public onlyOwner {
        require(pendingOwner != address(0));
        config.pendingOwner = pendingOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == config.pendingOwner);
        require(address(0) != config.pendingOwner);
        config.owner = config.pendingOwner;
        config.pendingOwner = address(0);
    }
}
```