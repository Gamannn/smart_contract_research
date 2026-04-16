```solidity
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
    
    function max(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }
    
    function min(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }
    
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
    
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

contract MultiSigWallet {
    using SafeMath for uint;
    
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
    
    modifier notNull(address _address) {
        require(_address != 0);
        _;
    }
    
    modifier validRequirement(uint ownerCount, uint _required) {
        require(!(ownerCount > MAX_OWNER_COUNT || _required > ownerCount || _required == 0 || ownerCount == 0));
        _;
    }
    
    function() public payable {
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value);
        }
    }
    
    constructor(address[] _owners, uint _required) public validRequirement(_owners.length, _required) {
        for (uint i = 0; i < _owners.length; i++) {
            require(!(isOwner[_owners[i]] || _owners[i] == 0));
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }
    
    function addOwner(address owner) public onlyWallet ownerDoesNotExist(owner) notNull(owner) validRequirement(owners.length.add(1), required) {
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
        if (required > owners.length) {
            changeRequirement(owners.length);
        }
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
            if (confirmations[transactionId][owners[i]]) {
                count += 1;
                if (count == required) return true;
            }
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
            if (confirmations[transactionId][owners[i]]) {
                count += 1;
            }
        }
    }
    
    function getTransactionCount(bool pending, bool executed) public constant returns (uint count) {
        for (uint i = 0; i < transactionCount; i++) {
            if (pending && !transactions[i].executed || executed && transactions[i].executed) {
                count += 1;
            }
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

contract ERC20Basic {
    mapping (address => uint256) public balanceOf;
    function burn(address _from) public;
}

contract ERC20 {
    function transfer(address _to, uint _value, bytes _data) public returns (bool success);
    function approve(address _spender, uint _value, address _sender) public returns (bool success);
    function tokenFallback(address _from, uint _value, uint _price) public returns (bool success);
}

interface ApproveAndCallFallBack {
    function receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData) external;
}

contract NamiCrowdSale {
    using SafeMath for uint256;
    
    uint public totalSupply = 0;
    
    constructor(address _namiMultiSigWallet, address _escrow) public {
        require(_namiMultiSigWallet != 0x0);
        require(_escrow != 0x0);
        namiMultiSigWallet = _namiMultiSigWallet;
        escrow = _escrow;
    }
    
    uint public decimals = 18;
    bool public transferable = false;
    uint public constant TOKEN_SUPPLY_LIMIT = 1000000000 * (1 ether / 1 wei);
    
    enum Phase {
        Created,
        Running,
        Paused,
        Migrating,
        Migrated
    }
    
    address public namiMultiSigWallet;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    modifier onlyNamiMultisig() {
        require(msg.sender == namiMultiSigWallet);
        _;
    }
    
    modifier onlyEscrow() {
        require(msg.sender == escrow);
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
    
    event LogBuy(address indexed owner, uint value);
    event LogBurn(address indexed owner, uint value);
    event LogPhaseSwitch(Phase newPhase);
    event LogMigrate(address _from, address _to, uint256 amount);
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
    
    function transfer(address _to, uint256 _value) public onlyTransferable {
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
        ApproveAndCallFallBack spender = ApproveAndCallFallBack(_spender);
        if (transferable) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
    
    function changeTransferable() public onlyEscrow {
        transferable = !transferable;
    }
    
    function changeEscrow(address _escrow) public onlyCrowdsaleManager {
        require(_escrow != 0x0);
        escrow = _escrow;
    }
    
    function changeMinRate(uint _minRate) public onlyCrowdsaleManager {
        minRate = _minRate;
    }
    
    function changeCrowdsaleManager(address _crowdsaleManager) public onlyEscrow {
        require(_crowdsaleManager != 0x0);
        crowdsaleManager = _crowdsaleManager;
    }
    
    /*
    * Price in ICO:
    * first week: 1 ETH = 2400 NAC
    * second week: 1 ETH = 2300 NAC
    * 3rd week: 1 ETH = 2200 NAC
    * 4th week: 1 ETH = 2100 NAC
    * 5th week: 1 ETH = 2000 NAC
    * 6th week: 1 ETH = 1900 NAC
    * 7th week: 1 ETH = 1800 NAC
    * 8th week: 1 ETH = 1700 NAC
    * time:
    * 1517443200: Thursday, February 1, 2018 12:00:00 AM
    * 1518048000: Thursday, February 8, 2018 12:00:00 AM
    * 1518652800: Thursday, February 15, 2018 12:00:00 AM
    * 1519257600: Thursday, February 22, 2018 12:00:00 AM
    * 1519862400: Thursday, March 1, 2018 12:00:00 AM
    * 1520467200: Thursday, March 8, 2018 12:00:00 AM
    * 1521072000: Thursday, March 15, 2018 12:00:00 AM
    * 1521676800: Thursday, March 22, 2018 12:00:00 AM
    * 1522281600: Thursday, March 29, 2018 12:00:00 AM
    */
    function price() public view returns (uint _price) {
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
            return minRate;
        }
    }
    
    function() payable public {
        buy(msg.sender);
    }
    
    function buy(address _buyer) payable public {
        require(currentPhase == Phase.Running);
        require(now <= 1522281600 || msg.sender == binaryAddress);
        require(msg.value != 0);
        uint tokens = msg.value * price();
        require(totalSupply.add(tokens) < TOKEN_SUPPLY_LIMIT);
        balanceOf[_buyer] = balanceOf[_buyer].add(tokens);
        totalSupply = totalSupply.add(tokens);
        emit LogBuy(_buyer, tokens);
        emit Transfer(this, _buyer, tokens);
    }
    
    function burn(address _from) public onlyCrowdsaleManager {
        require(currentPhase == Phase.Migrating);
        uint tokens = balanceOf[_from];
        require(tokens != 0);
        balanceOf[_from] = 0;
        totalSupply -= tokens;
        emit LogBurn(_from, tokens);
        emit Transfer(_from, namiMultiSigWallet, tokens);
        if (totalSupply == 0) {
            currentPhase = Phase.Migrated;
            emit LogPhaseSwitch(Phase.Migrated);
        }
    }
    
    /*
    * Administrative functions
    */
    function setPhase(Phase newPhase) public onlyEscrow {
        bool canSwitch = (currentPhase == Phase.Created && newPhase == Phase.Running) ||
            (currentPhase == Phase.Running && newPhase == Phase.Paused) ||
            ((currentPhase == Phase.Running || currentPhase == Phase.Paused) && newPhase == Phase.Migrating && crowdsaleManager != 0x0) ||
            (currentPhase == Phase.Paused && newPhase == Phase.Running) ||
            (currentPhase == Phase.Migrating && newPhase == Phase.Migrated && totalSupply == 0);
        require(canSwitch);
        currentPhase = newPhase;
        emit LogPhaseSwitch(newPhase);
    }
    
    function withdrawEther