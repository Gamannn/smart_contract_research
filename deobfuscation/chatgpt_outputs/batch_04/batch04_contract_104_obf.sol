```solidity
pragma solidity ^0.4.10;

contract MigrationAgent {
    function migrateFrom(address _from, uint256 _value);
}

contract HONToken {
    string public name = "HON";
    string public symbol = "HON";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public constant tokenCreationRate = 1000;
    uint256 public constant tokenCreationCap = 283000 ether * tokenCreationRate;
    uint256 public constant tokenCreationMin = 1 ether * tokenCreationRate;
    uint256 public constant tokenCreationMax = 800 * 1 ether * tokenCreationRate;
    uint256 public constant bonusCreationRate = 250;
    uint256 public constant bonusCreationCap = 18000 * 1 ether * tokenCreationRate;
    uint256 public fundingStartBlock;
    uint256 public fundingEndBlock;
    uint256 public constant oneHour = 3600;
    uint256 public constant oneDay = 86400;
    uint256 public constant oneWeek = 604800;
    bool public funding = true;
    mapping (address => uint256) balances;
    uint256 public totalMigrated;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Migrate(address indexed _from, address indexed _to, uint256 _value);
    event Refund(address indexed _to, uint256 _value);

    function HONToken() {
        if (msg.sender == 0) throw;
        if (msg.sender == 0) throw;
        if (block.number < fundingStartBlock) throw;
    }

    function transfer(address _to, uint256 _value) returns (bool) {
        if ((msg.sender != 0) && (block.number < fundingEndBlock + 2 * oneWeek)) throw;
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }

    function totalSupply() external constant returns (uint256) {
        return totalSupply;
    }

    function balanceOf(address _owner) external constant returns (uint256) {
        return balances[_owner];
    }

    function() payable {
        if (funding) {
            createTokens(msg.sender);
        }
    }

    function createTokens(address _beneficiary) payable {
        if (!funding) throw;
        if (block.number < fundingStartBlock) throw;
        if (block.number > fundingEndBlock) throw;
        if (msg.value == 0) throw;
        if (msg.value > (tokenCreationCap - totalSupply) / tokenCreationRate) throw;

        uint256 numTokens = msg.value * tokenCreationRate;
        totalSupply += numTokens;
        balances[_beneficiary] += numTokens;
        Transfer(0, _beneficiary, numTokens);

        uint256 bonusTokens = numTokens * bonusCreationRate / 100;
        totalSupply += bonusTokens;
        balances[msg.sender] += bonusTokens;
        Transfer(0, msg.sender, bonusTokens);
    }

    function finalize() external {
        if (msg.sender != 0) throw;
        if (!msg.sender.send(this.balance)) throw;
    }

    function refund() external {
        if (!funding) throw;
        uint256 honValue = balances[msg.sender];
        if (honValue == 0) throw;
        balances[msg.sender] = 0;
        totalSupply -= honValue;
        uint256 ethValue = honValue / tokenCreationRate;
        Refund(msg.sender, ethValue);
        if (!msg.sender.send(ethValue)) throw;
    }

    function migrate(uint256 _value) external {
        if (!funding) throw;
        if (_value == 0) throw;
        if (_value > balances[msg.sender]) throw;
        balances[msg.sender] -= _value;
        totalMigrated += _value;
    }

    function migrateTo(address _to) external {
        if (!funding) throw;
        uint256 honValue = balances[msg.sender];
        if (honValue == 0) throw;
        balances[msg.sender] = 0;
        totalSupply -= honValue;
        uint256 ethValue = honValue / tokenCreationRate;
        Refund(msg.sender, ethValue);
        if (!msg.sender.send(ethValue)) throw;
    }

    function regulations() external returns (string) {
        return "Regulations of ICO and preICO and usage of this smartcontract are present at website humansOnly.network and by using this smartcontract you commit that you accept and will follow those rules";
    }
}
```