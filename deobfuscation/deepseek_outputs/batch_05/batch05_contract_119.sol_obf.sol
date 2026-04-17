```solidity
contract TokenExchange {
    address public owner;
    address public devAddress;
    address public feeAddress;
    
    string public name;
    string public symbol;
    uint8 public decimals;
    
    uint256 public totalSupply;
    uint256 public circulatingSupply;
    uint256 public availableSupply;
    uint256 public frozenTokens;
    uint256 public collectedFees;
    uint256 public lifeValue;
    uint256 public devFeePercentage;
    
    bool public feesEnabled;
    bool public acceptEth;
    bool public freezeTokensEnabled;
    bool public burnFrozenTokens;
    
    uint256 public tokensPerEth;
    
    mapping(address => uint256) public balances;
    mapping(address => uint256) public exchangeRates;
    mapping(address => bool) public registeredPartners;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Exchanged(address indexed from, address indexed partner, uint256 value);
    
    function TokenExchange() {
        owner = msg.sender;
        initialize();
    }
    
    function initialize() internal {
        name = "CoEval";
        symbol = "Oxe2657f296e3ebfaa3ce3bc794b0b8bfde643f717";
        decimals = 18;
        
        totalSupply = 32664750000000000000000;
        availableSupply = 177000000000000000;
        circulatingSupply = 0;
        
        balances[owner] = totalSupply;
        tokensPerEth = 17700000000000;
        devFeePercentage = 10000;
    }
    
    function transfer(address recipient, uint256 amount) public {
        require(balances[msg.sender] >= amount);
        
        if (recipient == address(this)) {
            availableSupply = safeAdd(availableSupply, amount);
            balances[msg.sender] = safeSub(balances[msg.sender], amount);
            Transfer(msg.sender, recipient, amount);
        } else {
            uint codeLength;
            assembly {
                codeLength := extcodesize(recipient)
            }
            
            if (codeLength != 0) {
                requestTokensFromOtherContract(recipient, amount);
            } else {
                balances[msg.sender] = safeSub(balances[msg.sender], amount);
                balances[recipient] = safeAdd(balances[recipient], amount);
                Transfer(msg.sender, recipient, amount);
            }
        }
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public {
        require(balances[sender] >= amount);
        
        if (recipient == address(this)) {
            availableSupply = safeAdd(availableSupply, amount);
            balances[sender] = safeSub(balances[sender], amount);
            Transfer(sender, recipient, amount);
        } else {
            uint codeLength;
            assembly {
                codeLength := extcodesize(recipient)
            }
            
            if (codeLength != 0) {
                requestTokensFromOtherContract(recipient, amount);
            } else {
                balances[sender] = safeSub(balances[sender], amount);
                balances[recipient] = safeAdd(balances[recipient], amount);
                Transfer(sender, recipient, amount);
            }
        }
    }
    
    function requestTokensFromOtherContract(address partner, uint256 amount) internal {
        require(registeredPartners[partner]);
        
        TokenExchange(partner).transferFrom(partner, this, msg.sender, amount);
        
        if (burnFrozenTokens) {
            frozenTokens = safeAdd(frozenTokens, amount);
        } else {
            availableSupply = safeAdd(availableSupply, amount);
        }
        
        balances[msg.sender] = safeSub(balances[msg.sender], amount);
        circulatingSupply = safeSub(circulatingSupply, amount);
        Exchanged(msg.sender, partner, amount);
        Transfer(msg.sender, this, amount);
    }
    
    function receiveEth() public payable {
        require(msg.value > 0);
        require(acceptEth);
        
        uint256 tokens = safeMul(safeDiv(msg.value, 1 ether), tokensPerEth);
        require(availableSupply >= tokens, "Not enough tokens available at current rate");
        
        totalSupply = safeSub(totalSupply, tokens);
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
        circulatingSupply = safeAdd(circulatingSupply, tokens);
        
        lifeValue = safeAdd(lifeValue, msg.value);
        
        if (feesEnabled) {
            if (acceptEth) {
                collectedFees = safeAdd(collectedFees, safeMul(msg.value, devFeePercentage) / 10000);
            }
        }
    }
    
    function exchange(address partner, address recipient, uint256 amount) internal returns (bool) {
        TokenExchange exchangeContract = TokenExchange(partner);
        exchangeContract.transferFrom(partner, recipient, amount);
        return true;
    }
    
    function transferFrom(address partner, address recipient, uint256 amount) public {
        require(registeredPartners[msg.sender]);
        
        uint256 tokens = safeMul(amount, exchangeRates[partner]);
        require(tokens <= availableSupply);
        
        balances[recipient] = safeAdd(balances[recipient], tokens);
        availableSupply = safeSub(availableSupply, tokens);
        circulatingSupply = safeAdd(circulatingSupply, tokens);
        Exchanged(partner, recipient, tokens);
        Transfer(this, recipient, tokens);
    }
    
    function setTokensPerEth(uint256 newRate) public {
        require((msg.sender == owner || msg.sender == devAddress) && (tokensPerEth >= 0));
        tokensPerEth = newRate;
    }
    
    function withdraw(address recipient, uint256 amount) public {
        require(msg.sender == owner);
        require(amount <= address(this).balance);
        recipient.transfer(amount);
    }
    
    function balanceOf(address account) public constant returns (uint256) {
        return balances[account];
    }
    
    function setDevAddress(address newDevAddress) public {
        require(msg.sender == owner);
        devAddress = newDevAddress;
    }
    
    function setFeeAddress(address newFeeAddress) public {
        require(msg.sender == devAddress || msg.sender == owner);
        feeAddress = newFeeAddress;
    }
    
    function setOwner(address newOwner) public {
        require(msg.sender == devAddress || msg.sender == owner);
        owner = newOwner;
    }
    
    function toggleAcceptEth() public {
        require((msg.sender == devAddress || msg.sender == owner));
        if (!acceptEth) {
            acceptEth = true;
        } else {
            acceptEth = false;
        }
    }
    
    function toggleFreezeTokens() public {
        require((msg.sender == devAddress || msg.sender == owner));
        if (!freezeTokensEnabled) {
            freezeTokensEnabled = true;
        } else {
            freezeTokensEnabled = false;
        }
    }
    
    function defrostFrozenTokens() public {
        require((msg.sender == devAddress || msg.sender == owner));
        availableSupply = safeAdd(availableSupply, frozenTokens);
        frozenTokens = 0;
    }
    
    function registerPartner(address partner, uint256 rate) public {
        require((msg.sender == devAddress || msg.sender == owner));
        uint codeLength;
        assembly {
            codeLength := extcodesize(partner)
        }
        require(codeLength > 0);
        exchangeRates[partner] = rate;
    }
    
    function enablePartner(address partner) public {
        require((msg.sender == devAddress || msg.sender == owner));
        registeredPartners[partner] = true;
    }
    
    function disablePartner(address partner) public {
        require((msg.sender == devAddress || msg.sender == owner));
        registeredPartners[partner] = false;
    }
    
    function isPartner(address partner) public constant returns (bool) {
        return registeredPartners[partner];
    }
    
    function getExchangeRate(address partner) public returns (uint256) {
        return exchangeRates[partner];
    }
    
    function getAvailableSupply() public constant returns (uint256) {
        return availableSupply;
    }
    
    function getLifeValue() public constant returns (uint256) {
        return lifeValue;
    }
    
    function getCollectedFees() public constant returns (uint256) {
        require((msg.sender == owner || msg.sender == devAddress));
        return collectedFees;
    }
    
    function getCirculatingSupply() public constant returns (uint256) {
        return circulatingSupply;
    }
    
    function toggleFees() public {
        require((msg.sender == devAddress || msg.sender == owner));
        if (feesEnabled) {
            feesEnabled = false;
        } else {
            feesEnabled = true;
        }
    }
    
    function setDevFee(uint256 fee) public {
        require((msg.sender == devAddress || msg.sender == owner));
        require((fee > 0) && (fee <= 100));
        devFeePercentage = fee * 100;
    }
    
    function withdrawFees() public {
        require(feesEnabled);
        feeAddress.transfer(collectedFees);
        collectedFees = 0;
    }
    
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }
    
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
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
}
```