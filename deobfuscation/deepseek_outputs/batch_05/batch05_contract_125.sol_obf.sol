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

contract Authorizable is Ownable {
    mapping(address => bool) public authorized;
    
    modifier onlyAuthorized() {
        require(authorized[msg.sender]);
        _;
    }
    
    constructor() internal {
        authorized[msg.sender] = true;
    }
    
    function authorize(address user) public onlyOwner {
        authorized[user] = true;
    }
    
    function deauthorize(address user) public onlyOwner {
        authorized[user] = false;
    }
}

contract WalletController is Authorizable {
    address public defaultSweeper;
    mapping(address => address) public sweepers;
    
    event EthDeposit(address from, address to, uint amount);
    event WalletCreated(address wallet);
    event Sweeped(address from, address to, address token, uint amount);
    
    constructor() public {
        owner = msg.sender;
        defaultSweeper = msg.sender;
    }
    
    function setDefaultSweeper(address sweeper) public {
        defaultSweeper = sweeper;
    }
    
    function createWallet() public onlyAuthorized returns (address) {
        address newWallet = address(new Wallet(this));
        emit WalletCreated(newWallet);
        return newWallet;
    }
    
    function setSweeper(address token, address sweeper) public onlyOwner {
        sweepers[token] = sweeper;
    }
    
    function getSweeper(address token) public view returns (address) {
        address sweeper = sweepers[token];
        if (sweeper == address(0)) {
            sweeper = defaultSweeper;
        }
        return sweeper;
    }
    
    function logEthDeposit(address from, address to, uint amount) public {
        emit EthDeposit(from, to, amount);
    }
    
    function logSweep(address from, address to, address token, uint amount) public {
        emit Sweeped(from, to, token, amount);
    }
}

contract Wallet {
    WalletController private controller;
    
    constructor(address _controller) public {
        controller = WalletController(_controller);
    }
    
    function () public payable {
        controller.logEthDeposit(msg.sender, address(this), msg.value);
    }
    
    function execute(address to, uint value, bytes data) public pure {
        to;
        value;
        data;
    }
    
    function sweep(address token, uint amount) public returns (bool) {
        amount;
        return controller.getSweeper(token).delegatecall(msg.data);
    }
}

contract AbstractSweeper {
    WalletController public controller;
    
    constructor(address _controller) public {
        controller = WalletController(_controller);
    }
    
    function () public {
        revert();
    }
    
    function sweep(address token, uint amount) public returns (bool);
    
    modifier onlyAuthorized() {
        if (!controller.authorized(msg.sender)) revert();
        _;
    }
}

contract DefaultSweeper is AbstractSweeper {
    constructor(address _controller) public AbstractSweeper(_controller) {}
    
    function sweep(address token, uint amount) public onlyAuthorized returns (bool) {
        bool success = false;
        address destination = controller.defaultSweeper();
        
        if (token != address(0)) {
            ERC20 tokenContract = ERC20(token);
            uint balance = tokenContract.balanceOf(this);
            if (amount > balance) {
                return false;
            }
            success = tokenContract.transfer(destination, amount);
        } else {
            uint value = amount;
            if (value > address(this).balance) {
                return false;
            }
            success = destination.send(value);
        }
        
        if (success) {
            controller.logSweep(this, destination, token, amount);
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