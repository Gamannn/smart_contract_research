```solidity
pragma solidity ^0.5.16;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract Ownable {
    address private _owner;
    
    event OwnershipTransferred(address previousOwner, address newOwner);
    
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    
    function owner() public view returns (address) {
        return _owner;
    }
    
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
    
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }
}

contract KittyAuction is Ownable {
    using SafeMath for uint256;
    
    uint256 public auctionCreationReward = 10000000000000000;
    uint256 public numberOfWhitelistedKitties;
    
    mapping(uint256 => uint256) public startingSiringPriceForKitty;
    mapping(uint256 => bool) public kittyIsWhitelisted;
    
    uint256 public globalEndingSiringPrice = 0;
    uint256 public globalAuctionDuration = 1296000;
    
    address public kittyCoreAddress = 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d;
    address public kittySiresAddress = 0xC7af99Fe5513eB6710e6D5f44F9989dA40F27F26;
    
    function setStartingSiringPriceForKitty(uint256 kittyId, uint256 startingPrice) external onlyOwner {
        startingSiringPriceForKitty[kittyId] = startingPrice;
    }
    
    function setGlobalEndingSiringPrice(uint256 newGlobalEndingSiringPrice) external onlyOwner {
        globalEndingSiringPrice = newGlobalEndingSiringPrice;
    }
    
    function setGlobalAuctionDuration(uint256 newGlobalAuctionDuration) external onlyOwner {
        globalAuctionDuration = newGlobalAuctionDuration;
    }
    
    function setAuctionCreationReward(uint256 newAuctionCreationReward) external onlyOwner {
        auctionCreationReward = newAuctionCreationReward;
    }
    
    function createSiringAuction(uint256 kittyId) external onlyOwner {
        KittyCore(kittyCoreAddress).createSiringAuction(kittyId);
    }
    
    function bidOnSiringAuction(address bidder, uint256 kittyId) external onlyOwner {
        KittySires(kittySiresAddress).bidOnSiringAuction(bidder, kittyId);
    }
    
    function setWhitelistKitty(uint256 kittyId, bool isWhitelisted) external onlyOwner {
        require(kittyIsWhitelisted[kittyId] != isWhitelisted, "kitty already had that value for its whitelist status");
        kittyIsWhitelisted[kittyId] = isWhitelisted;
        
        if (isWhitelisted) {
            numberOfWhitelistedKitties = numberOfWhitelistedKitties.add(1);
        } else {
            numberOfWhitelistedKitties = numberOfWhitelistedKitties.sub(1);
        }
    }
    
    function withdrawExcess() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        uint256 requiredBalance = auctionCreationReward.mul(numberOfWhitelistedKitties);
        
        if (contractBalance > requiredBalance) {
            uint256 excess = contractBalance.sub(requiredBalance);
            msg.sender.transfer(excess);
        }
    }
    
    function emergencyWithdraw() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }
    
    constructor() public {
        startingSiringPriceForKitty[848437] = 200000000000000000;
        startingSiringPriceForKitty[848439] = 200000000000000000;
        startingSiringPriceForKitty[848440] = 200000000000000000;
        startingSiringPriceForKitty[848441] = 200000000000000000;
        startingSiringPriceForKitty[848442] = 200000000000000000;
        startingSiringPriceForKitty[848582] = 200000000000000000;
        
        kittyIsWhitelisted[848437] = true;
        kittyIsWhitelisted[848439] = true;
        kittyIsWhitelisted[848440] = true;
        kittyIsWhitelisted[848441] = true;
        kittyIsWhitelisted[848442] = true;
        kittyIsWhitelisted[848582] = true;
        
        numberOfWhitelistedKitties = 6;
        
        transferOwnership(0xBb1e390b77Ff99f2765e78EF1A7d069c29406bee);
    }
    
    function() external payable {}
}

interface KittyCore {
    function createSiringAuction(uint256 kittyId) external;
}

interface KittySires {
    function bidOnSiringAuction(address bidder, uint256 kittyId) external;
}
```