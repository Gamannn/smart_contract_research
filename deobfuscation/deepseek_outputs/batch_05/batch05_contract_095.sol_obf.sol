```solidity
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
    
    event Bought(uint256 indexed tokenId, address indexed buyer, uint256 price);
    event Sold(uint256 indexed tokenId, address indexed seller, uint256 price);
    
    address public owner;
    uint256[] private tokenIds;
    
    mapping(uint256 => uint256) private tokenPrices;
    mapping(uint256 => uint256) private tokenListPrices;
    mapping(uint256 => address) private tokenOwners;
    mapping(uint256 => string) private tokenURIs;
    
    uint256 public cutPercent = 5;
    
    function Marketplace() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }
    
    function setCutPercent(uint256 percent) onlyOwner() public {
        require(percent >= 0 && percent <= 10);
        cutPercent = percent;
    }
    
    function withdraw() onlyOwner() public {
        owner.transfer(this.balance);
    }
    
    function transferOwnership(address newOwner) onlyOwner() public {
        owner = newOwner;
    }
    
    function createToken(uint256 tokenId, string tokenURI, uint256 price) onlyOwner() public {
        require(price > 0);
        require(tokenListPrices[tokenId] == 0);
        require(tokenOwners[tokenId] == address(0));
        
        tokenOwners[tokenId] = owner;
        tokenListPrices[tokenId] = price;
        tokenPrices[tokenId] = price;
        tokenURIs[tokenId] = tokenURI;
        tokenIds.push(tokenId);
    }
    
    function getToken(uint256 tokenId) public view returns (address tokenOwner, uint256 price, string tokenURI) {
        tokenOwner = tokenOwners[tokenId];
        price = tokenListPrices[tokenId];
        tokenURI = tokenURIs[tokenId];
    }
    
    function getTokenOwner(uint256 tokenId) public view returns (address) {
        return tokenOwners[tokenId];
    }
    
    function getTokenOriginalPrice(uint256 tokenId) public view returns (uint256) {
        return tokenPrices[tokenId];
    }
    
    function getTokenListPrice(uint256 tokenId) public view returns (uint256) {
        return tokenListPrices[tokenId];
    }
    
    function getTokenNextPrice(uint256 tokenId) public view returns (uint256) {
        return calculateNextPrice(getTokenListPrice(tokenId));
    }
    
    function getAllTokenIds() public view returns (uint256[]) {
        return tokenIds;
    }
    
    function getTokenCount() public view returns (uint256) {
        return tokenIds.length;
    }
    
    function calculateNextPrice(uint256 price) public pure returns (uint256) {
        return price.mul(125).div(100);
    }
    
    function buyToken(uint256 tokenId) payable public {
        require(!isContract(msg.sender));
        require(getTokenListPrice(tokenId) > 0);
        require(getTokenOwner(tokenId) != address(0));
        require(msg.value == getTokenListPrice(tokenId));
        require(getTokenOwner(tokenId) != msg.sender);
        
        address seller = getTokenOwner(tokenId);
        address buyer = msg.sender;
        uint256 price = getTokenListPrice(tokenId);
        
        tokenOwners[tokenId] = buyer;
        tokenListPrices[tokenId] = getTokenNextPrice(tokenId);
        
        Bought(tokenId, buyer, price);
        Sold(tokenId, seller, price);
        
        uint256 cutAmount = price.mul(cutPercent).div(100);
        seller.transfer(price - cutAmount);
    }
    
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}
```