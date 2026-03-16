```solidity
pragma solidity ^0.4.11;

contract ERC20 {
    function transfer(address _to, uint256 _value) returns (bool success);
    function balanceOf(address _owner) constant returns (uint256 balance);
}

contract StatusContribution {
    uint256 public maxGasPrice;
    uint256 public startBlock;
    uint256 public totalNormalCollected;
    uint256 public finalizedBlock;
    function proxyPayment(address _th) payable returns (bool);
}

contract DynamicCeiling {
    function curves(uint currentIndex) returns (bytes32 hash, uint256 limit, uint256 slopeFactor, uint256 collectMinimum);
    uint256 public currentIndex;
    uint256 public revealedCurves;
}

contract StatusBuyer {
    mapping (address => uint256) public deposits;
    mapping (address => uint256) public simulatedSNT;
    uint256 public bounty;
    bool public boughtTokens;
    
    StatusContribution public sale = StatusContribution(0x55d34b686aa8C04921397c5807DB9ECEdba00a4c);
    DynamicCeiling public dynamic = DynamicCeiling(0xc636e73Ff29fAEbCABA9E0C3f6833EaD179FFd5c);
    ERC20 public token = ERC20(0x744d70FDBE2Ba4CF95131626614a1763DF805B9E);
    
    address public developer = 0x4e6A1c57CdBfd97e8efe831f8f4418b1F2A09e6e;
    
    function withdraw() {
        uint256 userDeposit = deposits[msg.sender];
        deposits[msg.sender] = 0;
        
        uint256 contractEthBalance = this.balance - bounty;
        uint256 contractSNTBalance = token.balanceOf(address(this));
        uint256 totalValue = (contractEthBalance * 10000) + contractSNTBalance;
        
        uint256 ethAmount = (userDeposit * contractEthBalance * 10000) / totalValue;
        uint256 sntAmount = 10000 * ((userDeposit * contractSNTBalance) / totalValue);
        
        uint256 fee = 0;
        if (simulatedSNT[msg.sender] < sntAmount) {
            fee = (sntAmount - simulatedSNT[msg.sender]) / 100;
        }
        
        if (!token.transfer(msg.sender, sntAmount - fee)) throw;
        if (!token.transfer(developer, fee)) throw;
        
        msg.sender.transfer(ethAmount);
    }
    
    function addToBounty() payable {
        if (boughtTokens) throw;
        bounty += msg.value;
    }
    
    function simulateICO() {
        if (tx.gasprice > sale.maxGasPrice()) throw;
        if (block.number < sale.startBlock()) throw;
        if (dynamic.revealedCurves() == 0) throw;
        
        uint256 limit;
        uint256 slopeFactor;
        (, limit, slopeFactor, ) = dynamic.curves(dynamic.currentIndex());
        
        uint256 totalNormalCollected = sale.totalNormalCollected();
        if (limit <= totalNormalCollected) throw;
        
        simulatedSNT[msg.sender] += ((limit - totalNormalCollected) / slopeFactor);
    }
    
    function buyTokens() {
        if (boughtTokens) return;
        
        boughtTokens = true;
        sale.proxyPayment.value(this.balance - bounty)(address(this));
        msg.sender.transfer(bounty);
    }
    
    function processDeposit() payable {
        if (!boughtTokens) {
            deposits[msg.sender] += msg.value;
            if (deposits[msg.sender] > 30 ether) throw;
        } else {
            if (msg.value != 0) throw;
            
            if (sale.finalizedBlock() == 0) {
                simulateICO();
            } else {
                withdraw();
            }
        }
    }
    
    function () payable {
        if (msg.sender == address(sale)) return;
        processDeposit();
    }
}
```