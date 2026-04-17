```solidity
pragma solidity 0.4.25;

contract Ownable {
    address public owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor() internal {
        owner = msg.sender;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract CasinoAuthorized is Ownable {
    mapping(address => bool) public authorized;
    bool public casinoAuthorized;
    
    modifier onlyAuthorized() {
        require(authorized[msg.sender] || (casinoAuthorized && owner == msg.sender));
        _;
    }
    
    constructor(address _owner) internal {
        authorized[msg.sender] = true;
        owner = _owner;
        casinoAuthorized = true;
    }
    
    function authorize(address user) public onlyOwner {
        authorized[user] = true;
    }
    
    function deauthorize(address user) public onlyOwner {
        authorized[user] = false;
    }
    
    function enableCasino() public onlyOwner {
        casinoAuthorized = true;
    }
    
    function disableCasino() public onlyOwner {
        casinoAuthorized = false;
    }
    
    function setOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract WalletFactory is CasinoAuthorized {
    address public destination;
    address public defaultSweeper = address(this);
    
    mapping(address => address) public sweeperOf;
    mapping(address => bool) public isWallet;
    
    event EthDeposit(address from, address to, uint amount);
    event WalletCreated(address wallet);
    event Sweeped(address from, address to, address token, uint amount);
    
    modifier onlyWallet() {
        require(isWallet[msg.sender]);
        _;
    }
    
    constructor(address _owner) public CasinoAuthorized(_owner) {
        owner = msg.sender;
        destination = msg.sender;
    }
    
    function setDestination(address newDestination) public onlyOwner {
        destination = newDestination;
    }
    
    function createWallet() public {
        address wallet = address(new Wallet(this));
        isWallet[wallet] = true;
        emit WalletCreated(wallet);
    }
    
    function createWallets(uint count) public {
        for (uint i = 0; i < count; i++) {
            createWallet();
        }
    }
    
    function setSweeper(address token, address sweeper) public onlyOwner {
        sweeperOf[token] = sweeper;
    }
    
    function enableSweep() public onlyAuthorized {
        sweepEnabled = true;
    }
    
    function disableSweep() public onlyOwner {
        sweepEnabled = false;
    }
    
    function sweeperOf(address token) public view returns (address) {
        address sweeper = sweeperOf[token];
        if (sweeper == address(0)) {
            sweeper = defaultSweeper;
        }
        return sweeper;
    }
    
    function logEthDeposit(address from, address to, uint amount) public onlyWallet {
        emit EthDeposit(from, to, amount);
    }
    
    function logSweep(address from, address to, address token, uint amount) public onlyWallet {
        emit Sweeped(from, to, token, amount);
    }
    
    bool public sweepEnabled;
}

contract Wallet {
    WalletFactory private factory;
    
    constructor(address factoryAddress) public {
        factory = WalletFactory(factoryAddress);
    }
    
    function() public payable {
        factory.logEthDeposit(msg.sender, address(this), msg.value);
    }
    
    function execute(address to, uint value, bytes data) public pure {
        to;
        value;
        data;
    }
    
    function sweep(address token, uint amount) public returns (bool) {
        amount;
        return factory.sweeperOf(token).delegatecall(msg.data);
    }
}

contract Sweeper {
    WalletFactory public factory;
    
    constructor(address factoryAddress) public {
        factory = WalletFactory(factoryAddress);
    }
    
    function() public {
        revert();
    }
    
    function sweep(address token, uint amount) public returns (bool);
    
    modifier onlyAuthorized() {
        if (!factory.authorized(msg.sender)) revert();
        if (factory.sweepEnabled()) revert();
        _;
    }
}

contract EthSweeper is Sweeper {
    constructor(address factoryAddress) public Sweeper(factoryAddress) {}
    
    function sweep(address token, uint amount) public onlyAuthorized returns (bool) {
        bool success = false;
        address destination = factory.destination();
        
        if (token != address(0)) {
            ERC20 tokenContract = ERC20(token);
            uint balance = tokenContract.balanceOf(this);
            if (amount > balance) {
                return false;
            }
            success = tokenContract.transfer(destination, amount);
        } else {
            uint ethAmount = amount;
            if (ethAmount > address(this).balance) {
                return false;
            }
            success = destination.send(ethAmount);
        }
        
        if (success) {
            factory.logSweep(this, destination, token, amount);
        }
        return success;
    }
}

contract ERC20 {
    function balanceOf(address who) public pure returns (uint) {
        who;
        return 0;
    }
    
    function transfer(address to, uint value) public pure returns (bool) {
        to;
        value;
        return false;
    }
}
```