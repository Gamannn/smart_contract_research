pragma solidity ^0.4.25;

contract Token {
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    uint256 public totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;
    address public owner;
    address public factory;
    uint256 public initCount;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() public {
        initCount = 0;
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balances[msg.sender] >= value);
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        uint256 allowance = allowed[from][msg.sender];
        require(balances[from] >= value && allowance >= value);
        balances[to] += value;
        balances[from] -= value;
        if (allowance < (2**256 - 1)) {
            allowed[from][msg.sender] -= value;
        }
        emit Transfer(from, to, value);
        return true;
    }

    function balanceOf(address who) public constant returns (uint256 balance) {
        return balances[who];
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public constant returns (uint256 remaining) {
        return allowed[owner][spender];
    }

    function burn(uint value) public returns (uint256 remaining) {
        if (balances[msg.sender] >= value) {
            if (totalSupply >= value) {
                transfer(address(0), value);
                balances[address(0)] -= value;
                totalSupply -= value;
            }
        }
        return balances[msg.sender];
    }

    function approveAndCall(address spender, uint256 value, bytes extraData) public returns (bool success) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        require(spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, value, this, extraData));
        return true;
    }

    function init(uint256 initialAmount, string tokenName, uint8 decimalUnits, string tokenSymbol, address tokenOwner) public returns (bool) {
        if (initCount > 0) revert();
        balances[tokenOwner] = initialAmount;
        totalSupply = initialAmount;
        name = tokenName;
        decimals = decimalUnits;
        symbol = tokenSymbol;
        owner = tokenOwner;
        factory = msg.sender;
        initCount = 1;
        return true;
    }

    function initFactory(uint256 initialAmount, string tokenName, uint8 decimalUnits, string tokenSymbol, address tokenOwner, address feeReceiver) public returns (bool) {
        if (initCount > 0) revert();
        Token floodToken = Token(address(0x63030f02d4B18acB558750db1Dc9A2F3961531eE));
        uint256 feePercent = floodToken.getFeePercentage();
        if (initialAmount > 1000) {
            balances[tokenOwner] = initialAmount - ((initialAmount / 1000) * feePercent);
            balances[feeReceiver] = (initialAmount / 1000) * feePercent;
        } else {
            balances[tokenOwner] = initialAmount;
        }
        totalSupply = initialAmount;
        name = tokenName;
        decimals = decimalUnits;
        symbol = tokenSymbol;
        owner = tokenOwner;
        factory = msg.sender;
        initCount = 1;
        return true;
    }

    function getFeePercentage() public constant returns (uint256) {
        return 0;
    }
}

contract Factory {
    address public owner;
    bool public giftEnabled;
    uint256 public giftAmount;
    Token public floodToken;
    uint256 public totalFreeCoins;
    mapping(string => bool) public nameUsed;
    mapping(string => bool) public symbolUsed;
    mapping(string => address) public nameToAddress;
    mapping(string => address) public symbolToAddress;
    mapping(address => string) public addressToName;
    mapping(address => string) public addressToSymbol;
    mapping(address => bool) public permissions;
    mapping(address => address[]) public userTokens;
    mapping(address => address[]) public creatorTokens;
    address[] public allTokens;
    uint256 public tokenCount;
    uint256 public feePercentage;
    uint256 public creationFee;

    constructor() public {
        owner = msg.sender;
        permissions[msg.sender] = true;
    }

    function setCreationFee(uint256 fee) public {
        if (msg.sender != owner) revert();
        creationFee = fee;
    }

    function setFeePercentage(uint256 percent) public {
        if (msg.sender != owner) revert();
        feePercentage = percent;
    }

    function setFloodToken(address floodTokenAddress) public {
        if (msg.sender != owner) revert();
        floodToken = Token(floodTokenAddress);
    }

    function enableGift(bool enable) public {
        if (msg.sender != owner) revert();
        giftEnabled = enable;
    }

    function setGiftAmount(uint amount) public {
        if (msg.sender != owner) revert();
        giftAmount = amount;
    }

    function setNameSymbol(string name, string symbol, bool enabled) public {
        if (!permissions[msg.sender]) revert();
        nameUsed[name] = enabled;
        symbolUsed[symbol] = enabled;
    }

    function removeToken(address tokenAddress) public {
        if (!permissions[msg.sender]) revert();
        nameUsed[addressToName[tokenAddress]] = false;
        nameToAddress[addressToName[tokenAddress]] = address(0);
        addressToName[tokenAddress] = "";
        symbolUsed[addressToSymbol[tokenAddress]] = false;
        symbolToAddress[addressToSymbol[tokenAddress]] = address(0);
        addressToSymbol[tokenAddress] = "";
    }

    function createToken(address tokenAddress, address creator, string name, string symbol, bool isFree) public returns (bool) {
        if ((!permissions[msg.sender]) || (nameUsed[name]) || (symbolUsed[symbol])) revert();
        if (isFree) {
            creatorTokens[creator].push(address(tokenAddress));
            totalFreeCoins++;
        } else {
            creatorTokens[creator].push(address(tokenAddress));
            allTokens.push(address(tokenAddress));
            nameUsed[name] = true;
            addressToName[tokenAddress] = name;
            nameToAddress[name] = tokenAddress;
            symbolUsed[symbol] = true;
            addressToSymbol[tokenAddress] = symbol;
            symbolToAddress[symbol] = tokenAddress;
            if (giftEnabled) {
                floodToken.transfer(creator, giftAmount);
            }
        }
        userTokens[msg.sender].push(tokenAddress);
        tokenCount++;
        return true;
    }

    function changeOwner(address newOwner) public {
        if (msg.sender != owner) revert();
        owner = newOwner;
    }

    function setPermission(address user, bool enabled) public {
        if (msg.sender != owner) revert();
        permissions[user] = enabled;
    }

    function getCreatorTokens(address creator, uint index) public constant returns (address, uint) {
        return (creatorTokens[creator][index], creatorTokens[creator].length);
    }

    function getUserTokens(address user, uint index) public constant returns (address, uint) {
        return (userTokens[user][index], userTokens[user].length);
    }

    function getAllTokens(uint index) public constant returns (address, uint) {
        return (allTokens[index], allTokens.length);
    }

    function getTokenInfo(address token) public constant returns (string, string) {
        return (addressToName[token], addressToSymbol[token]);
    }

    function isNameUsed(string name) public constant returns (bool) {
        return nameUsed[name];
    }

    function isSymbolUsed(string symbol) public constant returns (bool) {
        return symbolUsed[symbol];
    }

    function getNameAddress(string name) public constant returns (address) {
        return nameToAddress[name];
    }

    function getSymbolAddress(string symbol) public constant returns (address) {
        return symbolToAddress[symbol];
    }
}

contract Wallet {
    address public owner;
    Factory public factory;
    address public feeReceiver;

    constructor() public {
        owner = msg.sender;
    }

    function changeOwner(address newOwner) public {
        if (msg.sender != owner) revert();
        owner = newOwner;
    }

    function setFactory(address factoryAddress) public {
        if (msg.sender != owner) revert();
        factory = Factory(factoryAddress);
    }

    function createToken(uint256 initialAmount, string name, uint8 decimalUnits, string symbol) public payable {
        Token newToken = new Token();
        uint256 fee = factory.creationFee();
        if (msg.value >= fee) {
            feeReceiver.transfer(msg.value);
            if (!newToken.initFactory(initialAmount, name, decimalUnits, symbol, msg.sender, feeReceiver)) revert();
            if (!factory.createToken(address(newToken), msg.sender, name, symbol, false)) revert();
        } else {
            if (!newToken.init(initialAmount, name, decimalUnits, symbol, msg.sender)) revert();
            if (!factory.createToken(address(newToken), msg.sender, name, symbol, true)) revert();
        }
    }
}