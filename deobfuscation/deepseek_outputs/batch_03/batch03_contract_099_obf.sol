```solidity
pragma solidity ^0.4.18;

contract ERC20Interface {
    function transfer(address to, uint256 tokens) public returns (bool success);
}

contract Halo3D {
    function buy(address) public payable returns(uint256);
    function transfer(address, uint256) public returns(bool);
    function myTokens() public view returns(uint256);
    function myDividends(bool) public view returns(uint256);
    function reinvest() public;
}

contract AcceptsHalo3D {
    Halo3D public tokenContract;
    
    function AcceptsHalo3D(address _tokenContract) public {
        tokenContract = Halo3D(_tokenContract);
    }
    
    modifier onlyTokenContract {
        require(msg.sender == address(tokenContract));
        _;
    }
    
    function tokenFallback(address _from, uint256 _value, bytes _data) external returns (bool);
}

contract Halo3DShrimpFarmer is AcceptsHalo3D {
    using SafeMath for uint256;
    
    uint256 public EGGS_TO_HATCH_1SHRIMP = 86400;
    uint256 public PSN = 10000;
    uint256 public PSNH = 5000;
    
    mapping (address => uint256) public hatcheryShrimp;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    
    uint256 public marketEggs;
    bool public initialized = false;
    address public ceoAddress;
    
    function Halo3DShrimpFarmer(address _tokenContract, address _ceoAddress) 
        AcceptsHalo3D(_tokenContract) 
        public 
    {
        ceoAddress = _ceoAddress;
    }
    
    function() payable public {}
    
    function tokenFallback(address _from, uint256 _value, bytes _data) 
        external 
        onlyTokenContract 
        returns (bool) 
    {
        require(initialized);
        require(!_isContract(_from));
        require(_value >= 1 finney);
        
        uint256 halo3DBalance = tokenContract.myTokens();
        uint256 eggsBought = calculateEggBuy(_value, halo3DBalance.sub(_value));
        eggsBought = eggsBought.sub(devFee(eggsBought));
        
        reinvest();
        tokenContract.transfer(ceoAddress, devFee(_value));
        claimedEggs[_from] = claimedEggs[_from].add(eggsBought);
        
        return true;
    }
    
    function hatchEggs(address ref) public {
        require(initialized);
        
        if(referrals[msg.sender] == address(0) && ref != msg.sender) {
            referrals[msg.sender] = ref;
        }
        
        uint256 eggsUsed = getMyEggs();
        uint256 newShrimp = eggsUsed.div(EGGS_TO_HATCH_1SHRIMP);
        
        hatcheryShrimp[msg.sender] = hatcheryShrimp[msg.sender].add(newShrimp);
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        
        claimedEggs[referrals[msg.sender]] = claimedEggs[referrals[msg.sender]].add(eggsUsed.div(5));
        marketEggs = marketEggs.add(eggsUsed.div(10));
    }
    
    function sellEggs() public {
        require(initialized);
        
        uint256 hasEggs = getMyEggs();
        uint256 eggValue = calculateEggSell(hasEggs);
        uint256 fee = devFee(eggValue);
        
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        marketEggs = marketEggs.add(hasEggs);
        
        reinvest();
        tokenContract.transfer(ceoAddress, fee);
        tokenContract.transfer(msg.sender, eggValue.sub(fee));
    }
    
    function seedMarket(uint256 eggs) public {
        require(marketEggs == 0);
        require(msg.sender == ceoAddress);
        
        initialized = true;
        marketEggs = eggs;
    }
    
    function reinvest() public {
        if(tokenContract.myDividends(true) > 1) {
            tokenContract.reinvest();
        }
    }
    
    function calculateTrade(uint256 rt, uint256 rs, uint256 bs) 
        public 
        view 
        returns(uint256) 
    {
        return PSN.mul(bs).div(
            PSNH.add(
                PSN.mul(rs).add(PSNH.mul(rt)).div(rt)
            )
        );
    }
    
    function calculateEggSell(uint256 eggs) public view returns(uint256) {
        return calculateTrade(eggs, marketEggs, tokenContract.myTokens());
    }
    
    function calculateEggBuy(uint256 eth, uint256 contractBalance) 
        public 
        view 
        returns(uint256) 
    {
        return calculateTrade(eth, contractBalance, marketEggs);
    }
    
    function calculateEggBuySimple(uint256 eth) public view returns(uint256) {
        return calculateEggBuy(eth, tokenContract.myTokens());
    }
    
    function devFee(uint256 amount) public pure returns(uint256) {
        return amount.mul(4).div(100);
    }
    
    function getMyShrimp() public view returns(uint256) {
        return hatcheryShrimp[msg.sender];
    }
    
    function getMyEggs() public view returns(uint256) {
        return claimedEggs[msg.sender].add(getEggsSinceLastHatch(msg.sender));
    }
    
    function getEggsSinceLastHatch(address adr) public view returns(uint256) {
        uint256 secondsPassed = min(
            EGGS_TO_HATCH_1SHRIMP, 
            now.sub(lastHatch[adr])
        );
        return secondsPassed.mul(hatcheryShrimp[adr]);
    }
    
    function getMyDividends() public view returns(uint256) {
        return tokenContract.myDividends(true);
    }
    
    function getBalance() public view returns(uint256) {
        return tokenContract.myTokens();
    }
    
    function _isContract(address _user) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(_user)
        }
        return size > 0;
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
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