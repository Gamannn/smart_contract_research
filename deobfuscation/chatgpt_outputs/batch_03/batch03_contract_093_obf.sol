pragma solidity 0.4.25;

contract Owned {
    address public owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor() internal {
        owner = msg.sender;
    }

    function setOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}

contract RequiringAuthorization is Owned {
    mapping(address => bool) public authorized;

    modifier onlyAuthorized {
        require(authorized[msg.sender]);
        _;
    }

    constructor() internal {
        authorized[msg.sender] = true;
    }

    function authorize(address _address) public onlyOwner {
        authorized[_address] = true;
    }

    function deauthorize(address _address) public onlyOwner {
        authorized[_address] = false;
    }
}

contract WalletController is RequiringAuthorization {
    address public destination;
    address public defaultSweeper;
    mapping(address => address) public sweepers;
    bool public halted;

    event EthDeposit(address indexed _from, address indexed _to, uint _amount);
    event WalletCreated(address indexed _address);
    event Sweeped(address indexed _from, address indexed _to, address indexed _token, uint _amount);

    constructor() public {
        owner = msg.sender;
        destination = msg.sender;
    }

    function setDestination(address _destination) public onlyOwner {
        destination = _destination;
    }

    function createWallet() public onlyOwner {
        address wallet = address(new UserWallet(this));
        emit WalletCreated(wallet);
    }

    function createWallets(uint count) public onlyOwner {
        for (uint i = 0; i < count; i++) {
            createWallet();
        }
    }

    function addSweeper(address _token, address _sweeper) public onlyOwner {
        sweepers[_token] = _sweeper;
    }

    function halt() public onlyAuthorized {
        halted = true;
    }

    function start() public onlyOwner {
        halted = false;
    }

    function sweeperOf(address _token) public view returns (address) {
        address sweeper = sweepers[_token];
        if (sweeper == address(0)) {
            sweeper = defaultSweeper;
        }
        return sweeper;
    }

    function logEthDeposit(address _from, address _to, uint _amount) public {
        emit EthDeposit(_from, _to, _amount);
    }

    function logSweep(address _from, address _to, address _token, uint _amount) public {
        emit Sweeped(_from, _to, _token, _amount);
    }
}

contract UserWallet {
    WalletController private controller;

    constructor(address _controller) public {
        controller = WalletController(_controller);
    }

    function() public payable {
        controller.logEthDeposit(msg.sender, address(this), msg.value);
    }

    function tokenFallback(address _from, uint _value, bytes _data) public pure {
        // Placeholder to handle token fallback
    }

    function sweep(address _token, uint _amount) public returns (bool) {
        return controller.sweeperOf(_token).delegatecall(msg.data);
    }
}

contract AbstractSweeper {
    WalletController public controller;

    constructor(address _controller) public {
        controller = WalletController(_controller);
    }

    function() public {
        revert();
    }

    function sweep(address token, uint amount) public returns (bool);

    modifier canSweep() {
        require(controller.authorized(msg.sender));
        require(!controller.halted());
        _;
    }
}

contract DefaultSweeper is AbstractSweeper {
    constructor(address _controller) public AbstractSweeper(_controller) {}

    function sweep(address _token, uint _amount) public canSweep returns (bool) {
        bool success = false;
        address destination = controller.destination();

        if (_token != address(0)) {
            Token token = Token(_token);
            uint amount = _amount;
            if (amount > token.balanceOf(this)) {
                return false;
            }
            success = token.transfer(destination, amount);
        } else {
            uint amountInWei = _amount;
            if (amountInWei > address(this).balance) {
                return false;
            }
            success = destination.send(amountInWei);
        }

        if (success) {
            controller.logSweep(this, destination, _token, _amount);
        }

        return success;
    }
}

contract Token {
    function balanceOf(address a) public pure returns (uint) {
        return 0;
    }

    function transfer(address a, uint val) public pure returns (bool) {
        return false;
    }
}