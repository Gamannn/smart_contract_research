pragma solidity 0.4.25;

contract Ownable {
    address private owner;

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

    function authorize(address account) public onlyOwner {
        authorized[account] = true;
    }

    function deauthorize(address account) public onlyOwner {
        authorized[account] = false;
    }
}

contract WalletController is Authorizable {
    address public defaultSweeper;
    mapping(address => address) public walletToSweeper;

    event EthDeposit(address indexed from, address indexed to, uint amount);
    event WalletCreated(address indexed wallet);
    event Sweeped(address indexed from, address indexed to, address indexed wallet, uint amount);

    constructor() public {
        defaultSweeper = msg.sender;
    }

    function setDefaultSweeper(address newSweeper) public {
        defaultSweeper = newSweeper;
    }

    function createWallet() public onlyAuthorized {
        address newWallet = address(new Wallet(this));
        emit WalletCreated(newWallet);
    }

    function setWalletSweeper(address wallet, address sweeper) public onlyOwner {
        walletToSweeper[wallet] = sweeper;
    }

    function getWalletSweeper(address wallet) public view returns (address) {
        address sweeper = walletToSweeper[wallet];
        if (sweeper == address(0)) {
            sweeper = defaultSweeper;
        }
        return sweeper;
    }

    function logEthDeposit(address from, address to, uint amount) public {
        emit EthDeposit(from, to, amount);
    }

    function logSweep(address from, address to, address wallet, uint amount) public {
        emit Sweeped(from, to, wallet, amount);
    }
}

contract Wallet {
    WalletController private controller;

    constructor(address controllerAddress) public {
        controller = WalletController(controllerAddress);
    }

    function() public payable {
        controller.logEthDeposit(msg.sender, address(this), msg.value);
    }

    function executeTransaction(address to, uint value, bytes data) public pure {
        // Placeholder function to match the original contract's structure
    }

    function sweep(address to, uint amount) public returns (bool) {
        return controller.getWalletSweeper(to).delegatecall(msg.data);
    }
}

contract Sweeper {
    WalletController public controller;

    constructor(address controllerAddress) public {
        controller = WalletController(controllerAddress);
    }

    function() public {
        revert();
    }

    function sweep(address to, uint amount) public returns (bool);

    modifier onlyAuthorized() {
        if (!controller.authorized(msg.sender)) revert();
        _;
    }
}

contract DefaultSweeper is Sweeper {
    constructor(address controllerAddress) public Sweeper(controllerAddress) {}

    function sweep(address to, uint amount) public onlyAuthorized returns (bool) {
        bool success = false;
        address sweeper = controller.defaultSweeper();

        if (to != address(0)) {
            Wallet wallet = Wallet(to);
            uint balance = amount;
            if (balance > wallet.balance) {
                return false;
            }
            success = wallet.executeTransaction(sweeper, balance, "");
        } else {
            uint balance = amount;
            if (balance > address(this).balance) {
                return false;
            }
            success = sweeper.send(balance);
        }

        if (success) {
            controller.logSweep(this, to, to, amount);
        }
        return success;
    }
}

contract WalletInterface {
    function balance(address account) public pure returns (uint) {
        return 0;
    }

    function executeTransaction(address to, uint value, bytes data) public pure returns (bool) {
        return false;
    }
}

function getIntFunc(uint256 index) internal view returns (uint256) {
    return _integer_constant[index];
}

function getBoolFunc(uint256 index) internal view returns (bool) {
    return _bool_constant[index];
}

uint256[] public _integer_constant = [0];
bool[] public _bool_constant = [true, false];