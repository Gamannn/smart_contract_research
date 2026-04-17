```solidity
pragma solidity ^0.4.25;

contract Token {
    uint256 public totalSupply;
    string public name;
    uint8 public decimals;
    string public symbol;
    address public owner;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() public {}

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
        if (allowance < uint256(-1)) {
            allowed[from][msg.sender] -= value;
        }
        emit Transfer(from, to, value);
        return true;
    }

    function balanceOf(address owner) public view returns (uint256 balance) {
        return balances[owner];
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256 remaining) {
        return allowed[owner][spender];
    }

    function burn(uint256 value) public returns (uint256 remaining) {
        if (balances[msg.sender] >= value) {
            if (totalSupply >= value) {
                transfer(address(0x0), value);
                totalSupply -= value;
            }
        }
        return balances[msg.sender];
    }

    function approveAndCall(address spender, uint256 value, bytes extraData) public returns (bool success) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        require(spender.call(bytes4(keccak256("receiveApproval(address,uint256,address,bytes)")), msg.sender, value, this, extraData));
        return true;
    }

    function initialize(uint256 initialSupply, string tokenName, uint8 decimalUnits, string tokenSymbol, address centralMinter) public returns (bool) {
        if (totalSupply > 0) revert();
        balances[centralMinter] = initialSupply;
        totalSupply = initialSupply;
        name = tokenName;
        decimals = decimalUnits;
        symbol = tokenSymbol;
        owner = msg.sender;
        return true;
    }
}

contract TokenFactory {
    address public owner;
    mapping(string => bool) tokenExists;
    mapping(string => address) tokenAddress;
    mapping(address => string) tokenName;
    mapping(address => string) tokenSymbol;

    constructor() public {
        owner = msg.sender;
    }

    function createToken(uint256 initialSupply, string tokenName, uint8 decimalUnits, string tokenSymbol, address centralMinter) public returns (bool) {
        if (tokenExists[tokenName] || tokenExists[tokenSymbol]) revert();
        Token newToken = new Token();
        newToken.initialize(initialSupply, tokenName, decimalUnits, tokenSymbol, centralMinter);
        tokenExists[tokenName] = true;
        tokenName[address(newToken)] = tokenName;
        tokenAddress[tokenName] = address(newToken);
        tokenExists[tokenSymbol] = true;
        tokenSymbol[address(newToken)] = tokenSymbol;
        tokenAddress[tokenSymbol] = address(newToken);
        return true;
    }

    function getTokenAddressByName(string tokenName) public view returns (address) {
        return tokenAddress[tokenName];
    }

    function getTokenAddressBySymbol(string tokenSymbol) public view returns (address) {
        return tokenAddress[tokenSymbol];
    }
}

contract TokenManager {
    address public owner;
    TokenFactory public factory;
    address public wallet;

    constructor() public {
        owner = msg.sender;
    }

    function setFactory(address factoryAddress) public {
        if (msg.sender != owner) revert();
        factory = TokenFactory(factoryAddress);
    }

    function createToken(uint256 initialSupply, string tokenName, uint8 decimalUnits, string tokenSymbol) public payable {
        Token newToken = new Token();
        uint256 fee = factory.getFee();
        if (msg.value >= fee) {
            wallet.transfer(msg.value);
            if (!newToken.initialize(initialSupply, tokenName, decimalUnits, tokenSymbol, msg.sender)) revert();
            if (!factory.createToken(initialSupply, tokenName, decimalUnits, tokenSymbol, msg.sender)) revert();
        } else {
            if (!newToken.initialize(initialSupply, tokenName, decimalUnits, tokenSymbol, msg.sender)) revert();
            if (!factory.createToken(initialSupply, tokenName, decimalUnits, tokenSymbol, msg.sender)) revert();
        }
    }
}
```