```solidity
pragma solidity 0.4.24;

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    uint256 totalSupply_;

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }
}

contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) internal allowed;

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balances[from]);
        require(value <= allowed[from][msg.sender]);

        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

    function increaseApproval(address spender, uint256 addedValue) public returns (bool) {
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function decreaseApproval(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 oldValue = allowed[msg.sender][spender];
        if (subtractedValue > oldValue) {
            allowed[msg.sender][spender] = 0;
        } else {
            allowed[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

contract PausableToken is StandardToken, Pausable {
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseApproval(address spender, uint addedValue) public whenNotPaused returns (bool) {
        return super.increaseApproval(spender, addedValue);
    }

    function decreaseApproval(address spender, uint subtractedValue) public whenNotPaused returns (bool) {
        return super.decreaseApproval(spender, subtractedValue);
    }
}

contract BurnableToken is BasicToken {
    event Burn(address indexed burner, uint256 value);

    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

    function _burn(address who, uint256 value) internal {
        require(value <= balances[who]);
        balances[who] = balances[who].sub(value);
        totalSupply_ = totalSupply_.sub(value);
        emit Burn(who, value);
        emit Transfer(who, address(0), value);
    }
}

contract RepublicToken is PausableToken, BurnableToken {
    string public constant name = "Republic Token";
    string public constant symbol = "REN";
    uint8 public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 1000000000 * (10 ** uint256(decimals));

    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
    }

    function transferTokens(address beneficiary, uint256 amount) public onlyOwner returns (bool) {
        require(amount > 0);
        balances[owner] = balances[owner].sub(amount);
        balances[beneficiary] = balances[beneficiary].add(amount);
        emit Transfer(owner, beneficiary, amount);
        return true;
    }
}

library LinkedList {
    struct Node {
        bool inList;
        address previous;
        address next;
    }

    struct List {
        mapping (address => Node) list;
    }

    function insertBefore(List storage self, address node, address newNode) internal {
        require(!isInList(self, newNode), "already in list");
        require(isInList(self, node) || node == address(0), "not in list");
        address prev = self.list[node].previous;
        self.list[newNode].next = node;
        self.list[newNode].previous = prev;
        self.list[node].previous = newNode;
        self.list[prev].next = newNode;
        self.list[newNode].inList = true;
    }

    function insertAfter(List storage self, address node, address newNode) internal {
        require(!isInList(self, newNode), "already in list");
        require(isInList(self, node) || node == address(0), "not in list");
        address n = self.list[node].next;
        self.list[newNode].previous = node;
        self.list[newNode].next = n;
        self.list[node].next = newNode;
        self.list[n].previous = newNode;
        self.list[newNode].inList = true;
    }

    function remove(List storage self, address node) internal {
        require(isInList(self, node), "not in list");
        if (node == address(0)) {
            return;
        }
        address p = self.list[node].previous;
        address n = self.list[node].next;
        self.list[p].next = n;
        self.list[n].previous = p;
        self.list[node].inList = false;
        delete self.list[node];
    }

    function prepend(List storage self, address node) internal {
        insertBefore(self, begin(self), node);
    }

    function append(List storage self, address node) internal {
        insertAfter(self, end(self), node);
    }

    function swap(List storage self, address left, address right) internal {
        address previousRight = self.list[right].previous;
        remove(self, right);
        insertAfter(self, left, right);
        remove(self, left);
        insertAfter(self, previousRight, left);
    }

    function isInList(List storage self, address node) internal view returns (bool) {
        return self.list[node].inList;
    }

    function begin(List storage self) internal view returns (address) {
        return self.list[address(0)].next;
    }

    function end(List storage self) internal view returns (address) {
        return self.list[address(0)].previous;
    }

    function next(List storage self, address node) internal view returns (address) {
        require(isInList(self, node), "not in list");
        return self.list[node].next;
    }

    function previous(List storage self, address node) internal view returns (address) {
        require(isInList(self, node), "not in list");
        return self.list[node].previous;
    }
}

contract DarknodeRegistryStore is Ownable {
    struct Darknode {
        address owner;
        uint256 bond;
        uint256 registeredAt;
        uint256 deregisteredAt;
        bytes publicKey;
    }

    mapping(address => Darknode) private darknodeRegistry;
    LinkedList.List private darknodes;
    RepublicToken public ren;

    constructor(string _VERSION, RepublicToken _ren) public {
        ren = _ren;
    }

    function appendDarknode(
        address _darknodeID,
        address _darknodeOwner,
        uint256 _bond,
        bytes _publicKey,
        uint256 _registeredAt,
        uint256 _deregisteredAt
    ) external onlyOwner {
        Darknode memory darknode = Darknode({
            owner: _darknodeOwner,
            bond: _bond,
            publicKey: _publicKey,
            registeredAt: _registeredAt,
            deregisteredAt: _deregisteredAt
        });
        darknodeRegistry[_darknodeID] = darknode;
        LinkedList.append(darknodes, _darknodeID);
    }

    function begin() external view onlyOwner returns(address) {
        return LinkedList.begin(darknodes);
    }

    function next(address darknodeID) external view onlyOwner returns(address) {
        return LinkedList.next(darknodes, darknodeID);
    }

    function removeDarknode(address darknodeID) external onlyOwner {
        uint256 bond = darknodeRegistry[darknodeID].bond;
        delete darknodeRegistry[darknodeID];
        LinkedList.remove(darknodes, darknodeID);
        require(ren.transfer(owner, bond), "bond transfer failed");
    }

    function updateDarknodeBond(address darknodeID, uint256 bond) external onlyOwner {
        uint256 previousBond = darknodeRegistry[darknodeID].bond;
        darknodeRegistry[darknodeID].bond = bond;
        if (previousBond > bond) {
            require(ren.transfer(owner, previousBond - bond), "cannot transfer bond");
        }
    }

    function updateDarknodeDeregisteredAt(address darknodeID, uint256 deregisteredAt) external onlyOwner {
        darknodeRegistry[darknodeID].deregisteredAt = deregisteredAt;
    }

    function darknodeOwner(address darknodeID) external view onlyOwner returns (address) {
        return darknodeRegistry[darknodeID].owner;
    }

    function darknodeBond(address darknodeID) external view onlyOwner returns (uint256) {
        return darknodeRegistry[darknodeID].bond;
    }

    function darknodeRegisteredAt(address darknodeID) external view onlyOwner returns (uint256) {
        return darknodeRegistry[darknodeID].registeredAt;
    }

    function darknodeDeregisteredAt(address darknodeID) external view onlyOwner returns (uint256) {
        return darknodeRegistry[darknodeID].deregisteredAt;
    }

    function darknodePublicKey(address darknodeID) external view onlyOwner returns (bytes) {
        return darknodeRegistry[darknodeID].publicKey;
    }
}

contract DarknodeRegistry is Ownable {
    struct Epoch {
        uint256 epochhash;
        uint256 blocknumber;
    }

    Epoch public currentEpoch;
    Epoch public previousEpoch;
    RepublicToken public ren;
    DarknodeRegistryStore public store;

    event LogDarknodeRegistered(address _darknodeID, uint256 _bond);
    event LogDarknodeDeregistered(address _darknodeID);
    event LogDarknodeOwnerRefunded(address _owner, uint256 _amount);
    event LogNewEpoch();
    event LogMinimumBondUpdated(uint256 previousMinimumBond, uint256 nextMinimumBond);
    event LogMinimumPodSizeUpdated(uint256 previousMinimumPodSize, uint256 nextMinimumPodSize);
    event LogMinimumEpochIntervalUpdated(uint256 previousMinimumEpochInterval, uint256 nextMinimumEpochInterval);
    event LogSlasherUpdated(address previousSlasher, address nextSlasher);

    modifier onlyDarknodeOwner(address _darknodeID) {
        require(store.darknodeOwner(_darknodeID) == msg.sender, "must be darknode owner");
        _;
    }

    modifier onlyRefunded(address _darknodeID) {
        require(isRefunded(_darknodeID), "must be refunded or never registered");
        _;
    }

    modifier onlyRefundable(address _darknodeID) {
        require(isRefundable(_darknodeID), "must be deregistered for at least one epoch");
        _;
    }

    modifier onlyDeregisterable(address _darknodeID) {
        require(isDeregisterable(_darknodeID), "must be deregisterable");
        _;
    }

    modifier onlySlasher() {
        require(slasher == msg.sender, "must be slasher");
        _;
    }

    constructor(
        string _VERSION,
        RepublicToken _renAddress,
        DarknodeRegistryStore _storeAddress,
        uint256 _minimumBond,
        uint256 _minimumPodSize,
        uint256 _minimumEpochInterval
    ) public {
        store = _storeAddress;
        ren = _renAddress;
        minimumBond = _minimumBond;
        nextMinimumBond = minimumBond;
        minimumPodSize = _minimumPodSize;
        nextMinimumPodSize = minimumPodSize;
        minimumEpochInterval = _minimumEpochInterval;
        nextMinimumEpochInterval = minimumEpochInterval;
        currentEpoch = Epoch({
            epochhash: uint256(blockhash(block.number - 1)),
            blocknumber: block.number
        });
        numDarknodes = 0;
        numDarknodesNextEpoch = 0;
        numDarknodesPreviousEpoch = 0;
    }

    function register(address _darknodeID, bytes _publicKey, uint256 _bond) external onlyRefunded(_darknodeID) {
        require(_bond >= minimumBond, "insufficient bond");
        require(ren.transferFrom(msg.sender, address(this), _bond), "bond transfer failed");
        ren.transfer(address(store), _bond);
        store.appendDarknode(
            _darknodeID,
            msg.sender,
            _bond,
            _publicKey,
            currentEpoch.blocknumber + minimumEpochInterval,
            0
        );
        numDarknodesNextEpoch += 1;
        emit LogDarknodeRegistered(_darknodeID, _bond);
    }

    function deregister(address _darknodeID) external onlyDeregisterable(_darknodeID) onlyDarknodeOwner(_darknodeID) {
        store.updateDarknodeDeregisteredAt(_darknodeID, currentEpoch.blocknumber + minimumEpochInterval);
        numDarknodesNextEpoch -= 1;
        emit LogDarknodeDeregistered(_darknodeID);
    }

    function epoch() external {
        if (previousEpoch.blocknumber == 0) {
            require(msg.sender == owner, "not authorized (first epochs)");
        }
        require(block.number >= currentEpoch.blocknumber + minimumEpochInterval, "epoch interval has not passed");
        uint256 epochhash = uint256(blockhash(block.number - 1));
        previousEpoch = currentEpoch;
        currentEpoch = Epoch({
            epochhash: epochhash,
            blocknumber: block.number
        });
        numDarknodesPreviousEpoch = numDarknodes;
        numDarknodes = numDarknodesNextEpoch;
        if (nextMinimumBond != minimumBond) {
            minimumBond = nextMinimumBond;
            emit LogMinimumBondUpdated(minimumBond, nextMinimumBond);
        }
        if (nextMinimumPodSize != minimumPodSize) {
            minimumPodSize = nextMinimumPodSize;
            emit LogMinimumPodSizeUpdated(minimumPodSize, nextMinimumPodSize);
        }
        if (nextMinimumEpochInterval != minimumEpochInterval) {
            minimumEpochInterval = nextMinimumEpochInterval;
            emit LogMinimumEpochIntervalUpdated(minimumEpochInterval, nextMinimumEpochInterval);
        }
        if (nextSlasher != slasher) {
            slasher = nextSlasher;
            emit LogSlasherUpdated(slasher, nextSlasher);
        }
        emit LogNewEpoch();
    }

    function transferStoreOwnership(address _newOwner) external onlyOwner {
        store.transferOwnership(_newOwner);
    }

    function updateMinimumBond(uint256 _nextMinimumBond) external onlyOwner {
        nextMinimumBond = _nextMinimumBond;
    }

    function updateMinimumPodSize(uint256 _nextMinimumPodSize) external onlyOwner {
        nextMinimumPodSize = _nextMinimumPodSize;
    }

    function updateMinimumEpochInterval(uint256 _nextMinimumEpochInterval) external onlyOwner {
        nextMinimumEpochInterval = _nextMinimumEpochInterval;
    }

    function updateSlasher(address _slasher) external onlyOwner {
        nextSlasher = _slasher;
    }

    function slash(address _prover, address _challenger1, address _challenger2) external onlySlasher {
        uint256 penalty = store.darknodeBond(_prover) / 2;
        uint256 reward = penalty / 4;
        store.updateDarknodeBond(_prover, penalty);
        if (isDeregisterable(_prover)) {
            store.updateDarknodeDeregisteredAt(_prover, currentEpoch.blocknumber + minimumEpochInterval);
            numDarknodesNextEpoch -= 1;
            emit LogDarknodeDeregistered(_prover);
        }
        ren.transfer(store.darknodeOwner(_challenger1), reward);
        ren.transfer(store.darknodeOwner(_challenger2), reward);
    }

    function refund(address _darknodeID) external onlyRefundable(_darknodeID) {
        address darknodeOwner = store.darknodeOwner(_darknodeID);
        uint256 amount = store.darknodeBond(_darknodeID);
        store.removeDarknode(_darknodeID);
        ren.transfer(darknodeOwner, amount);
        emit LogDarknodeOwnerRefunded(darknodeOwner, amount);
    }

    function getDarknodeOwner(address _darknodeID) external view returns (address) {
        return store.darknodeOwner(_darknodeID);
    }

    function getDarknodeBond(address _darknodeID) external view returns (uint256) {
        return store.darknodeBond(_darknodeID);
    }

    function getDarknodePublicKey(address _darknodeID) external view returns (bytes) {
        return store.darknodePublicKey(_darknodeID);
    }

    function getDarknodes(address _start, uint256 _count) external view returns (address[]) {
        uint256 count = _count;
        if (count == 0) {
            count = numDarknodes;
        }
        return getDarknodesFromEpochs(_start, count, false);
    }

    function getPreviousDarknodes(address _start, uint256 _count) external view returns (address[]) {
        uint256 count = _count;
        if (count == 0) {
            count = numDarknodesPreviousEpoch;
        }
        return getDarknodesFromEpochs(_start, count, true);
    }

    function isPendingRegistration(address _darknodeID) external view returns (bool) {
        uint256 registeredAt = store.darknodeRegisteredAt(_darknodeID);
        return registeredAt != 0 && registeredAt > currentEpoch.blocknumber;
    }

    function isPendingDeregistration(address _darknodeID) external view returns (bool) {
        uint256 deregisteredAt = store.darknodeDeregisteredAt(_darknodeID);
        return deregisteredAt != 0 && deregisteredAt > currentEpoch.blocknumber;
    }

    function isDeregistered(address _darknodeID) public view returns (bool) {
        uint256 deregisteredAt = store.darknodeDeregisteredAt(_darknodeID);
        return deregisteredAt != 0 && deregisteredAt <= currentEpoch.blocknumber;
    }

    function isDeregisterable(address _darknodeID) public view returns (bool) {
        uint256 deregisteredAt = store.darknodeDeregisteredAt(_darknodeID);
        return isRegistered(_darknodeID) && deregisteredAt == 0;
    }

    function isRefunded(address _darknodeID) public view returns (bool) {
        uint256 registeredAt = store.darknodeRegisteredAt(_darknodeID);
        uint256 deregisteredAt = store.darknodeDeregisteredAt(_darknodeID);
        return registeredAt == 0 && deregisteredAt == 0;
    }

    function isRefundable(address _darknodeID) public view returns (bool) {
        return isDeregistered(_darknodeID) && store.darknodeDeregisteredAt(_darknodeID) <= previousEpoch.blocknumber;
    }

    function isRegistered(address _darknodeID) public view returns (bool) {
        return isRegisteredInEpoch(_darknodeID, currentEpoch);
    }

    function isRegisteredInPreviousEpoch(address _darknodeID) public view returns (bool) {
        return isRegisteredInEpoch(_darknodeID, previousEpoch);
    }

    function isRegisteredInEpoch(address _darknodeID, Epoch _epoch) private view returns (bool) {
        uint256 registeredAt = store.darknodeRegisteredAt(_darknodeID);
        uint256 deregisteredAt = store.darknodeDeregisteredAt(_darknodeID);
        bool registered = registeredAt != 0 && registeredAt <= _epoch.blocknumber;
        bool notDeregistered = deregisteredAt == 0 || deregisteredAt > _epoch.blocknumber;
        return registered && notDeregistered;
    }

    function getDarknodesFromEpochs(address _start, uint256 _count, bool _usePreviousEpoch) private view returns (address[]) {
        uint256 count = _count;
        if (count == 0) {
            count = numDarknodes;
        }
        address[] memory nodes = new address[](count);
        uint256 n = 0;
        address next = _start;
        if (next == 0x0) {
            next = store.begin();
        }
        while (n < count) {
            if (next == 0x0) {
                break;
            }
            bool includeNext;
            if (_usePreviousEpoch) {
                includeNext = isRegisteredInPreviousEpoch(next);
            } else {
                includeNext = isRegistered(next);
            }
            if (!includeNext) {
                next = store.next(next);
                continue;
            }
            nodes[n] = next;
            next = store.next(next);
            n += 1;
        }
        return nodes;
    }
}

library Math {
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

library CompatibleERC20Functions {
    using SafeMath for uint256;

    function safeTransfer(address token, address to, uint256 value) internal {
        CompatibleERC20(token).transfer(to, value);
        require(previousReturnValue(), "transfer failed");
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        CompatibleERC20(token).transferFrom(from, to, value);
        require(previousReturnValue(), "transferFrom failed");
    }

    function safeApprove(address token, address spender, uint256 value) internal {
        CompatibleERC20(token).approve(spender, value);
        require(previousReturnValue(), "approve failed");
    }

    function safeTransferFromWithFees(address token, address from, address to, uint256 value) internal returns (uint256) {
        uint256 balancesBefore = CompatibleERC20(token).balanceOf(to);
        CompatibleERC20(token).transferFrom(from, to, value);
        require(previousReturnValue(), "transferFrom failed");
        uint256 balancesAfter = CompatibleERC20(token).balanceOf(to);
        return Math.min256(value, balancesAfter.sub(balancesBefore));
    }

    function previousReturnValue() private pure returns (bool) {
        uint256 returnData = 0;
        assembly {
            switch returndatasize
            case 0 { returnData := 1 }
            case 32 { returndatacopy(0x0, 0x0, 32) returnData := mload(0x0) }
            default { }
        }
        return returnData != 0;
    }
}

interface CompatibleERC20 {
    function transfer(address to, uint256 value) external;
    function transferFrom(address from, address to, uint256 value) external;
    function approve(address spender, uint256 value) external;
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract DarknodeRewardVault is Ownable {
    using SafeMath for uint256;
    using CompatibleERC20Functions for CompatibleERC20;

    DarknodeRegistry public darknodeRegistry;
    mapping(address => mapping(address => uint256)) public darknodeBalances;

    event LogDarknodeRegistryUpdated(DarknodeRegistry previousDarknodeRegistry, DarknodeRegistry nextDarknodeRegistry);

    constructor(string _VERSION, DarknodeRegistry _darknodeRegistry) public {
        darknodeRegistry = _darknodeRegistry;
    }

    function updateDarknodeRegistry(DarknodeRegistry _newDarknodeRegistry) public onlyOwner {
        emit LogDarknodeRegistryUpdated(darknodeRegistry, _newDarknodeRegistry);
        darknodeRegistry = _newDarknodeRegistry;
    }

    function deposit(address _darknode, ERC20 token, uint256 value) public payable {
        uint256 receivedValue = value;
        if (address(token) == address(0)) {
            require(msg.value == value, "mismatched ether value");
        } else {
            require(msg.value == 0, "unexpected ether value");
            receivedValue = CompatibleERC20(token).safeTransferFromWithFees(msg.sender, address(this), value);
        }
        darknodeBalances[_darknode][token] = darknodeBalances[_darknode][token].add(receivedValue);
    }

    function withdraw(address _darknode, ERC20 token) public {
        address darknodeOwner = darknodeRegistry.getDarknodeOwner(address(_darknode));
        require(darknodeOwner != address(0), "invalid darknode owner");
        uint256 value = darknodeBalances[_darknode][token];
        darknodeBalances[_darknode][token] = 0;
        if (address(token) == address(0)) {
            darknodeOwner.transfer(value);
        } else {
            CompatibleERC20(token).safeTransfer(darknodeOwner, value);
        }
    }
}

interface BrokerVerifier {
    function verifyOpenSignature(address _trader, bytes _signature, bytes32 _orderID) external returns (bool);
}

interface Settlement {
    function submitOrder(bytes _details, uint64 _settlementID, uint64 _tokens, uint256 _price, uint256 _volume, uint256 _minimumVolume) external;
    function submissionGasPriceLimit() external view returns (uint256);
    function settle(bytes32 _buyID, bytes32 _sellID) external;
    function orderStatus(bytes32 _orderID) external view returns (uint8);
}

contract SettlementRegistry is Ownable {
    struct SettlementDetails {
        bool registered;
        Settlement settlementContract;
        BrokerVerifier brokerVerifierContract;
    }

    mapping(uint64 => SettlementDetails) public settlementDetails;

    event LogSettlementRegistered(uint64 settlementID, Settlement settlementContract, BrokerVerifier brokerVerifierContract);
    event LogSettlementUpdated(uint64 settlementID, Settlement settlementContract, BrokerVerifier brokerVerifierContract);
    event LogSettlementDeregistered(uint64 settlementID);

    constructor(string _VERSION) public {
    }

    function settlementRegistration(uint64 _settlementID) external view returns (bool) {
        return settlementDetails[_settlementID].registered;
    }

    function settlementContract(uint64 _settlementID) external view returns (Settlement) {
        return settlementDetails[_settlementID].settlementContract;
    }

    function brokerVerifierContract(uint64 _settlementID) external view returns (BrokerVerifier) {
        return settlementDetails[_settlementID].brokerVerifierContract;
    }

    function registerSettlement(uint64 _settlementID, Settlement _settlementContract, BrokerVerifier _brokerVerifierContract) public onlyOwner {
        bool alreadyRegistered = settlementDetails[_settlementID].registered;
        settlementDetails[_settlementID] = SettlementDetails({
            registered: true,
            settlementContract: _settlementContract,
            brokerVerifierContract: _brokerVerifierContract
        });
        if (alreadyRegistered) {
            emit LogSettlementUpdated(_settlementID, _settlementContract, _brokerVerifierContract);
        } else {
            emit LogSettlementRegistered(_settlementID, _settlementContract, _brokerVerifierContract);
        }
    }

    function deregisterSettlement(uint64 _settlementID) external onlyOwner {
        require(settlementDetails[_settlementID].registered, "not registered");
        delete settlementDetails[_settlementID];
        emit LogSettlementDeregistered(_settlementID);
    }
}

library ECRecovery {
    function recover(bytes32 hash, bytes sig) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (sig.length != 65) {
            return (address(0));
        }
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        if (v < 27) {
            v += 27;
        }
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }

    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

library Utils {
    function uintToBytes(uint256 v) internal pure returns (bytes) {
        if (v == 0) {
            return "0";
        }
        uint256 digits = 0;
        uint256 v2 = v;
        while (v2 > 0) {
            v2 /= 10;
            digits += 1;
        }
        bytes memory result = new bytes(digits);
        for (uint256 i = 0; i < digits; i++) {
            result[digits - i - 1] = bytes1((v % 10) + 48);
            v /= 10;
        }
        return result;
    }

    function addr(bytes _hash, bytes _signature) internal pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n";
        bytes memory encoded = abi.encodePacked(prefix, uintToBytes(_hash.length), _hash);
        bytes32 prefixedHash = keccak256(encoded);
        return ECRecovery.recover(prefixedHash, _signature);
    }
}

contract Orderbook is Ownable {
    enum OrderState {Undefined, Open, Confirmed, Canceled}

    struct Order {
        OrderState state;
        address trader;
        address confirmer;
        uint64 settlementID;
        uint256 priority;
        uint256 blockNumber;
        bytes32 matchedOrder;
    }

    DarknodeRegistry public darknodeRegistry;
    SettlementRegistry public settlementRegistry;
    bytes32[] private orderbook;
    mapping(bytes32 => Order) public orders;

    event LogFeeUpdated(uint256 previousFee, uint256 nextFee);
    event LogDarknodeRegistryUpdated(DarknodeRegistry previousDarknodeRegistry, DarknodeRegistry nextDarknodeRegistry);

    modifier onlyDarknode(address _sender) {
        require(darknodeRegistry.isRegistered(address(_sender)), "must be registered darknode");
        _;
    }

    constructor(string _VERSION, DarknodeRegistry _darknodeRegistry, SettlementRegistry _settlementRegistry) public {
        darknodeRegistry = _darknodeRegistry;
        settlementRegistry = _settlementRegistry;
    }

    function updateDarknodeRegistry(DarknodeRegistry _newDarknodeRegistry) external onlyOwner {
        emit LogDarknodeRegistryUpdated(darknodeRegistry, _newDarknodeRegistry);
        darknodeRegistry = _newDarknodeRegistry;
    }

    function openOrder(uint64 _settlementID, bytes _signature, bytes32 _orderID) external {
        require(orders[_orderID].state == OrderState.Undefined, "invalid order status");
        address trader = msg.sender;
        require(settlementRegistry.settlementRegistration(_settlementID), "settlement not registered");
        BrokerVerifier brokerVerifier = settlementRegistry.brokerVerifierContract(_settlementID);
        require(brokerVerifier.verifyOpenSignature(trader, _signature, _orderID), "invalid broker signature");
        orders[_orderID] = Order({
            state: OrderState.Open,
            trader: trader,
            confirmer: address(0),
            settlementID: _settlementID,
            priority: orderbook.length + 1,
            blockNumber: block.number,
            matchedOrder: bytes32(0)
        });
        orderbook.push(_orderID);
    }

    function confirmOrder(bytes32 _orderID, bytes32 _matchedOrderID) external onlyDarknode(msg.sender) {
        require(orders[_orderID].state == OrderState.Open, "invalid order status");
        require(orders[_matchedOrderID].state == OrderState.Open, "invalid order status");
        orders[_orderID].state = OrderState.Confirmed;
        orders[_orderID].confirmer = msg.sender;
        orders[_orderID].matchedOrder = _matchedOrderID;
        orders[_orderID].blockNumber = block.number;
        orders[_matchedOrderID].state = OrderState.Confirmed;
        orders[_matchedOrderID].confirmer = msg.sender;
        orders[_matchedOrderID].matchedOrder = _orderID;
        orders[_matchedOrderID].blockNumber = block.number;
    }

    function cancelOrder(bytes32 _orderID) external {
        require(orders[_orderID].state == OrderState.Open, "invalid order state");
        address brokerVerifier = address(settlementRegistry.brokerVerifierContract(orders[_orderID].settlementID));
        require(msg.sender == orders[_orderID].trader || msg.sender == brokerVerifier, "not authorized");
        orders[_orderID].state = OrderState.Canceled;
        orders[_orderID].blockNumber = block.number;
    }

    function orderState(bytes32 _orderID) external view returns (OrderState) {
        return orders[_orderID].state;
    }

    function orderMatch(bytes32 _orderID) external view returns (bytes32) {
        return orders[_orderID].matchedOrder;
    }

    function orderPriority(bytes32 _orderID) external view returns (uint256) {
        return orders[_orderID].priority;
    }

    function orderTrader(bytes32 _orderID) external view returns (address) {
        return orders[_orderID].trader;
    }

    function orderConfirmer(bytes32 _orderID) external view returns (address) {
        return orders[_orderID].confirmer;
    }

    function orderBlockNumber(bytes32 _orderID) external view returns (uint256) {
        return orders[_orderID].blockNumber;
    }

    function orderDepth(bytes32 _orderID) external view returns (uint256) {
        if (orders[_orderID].blockNumber == 0) {
            return 0;
        }
        return (block.number - orders[_orderID].blockNumber);
    }

    function ordersCount() external view returns (uint256) {
        return orderbook.length;
    }

    function getOrders(uint256 _offset, uint256 _limit) external view returns (bytes32[], address[], uint8[]) {
        if (_offset >= orderbook.length) {
            return;
        }
        uint256 limit = _limit;
        if (_offset + limit > orderbook.length) {
            limit = orderbook.length - _offset;
        }
        bytes32[] memory orderIDs = new bytes32[](limit);
        address[] memory traderAddresses = new address[](limit);
        uint8[] memory states = new uint8[](limit);
        for (uint256 i = 0; i < limit; i++) {
            bytes32 order = orderbook[i + _offset];
            orderIDs[i] = order;
            traderAddresses[i] = orders[order].trader;
            states[i] = uint8(orders[order].state);
        }
        return (orderIDs, traderAddresses, states);
    }
}

library SettlementUtils {
    struct OrderDetails {
        uint64 settlementID;
        uint64 tokens;
        uint256 price;
        uint256 volume;
        uint256 minimumVolume;
    }

    function hashOrder(bytes details, OrderDetails memory order) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(details, order.settlementID, order.tokens, order.price, order.volume, order.minimumVolume));
    }

    function verifyMatchDetails(OrderDetails memory _buy, OrderDetails memory _sell) internal pure returns (bool) {
        if (!verifyTokens(_buy.tokens, _sell.tokens)) {
            return false;
        }
        if (_buy.price < _sell.price) {
            return false;
        }
        if (_buy.volume < _sell.minimumVolume) {
            return false;
        }
        if (_sell.volume < _buy.minimumVolume) {
            return false;
        }
        if (_buy.settlementID != _sell.settlementID) {
            return false;
        }
        return true;
    }

    function verifyTokens(uint64 _buyTokens, uint64 _sellToken) internal pure returns (bool) {
        return ((uint32(_buyTokens) == uint32(_sellToken >> 32)) && (uint32(_sellToken) == uint32(_buyTokens >> 32)) && (uint32(_buyTokens >> 32) <= uint32(_buyTokens)));
    }
}

contract RenExTokens is Ownable {
    struct TokenDetails {
        address addr;
        uint8 decimals;
        bool registered;
    }

    mapping(uint32 => TokenDetails) public tokens;
    mapping(uint32 => bool) private detailsSubmitted;

    event LogTokenRegistered(uint32 tokenCode, address tokenAddress, uint8 tokenDecimals);
    event LogTokenDeregistered(uint32 tokenCode);

    constructor(string _VERSION) public {
    }

    function registerToken(uint32 _tokenCode, address _tokenAddress, uint8 _tokenDecimals) public onlyOwner {
        require(!tokens[_tokenCode].registered, "already registered");
        if (detailsSubmitted[_tokenCode]) {
            require(tokens[_tokenCode].addr == _tokenAddress, "different address");
            require(tokens[_tokenCode].decimals == _tokenDecimals, "different decimals");
        } else {
            detailsSubmitted[_tokenCode] = true;
        }
        tokens[_tokenCode] = TokenDetails({
            addr: _tokenAddress,
            decimals: _tokenDecimals,
            registered: true
        });
        emit LogTokenRegistered(_tokenCode, _tokenAddress, _tokenDecimals);
    }

    function deregisterToken(uint32 _tokenCode) external onlyOwner {
        require(tokens[_tokenCode].registered, "not registered");
        tokens[_tokenCode].registered = false;
        emit LogTokenDeregistered(_tokenCode);
    }
}

contract RenExSettlement is Ownable {
    using SafeMath for uint256;

    Orderbook public orderbookContract;
    RenExTokens public renExTokensContract;
    RenExBalances public renExBalancesContract;

    enum OrderStatus {None, Submitted, Settled, Slashed}

    struct TokenPair {
        RenExTokens.TokenDetails priorityToken;
        RenExTokens.TokenDetails secondaryToken;
    }

    struct ValueWithFees {
        uint256 value;
        uint256 fees;
    }

    struct Fraction {
        uint256 numerator;
        uint256 denominator;
    }

    struct SettlementDetails {
        uint256 leftVolume;
        uint256 rightVolume;
        uint256 leftTokenFee;
        uint256 rightTokenFee;
        address leftTokenAddress;
        address rightTokenAddress;
    }

    event LogOrderbookUpdated(Orderbook previousOrderbook, Orderbook nextOrderbook);
    event LogRenExTokensUpdated(RenExTokens previousRenExTokens, RenExTokens nextRenExTokens);
    event LogRenExBalancesUpdated(RenExBalances previousRenExBalances, RenExBalances nextRenExBalances);
    event LogSubmissionGasPriceLimitUpdated(uint256 previousSubmissionGasPriceLimit, uint256 nextSubmissionGasPriceLimit);
    event LogSlasherUpdated(address previousSlasher, address nextSlasher);

    mapping(bytes32 => SettlementUtils.OrderDetails) public orderDetails;
    mapping(bytes32 => address) public orderSubmitter;
    mapping(bytes32 => OrderStatus) public orderStatus;
    mapping(bytes32 => mapping(bytes32 => uint256)) public matchTimestamp;

    modifier withGasPriceLimit(uint256 _gasPriceLimit) {
        require(tx.gasprice <= _gasPriceLimit, "gas price too high");
        _;
    }

    modifier onlySlasher() {
        require(msg.sender == slasherAddress, "unauthorized");
        _;
    }

    constructor(
        string _VERSION,
        Orderbook _orderbookContract,
        RenExTokens _renExTokensContract,
        RenExBalances _renExBalancesContract,
        address _slasherAddress,
        uint256 _submissionGasPriceLimit
    ) public {
        orderbookContract = _orderbookContract;
        renExTokensContract = _renExTokensContract;
        renExBalancesContract = _renExBalancesContract;
        slasherAddress = _slasherAddress;
        submissionGasPriceLimit = _submissionGasPriceLimit;
    }

    function updateOrderbook(Orderbook _newOrderbookContract) external onlyOwner {
        emit LogOrderbookUpdated(orderbookContract, _newOrderbookContract);
        orderbookContract = _newOrderbookContract;
    }

    function updateRenExTokens(RenExTokens _newRenExTokensContract) external onlyOwner {
        emit LogRenExTokensUpdated(renExTokensContract, _newRenExTokensContract);
        renExTokensContract = _newRenExTokensContract;
    }

    function updateRenExBalances(RenExBalances _newRenExBalancesContract) external onlyOwner {
        emit LogRenExBalancesUpdated(renExBalancesContract, _newRenExBalancesContract);
        renExBalancesContract = _newRenExBalancesContract;
    }

    function updateSubmissionGasPriceLimit(uint256 _newSubmissionGasPriceLimit) external onlyOwner {
        emit LogSubmissionGasPriceLimitUpdated(submissionGasPriceLimit, _newSubmissionGasPriceLimit);
        submissionGasPriceLimit = _newSubmissionGasPriceLimit;
    }

    function updateSlasher(address _newSlasherAddress) external onlyOwner {
        emit LogSlasherUpdated(slasherAddress, _newSlasherAddress);
        slasherAddress = _newSlasherAddress;
    }

    function submitOrder(
        bytes _prefix,
        uint64 _settlementID,
        uint64 _tokens,
        uint256 _price,
        uint256 _volume,
        uint256 _minimumVolume
    ) external withGasPriceLimit(submissionGasPriceLimit) {
        SettlementUtils.OrderDetails memory order = SettlementUtils.OrderDetails({
            settlementID: _settlementID,
            tokens: _tokens,
            price: _price,
            volume: _volume,
            minimumVolume: _minimumVolume
        });
        bytes32 orderID = SettlementUtils.hashOrder(_prefix, order);
        require(orderStatus[orderID] == OrderStatus.None, "order already submitted");
        require(orderbookContract.orderState(orderID) == Orderbook.OrderState.Confirmed, "unconfirmed order");
        orderSubmitter[orderID] = msg.sender;
        orderStatus[orderID] = OrderStatus.Submitted;
        orderDetails[orderID] = order;
    }

    function settle(bytes32 _buyID, bytes32 _sellID) external {
        require(orderStatus[_buyID] == OrderStatus.Submitted, "invalid buy status");
        require(orderStatus[_sellID] == OrderStatus.Submitted, "invalid sell status");
        require(
            orderDetails[_buyID].settlementID == RENEX_ATOMIC_SETTLEMENT_ID ||
            orderDetails[_buyID].settlementID == RENEX_SETTLEMENT_ID,
            "invalid settlement id"
        );
        require(SettlementUtils.verifyMatchDetails(orderDetails[_buyID], orderDetails[_sellID]), "incompatible orders");
        require(orderbookContract.orderMatch(_buyID) == _sellID, "unconfirmed orders");
        TokenPair memory tokens = getTokenDetails(orderDetails[_buyID].tokens);
        require(tokens.priorityToken.registered, "unregistered priority token");
        require(tokens.secondaryToken.registered, "unregistered secondary token");
        address buyer = orderbookContract.orderTrader(_buyID);
        address seller = orderbookContract.orderTrader(_sellID);
        require(buyer != seller, "orders from same trader");
        execute(_buyID, _sellID, buyer, seller, tokens);
        matchTimestamp[_buyID][_sellID] = now;
        orderStatus[_buyID] = OrderStatus.Settled;
        orderStatus[_sellID] = OrderStatus.Settled;
    }

    function slash(bytes32 _guiltyOrderID) external onlySlasher {
        require(orderDetails[_guiltyOrderID].settlementID == RENEX_ATOMIC_SETTLEMENT_ID, "slashing non-atomic trade");
        bytes32 innocentOrderID = orderbookContract.orderMatch(_guiltyOrderID);
        require(orderStatus[_guiltyOrderID] == OrderStatus.Settled, "invalid order status");
        require(orderStatus[innocentOrderID] == OrderStatus.Settled, "invalid order status");
        orderStatus[_guiltyOrderID] = OrderStatus.Slashed;
        (bytes32 buyID, bytes32 sellID) = isBuyOrder(_guiltyOrderID) ? (_guiltyOrderID, innocentOrderID) : (innocentOrderID, _guiltyOrderID);
        TokenPair memory tokens = getTokenDetails(orderDetails[buyID].tokens);
        SettlementDetails memory settlementDetails = calculateAtomicFees(buyID, sellID, tokens);
        renExBalancesContract.transferBalanceWithFee(
            orderbookContract.orderTrader(_guiltyOrderID),
            orderbookContract.orderTrader(innocentOrderID),
            settlementDetails.leftTokenAddress,
            settlementDetails.leftTokenFee,
            0,
            address(0)
        );
        renExBalancesContract.transferBalanceWithFee(
            orderbookContract.orderTrader(_guiltyOrderID),
            slasherAddress,
            settlementDetails.leftTokenAddress,
            settlementDetails.leftTokenFee,
            0,
            address(0)
        );
    }

    function getMatchDetails(bytes32 _orderID) external view returns (
        bool settled,
        bool orderIsBuy,
        bytes32 matchedID,
        uint256 priorityVolume,
        uint256 secondaryVolume,
        uint256 priorityFee,
        uint256 secondaryFee,
        uint32 priorityToken,
        uint32 secondaryToken
    ) {
        matchedID = orderbookContract.orderMatch(_orderID);
        orderIsBuy = isBuyOrder(_orderID);
        (bytes32 buyID, bytes32 sellID) = orderIsBuy ? (_orderID, matchedID) : (matchedID, _orderID);
        SettlementDetails memory settlementDetails = calculateSettlementDetails(
            buyID,
            sellID,
            getTokenDetails(orderDetails[buyID].tokens)
        );
        return (
            orderStatus[_orderID] == OrderStatus.Settled || orderStatus[_orderID] == OrderStatus.Slashed,
            orderIsBuy,
            matchedID,
            settlementDetails.leftVolume,
            settlementDetails.rightVolume,
            settlementDetails.leftTokenFee,
            settlementDetails.rightTokenFee,
            uint32(orderDetails[buyID].tokens >> 32),
            uint32(orderDetails[buyID].tokens)
        );
    }

    function hashOrder(
        bytes _prefix,
        uint64 _settlementID,
        uint64 _tokens,
        uint256 _price,
        uint256 _volume,
        uint256 _minimumVolume
    ) external pure returns (bytes32) {
        return SettlementUtils.hashOrder(_prefix, SettlementUtils.OrderDetails({
            settlementID: _settlementID,
            tokens: _tokens,
            price: _price,
            volume: _volume,
            minimumVolume: _minimumVolume
        }));
    }

    function execute(
        bytes32 _buyID,
        bytes32 _sellID,
        address _buyer,
        address _seller,
        TokenPair memory _tokens
    ) private {
        SettlementDetails memory settlementDetails = (orderDetails[_buyID].settlementID == RENEX_ATOMIC_SETTLEMENT_ID) ?
            settlementDetails = calculateAtomicFees(_buyID, _sellID, _tokens) :
            settlementDetails = calculateSettlementDetails(_buyID, _sellID, _tokens);
        renExBalancesContract.transferBalanceWithFee(
            _buyer,
            _seller,
            settlementDetails.leftTokenAddress,
            settlementDetails.leftVolume,
            settlementDetails.leftTokenFee,
            orderSubmitter[_buyID]
        );
        renExBalancesContract.transferBalanceWithFee(
            _seller,
            _buyer,
            settlementDetails.rightTokenAddress,
            settlementDetails.rightVolume,
            settlementDetails.rightTokenFee,
            orderSubmitter[_sellID]
        );
    }

    function calculateSettlementDetails(
        bytes32 _buyID,
        bytes32 _sellID,
        TokenPair memory _tokens
    ) private view returns (SettlementDetails memory) {
        Fraction memory midPrice = Fraction(orderDetails[_buyID].price.add(orderDetails[_sellID].price), 2);
        uint256 commonVolume = Math.min256(orderDetails[_buyID].volume, orderDetails[_sellID].volume);
        uint256 priorityTokenVolume = joinFraction(
            commonVolume.mul(midPrice.numerator),
            midPrice.denominator,
            int16(_tokens.priorityToken.decimals) - PRICE_OFFSET - VOLUME_OFFSET
        );
        uint256 secondaryTokenVolume = joinFraction(
            commonVolume,
            1,
            int16(_tokens.secondaryToken.decimals) - VOLUME_OFFSET
        );
        ValueWithFees memory priorityVwF = subtractDarknodeFee(priorityTokenVolume);
        ValueWithFees memory secondaryVwF = subtractDarknodeFee(secondaryTokenVolume);
        return SettlementDetails({
            leftVolume: priorityVwF.value,
            rightVolume: secondaryVwF.value,
            leftTokenFee: priorityVwF.fees,
            rightTokenFee: secondaryVwF.fees,
            leftTokenAddress: _tokens.priorityToken.addr,
            rightTokenAddress: _tokens.secondaryToken.addr
        });
    }

    function calculateAtomicFees(
        bytes32 _buyID,
        bytes32 _sellID,
        TokenPair memory _tokens
    ) private view returns (SettlementDetails memory) {
        Fraction memory midPrice = Fraction(orderDetails[_buyID].price.add(orderDetails[_sellID].price), 2);
        uint256 commonVolume = Math.min256(orderDetails[_buyID].volume, orderDetails[_sellID].volume);
        if (isEthereumBased(_tokens.secondaryToken.addr)) {
            uint256 secondaryTokenVolume = joinFraction(
                commonVolume,
                1,
                int16(_tokens.secondaryToken.decimals) - VOLUME_OFFSET
            );
            ValueWithFees memory secondaryVwF = subtractDarknodeFee(secondaryTokenVolume);
            return SettlementDetails({
                leftVolume: 0,
                rightVolume: 0,
                leftTokenFee: secondaryVwF.fees,
                rightTokenFee: secondaryVwF.fees,
                leftTokenAddress: _tokens.secondaryToken.addr,
                rightTokenAddress: _tokens.secondaryToken.addr
            });
        } else if (isEthereumBased(_tokens.priorityToken.addr)) {
            uint256 priorityTokenVolume = joinFraction(
                commonVolume.mul(midPrice.numerator),
                midPrice.denominator,
                int16(_tokens.priorityToken.decimals) - PRICE_OFFSET - VOLUME_OFFSET
            );
            ValueWithFees memory priorityVwF = subtractDarknodeFee(priorityTokenVolume);
            return SettlementDetails({
                leftVolume: 0,
                rightVolume: 0,
                leftTokenFee: priorityVwF.fees,
                rightTokenFee: priorityVwF.fees,
                leftTokenAddress: _tokens.priorityToken.addr,
                rightTokenAddress: _tokens.priorityToken.addr
            });
        } else {
            revert("non-eth atomic swaps are not supported");
        }
    }

    function isBuyOrder(bytes32 _orderID) private view returns (bool) {
        uint64 tokens = orderDetails[_orderID].tokens;
        uint32 firstToken = uint32(tokens >> 32);
        uint32 secondaryToken = uint32(tokens);
        return (firstToken < secondaryToken);
    }

    function subtractDarknodeFee(uint256 value) private pure returns (ValueWithFees memory) {
        uint256 newValue = (value.mul(DARKNODE_FEES_DENOMINATOR.sub(DARKNODE_FEES_NUMERATOR))).div(DARKNODE_FEES_DENOMINATOR);
        return ValueWithFees(newValue, value.sub(newValue));
    }

    function getTokenDetails(uint64 _tokens) private view returns (TokenPair memory) {
        (address priorityAddress, uint8 priorityDecimals, bool priorityRegistered) = renExTokensContract.tokens(uint32(_tokens >> 32));
        (address secondaryAddress, uint8 secondaryDecimals, bool secondaryRegistered) = renExTokensContract.tokens(uint32(_tokens));
        return TokenPair({
            priorityToken: RenExTokens.TokenDetails(priorityAddress, priorityDecimals, priorityRegistered),
            secondaryToken: RenExTokens.TokenDetails(secondaryAddress, secondaryDecimals, secondaryRegistered)
        });
    }

    function isEthereumBased(address _tokenAddress) private pure returns (bool) {
        return (_tokenAddress != address(0));
    }

    function joinFraction(uint256 _numerator, uint256 _denominator, int16 _scale) private pure returns (uint256) {
        if (_scale >= 0) {
            assert(_scale <= 77);
            return _numerator.mul(10 ** uint256(_scale)).div(_denominator);
        } else {
            return (_numerator.div(_denominator)).div(10 ** uint256(-_scale));
        }
    }
}

contract RenExBrokerVerifier is Ownable {
    event LogBalancesContractUpdated(address previousBalancesContract, address nextBalancesContract);
    event LogBrokerRegistered(address broker);
    event LogBrokerDeregistered(address broker);

    mapping(address => bool) public brokers;
    mapping(address => uint256) public traderNonces;

    modifier onlyBalancesContract() {
        require(msg.sender == balancesContract, "not authorized");
        _;
    }

    constructor(string _VERSION) public {
    }

    function updateBalancesContract(address _balancesContract) external onlyOwner {
        emit LogBalancesContractUpdated(balancesContract, _balancesContract);
        balancesContract = _balancesContract;
    }

    function registerBroker(address _broker) external onlyOwner {
        require(!brokers[_broker], "already registered");
        brokers[_broker] = true;
        emit LogBrokerRegistered(_broker);
    }

    function deregisterBroker(address _broker) external onlyOwner {
        require(brokers[_broker], "not registered");
        brokers[_broker] = false;
        emit LogBrokerDeregistered(_broker);
    }

    function verifyOpenSignature(address _trader, bytes _signature, bytes32 _orderID) external view returns (bool) {
        bytes memory data = abi.encodePacked("Republic Protocol: open: ", _trader, _orderID);
        address signer = Utils.addr(data, _signature);
        return (brokers[signer] == true);
    }

    function verifyWithdrawSignature(address _trader, bytes _signature) external onlyBalancesContract returns (bool) {
        bytes memory data = abi.encodePacked("Republic Protocol: withdraw: ", _trader, traderNonces[_trader]);
        address signer = Utils.addr(data, _signature);
        if (brokers[signer]) {
            traderNonces[_trader] += 1;
            return true;
        }
        return false;
    }
}

contract RenExBalances is Ownable {
    using SafeMath for uint256;
    using CompatibleERC20Functions for CompatibleERC20;

    RenExSettlement public settlementContract;
    RenExBrokerVerifier public brokerVerifierContract;
    DarknodeRewardVault public rewardVaultContract;

    event LogBalanceDecreased(address trader, ERC20 token, uint256 value);
    event LogBalanceIncreased(address trader, ERC20 token, uint256 value);
    event LogRenExSettlementContractUpdated(address previousRenExSettlementContract, address newRenExSettlementContract);
    event LogRewardVaultContractUpdated(address previousRewardVaultContract, address newRewardVaultContract);
    event LogBrokerVerifierContractUpdated(address previousBrokerVerifierContract, address newBrokerVerifierContract);

    mapping(address => mapping(address => uint256)) public traderBalances;
    mapping(address => mapping(address => uint256)) public traderWithdrawalSignals;

    constructor(string _VERSION, DarknodeRewardVault _rewardVaultContract, RenExBrokerVerifier _brokerVerifierContract) public {
        rewardVaultContract = _rewardVaultContract;
        brokerVerifierContract = _brokerVerifierContract;
    }

    modifier onlyRenExSettlementContract() {
        require(msg.sender == address(settlementContract), "not authorized");
        _;
    }

    modifier withBrokerSignatureOrSignal(address token, bytes _signature) {
        address trader = msg.sender;
        if (_signature.length > 0) {
            require(brokerVerifierContract.verifyWithdrawSignature(trader, _signature), "invalid signature");
        } else {
            require(traderWithdrawalSignals[trader][token] != 0, "not signalled");
            require((now - traderWithdrawalSignals[trader][token]) > SIGNAL_DELAY, "signal time remaining");
            traderWithdrawalSignals[trader][token] = 0;
        }
        _;
    }

    function updateRenExSettlementContract(RenExSettlement _newSettlementContract) external onlyOwner {
        emit LogRenExSettlementContractUpdated(settlementContract, _newSettlementContract);
        settlementContract = _newSettlementContract;
    }

    function updateRewardVaultContract(DarknodeRewardVault _newRewardVaultContract) external onlyOwner {
        emit LogRewardVaultContractUpdated(rewardVaultContract, _newRewardVaultContract);
        rewardVaultContract = _newRewardVaultContract;
    }

    function updateBrokerVerifierContract(RenExBrokerVerifier _newBrokerVerifierContract) external onlyOwner {
        emit LogBrokerVerifierContractUpdated(brokerVerifierContract, _newBrokerVerifierContract);
        brokerVerifierContract = _newBrokerVerifierContract;
    }

    function transferBalanceWithFee(address _traderFrom, address _traderTo, address token, uint256 value, uint256 _fee, address _feePayee) external onlyRenExSettlementContract {
        require(traderBalances[_traderFrom][token] >= _fee, "insufficient funds for fee");
        if (address(token) == address(0)) {
            rewardVaultContract.deposit.value(_fee)(_feePayee, ERC20(token), _fee);
        } else {
            CompatibleERC20(token).safeApprove(rewardVaultContract, _fee);
            rewardVaultContract.deposit(_feePayee, ERC20(token), _fee);
        }
        privateDecrementBalance(_traderFrom, ERC20(token), value.add(_fee));
        if (value > 0) {
            privateIncrementBalance(_traderTo, ERC20(token), value);
        }
    }

    function deposit(ERC20 token, uint256 value) external payable {
        address trader = msg.sender;
        uint256 receivedValue = value;
        if (address(token) == address(0)) {
            require(msg.value == value, "mismatched value parameter and tx value");
        } else {
            require(msg.value == 0, "unexpected ether transfer");
            receivedValue = CompatibleERC20(token).safeTransferFromWithFees(trader, this, value);
        }
        privateIncrementBalance(trader, token, receivedValue);
    }

    function withdraw(ERC20 token, uint256 value, bytes _signature) external withBrokerSignatureOrSignal(token, _signature) {
        address trader = msg.sender;
        privateDecrementBalance(trader, token, value);
        if (address(token) == address(0)) {
            trader.transfer(value);
        } else {
            CompatibleERC20(token).safeTransfer(trader, value);
        }
    }

    function signalBackupWithdraw(address token) external {
        traderWithdrawalSignals[msg.sender][token] = now;
    }

    function privateIncrementBalance(address _trader, ERC20 token, uint256 value) private {
        traderBalances[_trader][token] = traderBalances[_trader][token].add(value);
        emit LogBalanceIncreased(_trader, token, value);
    }

    function privateDecrementBalance(address _trader, ERC20 token, uint256 value) private {
        require(traderBalances[_trader][token] >= value, "insufficient funds");
        traderBalances[_trader][token] = traderBalances[_trader][token].sub(value);
        emit LogBalanceDecreased(_trader, token, value);
    }
}
```