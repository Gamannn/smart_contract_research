```solidity
pragma solidity ^0.4.24;

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
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

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
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
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
    
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
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
    mapping(address => mapping(address => uint256)) internal allowed;
    
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
    
    function increaseApproval(address spender, uint256 addedValue) public whenNotPaused returns (bool success) {
        return super.increaseApproval(spender, addedValue);
    }
    
    function decreaseApproval(address spender, uint256 subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseApproval(spender, subtractedValue);
    }
}

contract BurnableToken is BasicToken {
    event Burn(address indexed burner, uint256 value);
    
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }
    
    function _burn(address burner, uint256 value) internal {
        require(value <= balances[burner]);
        balances[burner] = balances[burner].sub(value);
        totalSupply_ = totalSupply_.sub(value);
        emit Burn(burner, value);
        emit Transfer(burner, address(0), value);
    }
}

contract RepublicToken is PausableToken, BurnableToken {
    string public constant name = "Republic Token";
    string public constant symbol = "REN";
    uint8 public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 1000000000 * 10**uint256(decimals);
    
    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
    }
    
    function transfer(address to, uint256 value) public returns (bool) {
        return super.transfer(to, value);
    }
}

library LinkedList {
    address public constant NULL = 0x0;
    
    struct Node {
        bool exists;
        address next;
        address prev;
    }
    
    struct List {
        mapping(address => Node) list;
    }
    
    function insertBefore(List storage self, address target, address newNode) internal {
        require(!isInList(self, newNode), "already in list");
        require(isInList(self, target) || target == NULL, "not in list");
        
        address prev = self.list[target].prev;
        self.list[newNode].prev = target;
        self.list[newNode].next = prev;
        self.list[target].prev = newNode;
        self.list[prev].next = newNode;
        self.list[newNode].exists = true;
    }
    
    function insertAfter(List storage self, address target, address newNode) internal {
        require(!isInList(self, newNode), "already in list");
        require(isInList(self, target) || target == NULL, "not in list");
        
        address next = self.list[target].next;
        self.list[newNode].next = target;
        self.list[newNode].prev = next;
        self.list[target].next = newNode;
        self.list[next].prev = newNode;
        self.list[newNode].exists = true;
    }
    
    function remove(List storage self, address node) internal {
        require(isInList(self, node), "not in list");
        if (node == NULL) {
            return;
        }
        
        address next = self.list[node].next;
        address prev = self.list[node].prev;
        self.list[next].prev = prev;
        self.list[prev].next = next;
        self.list[node].exists = false;
        delete self.list[node];
    }
    
    function prepend(List storage self, address node) internal {
        insertBefore(self, head(self), node);
    }
    
    function append(List storage self, address node) internal {
        insertAfter(self, tail(self), node);
    }
    
    function swap(List storage self, address left, address right) internal {
        address rightPrev = self.list[right].prev;
        remove(self, right);
        insertAfter(self, left, right);
        remove(self, left);
        insertAfter(self, rightPrev, left);
    }
    
    function isInList(List storage self, address node) internal view returns (bool) {
        return self.list[node].exists;
    }
    
    function head(List storage self) internal view returns (address) {
        return self.list[NULL].prev;
    }
    
    function tail(List storage self) internal view returns (address) {
        return self.list[NULL].next;
    }
    
    function next(List storage self, address node) internal view returns (address) {
        require(isInList(self, node), "not in list");
        return self.list[node].next;
    }
    
    function prev(List storage self, address node) internal view returns (address) {
        require(isInList(self, node), "not in list");
        return self.list[node].prev;
    }
}

contract DarknodeRegistryStore is Ownable {
    string public VERSION;
    
    struct Darknode {
        address owner;
        uint256 bond;
        bytes publicKey;
        uint256 registeredAt;
        uint256 deregisteredAt;
    }
    
    mapping(address => Darknode) private darknodes;
    LinkedList.List private darknodeList;
    RepublicToken public ren;
    
    constructor(string _VERSION, RepublicToken _ren) public {
        VERSION = _VERSION;
        ren = _ren;
    }
    
    function addDarknode(address darknodeID, address darknodeOwner, uint256 bond, bytes publicKey, uint256 registeredAt, uint256 deregisteredAt) external onlyOwner {
        Darknode memory darknode = Darknode({
            owner: darknodeOwner,
            bond: bond,
            publicKey: publicKey,
            registeredAt: registeredAt,
            deregisteredAt: deregisteredAt
        });
        darknodes[darknodeID] = darknode;
        LinkedList.append(darknodeList, darknodeID);
    }
    
    function head() external view onlyOwner returns(address) {
        return LinkedList.head(darknodeList);
    }
    
    function next(address darknodeID) external view onlyOwner returns(address) {
        return LinkedList.next(darknodeList, darknodeID);
    }
    
    function removeDarknode(address darknodeID) external onlyOwner {
        uint256 bond = darknodes[darknodeID].bond;
        delete darknodes[darknodeID];
        LinkedList.remove(darknodeList, darknodeID);
        require(ren.transfer(owner, bond), "bond transfer failed");
    }
    
    function updateDarknodeBond(address darknodeID, uint256 bond) external onlyOwner {
        uint256 previousBond = darknodes[darknodeID].bond;
        darknodes[darknodeID].bond = bond;
        if (previousBond > bond) {
            require(ren.transfer(owner, previousBond - bond), "cannot transfer bond");
        }
    }
    
    function updateDarknodeDeregisteredAt(address darknodeID, uint256 deregisteredAt) external onlyOwner {
        darknodes[darknodeID].deregisteredAt = deregisteredAt;
    }
    
    function darknodeOwner(address darknodeID) external view onlyOwner returns (address) {
        return darknodes[darknodeID].owner;
    }
    
    function darknodeBond(address darknodeID) external view onlyOwner returns (uint256) {
        return darknodes[darknodeID].bond;
    }
    
    function darknodeRegisteredAt(address darknodeID) external view onlyOwner returns (uint256) {
        return darknodes[darknodeID].registeredAt;
    }
    
    function darknodeDeregisteredAt(address darknodeID) external view onlyOwner returns (uint256) {
        return darknodes[darknodeID].deregisteredAt;
    }
    
    function darknodePublicKey(address darknodeID) external view onlyOwner returns (bytes) {
        return darknodes[darknodeID].publicKey;
    }
}

contract DarknodeRegistry is Ownable {
    string public VERSION;
    
    struct Epoch {
        uint256 epochhash;
        uint256 blocknumber;
    }
    
    uint256 public numDarknodes;
    uint256 public numDarknodesNextEpoch;
    uint256 public numDarknodesPreviousEpoch;
    
    uint256 public minimumBond;
    uint256 public minimumPodSize;
    uint256 public minimumEpochInterval;
    
    address public slasher;
    uint256 public nextMinimumBond;
    uint256 public nextMinimumPodSize;
    uint256 public nextMinimumEpochInterval;
    address public nextSlasher;
    
    Epoch currentEpoch;
    Epoch previousEpoch;
    
    RepublicToken public ren;
    DarknodeRegistryStore public store;
    
    event LogMinimumBondUpdated(uint256 previousMinimumBond, uint256 nextMinimumBond);
    event LogMinimumPodSizeUpdated(uint256 previousMinimumPodSize, uint256 nextMinimumPodSize);
    event LogMinimumEpochIntervalUpdated(uint256 previousMinimumEpochInterval, uint256 nextMinimumEpochInterval);
    event LogSlasherUpdated(address previousSlasher, address nextSlasher);
    event LogDarknodeRegistered(address indexed darknodeID, uint256 bond);
    event LogDarknodeDeregistered(address indexed darknodeID);
    event LogDarknodeOwnerRefunded(address indexed owner, uint256 amount);
    
    modifier onlyDarknodeOwner(address darknodeID) {
        require(store.darknodeOwner(darknodeID) == msg.sender, "must be darknode owner");
        _;
    }
    
    modifier onlyRefunded(address darknodeID) {
        require(isRefunded(darknodeID), "must be refunded or never registered");
        _;
    }
    
    modifier onlyDeregisterable(address darknodeID) {
        require(isDeregisterable(darknodeID), "must be deregisterable");
        _;
    }
    
    modifier onlyDeregistered(address darknodeID) {
        require(isDeregistered(darknodeID), "must be deregistered for at least one epoch");
        _;
    }
    
    modifier onlySlasher() {
        require(slasher == msg.sender, "must be slasher");
        _;
    }
    
    constructor(
        string _VERSION,
        RepublicToken _ren,
        DarknodeRegistryStore _store,
        uint256 _minimumBond,
        uint256 _minimumPodSize,
        uint256 _minimumEpochInterval
    ) public {
        VERSION = _VERSION;
        ren = _ren;
        store = _store;
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
    
    function register(address darknodeID, bytes publicKey, uint256 bond) external onlyRefunded(darknodeID) {
        require(bond >= minimumBond, "insufficient bond");
        require(ren.transferFrom(msg.sender, address(this), bond), "bond transfer failed");
        ren.transfer(address(store), bond);
        store.addDarknode(
            darknodeID,
            msg.sender,
            bond,
            publicKey,
            currentEpoch.blocknumber + minimumEpochInterval,
            0
        );
        numDarknodesNextEpoch += 1;
        emit LogDarknodeRegistered(darknodeID, bond);
    }
    
    function deregister(address darknodeID) external onlyDeregisterable(darknodeID) onlyDarknodeOwner(darknodeID) {
        store.updateDarknodeDeregisteredAt(darknodeID, currentEpoch.blocknumber + minimumEpochInterval);
        numDarknodesNextEpoch -= 1;
        emit LogDarknodeDeregistered(darknodeID);
    }
    
    function epoch() external {
        if (previousEpoch.blocknumber == 0) {
            require(msg.sender == owner, "not authorized (first epoch)");
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
