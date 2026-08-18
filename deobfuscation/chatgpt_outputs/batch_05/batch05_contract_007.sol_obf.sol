pragma solidity ^0.4.18;

contract Vineyard {
    using SafeMath for uint256;

    mapping(address => uint256) public grapesOwned;
    mapping(address => uint256) public lastHarvest;
    mapping(address => uint256) public vineyardSize;
    mapping(address => uint256) public grapesToBuildWinery;
    mapping(address => uint256) public grapesToProduceBottle;
    mapping(address => uint256) public grapesToBuildVineyard;
    mapping(address => uint256) public referral;
    uint256 public marketGrapes;
    address public ceoAddress;

    function Vineyard(address _ceoAddress) public {
        require(_ceoAddress != address(0));
        ceoAddress = _ceoAddress;
    }

    function setCeoAddress(address _newCeoAddress) public {
        require(msg.sender == ceoAddress);
        require(_newCeoAddress != address(0));
        ceoAddress = _newCeoAddress;
    }

    modifier onlyCeo() {
        require(msg.sender == ceoAddress);
        _;
    }

    function harvestGrapes(address _referral) public {
        if (referral[msg.sender] == 0 && referral[msg.sender] != msg.sender) {
            referral[msg.sender] = _referral;
        }
        uint256 grapesProduced = calculateGrapesProduced();
        grapesOwned[msg.sender] = grapesOwned[msg.sender].add(grapesProduced);
        lastHarvest[msg.sender] = now;
    }

    function sellGrapes() public {
        uint256 grapesProduced = calculateGrapesProduced();
        uint256 grapesToSell = SafeMath.min(grapesProduced, grapesOwned[msg.sender]);
        uint256 grapeValue = calculateGrapeValue(grapesToSell);
        grapesOwned[msg.sender] = grapesOwned[msg.sender].sub(grapesToSell);
        lastHarvest[msg.sender] = now;
        marketGrapes = marketGrapes.add(grapesToSell);
        ceoAddress.transfer(grapeValue);
        msg.sender.transfer(grapeValue);
    }

    function buyGrapes() public payable {
        require(msg.value <= calculateGrapeValue(this.balance));
        uint256 grapesBought = calculateGrapesBought(msg.value);
        grapesOwned[msg.sender] = grapesOwned[msg.sender].add(grapesBought);
        marketGrapes = marketGrapes.add(grapesBought);
        ceoAddress.transfer(msg.value);
    }

    function calculateGrapesProduced() public view returns (uint256) {
        uint256 timePassed = now.sub(lastHarvest[msg.sender]);
        return timePassed.mul(vineyardSize[msg.sender]);
    }

    function calculateGrapeValue(uint256 _grapes) public view returns (uint256) {
        return _grapes.mul(this.balance).div(marketGrapes);
    }

    function calculateGrapesBought(uint256 _eth) public view returns (uint256) {
        return _eth.mul(marketGrapes).div(this.balance);
    }

    function initializeMarket(uint256 _initialGrapes) public payable onlyCeo {
        require(marketGrapes == 0);
        marketGrapes = _initialGrapes;
    }

    function getBalance() public view returns (uint256) {
        return this.balance;
    }

    function getGrapesOwned() public view returns (uint256) {
        return grapesOwned[msg.sender];
    }

    function getVineyardSize() public view returns (uint256) {
        return vineyardSize[msg.sender];
    }

    function getLastHarvest() public view returns (uint256) {
        return lastHarvest[msg.sender];
    }

    function getReferral() public view returns (uint256) {
        return referral[msg.sender];
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
