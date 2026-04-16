```solidity
pragma solidity ^0.4.18;

contract ERC721Interface {
    function approve(address _to, uint256 _tokenId) public;
    function balanceOf(address _owner) public view returns (uint256 _balance);
    function implementsERC721() public pure returns (bool);
    function ownerOf(uint256 _tokenId) public view returns (address _owner);
    function takeOwnership(uint256 _tokenId) public;
    function totalSupply() public view returns (uint256 _totalSupply);
    function transfer(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
}

contract CryptoSportStars is ERC721Interface {
    event Transfer(address _from, address _to, uint256 _tokenId);

    mapping (uint256 => address) public tokenIndexToOwner;
    mapping (address => uint256) private ownershipTokenCount;
    mapping (uint256 => address) public tokenIndexToApproved;
    mapping (uint256 => bytes32) public tokenIndexToMetadata;
    address public ceoAddress;
    address public masterContractAddress;
    uint256 public totalTokens;

    struct Token {
        string name;
    }

    Token[] private tokens;

    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    modifier onlyMasterContract() {
        require(msg.sender == masterContractAddress);
        _;
    }

    function CryptoSportStars() public {
        ceoAddress = msg.sender;
    }

    function setCEO(address _newCEO) public onlyCEO {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }

    function setMasterContract(address _newMasterContract) public onlyCEO {
        require(_newMasterContract != address(0));
        masterContractAddress = _newMasterContract;
    }

    function getToken(uint256 _tokenId) public view returns (string name, address owner) {
        Token storage token = tokens[_tokenId];
        name = token.name;
        owner = tokenIndexToOwner[_tokenId];
    }

    function getTokensOfOwner(address _owner) public view returns (uint256[] tokenIds) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalTokens = totalSupply();
            uint256 resultIndex = 0;
            uint256 tokenId;
            for (tokenId = 0; tokenId <= totalTokens; tokenId++) {
                if (tokenIndexToOwner[tokenId] == _owner) {
                    result[resultIndex] = tokenId;
                    resultIndex++;
                }
            }
            return result;
        }
    }

    function getMetadata(uint256 _tokenId) public view returns (bytes32 metadata) {
        return tokenIndexToMetadata[_tokenId];
    }

    function approve(address _to, uint256 _tokenId) public {
        require(_owns(msg.sender, _tokenId));
        tokenIndexToApproved[_tokenId] = _to;
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
        require(owner != address(0));
    }

    function takeOwnership(uint256 _tokenId) public {
        address newOwner = msg.sender;
        address oldOwner = tokenIndexToOwner[_tokenId];

        require(_approved(newOwner, _tokenId));
        require(_owns(oldOwner, _tokenId));

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
        require(_approved(msg.sender, _tokenId));
        require(_addressNotNull(_to));
        require(_owns(_from, _tokenId));

        _transfer(_from, _to, _tokenId);
    }

    function _addressNotNull(address _to) private pure returns (bool) {
        return _to != address(0);
    }

    function _approved(address _to, uint256 _tokenId) private view returns (bool) {
        return tokenIndexToApproved[_tokenId] == _to;
    }

    function _createToken(string _name, address _owner) private returns (uint256) {
        Token memory _token = Token({
            name: _name
        });
        uint256 newTokenId = tokens.push(_token) - 1;
        require(newTokenId == uint256(uint32(newTokenId)));

        _transfer(address(0), _owner, newTokenId);

        return newTokenId;
    }

    function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
        return claimant == tokenIndexToOwner[_tokenId];
    }

    function _transfer(address _from, address _to, uint256 _tokenId) private {
        ownershipTokenCount[_to]++;
        tokenIndexToOwner[_tokenId] = _to;
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            delete tokenIndexToApproved[_tokenId];
        }
        Transfer(_from, _to, _tokenId);
    }
}

contract CryptoSportStarsSale {
    event Birth(uint256 tokenId, string name, address owner);
    event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address newOwner);
    event Transfer(address from, address to, uint256 tokenId);

    uint256 private startingPrice = 0.001 ether;
    uint256 private constant promoCreationLimit = 5000;
    uint256 private firstStepLimit = 0.053613 ether;
    uint256 private secondStepLimit = 0.564957 ether;

    mapping (uint256 => uint256) private tokenIndexToPrice;

    CryptoSportStars private nonFungibleContract;

    function CryptoSportStarsSale() public {
        ceoAddress = msg.sender;
    }

    function setNFTContract(address _nftAddress) public onlyCEO {
        require(_nftAddress != address(0));
        nonFungibleContract = CryptoSportStars(_nftAddress);
    }

    function setCEO(address _newCEO) public onlyCEO {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }

    function setCOO(address _newCOO) public onlyCEO {
        require(_newCOO != address(0));
        cooAddress = _newCOO;
    }

    function getToken(uint256 _tokenId) public view returns (address owner, uint256 price) {
        owner = nonFungibleContract.ownerOf(_tokenId);
        price = tokenIndexToPrice[_tokenId];
    }

    function createPromoToken(address _owner, string _name, uint256 _price) public onlyCOO {
        require(promoCreatedCount < promoCreationLimit);

        address tokenOwner = _owner;
        if (tokenOwner == address(0)) {
            tokenOwner = cooAddress;
        }

        if (_price <= 0) {
            _price = startingPrice;
        }

        promoCreatedCount++;
        uint256 newTokenId = nonFungibleContract._createToken(_name, tokenOwner);
        tokenIndexToPrice[newTokenId] = startingPrice;

        Birth(newTokenId, _name, tokenOwner);
    }

    function createToken(string _name) public onlyCOO {
        uint256 newTokenId = nonFungibleContract._createToken(_name, address(this));
        tokenIndexToPrice[newTokenId] = startingPrice;

        Birth(newTokenId, _name, address(this));
    }

    function purchase(uint256 _tokenId) public payable {
        address oldOwner = nonFungibleContract.ownerOf(_tokenId);
        address newOwner = msg.sender;

        uint256 sellingPrice = tokenIndexToPrice[_tokenId];

        require(oldOwner != newOwner);
        require(_addressNotNull(newOwner));
        require(msg.value >= sellingPrice);

        uint256 payment = _computePayment(sellingPrice);
        uint256 purchaseExcess = msg.value - sellingPrice;

        tokenIndexToPrice[_tokenId] = _nextPrice(sellingPrice);

        nonFungibleContract.transferFrom(oldOwner, newOwner, _tokenId);

        if (oldOwner != address(this)) {
            oldOwner.transfer(payment);
        }

        TokenSold(_tokenId, sellingPrice, tokenIndexToPrice[_tokenId], oldOwner, newOwner);

        msg.sender.transfer(purchaseExcess);
    }

    function priceOf(uint256 _tokenId) public view returns (uint256 price) {
        return tokenIndexToPrice[_tokenId];
    }

    function _computePayment(uint256 _price) public view returns (uint256) {
        if (_price < firstStepLimit) {
            return _price * 3 / 100;
        } else if (_price < secondStepLimit) {
            return _price * 3 / 100;
        } else if (_price < thirdStepLimit) {
            return _price * 3 / 100;
        } else if (_price < fourthStepLimit) {
            return _price * 3 / 100;
        } else {
            return _price * 2 / 100;
        }
    }

    function _nextPrice(uint256 _price) public view returns (uint256) {
        if (_price < firstStepLimit) {
            return _price * 200 / 97;
        } else if (_price < secondStepLimit) {
            return _price * 133 / 97;
        } else if (_price < thirdStepLimit) {
            return _price * 125 / 97;
        } else if (_price < fourthStepLimit) {
            return _price * 115 / 97;
        } else {
            return _price * 113 / 98;
        }
    }

    function _addressNotNull(address _to) private pure returns (bool) {
        return _to != address(0);
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