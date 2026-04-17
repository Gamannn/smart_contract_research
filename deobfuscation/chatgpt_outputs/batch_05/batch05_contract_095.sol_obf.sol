pragma solidity ^0.4.13;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Marketplace {
    using SafeMath for uint256;

    event Bought(uint256 indexed itemId, address indexed buyer, uint256 price);
    event Sold(uint256 indexed itemId, address indexed seller, uint256 price);

    address public owner;
    uint256[] private itemIds;
    mapping(uint256 => uint256) private itemPrices;
    mapping(uint256 => uint256) private itemQuantities;
    mapping(uint256 => address) private itemOwners;
    mapping(uint256 => string) private itemDescriptions;
    uint256 public feePercentage = 5;

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    function Marketplace() public {
        owner = msg.sender;
    }

    function setFeePercentage(uint256 _feePercentage) public onlyOwner {
        require(_feePercentage >= 0 && _feePercentage <= 10);
        feePercentage = _feePercentage;
    }

    function withdraw() public onlyOwner {
        owner.transfer(this.balance);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function addItem(uint256 itemId, string description, uint256 price) public onlyOwner {
        require(price > 0);
        require(itemQuantities[itemId] == 0);
        require(itemOwners[itemId] == address(0));

        itemOwners[itemId] = owner;
        itemQuantities[itemId] = price;
        itemPrices[itemId] = price;
        itemDescriptions[itemId] = description;
        itemIds.push(itemId);
    }

    function getItem(uint256 itemId) public view returns (address itemOwner, uint256 price, string description) {
        itemOwner = itemOwners[itemId];
        price = itemQuantities[itemId];
        description = itemDescriptions[itemId];
    }

    function getItemOwner(uint256 itemId) public view returns (address) {
        return itemOwners[itemId];
    }

    function getItemPrice(uint256 itemId) public view returns (uint256) {
        return itemPrices[itemId];
    }

    function getItemQuantity(uint256 itemId) public view returns (uint256) {
        return itemQuantities[itemId];
    }

    function getItemFee(uint256 itemId) public view returns (uint256) {
        return calculateFee(getItemPrice(itemId));
    }

    function getAllItemIds() public view returns (uint256[]) {
        return itemIds;
    }

    function getItemCount() public view returns (uint256) {
        return itemIds.length;
    }

    function calculateFee(uint256 price) public pure returns (uint256) {
        return price.mul(125).div(100);
    }

    function buyItem(uint256 itemId) payable public {
        require(!isContract(msg.sender));
        require(getItemPrice(itemId) > 0);
        require(getItemOwner(itemId) != address(0));
        require(msg.value == getItemPrice(itemId));
        require(getItemOwner(itemId) != msg.sender);

        address seller = getItemOwner(itemId);
        address buyer = msg.sender;
        uint256 price = getItemPrice(itemId);

        itemOwners[itemId] = buyer;
        itemQuantities[itemId] = getItemFee(itemId);

        Bought(itemId, buyer, price);
        Sold(itemId, seller, price);

        uint256 fee = price.mul(feePercentage).div(100);
        seller.transfer(price.sub(fee));
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}