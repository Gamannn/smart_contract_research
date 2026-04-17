```solidity
pragma solidity ^0.4.19;

contract Ox712839a56036c2449ded4d3d73b072f537ec0d66 {
    struct GameData {
        uint256 marketEggs;
        address ceoAddress;
        bool initialized;
        uint256 PSN;
        uint256 PSNH;
        uint256 EGGS_TO_HATCH_1SHRIMP;
    }
    
    GameData private gameData = GameData(0, address(0), false, 10000, 5000, 86400);
    
    mapping (address => uint256) public hatcheryShrimp;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    
    function Ox712839a56036c2449ded4d3d73b072f537ec0d66() public {
        gameData.ceoAddress = msg.sender;
    }
    
    function hatchEggs(address ref) public {
        require(gameData.initialized);
        
        if (referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        
        uint256 eggsUsed = getMyEggs();
        uint256 newShrimp = SafeMath.div(eggsUsed, gameData.EGGS_TO_HATCH_1SHRIMP);
        hatcheryShrimp[msg.sender] = SafeMath.add(hatcheryShrimp[msg.sender], newShrimp);
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        
        claimedEggs[referrals[msg.sender]] = SafeMath.add(
            claimedEggs[referrals[msg.sender]],
            SafeMath.div(eggsUsed, 5)
        );
        
        gameData.marketEggs = SafeMath.add(
            gameData.marketEggs,
            SafeMath.div(eggsUsed, 10)
        );
    }
    
    function sellEggs() public {
        require(gameData.initialized);
        
        uint256 hasEggs = getMyEggs();
        uint256 eggValue = calculateEggSell(hasEggs);
        uint256 fee = devFee(eggValue);
        
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        gameData.marketEggs = SafeMath.add(gameData.marketEggs, hasEggs);
        gameData.ceoAddress.transfer(fee);
        msg.sender.transfer(SafeMath.sub(eggValue, fee));
    }
    
    function buyEggs() public payable {
        require(gameData.initialized);
        
        uint256 eggsBought = calculateEggBuy(
            msg.value,
            SafeMath.sub(address(this).balance, msg.value)
        );
        eggsBought = SafeMath.sub(eggsBought, devFee(eggsBought));
        gameData.ceoAddress.transfer(devFee(msg.value));
        claimedEggs[msg.sender] = SafeMath.add(claimedEggs[msg.sender], eggsBought);
    }
    
    function calculateTrade(
        uint256 rt,
        uint256 rs,
        uint256 bs
    ) public view returns(uint256) {
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
    
    function calculateEggSell(uint256 eggs) public view returns(uint256) {
        return calculateTrade(eggs, gameData.marketEggs, address(this).balance);
    }
    
    function calculateEggBuy(
        uint256 eth,
        uint256 contractBalance
    ) public view returns(uint256) {
        return calculateTrade(eth, contractBalance, gameData.marketEggs);
    }
    
    function calculateEggBuySimple(uint256 eth) public view returns(uint256) {
        return calculateEggBuy(eth, address(this).balance);
    }
    
    function devFee(uint256 amount) public view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount, 4), 100);
    }
    
    function seedMarket(uint256 eggs) public payable {
        require(gameData.marketEggs == 0);
        gameData.initialized = true;
        gameData.marketEggs = eggs;
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMyShrimp() public view returns(uint256) {
        return hatcheryShrimp[msg.sender];
    }
    
    function getMyEggs() public view returns(uint256) {
        return SafeMath.add(
            claimedEggs[msg.sender],
            getEggsSinceLastHatch(msg.sender)
        );
    }
    
    function getEggsSinceLastHatch(address adr) public view returns(uint256) {
        uint256 secondsPassed = min(
            gameData.EGGS_TO_HATCH_1SHRIMP,
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