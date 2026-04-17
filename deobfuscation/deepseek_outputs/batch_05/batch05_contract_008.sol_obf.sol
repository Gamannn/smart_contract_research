```solidity
pragma solidity ^0.4.18;

contract ShrimpFarmer {
    using SafeMath for uint256;
    
    uint256 constant public SHRIMP_TO_HATCH_1SHRIMP = 86400;
    uint256 constant public STARTING_SHRIMP = 300;
    uint256 constant public PSN = 10000;
    uint256 constant public PSNH = 5000;
    uint256 constant public REFERRAL_COMMISSION = 10;
    uint256 constant public MARKET_SHRIMP_INITIAL = 86400;
    
    mapping (address => uint256) public hatcheryShrimp;
    mapping (address => uint256) public claimedShrimp;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    
    uint256 public marketShrimp;
    address public ceoAddress;
    bool public initialized = false;
    
    function ShrimpFarmer() public {
        ceoAddress = msg.sender;
    }
    
    function hatchShrimp(address ref) public {
        require(initialized);
        
        if (referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        
        uint256 eggsUsed = getMyShrimp();
        uint256 newShrimp = SafeMath.div(eggsUsed, SHRIMP_TO_HATCH_1SHRIMP);
        hatcheryShrimp[msg.sender] = SafeMath.add(hatcheryShrimp[msg.sender], newShrimp);
        claimedShrimp[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        
        claimedShrimp[referrals[msg.sender]] = SafeMath.add(
            claimedShrimp[referrals[msg.sender]],
            SafeMath.div(SafeMath.mul(eggsUsed, REFERRAL_COMMISSION), 100)
        );
        
        marketShrimp = SafeMath.add(marketShrimp, SafeMath.div(eggsUsed, 10));
    }
    
    function sellShrimp() public {
        require(initialized);
        
        uint256 hasShrimp = getMyShrimp();
        uint256 eggValue = calculateShrimpSell(hasShrimp);
        uint256 fee = devFee(eggValue);
        
        claimedShrimp[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        marketShrimp = SafeMath.add(marketShrimp, hasShrimp);
        ceoAddress.transfer(fee);
        msg.sender.transfer(SafeMath.sub(eggValue, fee));
    }
    
    function buyShrimp() public payable {
        require(initialized);
        
        uint256 eggsBought = calculateShrimpBuy(
            msg.value,
            SafeMath.sub(address(this).balance, msg.value)
        );
        eggsBought = SafeMath.sub(eggsBought, devFee(eggsBought));
        ceoAddress.transfer(devFee(msg.value));
        claimedShrimp[msg.sender] = SafeMath.add(claimedShrimp[msg.sender], eggsBought);
    }
    
    function calculateTrade(uint256 rt, uint256 rs, uint256 bs) public view returns(uint256) {
        return SafeMath.div(
            SafeMath.mul(PSN, bs),
            SafeMath.add(
                PSNH,
                SafeMath.div(
                    SafeMath.add(
                        SafeMath.mul(PSN, rs),
                        SafeMath.mul(PSNH, rt)
                    ),
                    rt
                )
            )
        );
    }
    
    function calculateShrimpSell(uint256 shrimp) public view returns(uint256) {
        return calculateTrade(shrimp, marketShrimp, address(this).balance);
    }
    
    function calculateShrimpBuy(uint256 eth, uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth, contractBalance, marketShrimp);
    }
    
    function calculateShrimpBuySimple(uint256 eth) public view returns(uint256) {
        return calculateShrimpBuy(eth, address(this).balance);
    }
    
    function devFee(uint256 amount) public pure returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount, 5), 100);
    }
    
    function seedMarket(uint256 shrimp) public payable {
        require(marketShrimp == 0);
        initialized = true;
        marketShrimp = shrimp;
    }
    
    function getFreeShrimp() public {
        require(initialized);
        require(hatcheryShrimp[msg.sender] == 0);
        lastHatch[msg.sender] = now;
        hatcheryShrimp[msg.sender] = STARTING_SHRIMP;
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMyHatcheryShrimp() public view returns(uint256) {
        return hatcheryShrimp[msg.sender];
    }
    
    function getMyShrimp() public view returns(uint256) {
        return SafeMath.add(claimedShrimp[msg.sender], getShrimpSinceLastHatch(msg.sender));
    }
    
    function getShrimpSinceLastHatch(address adr) public view returns(uint256) {
        uint256 secondsPassed = min(
            SHRIMP_TO_HATCH_1SHRIMP,
            SafeMath.sub(now, lastHatch[adr])
        );
        return SafeMath.mul(secondsPassed, hatcheryShrimp[adr]);
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