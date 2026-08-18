pragma solidity ^0.4.24;

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

contract MultiSigWallet {
    uint constant public MAX_OWNER_COUNT = 50;

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

    modifier notNull(address _address) {
        require(_address != 0);
        _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        require(!(ownerCount > MAX_OWNER_COUNT || _required > ownerCount || _required == 0));
        _;
    }

    function() public payable {
        if (msg.value > 0)
            emit Deposit(msg.sender, msg.value);
    }

    constructor(address[] _owners, uint _required) public validRequirement(_owners.length, _required) {
        for (uint i = 0; i < _owners.length; i++) {
            require(!(isOwner[_owners[i]] || _owners[i] == 0));
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }

    function addOwner(address owner) public onlyWallet ownerDoesNotExist(owner) notNull(owner) validRequirement(owners.length + 1, required) {
        isOwner[owner] = true;
        owners.push(owner);
        emit OwnerAddition(owner);
    }

    function removeOwner(address owner) public onlyWallet ownerExists(owner) {
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

    function replaceOwner(address owner, address newOwner) public onlyWallet ownerExists(owner) ownerDoesNotExist(newOwner) {
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

    function changeRequirement(uint _required) public onlyWallet validRequirement(owners.length, _required) {
        required = _required;
        emit RequirementChange(_required);
    }

    function submitTransaction(address destination, uint value, bytes data) public returns (uint transactionId) {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

    function confirmTransaction(uint transactionId) public ownerExists(msg.sender) transactionExists(transactionId) notConfirmed(transactionId, msg.sender) {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    function revokeConfirmation(uint transactionId) public ownerExists(msg.sender) confirmed(transactionId, msg.sender) notExecuted(transactionId) {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

    function executeTransaction(uint transactionId) public notExecuted(transactionId) {
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

    function isConfirmed(uint transactionId) public constant returns (bool) {
        uint count = 0;
        for (uint i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == required)
                return true;
        }
    }

    function addTransaction(address destination, uint value, bytes data) internal notNull(destination) returns (uint transactionId) {
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

    function getConfirmationCount(uint transactionId) public constant returns (uint count) {
        for (uint i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
        }
    }

    function getTransactionCount(bool pending, bool executed) public constant returns (uint count) {
        for (uint i = 0; i < transactionCount; i++) {
            if (pending && !transactions[i].executed || executed && transactions[i].executed)
                count += 1;
        }
    }

    function getOwners() public constant returns (address[]) {
        return owners;
    }

    function getConfirmations(uint transactionId) public constant returns (address[] _confirmations) {
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

    function getTransactionIds(uint from, uint to, bool pending, bool executed) public constant returns (uint[] _transactionIds) {
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

contract OldToken {
    mapping (address => uint256) public balanceOf;
    function burn(address _who) public;
}

contract TokenRecipient {
    function receiveApproval(address _from, uint _value, bytes _extraData) public returns (bool success);
    function receiveTransfer(address _from, uint _value, address _buyer) public returns (bool success);
    function receiveSell(address _from, uint _value, uint _price) public returns (bool success);
}

interface TokenRecipientInterface {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}

contract NamiToken {
    address public owner;
    address public crowdsaleManager;
    address public binaryEscrow;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    address public migrationMaster;
    uint public totalSupply;
    uint public maxWithdraw;
    uint public minWithdraw;
    address public namiMultiSigWallet;
    address public namiExchange;
    address public migrationAgent;
    address public oldToken;
    uint public decimals = 18;
    bool public transferable = false;
    uint public constant TOKEN_SUPPLY_LIMIT = 1000000000 * (1 ether / 1 wei);

    enum Phase { Created, Running, Paused, Migrating, Migrated }

    address public binaryEscrowAddress;
    mapping (address => bool) public isController;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyCrowdsaleManager() {
        require(msg.sender == crowdsaleManager);
        _;
    }

    modifier onlyTransferable() {
        require(transferable);
        _;
    }

    modifier onlyMigrationMaster() {
        require(msg.sender == migrationMaster);
        _;
    }

    event LogBuy(address indexed buyer, uint value);
    event LogBurn(address indexed burner, uint value);
    event LogPhaseSwitch(Phase newPhase);
    event LogMigrate(address indexed holder, address indexed newToken, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public onlyCrowdsaleManager {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public onlyTransferable returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public onlyTransferable returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public onlyTransferable returns (bool success) {
        TokenRecipientInterface spender = TokenRecipientInterface(_spender);
        if (transferable) spender.receiveApproval(msg.sender, _value, this, _extraData);
        return true;
    }

    function changeTransferable() public onlyCrowdsaleManager {
        transferable = !transferable;
    }

    function setBinaryEscrow(address _binaryEscrow) public onlyMigrationMaster {
        require(_binaryEscrow != 0x0);
        binaryEscrow = _binaryEscrow;
    }

    function setMaxWithdraw(uint _maxWithdraw) public onlyOwner {
        maxWithdraw = _maxWithdraw;
    }

    function setMinWithdraw(uint _minWithdraw) public onlyCrowdsaleManager {
        require(_minWithdraw != 0x0);
        minWithdraw = _minWithdraw;
    }

    function setNamiMultiSigWallet(address _namiMultiSigWallet) public onlyCrowdsaleManager {
        require(_namiMultiSigWallet != 0x0);
        namiMultiSigWallet = _namiMultiSigWallet;
    }

    function getPrice() public view returns (uint price) {
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
            return 0;
        }
    }

    function() payable public {
        buy(msg.sender);
    }

    function buy(address _buyer) payable public {
        require(phase == Phase.Running);
        require(now <= 1522281600 || msg.sender == binaryEscrow);
        require(msg.value != 0);
        uint tokens = msg.value * getPrice();
        require (totalSupply + tokens < TOKEN_SUPPLY_LIMIT);
        balanceOf[_buyer] = balanceOf[_buyer] + tokens;
        totalSupply = totalSupply.add(tokens);
        emit LogBuy(_buyer, tokens);
        emit Transfer(this, _buyer, tokens);
    }

    function burn(address _who) public onlyCrowdsaleManager {
        require(phase == Phase.Migrating);
        uint balance = balanceOf[_who];
        require(balance != 0);
        balanceOf[_who] = 0;
        totalSupply -= balance;
        emit LogBurn(_who, balance);
        emit Transfer(_who, owner, balance);
        if (totalSupply == 0) {
            phase = Phase.Migrated;
            emit LogPhaseSwitch(Phase.Migrated);
        }
    }

    function setPhase(Phase _newPhase) public onlyCrowdsaleManager {
        bool validTransition = (phase == Phase.Created && _newPhase == Phase.Running) || (phase == Phase.Running && _newPhase == Phase.Paused) || ((phase == Phase.Running || phase == Phase.Paused) && _newPhase == Phase.Migrating && migrationAgent != 0x0) || (phase == Phase.Paused && _newPhase == Phase.Running) || (phase == Phase.Migrating && _newPhase == Phase.Migrated && totalSupply == 0);
        require(validTransition);
        phase = _newPhase;
        emit LogPhaseSwitch(_newPhase);
    }

    function withdraw(uint _amount) public onlyMigrationMaster {
        require(migrationMaster != 0x0);
        if (address(this).balance > 0) {
            migrationMaster.transfer(_amount);
        }
    }

    function withdrawTo(address _to, uint _amount) public onlyCrowdsaleManager {
        MultiSigWallet namiWallet = MultiSigWallet(namiMultiSigWallet);
        if (namiWallet.isOwner(_to)) {
            _to.transfer(_amount);
        }
    }

    function setMigrationAgent(address _migrationAgent) public onlyCrowdsaleManager {
        require(phase != Phase.Migrating);
        migrationAgent = _migrationAgent;
    }

    function migrate(address _from, address _to) internal {
        OldToken oldTokenContract = OldToken(oldToken);
        uint256 newToken = oldTokenContract.balanceOf(_from);
        require(newToken > 0);
        oldTokenContract.burn(_from);
        balanceOf[_to] = balanceOf[_to].add(newToken);
        totalSupply = totalSupply.add(newToken);
        emit LogMigrate(_from, _to, newToken);
        emit Transfer(this, _to, newToken);
    }

    function migrate(address _from, address _to) public onlyCrowdsaleManager {
        migrate(_from, _to);
    }

    function migrate() public {
        migrate(msg.sender, msg.sender);
    }

    event TransferToBuyer(address indexed _from, address indexed _to, uint _value, address indexed _buyer);
    event TransferToExchange(address indexed _from, address indexed _to, uint _value, uint _price);

    function transferToExchange(address _to, uint _value, uint _price) public {
        uint codeLength;
        assembly {
            codeLength := extcodesize(_to)
        }
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        if (codeLength > 0) {
            TokenRecipient recipient = TokenRecipient(_to);
            recipient.receiveSell(msg.sender, _value, _price);
            emit TransferToExchange(msg.sender, _to, _value, _price);
        }
    }

    function transferToBuyer(address _to, uint _value, address _buyer) public {
        uint codeLength;
        assembly {
            codeLength := extcodesize(_to)
        }
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        if (codeLength > 0) {
            TokenRecipient recipient = TokenRecipient(_to);
            recipient.receiveTransfer(msg.sender, _value, _buyer);
            emit TransferToBuyer(msg.sender, _to, _value, _buyer);
        }
    }
}

contract NamiEscrow {
    using SafeMath for uint256;

    constructor(address _namiToken = 0xa9eeee0e8f9a7243987b00fb5ea0f191d85ba150) public {
        namiToken = _namiToken;
    }

    address public namiToken;
    address public namiMultiSigWallet;
    bool public isPaused;

    mapping(address => bool) public isController;

    event Deposit(address indexed _from, uint _value, uint _time);
    event Withdraw(address indexed _to, uint _value, uint _time);

    modifier onlyCrowdsaleManager() {
        require(msg.sender == namiMultiSigWallet);
        _;
    }

    modifier onlyNamiMultiSigWallet() {
        require(msg.sender == namiMultiSigWallet);
        _;
    }

    modifier onlyNamiToken() {
        require(msg.sender == namiToken);
        _;
    }

    modifier onlyWhenNotPaused() {
        require(!isPaused);
        _;
    }

    function setNamiMultiSigWallet(address _namiMultiSigWallet) public onlyNamiToken {
        require(_namiMultiSigWallet != 0x0);
        namiMultiSigWallet = _namiMultiSigWallet;
    }

    function togglePause() public onlyNamiMultiSigWallet {
        isPaused = !isPaused;
    }

    function setMaxWithdraw(uint _maxWithdraw) public onlyCrowdsaleManager {
        require(_maxWithdraw != 0);
        maxWithdraw = _maxWithdraw;
    }

    function setMinWithdraw(uint _minWithdraw) public onlyCrowdsaleManager {
        require(_minWithdraw != 0);
        minWithdraw = _minWithdraw;
    }

    function withdraw(uint _amount, address _to) public onlyCrowdsaleManager {
        require(_to != address(0x0));
        if (address(this).balance > 0) {
            _to.transfer(_amount);
        }
    }

    function withdrawToken(uint _amount) public onlyCrowdsaleManager {
        require(namiToken != address(0x0));
        NamiToken token = NamiToken(namiMultiSigWallet);
        if (token.balanceOf(address(this)) > 0) {
            token.transfer(namiToken, _amount);
        }
    }

    function addController(address _controller) public onlyCrowdsaleManager {
        require(!isController[_controller]);
        isController[_controller] = true;
    }

    function removeController(address _controller) public onlyCrowdsaleManager {
        require(isController[_controller]);
        isController[_controller] = false;
    }

    string public name = "Nami Game";
    uint public maxWithdraw;
    uint public minWithdraw;

    function deposit() public payable {
        require(msg.value > 0);
        emit Deposit(msg.sender, msg.value, now);
    }

    function() public payable {
        deposit();
    }

    function withdraw(uint _amount, address _to) public onlyWhenNotPaused {
        require(_to != address(0x0) && _amount != 0);
        require(_amount >= minWithdraw && _amount <= maxWithdraw);
        if (address(this).balance > 0) {
            _to.transfer(_amount);
        }
        emit Withdraw(_to, _amount, now);
    }
}

function getIntFunc(uint256 index) internal view returns(uint256) {
    return _integer_constant[index];
}

function getBoolFunc(uint256 index) internal view returns(bool) {
    return _bool_constant[index];
}

function getStrFunc(uint256 index) internal view returns(string storage) {
    return _string_constant[index];
}

uint256[] public _integer_constant = [1000000000000000000, 1521072000, 1517443200, 16, 1518652800, 1520467200, 1, 1700, 2200, 3450, 1519257600, 18, 2300, 1900, 2100, 10, 2400, 50, 2000, 1522281600, 0, 1521676800, 1800, 1000000000, 1519862400];
bool[] public _bool_constant = [true, false];
string[] public _string_constant = ["Nami ICO", "NAC", "Nami Game"];
