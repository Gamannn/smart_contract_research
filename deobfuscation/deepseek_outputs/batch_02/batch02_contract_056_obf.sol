pragma solidity ^0.4.24;

contract MultiSigWallet {
    uint constant public MAX_OWNER_COUNT = 50;

    event Confirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint required);

    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] public owners;
    uint public required;
    uint public transactionCount;

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }

    modifier onlyWallet() {
        require(msg.sender == address(this));
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner]);
        _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner]);
        _;
    }

    modifier transactionExists(uint transactionId) {
        require(transactions[transactionId].destination != 0);
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        require(confirmations[transactionId][owner]);
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        require(!confirmations[transactionId][owner]);
        _;
    }

    modifier notExecuted(uint transactionId) {
        require(!transactions[transactionId].executed);
        _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        require(ownerCount <= MAX_OWNER_COUNT
            && _required <= ownerCount
            && _required != 0
            && ownerCount != 0);
        _;
    }

    function() public payable {
        if (msg.value > 0)
            emit Deposit(msg.sender, msg.value);
    }

    constructor(address[] _owners, uint _required)
        public
        validRequirement(_owners.length, _required)
    {
        for (uint i = 0; i < _owners.length; i++) {
            require(!isOwner[_owners[i]] && _owners[i] != 0);
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }

    function addOwner(address owner)
        public
        onlyWallet
        ownerDoesNotExist(owner)
        validRequirement(owners.length + 1, required)
    {
        isOwner[owner] = true;
        owners.push(owner);
        emit OwnerAddition(owner);
    }

    function removeOwner(address owner)
        public
        onlyWallet
        ownerExists(owner)
    {
        isOwner[owner] = false;
        for (uint i = 0; i < owners.length - 1; i++) {
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        }
        owners.length -= 1;
        if (required > owners.length)
            changeRequirement(owners.length);
        emit OwnerRemoval(owner);
    }

    function replaceOwner(address owner, address newOwner)
        public
        onlyWallet
        ownerExists(owner)
        ownerDoesNotExist(newOwner)
    {
        for (uint i = 0; i < owners.length; i++) {
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        emit OwnerRemoval(owner);
        emit OwnerAddition(newOwner);
    }

    function changeRequirement(uint _required)
        public
        onlyWallet
        validRequirement(owners.length, _required)
    {
        required = _required;
        emit RequirementChange(_required);
    }

    function submitTransaction(address destination, uint value, bytes data)
        public
        returns (uint transactionId)
    {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

    function confirmTransaction(uint transactionId)
        public
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    function revokeConfirmation(uint transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

    function executeTransaction(uint transactionId)
        public
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            transactions[transactionId].executed = true;
            if (transactions[transactionId].destination.call.value(transactions[transactionId].value)(transactions[transactionId].data)) {
                emit Execution(transactionId);
            } else {
                emit ExecutionFailure(transactionId);
                transactions[transactionId].executed = false;
            }
        }
    }

    function isConfirmed(uint transactionId)
        public
        constant
        returns (bool)
    {
        uint count = 0;
        for (uint i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == required)
                return true;
        }
    }

    function addTransaction(address destination, uint value, bytes data)
        internal
        returns (uint transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
        emit Submission(transactionId);
    }

    function getConfirmationCount(uint transactionId)
        public
        constant
        returns (uint count)
    {
        for (uint i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
        }
    }

    function getTransactionCount(bool pending, bool executed)
        public
        constant
        returns (uint count)
    {
        for (uint i = 0; i < transactionCount; i++) {
            if (pending && !transactions[i].executed || executed && transactions[i].executed)
                count += 1;
        }
    }

    function getOwners()
        public
        constant
        returns (address[])
    {
        return owners;
    }

    function getConfirmations(uint transactionId)
        public
        constant
        returns (address[] _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint count = 0;
        uint i;
        for (i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        }
        _confirmations = new address[](count);
        for (i = 0; i < count; i++) {
            _confirmations[i] = confirmationsTemp[i];
        }
    }

    function getTransactionIds(uint from, uint to, bool pending, bool executed)
        public
        constant
        returns (uint[] _transactionIds)
    {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;
        for (i = 0; i < transactionCount; i++) {
            if (pending && !transactions[i].executed || executed && transactions[i].executed) {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        }
        _transactionIds = new uint[](to - from);
        for (i = from; i < to; i++) {
            _transactionIds[i - from] = transactionIdsTemp[i];
        }
    }
}

contract ERC223 {
    function tokenFallback(address from, uint value, bytes data) public returns (bool ok);
    function transfer(address to, uint value, address sender) public returns (bool ok);
    function transfer(address to, uint value, uint fee) public returns (bool ok);
}

contract BasicToken {
    mapping (address => uint256) public balanceOf;
    function burn(address who) public;
}

interface TokenRecipient {
    function receiveApproval(address from, uint256 value, address token, bytes extraData) external;
}

contract NamiCrowdsale {
    using SafeMath for uint256;

    uint public decimals = 18;
    bool public paused = false;
    uint public constant TOKEN_SUPPLY_LIMIT = 1000;
    uint public rate = 0;
    enum Phase { Created, Running, Paused, Migrating, Migrated }
    mapping (address => mapping (address => uint256)) public allowance;
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier onlyCrowdsaleManager() {
        require(msg.sender == crowdsaleManager);
        _;
    }
    modifier onlyWhenNotPaused() {
        require(!paused);
        _;
    }
    modifier onlyEscrow() {
        require(msg.sender == escrow);
        _;
    }

    event LogBuy(address indexed buyer, uint value);
    event LogBurn(address indexed burner, uint value);
    event LogPhaseSwitch(Phase newPhase);
    event LogMigrate(address from, address to, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    address public owner;
    address public crowdsaleManager;
    address public escrow;
    address public wallet;
    address public presaleToken;
    address public token;
    uint256 public totalSupply;
    uint public rateOverride;
    uint public constant MAX_RATE = 1000;
    bool public pausedState;
    uint256 public decimalsValue;
    string public name;
    string public symbol;
    uint public transactionCount;
    uint public required;
    uint public MAX_OWNER_COUNT;

    function transferInternal(address from, address to, uint value) internal {
        require(to != 0x0);
        require(balanceOf[from] >= value);
        require(balanceOf[to] + value > balanceOf[to]);
        uint previousBalances = balanceOf[from] + balanceOf[to];
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
        assert(balanceOf[from] + balanceOf[to] == previousBalances);
    }

    function transfer(address to, uint256 value) public onlyCrowdsaleManager {
        transferInternal(msg.sender, to, value);
    }

    function transferFrom(address from, address to, uint256 value) public onlyWhenNotPaused returns (bool ok) {
        require(value <= allowance[from][msg.sender]);
        allowance[from][msg.sender] -= value;
        transferInternal(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public onlyWhenNotPaused returns (bool ok) {
        allowance[msg.sender][spender] = value;
        return true;
    }

    function approveAndCall(address spender, uint256 value, bytes extraData) public onlyWhenNotPaused returns (bool ok) {
        TokenRecipient recipient = TokenRecipient(spender);
        if (approve(spender, value)) {
            recipient.receiveApproval(msg.sender, value, this, extraData);
            return true;
        }
    }

    function togglePause() public onlyCrowdsaleManager {
        paused = !paused;
    }

    function setOwner(address newOwner) public onlyEscrow {
        require(newOwner != 0x0);
        owner = newOwner;
    }

    function setRate(uint _rate) public onlyCrowdsaleManager {
        rate = _rate;
    }

    function setWallet(address newWallet) public onlyCrowdsaleManager {
        require(newWallet != 0x0);
        wallet = newWallet;
    }

    function getRate() public view returns (uint currentRate) {
        if (now < 1517443200) {
            return 3450;
        } else if (1517443200 < now && now <= 1518048000) {
            return 2400;
        } else if (1518048000 < now && now <= 1518652800) {
            return 2300;
        } else if (1518652800 < now && now <= 1519257600) {
            return 2200;
        } else if (1519257600 < now && now <= 1519862400) {
            return 2100;
        } else if (1519862400 < now && now <= 1520467200) {
            return 2000;
        } else if (1520467200 < now && now <= 1521072000) {
            return 1900;
        } else if (1521072000 < now && now <= 1521676800) {
            return 1800;
        } else if (1521676800 < now && now <= 1522281600) {
            return 1700;
        } else {
            return rate;
        }
    }

    function() public payable {
        buy();
    }

    function buy() payable public {
        require(now <= 1522281600);
        require(totalSupply < TOKEN_SUPPLY_LIMIT);
        require(msg.value != 0);
        uint tokens = msg.value * getRate();
        require(totalSupply + tokens < TOKEN_SUPPLY_LIMIT);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(tokens);
        totalSupply = totalSupply.add(tokens);
        emit LogBuy(msg.sender, tokens);
        emit Transfer(this, msg.sender, tokens);
    }

    function migrate(address holder) public onlyOwner {
        require(phase == Phase.Migrating);
        uint amount = balanceOf[holder];
        require(amount != 0);
        balanceOf[holder] = 0;
        totalSupply -= amount;
        emit LogBurn(holder, amount);
        emit Transfer(holder, owner, amount);
        if (totalSupply == 0) {
            phase = Phase.Migrated;
            emit LogPhaseSwitch(Phase.Migrated);
        }
    }

    function setPhase(Phase newPhase) public onlyCrowdsaleManager {
        bool validPhase = (phase == Phase.Created && newPhase == Phase.Running) || (phase == Phase.Running && newPhase == Phase.Paused) || ((phase == Phase.Running || phase == Phase.Paused) && newPhase == Phase.Migrating && owner != 0x0) || (phase == Phase.Paused && newPhase == Phase.Running) || (phase == Phase.Migrating && newPhase == Phase.Migrated && totalSupply == 0);
        require(validPhase);
        phase = newPhase;
        emit LogPhaseSwitch(newPhase);
    }

    function withdrawEther() public onlyCrowdsaleManager {
        require(escrow != 0x0);
        if (address(this).balance > 0) {
            escrow.transfer(address(this).balance);
        }
    }

    function withdrawTo(address recipient, uint amount) public onlyEscrow {
        MultiSigWallet multiSigWallet = MultiSigWallet(escrow);
        if (multiSigWallet.isOwner(recipient)) {
            recipient.transfer(amount);
        }
    }

    function setCrowdsaleManager(address newManager) public onlyCrowdsaleManager {
        require(phase != Phase.Migrating);
        crowdsaleManager = newManager;
    }

    function migrateInternal(address from, address to) internal {
        BasicToken presaleTokenContract = BasicToken(presaleToken);
        uint256 amount = presaleTokenContract.balanceOf(from);
        require(amount > 0);
        presaleTokenContract.burn(from);
        balanceOf[to] = balanceOf[to].add(amount);
        totalSupply = totalSupply.add(amount);
        emit LogMigrate(from, to, amount);
        emit Transfer(this, to, amount);
    }

    function migrateFrom(address from, address to) public onlyCrowdsaleManager {
        migrateInternal(from, to);
    }

    function migrate() public {
        migrateInternal(msg.sender, msg.sender);
    }

    event TransferToBuyer(address indexed from, address indexed to, uint value, address indexed seller);
    event TransferToExchange(address indexed from, address indexed to, uint value, uint fee);

    function transferToExchange(address to, uint value, uint fee) public {
        uint codeSize;
        assembly { codeSize := extcodesize(to) }
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(msg.sender, to, value);
        if (codeSize > 0) {
            ERC223 receiver = ERC223(to);
            receiver.transfer(msg.sender, value, fee);
            emit TransferToExchange(msg.sender, to, value, fee);
        }
    }

    function transferToBuyer(address to, uint value, address seller) public {
        uint codeSize;
        assembly { codeSize := extcodesize(to) }
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(msg.sender, to, value);
        if (codeSize > 0) {
            ERC223 receiver = ERC223(to);
            receiver.transfer(msg.sender, value, seller);
            emit TransferToBuyer(msg.sender, to, value, seller);
        }
    }
}

library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        uint c = a / b;
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

contract NamiMarket {
    using SafeMath for uint256;

    constructor(address _owner, address _wallet) public {
        owner = _owner;
        wallet = _wallet;
    }

    address public escrow;
    address public wallet;
    bool public paused;

    mapping(address => bool) public controllers;

    event Deposit(address indexed sender, uint value, uint time);
    event Withdraw(address indexed sender, uint value, uint time);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyWallet {
        require(msg.sender == wallet);
        _;
    }

    modifier onlyEscrow {
        require(msg.sender == escrow);
        _;
    }

    modifier onlyController {
        require(controllers[msg.sender] == true);
        _;
    }

    uint public minWithdraw;
    uint public maxWithdraw;

    function setOwner(address newOwner) public onlyOwner {
        require(newOwner != 0x0);
        owner = newOwner;
    }

    function togglePause() public onlyOwner {
        paused = !paused;
    }

    function setMinWithdraw(uint _min) public onlyOwner {
        require(_min != 0);
        minWithdraw = _min;
    }

    function setMaxWithdraw(uint _max) public onlyOwner {
        require(_max != 0);
        maxWithdraw = _max;
    }

    function withdrawEther(uint amount, address to) public onlyOwner {
        require(escrow != address(0x0));
        to.transfer(amount);
    }

    function withdrawToken(uint amount) public onlyOwner {
        require(escrow != address(0x0));
        BasicToken tokenContract = BasicToken(wallet);
        if (tokenContract.balanceOf(address(this)) > 0) {
            tokenContract.transfer(escrow, amount);
        }
    }

    function addController(address newController) public onlyOwner {
        require(!controllers[newController]);
        controllers[newController] = true;
    }

    function removeController(address controller) public onlyOwner {
        require(controllers[controller]);
        controllers[controller] = false;
    }

    string public name = "Nami Market";

    function deposit() public payable {
        require(maxWithdraw > 0);
        emit Deposit(msg.sender, msg.value, now);
    }

    function() public payable {
        deposit();
    }

    function withdraw(uint amount) public onlyController {
        require(to != address(0x0) && amount != 0);
        require(amount >= minWithdraw && amount <= maxWithdraw);
        if (address(this).balance > 0) {
            to.transfer(amount);
        }
    }
}

function getIntFunc(uint256 index) internal view returns(uint256){
    return _integer_constant[index];
}

function getStrFunc(uint256 index) internal view returns(string storage){
    return _string_constant[index];
}

function getBoolFunc(uint256 index) internal view returns(bool){
    return _bool_constant[index];
}

uint256[] public _integer_constant = [10, 1000000000, 0, 50, 2200, 1519257600, 2400, 16, 2000, 1522281600, 1519862400, 1000000000000000000, 1517443200, 2300, 1521072000, 1518048000, 1520467200, 1900, 1700, 1, 2100, 1521676800, 3450, 1800, 18];
string[] public _string_constant = ["NAC", "Nami Market", "Nami ICO"];
bool[] public _bool_constant = [true, false];
