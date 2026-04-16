```solidity
pragma solidity ^0.4.24;

contract UpgradeTokenUtility {
    address public owner;
    address public feesAddr;
    address public trancheAdmin;
    uint256 public trancheAdminTime;
    
    uint256 public feePercent = 1500;
    uint256 public maxTranche = 4;
    uint256 public loopCount = 0;
    uint256 public currentTranche = 1;
    uint256 public circulatingSupply = 0;
    uint256 public totalTranches = 0;
    
    bool public payFees = true;
    bool public receiveEth = true;
    bool public trancheSaleActive = false;
    bool public trancheAdminActive = false;
    
    mapping(address => uint256) public balances;
    mapping(address => uint256) public lockedBalances;
    mapping(address => mapping(address => uint256)) public allowances;
    mapping(uint256 => uint256) public trancheSupply;
    mapping(uint256 => uint256) public trancheRate;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor() public {
        owner = msg.sender;
        feesAddr = msg.sender;
        trancheAdmin = msg.sender;
        trancheAdminTime = now + 182 days;
        
        initializeTrancheSupplies();
        initializeTrancheRates();
    }
    
    function initializeTrancheSupplies() internal {
        trancheSupply[1] = 1e25;
        trancheSupply[2] = 2e25;
        trancheSupply[3] = 1e25;
        trancheSupply[4] = 1e25;
    }
    
    function initializeTrancheRates() internal {
        trancheRate[1] = 3.457e20;
        trancheRate[2] = 8.643e19;
        trancheRate[3] = 4.321e19;
        trancheRate[4] = 2.161e19;
    }
    
    function() public payable {
        require((msg.value > 0) && (receiveEth));
        processPurchase(msg.value, 0);
    }
    
    function processPurchase(uint256 amount, uint256 tokens) internal {
        uint256 feeAmount = 0;
        loopCount++;
        
        if((currentTranche <= totalTranches) && (loopCount <= maxTranche)) {
            tokens = safeDiv(safeMul(loopCount, trancheSupply[currentTranche]), 1 ether);
        }
        
        if((tokens >= trancheSupply[currentTranche]) && (loopCount <= maxTranche)) {
            amount = safeSub(safeDiv(safeMul(trancheSupply[currentTranche], 1 ether), trancheRate[currentTranche]), amount);
            tokens = trancheSupply[currentTranche];
            lockedBalances[msg.sender] = safeAdd(lockedBalances[msg.sender], trancheSupply[currentTranche]);
            
            if(currentTranche == 1) {
                lockedBalances[msg.sender] = safeAdd(lockedBalances[msg.sender], trancheSupply[currentTranche]);
            }
            
            circulatingSupply = safeAdd(circulatingSupply, tokens);
            trancheSupply[currentTranche] = 0;
            currentTranche++;
            
            if(currentTranche == totalTranches) {
                trancheSaleActive = false;
            }
            
            processPurchase(amount, tokens);
        } else if((trancheSupply[currentTranche] >= tokens) && (tokens > 0) && (loopCount <= maxTranche)) {
            trancheSupply[currentTranche] = safeSub(trancheSupply[currentTranche], tokens);
            tokens = safeDiv(safeMul(amount, trancheRate[currentTranche]), 1 ether);
            circulatingSupply = safeAdd(circulatingSupply, tokens);
            
            if(currentTranche == totalTranches) {
                lockedBalances[msg.sender] = safeAdd(lockedBalances[msg.sender], tokens);
            }
            
            processPurchase(0, tokens);
        } else {
            if(payFees) {
                feeAmount = safeAdd(feeAmount, ((tokens * feePercent) / 10000));
                circulatingSupply = safeAdd(circulatingSupply, feeAmount);
            }
            
            balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
            trancheSupply[totalTranches] = safeSub(trancheSupply[totalTranches], feeAmount);
            balances[feesAddr] = safeAdd(balances[feesAddr], feeAmount);
            
            if(trancheSaleActive) {
                lockedBalances[feesAddr] = safeAdd(lockedBalances[feesAddr], feeAmount);
            }
            
            Transfer(this, msg.sender, tokens);
            Transfer(this, feesAddr, feeAmount);
            loopCount = 0;
        }
    }
    
    function transfer(address to, uint256 value) public {
        require(balances[msg.sender] >= value);
        
        if(to == address(this)) {
            balances[msg.sender] = safeSub(balances[msg.sender], value);
            
            if(value >= lockedBalances[msg.sender]) {
                lockedBalances[msg.sender] = 0;
            } else {
                lockedBalances[msg.sender] = safeSub(lockedBalances[msg.sender], value);
            }
            
            circulatingSupply = safeSub(circulatingSupply, value);
            Transfer(msg.sender, to, value);
        } else {
            if(trancheAdminTime > now) {
                balances[msg.sender] = safeSub(balances[msg.sender], value);
                balances[to] = safeAdd(balances[to], value);
                Transfer(msg.sender, to, value);
            } else {
                if(value <= safeSub(balances[msg.sender], lockedBalances[msg.sender])) {
                    balances[msg.sender] = safeSub(balances[msg.sender], value);
                    balances[to] = safeAdd(balances[to], value);
                    Transfer(msg.sender, to, value);
                } else {
                    revert();
                }
            }
        }
    }
    
    function balanceOf(address account) public constant returns (uint256) {
        return balances[account];
    }
    
    function lockedBalanceOf(address account) public constant returns (uint256) {
        return lockedBalances[account];
    }
    
    function currentTrancheSupply() public constant returns (uint256) {
        return trancheSupply[currentTranche];
    }
    
    function getTrancheSupply(uint256 tranche) public constant returns (uint256) {
        return trancheSupply[tranche];
    }
    
    function getTrancheRate(uint256 tranche) public constant returns (uint256) {
        return trancheRate[tranche];
    }
    
    function changeFeesAddress(address newFeesAddr) public {
        require(msg.sender == trancheAdmin);
        feesAddr = newFeesAddr;
    }
    
    function toggleFees() public {
        require(msg.sender == owner);
        if(payFees) {
            payFees = false;
        } else {
            payFees = true;
        }
    }
    
    function changeFeePercent(uint256 newFeePercent) public {
        require(msg.sender == owner);
        require((newFeePercent >= 0) && (newFeePercent <= 100));
        feePercent = newFeePercent * 100;
    }
    
    function changeOwner(address newOwner) public {
        require(msg.sender == owner);
        owner = newOwner;
    }
    
    function changeTrancheAdmin(address newTrancheAdmin) public {
        require((msg.sender == owner) || (msg.sender == trancheAdmin));
        trancheAdmin = newTrancheAdmin;
    }
    
    function toggleReceiveEth() public {
        require(msg.sender == owner);
        if(receiveEth == true) {
            receiveEth = false;
        } else {
            receiveEth = true;
        }
    }
    
    function allocateTokens(uint256 amount, address recipient) public {
        require(msg.sender == owner);
        balances[recipient] = safeAdd(balances[recipient], amount);
        circulatingSupply = safeAdd(circulatingSupply, amount);
        Transfer(this, recipient, amount);
    }
    
    function allocateLockedTokens(uint256 amount, address recipient) public {
        require(msg.sender == owner);
        balances[recipient] = safeAdd(balances[recipient], amount);
        lockedBalances[recipient] = safeAdd(lockedBalances[recipient], amount);
        circulatingSupply = safeAdd(circulatingSupply, amount);
        Transfer(this, recipient, amount);
    }
    
    function forceTransfer(address from, uint256 value) public {
        require(msg.sender == owner);
        require(balances[from] >= value);
        from.transfer(value);
    }
    
    function addTranche(uint256 supply, uint256 rate) public {
        require(((msg.sender == owner) || (msg.sender == trancheAdmin)) && (trancheAdminActive == true));
        require(safeAdd(supply, circulatingSupply) <= 50000000000000000000000000);
        totalTranches++;
        trancheSupply[totalTranches] = supply;
        trancheRate[totalTranches] = rate;
    }
    
    function updateTrancheRate(uint256 tranche, uint256 rate) public {
        require(((msg.sender == owner) || (msg.sender == trancheAdmin)) && trancheRate[tranche] > 0);
        trancheRate[tranche] = rate;
    }
    
    function activateTrancheSale() public {
        require(msg.sender == owner);
        trancheSaleActive = true;
    }
    
    function activateTrancheAdmin() public {
        require(msg.sender == owner);
        trancheAdminActive = true;
    }
    
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }
    
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }
    
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(balances[from] >= value);
        balances[from] = safeSub(balances[from], value);
        allowances[from][msg.sender] = safeSub(allowances[from][msg.sender], value);
        balances[to] = safeAdd(balances[to], value);
        Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool success) {
        allowances[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }
    
    function allowance(address ownerAddr, address spender) public constant returns (uint256 remaining) {
        return allowances[ownerAddr][spender];
    }
}
```