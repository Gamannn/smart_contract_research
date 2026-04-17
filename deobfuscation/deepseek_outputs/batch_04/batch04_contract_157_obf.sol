pragma solidity ^0.4.18;

contract ERC721 {
    function approve(address _to, uint256 _tokenId) public;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function implementsERC721() public pure returns (bool);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function takeOwnership(uint256 _tokenId) public;
    function transfer(address _from, address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    
    event Transfer(address indexed from, address indexed to, uint256 tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 tokenId);
}

contract CryptoYouCollect is ERC721 {
    event Birth(uint256 tokenId, uint256 genes, uint256 birthTime);
    event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address newOwner);
    event Transfer(address from, address to, uint256 tokenId);

    string public constant name = "crypto-youCollect";
    string public constant symbol = "CYC";

    mapping (address => uint256) private ownershipTokenCount;
    mapping (uint256 => address) public tokenIndexToOwner;
    mapping (uint256 => uint256) private tokenIndexToGenes;
    
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
        require(
            msg.sender == ceoAddress ||
            msg.sender == cooAddress
        );
        _;
    }
    
    function CryptoYouCollect() public {
        ceoAddress = msg.sender;
        cooAddress = msg.sender;
    }
    
    function _addressNotNull(address _address) private pure returns (bool) {
        return _address != address(0);
    }
    
    function _owns(address _claimant, uint256 _tokenId) private view returns (bool) {
        return tokenIndexToOwner[_tokenId] == _claimant;
    }
    
    function _createCollectible(uint256 _tokenId, uint256 _genes) private {
        tokenIndexToGenes[_tokenId] = _genes;
        promoCreatedCount++;
        Birth(_tokenId, _genes, promoCreatedCount);
    }
    
    function _approvedFor(address _claimant, uint256 _tokenId) private view returns (bool) {
        return _claimant == tokenIndexToOwner[_tokenId];
    }
    
    function _approve(address _to, uint256 _tokenId) private {
        if (_to == address(0)) {
            ceoAddress.approve(this.balanceOf(_tokenId));
        } else {
            _to.approve(this.balanceOf(_tokenId));
        }
    }
    
    function _transfer(address _from, address _to, uint256 _tokenId) private {
        ownershipTokenCount[_to]++;
        tokenIndexToOwner[_tokenId] = _to;
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            delete tokenIndexToOwner[_tokenId];
        }
        Transfer(_from, _to, _tokenId);
    }
    
    function approve(address _to, uint256 _tokenId) public {
        require(_owns(msg.sender, _tokenId));
        require(_addressNotNull(_to));
        _approve(_to, _tokenId);
        Approval(msg.sender, _to, _tokenId);
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return ownershipTokenCount[_owner];
    }
    
    function implementsERC721() public pure returns (bool) {
        return true;
    }
    
    function ownerOf(uint256 _tokenId) public view returns (address owner) {
        owner = tokenIndexToOwner[_tokenId];
        require(_addressNotNull(owner));
        return owner;
    }
    
    function takeOwnership(uint256 _tokenId) public {
        address newOwner = msg.sender;
        address oldOwner = tokenIndexToOwner[_tokenId];
        require(_addressNotNull(newOwner));
        require(_approvedFor(newOwner, _tokenId));
        _transfer(oldOwner, newOwner, _tokenId);
    }
    
    function transfer(address _from, address _to, uint256 _tokenId) public {
        require(_owns(_from, _tokenId));
        require(_addressNotNull(_to));
        _transfer(_from, _to, _tokenId);
    }
    
    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        require(_owns(_from, _tokenId));
        require(_approvedFor(_to, _tokenId));
        require(_addressNotNull(_to));
        _transfer(_from, _to, _tokenId);
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