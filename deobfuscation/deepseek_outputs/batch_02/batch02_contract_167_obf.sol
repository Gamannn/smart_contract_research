```solidity
pragma solidity ^0.4.18;

contract ERC721 {
    function approve(address _to, uint256 _tokenId) public;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function implementsERC721() public pure returns (bool);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function takeOwnership(uint256 _tokenId) public;
    function totalSupply() public view returns (uint256 total);
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;
    
    event Transfer(address indexed from, address indexed to, uint256 tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 tokenId);
}

contract SportStarToken is ERC721 {
    event Transfer(address from, address to, uint256 tokenId);
    
    string public constant NAME = "CryptoSportStars";
    string public constant SYMBOL = "SportStarToken";
    
    uint256 private totalTokens;
    
    mapping (uint256 => address) public tokenIndexToOwner;
    mapping (address => uint256) private ownershipTokenCount;
    mapping (uint256 => address) public tokenIndexToApproved;
    mapping (uint256 => bytes32) public tokenIndexToMetadata;
    
    address public ceoAddress;
    address public cooAddress;
    
    struct Token {
        string name;
    }
    
    Token[] private tokens;
    
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }
    
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }
    
    modifier onlyCLevel() {
        require(
            msg.sender == ceoAddress ||
            msg.sender == cooAddress
        );
        _;
    }
    
    constructor() public {
        ceoAddress = msg.sender;
        cooAddress = msg.sender;
    }
    
    function setCEO(address _newCEO) public onlyCEO {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }
    
    function setCOO(address _newCOO) public onlyCEO {
        require(_newCOO != address(0));
        cooAddress = _newCOO;
    }
    
    function getToken(uint256 _tokenId) public view returns (
        string memory tokenName,
        address owner
    ) {
        Token storage token = tokens[_tokenId];
        tokenName = token.name;
        owner = tokenIndexToOwner[_tokenId];
    }
    
    function tokensOfOwner(address _owner) public view returns (uint256[] memory ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 total = totalSupply();
            uint256 resultIndex = 0;
            uint256 tokenId;
            
            for (tokenId = 0; tokenId <= total; tokenId++) {
                if (tokenIndexToOwner[tokenId] == _owner) {
                    result[resultIndex] = tokenId;
                    resultIndex++;
                }
            }
            return result;
        }
    }
    
    function tokenMetadata(uint256 _tokenId) public view returns (bytes32 metadata) {
        return tokenIndexToMetadata[_tokenId];
    }
    
    function approve(address _to, uint256 _tokenId) public {
        require(_owns(msg.sender, _tokenId));
        tokenIndexToApproved[_tokenId] = _to;
        emit Approval(msg.sender, _to, _tokenId);
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return ownershipTokenCount[_owner];
    }
    
    function name() public pure returns (string memory) {
        return NAME;
    }
    
    function symbol() public pure returns (string memory) {
        return SYMBOL;
    }
    
    function implementsERC721() public pure returns (bool) {
        return true;
    }
    
    function ownerOf(uint256 _tokenId) public view returns (address owner) {
        owner = tokenIndexToOwner[_tokenId];
        require(owner != address(0));
    }
    
    function takeOwnership(uint256 _tokenId) public {
        address newOwner = msg.sender;
        address oldOwner = tokenIndexToOwner[_tokenId];
        
        require(_addressNotNull(newOwner));
        require(_approvedFor(newOwner, _tokenId));
        
        _transfer(oldOwner, newOwner, _tokenId);
    }
    
    function totalSupply() public view returns (uint256 total) {
        return tokens.length;
    }
    
    function transfer(address _to, uint256 _tokenId) public {
        require(_owns(msg.sender, _tokenId));
        require(_addressNotNull(_to));
        _transfer(msg.sender, _to, _tokenId);
    }
    
    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        require(_owns(_from, _tokenId));
        require(_approvedFor(_to, _tokenId));
        require(_addressNotNull(_to));
        _transfer(_from, _to, _tokenId);
    }
    
    function createPromoToken(string memory _name, address _owner) public onlyCLevel returns (uint256) {
        return _createToken(_name, _owner);
    }
    
    function createContractToken(string memory _name) public onlyCLevel returns (uint256) {
        return _createToken(_name, address(this));
    }
    
    function setTokenMetadata(uint256 _tokenId, bytes32 _metadata) public onlyCLevel {
        tokenIndexToMetadata[_tokenId] = _metadata;
    }
    
    function _addressNotNull(address _to) private pure returns (bool) {
        return _to != address(0);
    }
    
    function _approvedFor(address _claimant, uint256 _tokenId) private view returns (bool) {
        return tokenIndexToApproved[_tokenId] == _claimant;
    }
    
    function _createToken(string memory _name, address _owner) private returns (uint256) {
        Token memory token = Token({
            name: _name
        });
        
        uint256 newTokenId = tokens.push(token) - 1;
        require(newTokenId == uint256(uint32(newTokenId)));
        
        _transfer(address(0), _owner, newTokenId);
        return newTokenId;
    }
    
    function _owns(address _claimant, uint256 _tokenId) private view returns (bool) {
        return _claimant == tokenIndexToOwner[_tokenId];
    }
    
    function _transfer(address _from, address _to, uint256 _tokenId) private {
        ownershipTokenCount[_to]++;
        tokenIndexToOwner[_tokenId] = _to;
        
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            delete tokenIndexToApproved[_tokenId];
        }
        
        emit Transfer(_from, _to, _tokenId);
    }
}

contract SportStarTokenSale is SportStarToken {
    event Birth(uint256 tokenId, string name, address owner);
    event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address newOwner);
    
    uint256 private startingPrice = 0.001 ether;
    uint256 private constant PROMO_CREATION_LIMIT = 5000;
    uint256 private firstStepLimit = 0.053613 ether;
    uint256 private secondStepLimit = 0.564957 ether;
    
    mapping(uint256 => uint256) private tokenIndexToPrice;
    
    uint256 public promoCreatedCount;
    
    constructor() public {
        ceoAddress = msg.sender;
        cooAddress = msg.sender;
    }
    
    function setNewAddress(address _v2Address) public onlyCEO {
        require(_v2Address != address(0));
    }
    
    function getToken(uint256 _tokenId) public view returns (
        address owner,
        uint256 price
    ) {
        owner = ownerOf(_tokenId);
        price = tokenIndexToPrice[_tokenId];
    }
    
    function createPromoToken(address _owner, string memory _name, uint256 _price) public onlyCOO returns (uint256) {
        require(promoCreatedCount < PROMO_CREATION_LIMIT);
        
        address tokenOwner = _owner;
        if (tokenOwner == address(0)) {
            tokenOwner = cooAddress;
        }
        
        if (_price <= 0) {
            _price = startingPrice;
        }
        
        promoCreatedCount++;
        uint256 tokenId = createPromoToken(_name, tokenOwner);
        tokenIndexToPrice[tokenId] = _price;
        
        emit Birth(tokenId, _name, tokenOwner);
        return tokenId;
    }
    
    function createContractToken(string memory _name) public onlyCOO returns (uint256) {
        uint256 tokenId = createContractToken(_name);
        tokenIndexToPrice[tokenId] = startingPrice;
        
        emit Birth(tokenId, _name, address(this));
        return tokenId;
    }
    
    function purchase(uint256 _tokenId) public payable {
        address oldOwner = ownerOf(_tokenId);
        address newOwner = msg.sender;
        uint256 sellingPrice = tokenIndexToPrice[_tokenId];
        
        require(oldOwner != newOwner);
        require(_addressNotNull(newOwner));
        require(msg.value >= sellingPrice);
        
        uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 3), 100));
        uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);
        
        tokenIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 3), 2);
        
        transferFrom(oldOwner, newOwner, _tokenId);
        
        if (oldOwner != address(this)) {
            oldOwner.transfer(payment);
        }
        
        emit TokenSold(_tokenId, sellingPrice, tokenIndexToPrice[_tokenId], oldOwner, newOwner);
        newOwner.transfer(purchaseExcess);
    }
    
    function priceOf(uint256 _tokenId) public view returns (uint256 price) {
        return tokenIndexToPrice[_tokenId];
    }
    
    function nextPrice(uint256 _price) public view returns (uint256) {
        if (_price < firstStepLimit) {
            return SafeMath.div(SafeMath.mul(_price, 3), 2);
        } else if (_price < secondStepLimit) {
            return SafeMath.div(SafeMath.mul(_price, 5), 4);
        } else {
            return SafeMath.div(SafeMath.mul(_price, 6), 5);
        }
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
```