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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
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
}

contract KittyAuction is Ownable {
    using SafeMath for uint256;

    uint256 public auctionCreationReward = 10000000000000000;
    uint256 public numberOfWhitelistedKitties;
    uint256 public globalAuctionDuration = 1296000;

    mapping(uint256 => uint256) public startingSiringPriceForKitty;
    mapping(uint256 => bool) public kittyIsWhitelisted;

    function setAuctionCreationReward(uint256 newReward) external onlyOwner {
        auctionCreationReward = newReward;
    }

    function setGlobalAuctionDuration(uint256 newDuration) external onlyOwner {
        globalAuctionDuration = newDuration;
    }

    function setStartingSiringPriceForKitty(uint256 kittyId, uint256 price) external onlyOwner {
        startingSiringPriceForKitty[kittyId] = price;
    }

    function whitelistKitty(uint256 kittyId, bool isWhitelisted) external onlyOwner {
        require(kittyIsWhitelisted[kittyId] != isWhitelisted, "Kitty already has that whitelist status");
        kittyIsWhitelisted[kittyId] = isWhitelisted;
        if (isWhitelisted) {
            numberOfWhitelistedKitties = numberOfWhitelistedKitties.add(1);
        } else {
            numberOfWhitelistedKitties = numberOfWhitelistedKitties.sub(1);
        }
    }

    function withdrawExcessBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        uint256 requiredBalance = auctionCreationReward.mul(numberOfWhitelistedKitties);
        if (balance > requiredBalance) {
            uint256 excess = balance.sub(requiredBalance);
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
    }

    function() external payable {}
}

contract ExternalContract {
    function transfer(address to, uint256 value) external;
    function someFunction(uint256 param1, uint256 param2, uint256 param3, uint256 param4) external;
}

contract AnotherExternalContract {
    function anotherFunction(uint256 param) external;
}
```