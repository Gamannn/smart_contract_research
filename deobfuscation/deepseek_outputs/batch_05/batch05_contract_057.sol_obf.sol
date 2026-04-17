```solidity
pragma solidity ^0.4.21;

contract ERC20Interface {
    function transfer(address to, uint256 value) public;
}

contract Token {
    string public name = "CoEval";
    string public symbol = "CoEval";
    uint8 public decimals = 18;
    address public premineAddress = 0x76D05E325973D7693Bb854ED258431aC7DBBeDc3;
    
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) public isExchangePartner;
    mapping (address => uint256) public exchangeRate;
    
    address public owner;
    address public devAddress;
    address public devFeesAddress;
    
    uint256 public totalSupply;
    uint256 public circulatingSupply;
    uint256 public frozenTokens;
    uint256 public devFees;
    uint256 public lifeValue;
    uint256 public payFees;
    uint256 public fees;
    
    bool public devFeesEnabled;
    bool public receiveEthEnabled;
    bool public freezeTokensEnabled;
    bool public coldStorage;
    
    uint256 public tokenPerEth;
    address public WETH;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Exchanged(address indexed from, address indexed to, uint256 value);
    
    constructor() public {
        owner = msg.sender;
        initializePremine();
    }
    
    function initializePremine() internal {
        totalSupply = 750000000000000000000000000;
        circulatingSupply = 32664750000000000000000;
        balanceOf[premineAddress] = circulatingSupply;
        Transfer(address(0), premineAddress, circulatingSupply);
    }
    
    function transfer(address to, uint256 value) public {
        require(balanceOf[msg.sender] >= value);
        
        if(to == address(this)) {
            totalSupply = safeSub(totalSupply, value);
            balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], value);
            Transfer(msg.sender, to, value);
        } else {
            uint codeSize;
            assembly { codeSize := extcodesize(to) }
            
            if(codeSize != 0) {
                requestTokensFromExchange(to, value);
            } else {
                balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], value);
                balanceOf[to] = safeAdd(balanceOf[to], value);
                Transfer(msg.sender, to, value);
            }
        }
    }
    
    function transferFrom(address from, address to, uint256 value) public {
        require(balanceOf[from] >= value);
        
        if(to == address(this)) {
            totalSupply = safeSub(totalSupply, value);
            balanceOf[from] = safeSub(balanceOf[from], value);
            Transfer(from, to, value);
        } else {
            uint codeSize;
            assembly { codeSize := extcodesize(to) }
            
            if(codeSize != 0) {
                requestTokensFromExchange(to, value);
            } else {
                balanceOf[from] = safeSub(balanceOf[from], value);
                balanceOf[to] = safeAdd(balanceOf[to], value);
                Transfer(from, to, value);
            }
        }
    }
    
    function requestTokensFromExchange(address exchange, uint256 value) internal {
        require(isExchangePartner[exchange]);
        require(requestTokensFromExchangeContract(exchange, address(this), msg.sender, value));
        
        if(coldStorage) {
            frozenTokens = safeAdd(frozenTokens, value);
        } else {
            totalSupply = safeAdd(totalSupply, value);
        }
        
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], value);
        circulatingSupply = safeSub(circulatingSupply, value);
        Exchanged(msg.sender, exchange, value);
        Transfer(msg.sender, address(this), value);
    }
    
    function () payable public {
        require((msg.value > 0) && (receiveEthEnabled));
        uint256 tokensToSend = safeDiv(safeMul(tokenPerEth, msg.value), 1 ether);
        require(totalSupply >= tokensToSend);
        
        totalSupply = safeSub(totalSupply, tokensToSend);
        balanceOf[msg.sender] = safeAdd(balanceOf[msg.sender], tokensToSend);
        circulatingSupply = safeAdd(circulatingSupply, tokensToSend);
        lifeValue = safeAdd(lifeValue, msg.value);
        Transfer(address(this), msg.sender, tokensToSend);
        
        payFees = safeAdd(payFees, msg.value);
        
        if(devFeesEnabled) {
            if(!devFeesEnabled) {
                if(lifeValue >= payFees) {
                    devFeesEnabled = true;
                }
            }
            
            if(devFeesEnabled) {
                devFees = safeAdd(devFees, ((msg.value * fees) / 10000));
            }
        }
    }
    
    function requestTokensFromExchangeContract(address tokenContract, address from, address to, uint256 value) internal returns (bool) {
        ERC20Interface exchange = ERC20Interface(tokenContract);
        exchange.transfer(from, to, value);
        return true;
    }
    
    function changeTokenPerEth(uint256 newRate) public {
        require((msg.sender == owner) || (msg.sender == devAddress) && (newRate >= 0));
        tokenPerEth = newRate;
    }
    
    function safeWithdrawal(address to, uint256 value) public {
        require((msg.sender == owner));
        uint256 valueInWei = safeDiv(safeMul(value, 1 ether), tokenPerEth);
        
        if(devFeesEnabled) {
            if(devFeesEnabled) {
                WETH.transferFrom(devFees);
                devFees = 0;
            }
        }
        
        require(valueInWei <= this.balance);
        to.transferFrom(valueInWei);
    }
    
    function balanceOf(address account) public constant returns (uint256 balance) {
        return balanceOf[account];
    }
    
    function changeOwner(address newOwner) public {
        require(msg.sender == owner);
        devAddress = newOwner;
    }
    
    function transferOwnership(address newOwner) public {
        require(msg.sender == devAddress);
        owner = newOwner;
    }
    
    function changeDevFeesAddress(address newAddress) public {
        require(msg.sender == devAddress);
        devFeesAddress = newAddress;
    }
    
    function toggleReceiveEth() public {
        require((msg.sender == devAddress) || (msg.sender == owner));
        if(!receiveEthEnabled) {
            receiveEthEnabled = true;
        } else {
            receiveEthEnabled = false;
        }
    }
    
    function toggleFreezeTokens() public {
        require((msg.sender == devAddress) || (msg.sender == owner));
        if(freezeTokensEnabled) {
            freezeTokensEnabled = true;
        } else {
            coldStorage = false;
        }
    }
    
    function destroyTokens(uint256 tokensToDestroy) public {
        require((msg.sender == owner));
        totalSupply = safeAdd(totalSupply, tokensToDestroy);
        frozenTokens = 0;
    }
    
    function addExchangePartnerAddressAndRate(address partner, uint256 rate) public {
        require((msg.sender == devAddress) || (msg.sender == owner));
        uint codeSize;
        assembly { codeSize := extcodesize(partner) }
        require(codeSize > 0);
        exchangeRate[partner] = rate;
    }
    
    function enableExchangePartner(address partner) public {
        require((msg.sender == devAddress) || (msg.sender == owner));
        isExchangePartner[partner] = true;
    }
    
    function disableExchangePartner(address partner) public {
        require((msg.sender == devAddress) || (msg.sender == owner));
        isExchangePartner[partner] = false;
    }
    
    function isExchange(address tokenContract) public constant returns (bool) {
        return isExchangePartner[tokenContract];
    }
    
    function exchangeRateOf(address tokenContract) public constant returns (uint256) {
        return exchangeRate[tokenContract];
    }
    
    function totalSupply() public constant returns (uint256) {
        return totalSupply;
    }
    
    function ownerBalance() public constant returns (uint256) {
        return balanceOf[owner];
    }
    
    function lifeValue() public constant returns (uint256) {
        require((msg.sender == owner) || (msg.sender == devAddress));
        return lifeValue;
    }
    
    function circulatingSupply() public constant returns (uint256) {
        return circulatingSupply;
    }
    
    function toggleDevFees() public {
        require((msg.sender == devAddress) || (msg.sender == owner));
        if(devFeesEnabled) {
            devFeesEnabled = false;
        } else {
            devFeesEnabled = true;
        }
    }
    
    function changeFees(uint256 newFees) public {
        require((msg.sender == devAddress) || (msg.sender == owner));
        require((newFees >= 0) && (newFees < fees * 100));
        fees = newFees;
    }
    
    function withdrawDevFees() public {
        require(devFeesEnabled);
        WETH.transferFrom(devFees);
        devFees = 0;
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