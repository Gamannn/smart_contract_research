```solidity
pragma solidity ^0.4.18;

contract SpermBank {
    using SafeMath for uint256;
    
    uint256 public PSN = 10000;
    uint256 public PSNH = 5000;
    uint256 public CELLS_TO_MAKE_1_SPERM = 500000;
    
    bool public initialized = false;
    address public spermlordAddress;
    uint256 public spermlordReq = 500000;
    
    mapping (address => uint256) public spermCount;
    mapping (address => uint256) public cellCount;
    mapping (address => uint256) public lastAction;
    mapping (address => address) public referrals;
    
    uint256 public marketCells;
    
    function SpermBank() public {
        spermlordAddress = msg.sender;
    }
    
    function buyCells(address ref) public {
        require(initialized);
        
        if (referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        
        uint256 cellsBought = calculateCellBuy(msg.value, SafeMath.sub(address(this).balance, msg.value));
        cellsBought = SafeMath.sub(cellsBought, devFee(cellsBought));
        cellCount[msg.sender] = SafeMath.add(cellCount[msg.sender], cellsBought);
        spermCount[msg.sender] = 0;
        lastAction[msg.sender] = now;
        
        spermCount[referrals[msg.sender]] = SafeMath.add(
            spermCount[referrals[msg.sender]],
            SafeMath.div(cellsBought, 5)
        );
        
        marketCells = SafeMath.add(marketCells, cellsBought);
    }
    
    function sellCells() public {
        require(initialized);
        
        uint256 hasCells = getMyCells();
        uint256 cellValue = calculateCellSell(hasCells);
        uint256 fee = devFee(cellValue);
        
        cellCount[msg.sender] = SafeMath.mul(SafeMath.div(cellCount[msg.sender], 3), 2);
        spermCount[msg.sender] = 0;
        lastAction[msg.sender] = now;
        
        marketCells = SafeMath.add(marketCells, hasCells);
        spermlordAddress.transfer(fee);
        msg.sender.transfer(SafeMath.sub(cellValue, fee));
    }
    
    function reinvest() public payable {
        require(initialized);
        
        uint256 cellsBought = calculateCellBuy(
            msg.value,
            SafeMath.sub(address(this).balance, msg.value)
        );
        cellsBought = SafeMath.sub(cellsBought, devFee(cellsBought));
        
        spermCount[msg.sender] = SafeMath.add(spermCount[msg.sender], cellsBought);
        spermlordAddress.transfer(devFee(msg.value));
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
    
    function calculateCellSell(uint256 cells) public view returns(uint256) {
        return calculateTrade(cells, marketCells, address(this).balance);
    }
    
    function calculateCellBuy(uint256 eth, uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth, contractBalance, marketCells);
    }
    
    function calculateCellBuySimple(uint256 eth) public view returns(uint256) {
        return calculateCellBuy(eth, address(this).balance);
    }
    
    function devFee(uint256 amount) public view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount, 4), 100);
    }
    
    function seedMarket(uint256 cells) public payable {
        require(marketCells == 0);
        initialized = true;
        marketCells = cells;
    }
    
    function getFreeSperm() public payable {
        require(initialized);
        require(msg.value == 0.001 ether);
        spermlordAddress.transfer(msg.value);
        require(spermCount[msg.sender] == 0);
        lastAction[msg.sender] = now;
        spermCount[msg.sender] = CELLS_TO_MAKE_1_SPERM;
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMySperm() public view returns(uint256) {
        return spermCount[msg.sender];
    }
    
    function becomeSpermlord() public {
        require(initialized);
        require(msg.sender != spermlordAddress);
        require(spermCount[msg.sender] >= spermlordReq);
        
        spermCount[msg.sender] = SafeMath.sub(spermCount[msg.sender], spermlordReq);
        spermlordReq = spermCount[msg.sender];
        spermlordAddress = msg.sender;
    }
    
    function getSpermlordReq() public view returns(uint256) {
        return spermlordReq;
    }
    
    function getMyCells() public view returns(uint256) {
        return SafeMath.add(cellCount[msg.sender], getCellsSinceLastAction(msg.sender));
    }
    
    function getCellsSinceLastAction(address adr) public view returns(uint256) {
        uint256 secondsPassed = min(CELLS_TO_MAKE_1_SPERM, SafeMath.sub(now, lastAction[adr]));
        return SafeMath.div(secondsPassed, spermCount[adr]);
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