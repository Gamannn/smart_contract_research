```solidity
pragma solidity ^0.4.18;

contract FutereumMiniature {
    uint8 public decimals = 18;
    string public name = "Futereum Miniature";
    string public symbol = "Ox7c347819fb6b2a3397c574472b70447fbd7e3433";
    
    uint256 public totalSupply = 0;
    uint256 public totalSubmitted = 0;
    uint256 public submittedFeesPaid = 0;
    uint256 public reservedFees = 0;
    uint256 public penalty = 0;
    uint256 public payRate = 0;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    address public foundation = 0x448468d5591C724f5310027B859135d5F6434286;
    address public team = 0xE252765E4A71e3170b2215cf63C16E7553ec26bD;
    address public advisor = 0xb69a63279319197adca53b9853469d3aac586a4c;
    
    uint256 public miningStartTime;
    uint256 public miningEndTime;
    uint256 public swapStartTime;
    uint256 public swapEndTime;
    uint256 public swapEndTimeExtended;
    uint256 public waitStartTime;
    uint256 public waitEndTime;
    
    bool public miningExtended = false;
    bool public waiting = false;
    bool public swapping = false;
    
    uint256 public currentTier = 0;
    uint256 public totalMined = 0;
    
    uint256[11] public tierLimits = [
        50006715761945500000,
        41506715761945900000,
        30840049095279200000,
        21840049095279200000,
        14840049095279200000,
        9840049095279210000,
        6411477666707780000,
        3735007078472480000,
        1989552533017940000,
        877192982456140000,
        0
    ];
    
    uint256[11] public tierRates = [
        5,
        8,
        13,
        18,
        21,
        34,
        55,
        89,
        144,
        256,
        740000
    ];
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event MiningStart(uint256 startTime, uint256 endTime, uint256 swapStartTime);
    event MiningExtended(uint256 newEndTime, uint256 oldEndTime, uint256 swapStartTime);
    event WaitStarted(uint256 waitStartTime);
    event SwapStarted(uint256 swapStartTime);
    
    function FutereumMiniature() public {
        miningStartTime = now + 2 hours;
        miningEndTime = miningStartTime + 8 hours;
        swapStartTime = miningEndTime + 2 hours;
        swapEndTime = swapStartTime + 2 hours;
        swapEndTimeExtended = swapEndTime + 2 hours;
        waitStartTime = swapEndTimeExtended + 2 hours;
        waitEndTime = waitStartTime + 8 hours;
        
        miningExtended = false;
        waiting = false;
        swapping = false;
        currentTier = 0;
        totalMined = 0;
        totalSubmitted = 0;
        submittedFeesPaid = 0;
        reservedFees = 0;
        penalty = 0;
        payRate = 0;
        
        MiningStart(miningStartTime, miningEndTime, swapStartTime);
    }
    
    function () external payable {
        require(msg.sender != address(0) && currentTier != 10 && !swapping && !waiting);
        uint256 amount = min(miningEndTime - now, msg.value);
        require(amount > 0);
        uint256 tokens = mintTokens(msg.sender, amount);
        Transfer(address(0), msg.sender, tokens);
    }
    
    function startSwap() public {
        require(swapping && now >= swapStartTime);
        reservedFees = this.balance * 10000;
        distributeFees();
        calculatePayRate();
    }
    
    function totalMinedTokens() public view returns (uint256) {
        return totalMined;
    }
    
    function totalSubmittedAmount() public view returns (uint256) {
        return totalSubmitted;
    }
    
    function availableBalance() public view returns (uint256) {
        return this.balance - (reservedFees + (totalSubmitted - submittedFeesPaid) * 1530 / 10000);
    }
    
    function calculatePayRate() internal {
        reservedFees = reservedFees + (totalSubmitted - submittedFeesPaid) * 1530 / 10000;
        uint256 available = this.balance - reservedFees;
        payRate = available / totalMined;
    }
    
    function updateState() internal {
        if (now >= miningEndTime && !swapping && !waiting) {
            if (miningExtended) {
                waiting = true;
                waitStartTime = waitEndTime;
                WaitStarted(waitStartTime);
            } else if (currentTier == 10) {
                waiting = true;
                waitStartTime = swapStartTime;
                WaitStarted(waitStartTime);
            } else {
                miningEndTime = swapStartTime;
                miningExtended = true;
                MiningExtended(miningEndTime, miningStartTime, swapStartTime);
            }
        } else if (waiting) {
            swapping = true;
            waiting = false;
            if (miningExtended) {
                swapStartTime = swapEndTimeExtended;
            } else {
                swapStartTime = swapEndTime;
            }
            SwapStarted(swapStartTime);
        }
    }
    
    function mintTokens(address recipient, uint256 amount) internal returns (uint256) {
        uint256 remaining = amount;
        
        if (remaining > tierLimits[currentTier]) {
            uint256 overflow = remaining - tierLimits[currentTier] - 1;
            amount = amount - overflow;
            recipient.transfer(overflow);
        }
        
        totalSubmitted += amount;
        remaining -= amount;
        
        uint256 tokens = calculateTokens(remaining, amount);
        balanceOf[recipient] += tokens;
        totalMined += tokens;
        
        return tokens;
    }
    
    function calculateTokens(uint256 remaining, uint256 amount) internal returns (uint256) {
        if (currentTier == 10) {
            return 740000;
        }
        
        uint256 tokens = 0;
        
        if (remaining > tierLimits[currentTier]) {
            uint256 overflow = remaining - tierLimits[currentTier];
            amount -= overflow;
            tokens = amount * tierRates[currentTier];
            currentTier += 1;
            tokens += calculateTokens(remaining, overflow);
        } else {
            tokens = amount * tierRates[currentTier];
        }
        
        return tokens;
    }
    
    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);
        updateState();
        
        if (to == address(this)) {
            require(swapping);
            if (payRate == 0) {
                calculatePayRate();
            }
            uint256 etherAmount = value * payRate;
            etherAmount /= 1 ether;
            balanceOf[msg.sender] -= value;
            totalMined -= value;
            Transfer(msg.sender, to, value);
            msg.sender.transfer(etherAmount);
        } else {
            balanceOf[msg.sender] -= value;
            balanceOf[to] += value;
            Transfer(msg.sender, to, value);
        }
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        uint256 allowed = allowance[from][msg.sender];
        require(balanceOf[from] >= value && allowed >= value);
        balanceOf[to] += value;
        if (allowed < (2**256 - 1)) {
            allowance[from][msg.sender] -= value;
        }
        return true;
    }
    
    function balanceOf(address owner) public view returns (uint256 balance) {
        return balanceOf[owner];
    }
    
    function approve(address spender, uint256 value) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }
    
    function allowance(address owner, address spender) public view returns (uint256 remaining) {
        return allowance[owner][spender];
    }
    
    function distributeFees() public {
        uint256 fees = reservedFees;
        reservedFees = 0;
        
        if (fees > 0) {
            team.transfer(fees / 2);
            foundation.transfer(fees / 4);
            advisor.transfer(fees / 4);
        }
    }
    
    function changeTeam(address newTeam) public {
        require(msg.sender == foundation);
        team = newTeam;
    }
    
    function changeFoundation(address newFoundation) public {
        require(msg.sender == foundation);
        foundation = newFoundation;
    }
    
    function changeAdvisor(address newAdvisor) public {
        require(msg.sender == advisor);
        advisor = newAdvisor;
    }
    
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
```