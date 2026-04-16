```solidity
pragma solidity ^0.4.24;

contract PoohGame {
    using SafeMath for uint256;
    
    uint256 public POOH_TO_CALL_1PLUMBER = 86400;
    uint256 public POOH_TO_HATCH_1PLUMBER = 300;
    uint256 public POOH_TO_CALL_1PLUMBER_MODIFIER = 5000;
    uint256 public POOH_TO_HATCH_1PLUMBER_MODIFIER = 10000;
    
    bool public initialized = false;
    address public ceoAddress;
    
    mapping (address => uint256) public hatcheryPlumber;
    mapping (address => uint256) public claimedPooh;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    
    uint256 public marketPooh;
    
    constructor() public {
        ceoAddress = msg.sender;
    }
    
    function hatchPooh(address ref) public {
        require(initialized);
        
        if (referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        
        uint256 poohUsed = getMyPooh();
        uint256 newPlumber = poohUsed.div(POOH_TO_CALL_1PLUMBER);
        hatcheryPlumber[msg.sender] = hatcheryPlumber[msg.sender].add(newPlumber);
        claimedPooh[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        
        claimedPooh[referrals[msg.sender]] = claimedPooh[referrals[msg.sender]].add(poohUsed.div(5));
        
        marketPooh = marketPooh.add(poohUsed.div(10));
    }
    
    function sellPooh() public {
        require(initialized);
        uint256 hasPooh = getMyPooh();
        uint256 poohValue = calculatePoohSell(hasPooh);
        uint256 fee = devFee(poohValue);
        
        hatcheryPlumber[msg.sender] = hatcheryPlumber[msg.sender].mul(2);
        claimedPooh[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        
        marketPooh = marketPooh.add(hasPooh);
        ceoAddress.transfer(fee);
        msg.sender.transfer(poohValue.sub(fee));
    }
    
    function buyPooh() public payable {
        require(initialized);
        uint256 poohBought = calculatePoohBuy(msg.value, address(this).balance.sub(msg.value));
        poohBought = poohBought.sub(devFee(poohBought));
        
        ceoAddress.transfer(devFee(msg.value));
        claimedPooh[msg.sender] = claimedPooh[msg.sender].add(poohBought);
    }
    
    function calculateTrade(uint256 rt, uint256 rs, uint256 bs) public view returns(uint256) {
        return SafeMath.div(
            SafeMath.mul(POOH_TO_HATCH_1PLUMBER_MODIFIER, bs),
            SafeMath.add(
                POOH_TO_CALL_1PLUMBER_MODIFIER,
                SafeMath.div(
                    SafeMath.add(
                        SafeMath.mul(POOH_TO_CALL_1PLUMBER_MODIFIER, rs),
                        SafeMath.mul(POOH_TO_HATCH_1PLUMBER_MODIFIER, rt)
                    ),
                    rt
                )
            )
        );
    }
    
    function calculatePoohSell(uint256 pooh) public view returns(uint256) {
        return calculateTrade(pooh, marketPooh, address(this).balance);
    }
    
    function calculatePoohBuy(uint256 eth, uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth, contractBalance, marketPooh);
    }
    
    function calculatePoohBuySimple(uint256 eth) public view returns(uint256) {
        return calculatePoohBuy(eth, address(this).balance);
    }
    
    function devFee(uint256 amount) public pure returns(uint256) {
        return amount.div(20);
    }
    
    function seedMarket(uint256 pooh) public payable {
        require(marketPooh == 0);
        initialized = true;
        marketPooh = pooh;
    }
    
    function getFreePlumber() public payable {
        require(initialized);
        require(msg.value == 0.001 ether);
        ceoAddress.transfer(msg.value);
        
        require(hatcheryPlumber[msg.sender] == 0);
        lastHatch[msg.sender] = now;
        hatcheryPlumber[msg.sender] = 300;
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMyPlumber() public view returns(uint256) {
        return hatcheryPlumber[msg.sender];
    }
    
    function getMyPooh() public view returns(uint256) {
        return claimedPooh[msg.sender].add(getPoohSinceLastHatch(msg.sender));
    }
    
    function getPoohSinceLastHatch(address adr) public view returns(uint256) {
        uint256 secondsPassed = min(POOH_TO_CALL_1PLUMBER, now.sub(lastHatch[adr]));
        return secondsPassed.mul(hatcheryPlumber[adr]);
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