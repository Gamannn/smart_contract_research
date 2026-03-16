```solidity
pragma solidity ^0.4.10;

contract SafeMath {
    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x * y;
        assert((x == 0) || (z / x == y));
        return z;
    }
}

contract Token {
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract SPINToken is StandardToken, SafeMath {
    string public constant name = "ETHERSPIN";
    string public constant symbol = "SPIN";
    string public version = "2.0";
    uint256 public constant decimals = 18;

    struct TokenConfig {
        uint256 tokenCreationCap;
        uint256 SPINFund;
        uint256 fundingEndBlock;
        uint256 fundingStartBlock;
        bool isFinalized;
        address SPINFundDeposit;
        address ethFundDeposit;
        uint256 totalSupply;
    }

    TokenConfig public config;

    event CreateSPIN(address indexed _to, uint256 _value);

    function SPINToken(
        address _ethFundDeposit,
        address _SPINFundDeposit,
        uint256 _fundingStartBlock,
        uint256 _fundingEndBlock
    ) {
        config.isFinalized = false;
        config.ethFundDeposit = _ethFundDeposit;
        config.SPINFundDeposit = _SPINFundDeposit;
        config.fundingStartBlock = _fundingStartBlock;
        config.fundingEndBlock = _fundingEndBlock;
        config.totalSupply = config.SPINFund;
        balances[config.SPINFundDeposit] = config.SPINFund;
        CreateSPIN(config.SPINFundDeposit, config.SPINFund);
    }

    function tokenRate() constant returns(uint) {
        if (block.number >= config.fundingStartBlock && block.number < config.fundingStartBlock + 250) return 1300;
        if (block.number >= config.fundingStartBlock && block.number < config.fundingStartBlock + 33600) return 1000;
        if (block.number >= config.fundingStartBlock && block.number < config.fundingStartBlock + 67200) return 750;
        if (block.number >= config.fundingStartBlock && block.number < config.fundingStartBlock + 100800) return 600;
        return 500;
    }

    function makeTokens() payable {
        if (config.isFinalized) throw;
        if (block.number < config.fundingStartBlock) throw;
        if (block.number > config.fundingEndBlock) throw;
        if (msg.value == 0) throw;

        uint256 tokens = safeMult(msg.value, tokenRate());
        uint256 checkedSupply = safeAdd(config.totalSupply, tokens);

        if (config.tokenCreationCap < checkedSupply) throw;

        config.totalSupply = checkedSupply;
        balances[msg.sender] += tokens;
        CreateSPIN(msg.sender, tokens);
    }

    function() payable {
        makeTokens();
    }

    function finalize() external {
        if (config.isFinalized) throw;
        if (msg.sender != config.ethFundDeposit) throw;
        if (block.number <= config.fundingEndBlock && config.totalSupply != config.tokenCreationCap) throw;

        config.isFinalized = true;
        if (!config.ethFundDeposit.send(this.balance)) throw;
    }

    TokenConfig public config = TokenConfig(
        10 * (10**6) * 10**decimals,
        2000 * (10**3) * 10**decimals,
        0,
        0,
        false,
        address(0),
        address(0),
        0
    );
}
```