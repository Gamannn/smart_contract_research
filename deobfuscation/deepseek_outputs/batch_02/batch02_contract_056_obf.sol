```solidity
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

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }

    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] public owners;
    uint public required;
    uint public transactionCount;

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
        require(!(ownerCount > MAX_OWNER_COUNT || _required == 0 || ownerCount == 0));
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
            require(!(isOwner[_owners[i]] || _owners[i] == 0));
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }

    function addOwner(address owner) 
        public 
        onlyWallet 
        ownerDoesNotExist(owner) 
        notNull(owner) 
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
        notNull(destination) 
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

contract NamiExchange {
    function tokenFallback(address from, uint value, bytes data) public returns (bool ok);
    function tokenFallback(address from, uint value, address seller) public returns (bool ok);
    function tokenFallback(address from, uint value, uint price) public returns (bool ok);
}

contract Token {
    mapping (address => uint256) public balanceOf;
    function burn(address holder) public;
}

interface tokenRecipient {
    function tokenFallback(address from, uint256 value, address to, bytes extraData) external;
}

contract NamiCrowdSale {
    using SafeMath for uint256;
    
    uint public decimals = 18;
    bool public transferable = false;
    uint public constant TOKEN_SUPPLY_LIMIT = 1000;
    uint public binary = 0;
    
    enum Phase {
        Created,
        Running,
        Paused,
        Migrating,
        Migrated
    }
    
    mapping (address => mapping (address => uint256)) public allowance;
    
    modifier onlyNami {
        require(msg.sender == namiMultiSigWallet);
        _;
    }
    
    modifier onlyNamiManager {
        require(msg.sender == namiManager);
        _;
    }
    
    modifier whenTransferable {
        require(transferable);
        _;
    }
    
    modifier onlyEscrow {
        require(msg.sender == escrow);
        _;
    }
    
    event LogBuy(address indexed owner, uint value);
    event LogBurn(address indexed owner, uint value);
    event LogPhaseSwitch(Phase newPhase);
    event LogMigrate(address from, address to, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function _transfer(address from, address to, uint value) internal {
        require(to != 0x0);
        require(balanceOf[from] >= value);
        require(balanceOf[to] + value > balanceOf[to]);
        
        uint previousBalances = balanceOf[from] + balanceOf[to];
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
        
        assert(balanceOf[from] + balanceOf[to] == previousBalances);
    }
    
    function transfer(address to, uint256 value) public onlyNamiManager {
        _transfer(msg.sender, to, value);
    }
    
    function transferFrom(address from, address to, uint256 value) public whenTransferable returns (bool success) {
        require(value <= allowance[from][msg.sender]);
        allowance[from][msg.sender] -= value;
        _transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public whenTransferable returns (bool success) {
        allowance[msg.sender][spender] = value;
        return true;
    }
    
    function approveAndCall(address spender, uint256 value, bytes extraData) public whenTransferable returns (bool success) {
        tokenRecipient recipient = tokenRecipient(spender);
        if (approve(spender, value)) {
            recipient.tokenFallback(msg.sender, value, this, extraData);
            return true;
        }
    }
    
    function changeTransferable() public onlyNamiManager {
        transferable = !transferable;
    }
    
    function changeEscrow(address _escrow) public onlyEscrow {
        require(_escrow != 0x0);
        escrow = _escrow;
    }
    
    function changeBinary(uint _binary) public onlyNamiManager {
        binary = _binary;
    }
    
    function changeNamiManager(address _namiManager) public onlyNamiManager {
        require(_namiManager != 0x0);
        namiManager = _namiManager;
    }
    
    function currentPrice() public view returns (uint price) {
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
            return binary;
        }
    }
    
    function() payable public {
        buy(msg.sender);
    }
    
    function buy(address buyer) payable public {
        require(currentPhase == Phase.Running);
        require(now <= 1522281600);
        require(binary == 0);
        require(msg.value != 0);
        
        uint tokens = msg.value * currentPrice();
        require(totalSupply + tokens < TOKEN_SUPPLY_LIMIT);
        
        balanceOf[buyer] = balanceOf[buyer].add(tokens);
        totalSupply = totalSupply.add(tokens);
        emit LogBuy(buyer, tokens);
        emit Transfer(this, buyer, tokens);
    }
    
    function burn(address holder) public onlyNami {
        require(currentPhase == Phase.Migrating);
        uint tokens = balanceOf[holder];
        require(tokens != 0);
        
        balanceOf[holder] = 0;
        totalSupply -= tokens;
        emit LogBurn(holder, tokens);
        emit Transfer(holder, namiMultiSigWallet, tokens);
        
        if (totalSupply == 0) {
            currentPhase = Phase.Migrated;
            emit LogPhaseSwitch(Phase.Migrated);
        }
    }
    
    function changePhase(Phase newPhase) public onlyNamiManager {
        bool canChange = 
            (currentPhase == Phase.Created && newPhase == Phase.Running) ||
            (currentPhase == Phase.Running && newPhase == Phase.Paused) ||
            ((currentPhase == Phase.Running || currentPhase == Phase.Paused) && newPhase == Phase.Migrating && namiMultiSigWallet != 0x0) ||
            (currentPhase == Phase.Paused && newPhase == Phase.Running) ||
            (currentPhase == Phase.Migrating && newPhase == Phase.Migrated && totalSupply == 0);
        
        require(canChange);
        currentPhase = newPhase;
        emit LogPhaseSwitch(newPhase);
    }
    
    function withdrawEther() public onlyNamiManager {
        require(escrow != 0x0);
        if (address(this).balance > 0) {
            escrow.transfer(address(this).balance);
        }
    }
    
    function safeWithdraw(address _withdraw, uint amount) public onlyEscrow {
        MultiSigWallet namiWallet = MultiSigWallet(escrow);
        if (namiWallet.isOwner(_withdraw)) {
            _withdraw.transfer(amount);
        }
    }
    
    function setCrowdsaleAddress(address _namiMultiSigWallet) public onlyNamiManager {
        require(currentPhase != Phase.Migrating);
        namiMultiSigWallet = _namiMultiSigWallet;
    }
    
    function _migrate(address from, address to) internal {
        Token presaleToken = Token(crowdsaleData);
        uint256 tokens = presaleToken.balanceOf(from);
        require(tokens > 0);
        
        presaleToken.burn(from);
        balanceOf[to] = balanceOf[to].add(tokens);
        totalSupply = totalSupply.add(tokens);
        emit LogMigrate(from, to, tokens);
        emit Transfer(this, to, tokens);
    }
    
    function migrateFor(address from, address to) public onlyNamiManager {
        _migrate(from, to);
    }
    
    function migrate() public {
        _migrate(msg.sender, msg.sender);
    }
    
    event TransferToBuyer(address indexed from, address indexed to, uint value, address indexed seller);
    event TransferToExchange(address indexed from, address indexed to, uint value, uint price);
    
    function transferToExchange(address to, uint value, uint price) public {
        uint codeLength;
        assembly {
            codeLength := extcodesize(to)
        }
        
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(msg.sender, to, value);
        
        if (codeLength > 0) {
            NamiExchange exchange = NamiExchange(to);
            exchange.tokenFallback(msg.sender, value, price);
            emit TransferToExchange(msg.sender, to, value, price);
        }
    }
    
    function transferToBuyer(address to, uint value, address seller) public {
        uint codeLength;
        assembly {
            codeLength := extcodesize(to)
        }
        
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(msg.sender, to, value);
        
        if (codeLength > 0) {
            NamiExchange exchange = NamiExchange(to);
            exchange.tokenFallback(msg.sender, value, seller);
            emit TransferToBuyer(msg.sender, to, value, seller);
        }
    }
    
    Phase public currentPhase = Phase.Created;
    uint public totalSupply = 0;
    string public name = "NAC";
    string public symbol = "NAC";
    address public namiMultiSigWallet;
    address public crowdsaleData;
    address public escrow;
    address public namiManager;
    mapping (address => uint256) public balanceOf;
}

library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c