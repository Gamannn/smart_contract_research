```solidity
pragma solidity ^0.4.25;

contract TokenSale {
    PriceOracle public priceOracle = PriceOracle(0x0);
    NFTRegistry public nftRegistry = NFTRegistry(0x0);
    
    event TokenPurchase(address indexed buyer, uint256 tokenId, uint256 pricePaid);
    
    struct State {
        address owner;
        address tokenAddress;
        address admin;
        uint256 reservedFunds;
        uint256 availableFunds;
    }
    
    State public state = State(address(0), address(0xdf0960778c6e6597f197ed9a25f12f5d971da86c), address(0), 0, 0);
    
    constructor() public {
        state.owner = msg.sender;
    }
    
    function() payable external {
    }
    
    function setNFTRegistry(address _nftRegistry) external {
        require(msg.sender == state.owner);
        nftRegistry = NFTRegistry(_nftRegistry);
    }
    
    function setCommissionRates(uint256 teamRate, uint256 reserveRate) payable external {
        require(teamRate <= 100);
        require(reserveRate <= 100);
        require(teamRate + reserveRate <= 100);
        
        state.availableFunds += (msg.value * teamRate) / 100;
        state.reservedFunds += (msg.value * reserveRate) / 100;
    }
    
    function setPriceOracle(address _priceOracle) external {
        require(msg.sender == state.owner);
        priceOracle = PriceOracle(_priceOracle);
    }
    
    function purchaseToken(uint256 tokenId, uint256 amount, uint256 price) external {
        require(msg.sender == state.owner);
        require(amount > 0);
        require(nftRegistry.tokenExists(tokenId));
        
        address buyer = nftRegistry.tokenOwner(tokenId);
        require(ERC20(state.tokenAddress).transferFrom(state.owner, address(nftRegistry), amount));
        require(price >= state.reservedFunds);
        
        state.reservedFunds -= price;
        state.owner.transfer(price);
        emit TokenPurchase(buyer, amount, price);
    }
    
    function setAvailableFunds(uint256 amount) external {
        require(msg.sender == state.owner);
        require(amount < (address(this).balance - state.reservedFunds));
        state.availableFunds = amount;
    }
    
    function setReservedFunds(uint256 amount) external {
        require(msg.sender == state.owner);
        require(amount < (address(this).balance - state.availableFunds));
        state.reservedFunds = amount;
    }
    
    function tokenFallback(address from, uint256 value, address, bytes) external {
        require(msg.sender == state.admin);
        uint256 cost = priceOracle.calculateCost(value);
        require(cost <= state.availableFunds);
        
        ERC20(msg.sender).transferFrom(from, address(0), value);
        state.availableFunds -= cost;
        from.transfer(cost);
    }
}

contract PriceOracle {
    TokenSale constant public tokenSale = TokenSale(0x66a9f1e53173de33bec727ef76afa84956ae1b25);
    ERC20 constant public token = ERC20(0xdf0960778c6e6597f197ed9a25f12f5d971da86c);
    
    address public owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function calculateCost(uint256 tokenAmount) external view returns(uint256 cost) {
        cost = (tokenSale.state.availableFunds() * tokenAmount) / (token.balanceOf(address(this)) * 2);
    }
    
    function getUnitPrice() external view returns(uint256 price) {
        price = tokenSale.state.availableFunds() / (token.balanceOf(address(this)) * 2);
    }
}

interface NFTRegistry {
    function tokenExists(uint256 tokenId) public view returns (bool);
    function tokenOwner(uint256 tokenId) public view returns (address);
}

interface ERC20 {
    function balanceOf(address account) external view returns(uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}
```