```solidity
pragma solidity ^0.4.18;

contract WineGame {
    using SafeMath for uint256;
    
    mapping (address => uint256) public grapes;
    mapping (address => uint256) public lastHarvest;
    uint256 public marketGrapes;
    mapping (address => uint256) public vineyardVines;
    mapping (address => uint256) public vineCapacity;
    mapping (address => uint256) public wineProduced;
    mapping (address => uint256) public referrals;
    mapping (address => address) public referrer;
    
    address public ceoAddress;
    bool public initialized = false;
    uint256 public grapesToBuildWinery = 21600000000;
    
    uint256 constant SECONDS_PER_DAY = 86400;
    uint256 constant VINE_CAPACITY_PER_LAND = 300;
    uint256 constant STARTING_VINES = 1;
    uint256 constant GRAPES_PER_VINE_PER_SECOND = 1;
    uint256 constant REFERRAL_PERCENT = 5;
    uint256 constant DEV_FEE_PERCENT = 3;
    uint256 constant MARKET_GRAPES_INITIAL = 100000;
    
    LandContractInterface landContract;
    
    constructor(address _landContractAddress) public {
        require(_landContractAddress != address(0));
        ceoAddress = msg.sender;
        landContract = LandContractInterface(_landContractAddress);
    }
    
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }
    
    modifier whenInitialized() {
        require(initialized);
        _;
    }
    
    function buyGrapes(address _referrer) whenInitialized public payable {
        if(referrer[msg.sender] == address(0) && referrer[msg.sender] != msg.sender) {
            referrer[msg.sender] = _referrer;
        }
        
        uint256 grapesBought = calculateGrapeBuy(msg.value, SafeMath.sub(address(this).balance, msg.value));
        grapesBought = SafeMath.sub(grapesBought, devFee(grapesBought));
        uint256 fee = devFee(msg.value);
        ceoAddress.transfer(fee);
        
        grapes[msg.sender] = SafeMath.add(grapes[msg.sender], grapesBought);
        marketGrapes = SafeMath.add(marketGrapes, grapesBought);
    }
    
    function harvest() whenInitialized public {
        uint256 grapesUsed = getMyGrapes();
        uint256 grapesForWine = SafeMath.div(grapesUsed, grapesToBuildWinery);
        grapes[msg.sender] = 0;
        lastHarvest[msg.sender] = now;
        
        wineProduced[msg.sender] = SafeMath.add(wineProduced[msg.sender], grapesForWine);
    }
    
    function sellGrapes() whenInitialized public {
        require(vineyardVines[msg.sender] > 0);
        uint256 hasGrapes = getMyGrapes();
        require(hasGrapes >= grapesToBuildWinery);
        uint256 grapeValue = calculateGrapeSell(hasGrapes);
        grapes[msg.sender] = 0;
        lastHarvest[msg.sender] = now;
        vineyardVines[msg.sender] = SafeMath.add(vineyardVines[msg.sender], 1);
        grapesToBuildWinery = SafeMath.add(grapesToBuildWinery, 21600000000);
        msg.sender.transfer(grapeValue);
    }
    
    function buyVineyard() whenInitialized public payable {
        require(marketGrapes > 0);
        uint256 grapesBought = calculateGrapeBuy(msg.value, SafeMath.sub(address(this).balance, msg.value));
        grapesBought = SafeMath.sub(grapesBought, devFee(grapesBought));
        uint256 fee = devFee(msg.value);
        marketGrapes = SafeMath.sub(marketGrapes, grapesBought);
        ceoAddress.transfer(fee);
        msg.sender.transfer(SafeMath.sub(msg.value, fee));
        
        grapes[msg.sender] = SafeMath.add(grapes[msg.sender], grapesBought);
        lastHarvest[msg.sender] = now;
    }
    
    function reinvest() whenInitialized public payable {
        require(msg.value <= SafeMath.sub(address(this).balance, msg.value));
        uint256 grapesBought = calculateGrapeBuy(msg.value, SafeMath.sub(address(this).balance, msg.value));
        grapesBought = SafeMath.sub(grapesBought, devFee(grapesBought));
        uint256 fee = devFee(msg.value);
        marketGrapes = SafeMath.sub(marketGrapes, grapesBought);
        ceoAddress.transfer(fee);
        grapes[msg.sender] = SafeMath.add(grapes[msg.sender], grapesBought);
    }
    
    function calculateTrade(uint256 rt, uint256 rs, uint256 bs) public view returns(uint256) {
        return SafeMath.div(SafeMath.mul(SafeMath.div(SafeMath.mul(rs, 10000), SafeMath.add(SafeMath.div(SafeMath.mul(bs, 5000), 10000), rs)), rt), 10000);
    }
    
    function calculateGrapeSell(uint256 grapesAmount) public view returns(uint256) {
        return calculateTrade(grapesAmount, marketGrapes, address(this).balance);
    }
    
    function calculateGrapeBuy(uint256 eth, uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth, contractBalance, marketGrapes);
    }
    
    function calculateGrapeBuySimple(uint256 eth) public view returns(uint256) {
        return calculateGrapeBuy(eth, address(this).balance);
    }
    
    function devFee(uint256 amount) public view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount, 3), 100);
    }
    
    function seedMarket(uint256 grapesAmount) public payable {
        require(marketGrapes == 0);
        initialized = true;
        marketGrapes = grapesAmount;
    }
    
    function getFreeVineyard() whenInitialized public {
        require(vineyardVines[msg.sender] == 0);
        createPlot(msg.sender);
    }
    
    function giveFreeVineyard(address player) onlyCEO public {
        require(vineyardVines[player] == 0);
        createPlot(player);
    }
    
    function createPlot(address player) private {
        lastHarvest[player] = now;
        vineyardVines[player] = STARTING_VINES;
        vineCapacity[player] = 1;
        referrals[player] = 1;
    }
    
    function updateVineCapacity(address player) public {
        vineCapacity[player] = SafeMath.add(landContract.getLandCount(player), SafeMath.add(SafeMath.mul(landContract.getLandLevel(player), 3), SafeMath.mul(landContract.getLandRarity(player), 9)));
        referrals[player] = SafeMath.mul(vineCapacity[player], SECONDS_PER_DAY);
    }
    
    function updateVineCapacityWithToken(bytes32 token, address player) public {
        require(msg.sender == ceoAddress);
        vineCapacity[player] = SafeMath.add(1, SafeMath.add(SafeMath.mul(landContract.getTokenLevel(token), 3), SafeMath.mul(landContract.getTokenRarity(token), 9)));
        referrals[player] = SafeMath.mul(vineCapacity[player], SECONDS_PER_DAY);
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMyVineCapacity() public view returns(uint256) {
        return vineCapacity[msg.sender];
    }
    
    function getGrapesToBuildWinery() public view returns(uint256) {
        return grapesToBuildWinery;
    }
    
    function getMyGrapes() public view returns(uint256) {
        return SafeMath.add(grapes[msg.sender], getGrapesSinceLastHarvest(msg.sender));
    }
    
    function getMyWineProduced() public view returns(uint256) {
        return wineProduced[msg.sender];
    }
    
    function getMyVineyardVines() public view returns(uint256) {
        return vineyardVines[msg.sender];
    }
    
    function getGrapesSinceLastHarvest(address player) public view returns(uint256) {
        uint256 secondsPassed = SafeMath.sub(now, lastHarvest[player]);
        return SafeMath.mul(vineCapacity[player], SafeMath.mul(secondsPassed, GRAPES_PER_VINE_PER_SECOND));
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}

interface LandContractInterface {
    function getLandCount(address player) public returns (uint256);
    function getLandLevel(address player) public returns (uint256);
    function getLandRarity(address player) public returns (uint256);
    function getTokenLevel(bytes32 token) public returns (uint256);
    function getTokenRarity(bytes32 token) public returns (uint256);
    function getTokenCount(bytes32 token) public returns (uint256);
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