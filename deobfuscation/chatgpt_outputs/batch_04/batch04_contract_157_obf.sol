pragma solidity ^0.4.18;

contract CollectibleBase {
    function transfer(address to, uint256 tokenId) public;
    function balanceOf(address owner) public view returns (uint256 balance);
    function isContract() public pure returns (bool);
    function ownerOf(uint256 tokenId) public view returns (address owner);
    function approve(address to, uint256 tokenId) public;
    function transferFrom(address from, address to, uint256 tokenId) public;
    
    event Transfer(address indexed from, address indexed to, uint256 tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 tokenId);
}

contract CryptoCollectible is CollectibleBase {
    event Birth(uint256 tokenId, uint256 price, uint256 totalSupply);
    event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address newOwner);
    event Transfer(address from, address to, uint256 tokenId);

    string public constant name = "crypto-youCollect";
    mapping (address => uint256) private ownershipTokenCount;
    mapping (uint256 => address) public tokenIndexToOwner;
    mapping (uint256 => uint256) private tokenIndexToPrice;
    address public ceoAddress;
    address public cooAddress;
    uint256 public promoCreatedCount;

    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    modifier onlyCLevel() {
        require(msg.sender == ceoAddress || msg.sender == cooAddress);
        _;
    }

    function CryptoCollectible() public {
        ceoAddress = msg.sender;
        cooAddress = msg.sender;
    }

    function _addressNotNull(address _to) private pure returns (bool) {
        return _to != address(0);
    }

    function _owns(address claimant, uint256 tokenId) private view returns (bool) {
        return tokenIndexToOwner[tokenId] == claimant;
    }

    function _createCollectible(uint256 tokenId, uint256 price) private {
        tokenIndexToPrice[tokenId] = price;
        promoCreatedCount++;
        Birth(tokenId, price, promoCreatedCount);
    }

    function _approvedFor(address claimant, uint256 tokenId) private view returns (bool) {
        return claimant == tokenIndexToOwner[tokenId];
    }

    function _transfer(address from, address to, uint256 tokenId) private {
        ownershipTokenCount[to]++;
        tokenIndexToOwner[tokenId] = to;
        if (from != address(0)) {
            ownershipTokenCount[from]--;
            delete tokenIndexToOwner[tokenId];
        }
        Transfer(from, to, tokenId);
    }
}

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

function getStrFunc(uint256 index) internal view returns(string storage) {
    return _string_constant[index];
}

function getIntFunc(uint256 index) internal view returns(uint256) {
    return _integer_constant[index];
}

string[] public _string_constant = ["crypto-youCollect", "CYC"];
uint256[] public _integer_constant = [5000, 200, 94, 120, 53613000000000000, 1000000000000000, 115, 0, 564957000000000000, 100];