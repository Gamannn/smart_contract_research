```solidity
pragma solidity ^0.4.10;

contract Token {
    function transfer(address to, uint256 value);
}

contract HumansOnlyToken {
    string public name = "HON";
    string public symbol = "HON";
    uint8 public decimals = 18;
    
    uint256 public totalSupply;
    uint256 public totalMigrated;
    uint256 public tokenCreationCap;
    uint256 public tokenCreationRate;
    uint256 public bonusCreationRate;
    
    uint256 public onehour = 250;
    uint256 public oneday = 24 * onehour;
    uint256 public oneweek = 7 * oneday;
    
    uint256 public fundingStartBlock;
    uint256 public blackFridayEndBlock;
    uint256 public fundingEndBlock;
    
    bool public funding = true;
    bool public migrationState = false;
    bool public refundState = false;
    
    mapping(address => uint256) balances;
    mapping(address => uint256) migratedValue;
    
    address public migrationMaster;
    address public hon1ninja;
    address public hon2backup;
    
    uint256 public constant tokenXstepCAP = 18000 * 1 ether * 1000;
    uint256 public constant token18KstepCAP = 800 * 1 ether * 1000;
    uint256 public constant tokenSEEDcap = 100 * 1 ether * 1000;
    uint256 public constant tokenCreationMin = 283000 ether * 1000;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Migrate(address indexed from, address indexed to, uint256 value);
    event Refund(address indexed from, uint256 value);
    
    function HumansOnlyToken() {
        if (hon1ninja == 0) throw;
        if (migrationMaster == 0) throw;
        if (fundingStartBlock < block.number) throw;
    }
    
    function transfer(address to, uint256 value) returns (bool) {
        if ((msg.sender != migrationMaster) && (block.number < fundingStartBlock + 2 * oneweek)) throw;
        
        if (balances[msg.sender] >= value && value > 0) {
            balances[msg.sender] -= value;
            balances[to] += value;
            Transfer(msg.sender, to, value);
            return true;
        }
        return false;
    }
    
    function totalSupply() external constant returns (uint256) {
        return totalSupply;
    }
    
    function balanceOf(address owner) external constant returns (uint256) {
        return balances[owner];
    }
    
    function() payable {
        if (funding) {
            createTokens(msg.sender);
        }
    }
    
    function createTokens(address recipient) payable {
        if (!funding) throw;
        if (block.number < fundingStartBlock) throw;
        if (block.number > fundingEndBlock) throw;
        if (msg.value == 0) throw;
        if (msg.value > (tokenCreationCap - totalSupply) / tokenCreationRate) throw;
        
        uint256 tokens = msg.value * tokenCreationRate;
        uint256 bonusTokens = 0;
        
        if (totalSupply < tokenSEEDcap) {
            bonusCreationRate = tokenCreationRate;
        }
        if (totalSupply > tokenXstepCAP) {
            bonusCreationRate = tokenCreationRate;
        }
        if (totalSupply > token18KstepCAP) {
            bonusCreationRate = tokenCreationRate * 3;
        }
        
        uint256 numTokens = tokens + bonusTokens;
        totalSupply += numTokens;
        balances[recipient] += numTokens;
        
        Transfer(0, recipient, numTokens);
        
        uint256 percent = 18;
        uint256 teamTokens = numTokens * percent / 100;
        totalSupply += teamTokens;
        balances[migrationMaster] += teamTokens;
        Transfer(0, migrationMaster, teamTokens);
    }
    
    function partialWithdraw() external {
        migrationMaster.transfer(this.balance - 0.1 ether);
    }
    
    function hon1ninjaWithdraw() external {
        if (msg.sender != hon1ninja) throw;
        hon1ninja.transfer(this.balance - 1 ether);
    }
    
    function finalize() external {
        if (msg.sender != hon1ninja) throw;
        refundState = true;
    }
    
    function toggleMigrationState() external {
        if (msg.sender != migrationMaster) throw;
        migrationState = !migrationState;
    }
    
    function withdraw() external {
        if ((msg.sender != migrationMaster) && (msg.sender != hon1ninja) && (msg.sender != hon2backup)) throw;
        funding = false;
        if (!hon1ninja.send(this.balance)) throw;
        
        uint256 additionalTokens = tokenCreationCap - totalSupply;
        totalSupply += additionalTokens;
        balances[migrationMaster] += additionalTokens;
        Transfer(0, migrationMaster, additionalTokens);
    }
    
    function migrate(uint256 value) external {
        if (migrationState) throw;
        if (value == 0) throw;
        if (value > balances[msg.sender]) throw;
        
        balances[msg.sender] -= value;
        totalSupply -= value;
        totalMigrated += value;
    }
    
    function refund() external {
        if (!refundState) throw;
        uint256 tokenValue = balances[msg.sender];
        uint256 etherValue = migratedValue[msg.sender];
        
        if (etherValue == 0) throw;
        migratedValue[msg.sender] = 0;
        totalSupply -= tokenValue;
        
        uint256 refundAmount = etherValue / tokenCreationRate;
        Refund(msg.sender, refundAmount);
        msg.sender.transfer(refundAmount);
    }
    
    function regulations() external returns (string) {
        return "Regulations of ICO and preICO and usage of this smartcontract are present at website humansOnly.network and by using this smartcontract you commit that you accept and will follow those rules";
    }
}
```