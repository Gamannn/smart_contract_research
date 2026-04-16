```solidity
pragma solidity ^0.4.13;

contract ERC20Interface {
    uint256 public totalSupply;
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is ERC20Interface {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
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

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract GeneralAdvertisingToken is StandardToken {
    string public constant name = "General Advertising Token";
    string public constant symbol = "GAT";
    uint8 public constant decimals = 18;
    address public owner;
    bool public purchasingAllowed = false;
    uint256 public tokenExchangeRate = 5000;
    uint256 public tokenCreationCap = 750 * (10**6) * 10**decimals;
    uint256 public tokenCreationMin = 250 * (10**6) * 10**decimals;
    uint256 public fundingStartBlock;
    uint256 public fundingEndBlock;
    uint256 public refundDeadline;
    uint256 public totalBonusTokensIssued;
    uint256 public totalContribution;
    uint256 public totalSupply;
    uint256 public transactionCounter;

    event LogTransaction(address indexed _from, uint256 _value);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function GeneralAdvertisingToken() public {
        owner = msg.sender;
        fundingStartBlock = block.number;
        fundingEndBlock = fundingStartBlock + 30 days;
        refundDeadline = fundingEndBlock + 30 days;
    }

    function enablePurchasing() public onlyOwner {
        purchasingAllowed = true;
    }

    function disablePurchasing() public onlyOwner {
        purchasingAllowed = false;
    }

    function calculateBonus(uint256 amount) internal view returns (uint256) {
        if (transactionCounter > 0 && transactionCounter <= 1000) {
            return amount / 2;
        } else if (transactionCounter > 1000 && transactionCounter <= 2000) {
            return amount / 5;
        } else if (transactionCounter > 2000 && transactionCounter <= 3000) {
            return amount / 10;
        } else if (transactionCounter > 3000 && transactionCounter <= 4000) {
            return amount / 20;
        }
        return amount;
    }

    function createTokens() public payable {
        require(purchasingAllowed);
        require(block.number >= fundingStartBlock && block.number <= fundingEndBlock);
        require(msg.value > 0);

        uint256 tokens = msg.value * tokenExchangeRate;
        uint256 bonusTokens = calculateBonus(tokens);

        balances[msg.sender] += tokens + bonusTokens;
        totalSupply += tokens + bonusTokens;
        totalContribution += msg.value;
        totalBonusTokensIssued += bonusTokens;
        transactionCounter += 1;

        Transfer(address(this), msg.sender, tokens + bonusTokens);
    }

    function refund() public {
        require(block.number > refundDeadline);
        require(totalContribution < tokenCreationMin);

        uint256 refundAmount = balances[msg.sender];
        balances[msg.sender] = 0;
        msg.sender.transfer(refundAmount);

        LogTransaction(msg.sender, refundAmount);
    }

    function withdrawEther() public onlyOwner {
        require(totalContribution >= tokenCreationMin);
        owner.transfer(this.balance);
    }
}
```