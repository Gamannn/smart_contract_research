pragma solidity ^0.4.24;

contract Ownable {
    address public owner;
    
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    
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
    
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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
    mapping (address => mapping (address => uint256)) internal allowed;
    
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool) {
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
    
    function allowance(
        address owner,
        address spender
    ) public view returns (uint256) {
        return allowed[owner][spender];
    }
    
    function increaseApproval(
        address spender,
        uint256 addedValue
    ) public returns (bool) {
        allowed[msg.sender][spender] = (
            allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
    
    function decreaseApproval(
        address spender,
        uint256 subtractedValue
    ) public returns (bool) {
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
    
    function transfer(
        address to,
        uint256 value
    ) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }
    
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }
    
    function approve(
        address spender,
        uint256 value
    ) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }
    
    function increaseApproval(
        address spender,
        uint addedValue
    ) public whenNotPaused returns (bool success) {
        return super.increaseApproval(spender, addedValue);
    }
    
    function decreaseApproval(
        address spender,
        uint subtractedValue
    ) public whenNotPaused returns (bool success) {
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
    uint256 public constant INITIAL_SUPPLY = 1000000000 * 10**uint256(decimals);
    
    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
    }
}

library LinkedList {
    address public constant NULL = 0x0;
    
    struct Node {
        bool active;
        address previous;
        address next;
    }
    
    struct List {
        mapping (address => Node) list;
    }
    
    function insertBefore(List storage self, address existing, address addr) internal {
        require(!contains(self, addr), "already in list");
        require(contains(self, existing) || existing == NULL, "not in list");
        
        address previous = self.list[existing].previous;
        self.list[addr].next = existing;
        self.list[addr].previous = previous;
        self.list[existing].previous = addr;
        self.list[previous].next = addr;
        self.list[addr].active = true;
    }
    
    function insertAfter(List storage self, address existing, address addr) internal {
        require(!contains(self, addr), "already in list");
        require(contains(self, existing) || existing == NULL, "not in list");
        
        address next = self.list[existing].next;
        self.list[addr].previous = existing;
        self.list[addr].next = next;
        self.list[existing].next = addr;
        self.list[next].previous = addr;
        self.list[addr].active = true;
    }
    
    function remove(List storage self, address addr) internal {
        require(contains(self, addr), "not in list");
        if (addr == NULL) {
            return;
        }
        
        address previous = self.list[addr].previous;
        address next = self.list[addr].next;
        self.list[previous].next = next;
        self.list[next].previous = previous;
        self.list[addr].active = false;
        delete self.list[addr];
    }
    
    function pushFront(List storage self, address addr) internal {
        insertBefore(self, head(self), addr);
    }
    
    function pushBack(List storage self, address addr) internal {
        insertAfter(self, tail(self), addr);
    }
    
    function moveToFront(List storage self, address from, address to) internal {
        address previous = self.list[to].previous;
        remove(self, to);
        insertAfter(self, from, to);
        remove(self, from);
        insertAfter(self, previous, from);
    }
    
    function contains(List storage self, address addr) internal view returns (bool) {
        return self.list[addr].active;
    }
    
    function head(List storage self) internal view returns (address) {
        return self.list[NULL].next;
    }
    
    function tail(List storage self) internal view returns (address) {
        return self.list[NULL].previous;
    }
    
    function next(List storage self, address addr) internal view returns (address) {
        require(contains(self, addr), "not in list");
        return self.list[addr].next;
    }
    
    function previous(List storage self, address addr) internal view returns (address) {
        require(contains(self, addr), "not in list");
        return self.list[addr].previous;
    }
}

contract DarknodeRegistry is Ownable {
    string public name;
    
    struct Darknode {
        address owner;
        uint256 bond;
        uint256 registeredAt;
        uint256 deregisteredAt;
        bytes publicKey;
    }
    
    mapping(address => Darknode) private darknodes;
    LinkedList.List private darknodeList;
    RepublicToken public token;
    
    constructor(
        string _name,
        RepublicToken _token
    ) public {
        name = _name;
        token = _token;
    }
    
    function register(
        address darknodeID,
        address owner,
        uint256 bond,
        bytes publicKey,
        uint256 registeredAt,
        uint256 deregisteredAt
    ) external onlyOwner {
        Darknode memory darknode = Darknode({
            owner: owner,
            bond: bond,
            publicKey: publicKey,
            registeredAt: registeredAt,
            deregisteredAt: deregisteredAt
        });
        darknodes[darknodeID] = darknode;
        LinkedList.pushBack(darknodeList, darknodeID);
    }
    
    function head() external view onlyOwner returns(address) {
        return LinkedList.head(darknodeList);
    }
    
    function next(address darknodeID) external view onlyOwner returns(address) {
        return LinkedList.next(darknodeList, darknodeID);
    }
    
    function deregister(address darknodeID) external onlyOwner {
        uint256 bond = darknodes[darknodeID].bond;
        delete darknodes[darknodeID];
        LinkedList.remove(darknodeList, darknodeID);
        require(token.transfer(owner, bond), "bond transfer failed");
    }
    
    function updateBond(address darknodeID, uint256 bond) external onlyOwner {
        uint256 oldBond = darknodes[darknodeID].bond;
        darknodes[darknodeID].bond = bond;
        if (oldBond > bond) {
            require(token.transfer(owner, oldBond - bond), "cannot transfer bond");
        }
    }
    
    function updateDeregisteredAt(address darknodeID, uint256 deregisteredAt) external onlyOwner {
        darknodes[darknodeID].deregisteredAt = deregisteredAt;
    }
    
    function ownerOf(address darknodeID) external view returns (address) {
        return darknodes[darknodeID].owner;
    }
    
    function bondOf(address darknodeID) external view onlyOwner returns (uint256) {
        return darknodes[darknodeID].bond;
    }
    
    function registeredAt(address darknodeID) external view onlyOwner returns (uint256) {
        return darknodes[darknodeID].registeredAt;
    }
    
    function deregisteredAt(address darknodeID) external view onlyOwner returns (uint256) {
        return darknodes[darknodeID].deregisteredAt;
    }
    
    function publicKeyOf(address darknodeID) external view onlyOwner returns (bytes) {
        return darknodes[darknodeID].publicKey;
    }
}

contract DarknodeRegistryV2 is Ownable {
    string public name;
    
    struct Epoch {
        uint256 blockhashValue;
        uint256 blockNumber;
    }
    
    uint256 public currentEpoch;
    uint256 public currentEpochBlock;
    uint256 public numDarknodesPrevious;
    uint256 public minimumBond;
    uint256 public minimumPodSize;
    uint256 public minimumEpochInterval;
    address public slasher;
    uint256 public nextMinimumBond;
    uint256 public nextMinimumPodSize;
    uint256 public nextMinimumEpochInterval;
    address public nextSlasher;
    
    Epoch public previousEpoch;
    Epoch public currentEpochData;
    
    event LogMinimumBondUpdated(uint256 previous, uint256 current);
    event LogMinimumPodSizeUpdated(uint256 previous, uint256 current);
    event LogMinimumEpochIntervalUpdated(uint256 previous, uint256 current);
    event LogSlasherUpdated(address previous, address current);
    
    modifier onlyDarknodeOwner(address darknodeID) {
        require(darknodeRegistry.ownerOf(darknodeID) == msg.sender, "must be darknode owner");
        _;
    }
    
    modifier onlyRefundedOrNever(address darknodeID) {
        require(isRefundedOrNever(darknodeID), "must be refunded or never registered");
        _;
    }
    
    modifier onlyDeregisteredForAtLeastOneEpoch(address darknodeID) {
        require(isDeregisteredForAtLeastOneEpoch(darknodeID), "must be deregistered for at least one epoch");
        _;
    }
    
    modifier onlyDeregisterable(address darknodeID) {
        require(isDeregisterable(darknodeID), "must be deregisterable");
        _;
    }
    
    modifier onlySlasher() {
        require(slasher == msg.sender, "must be slasher");
        _;
    }
    
    DarknodeRegistry public darknodeRegistry;
    
    constructor(
        string _name,
        RepublicToken _token,
        DarknodeRegistry _darknodeRegistry,
        uint256 _minimumBond,
        uint256 _minimumPodSize,
        uint256 _minimumEpochInterval
    ) public {
        name = _name;
        darknodeRegistry = _darknodeRegistry;
        
        minimumBond = _minimumBond;
        nextMinimumBond = minimumBond;
        minimumPodSize = _minimumPodSize;
        nextMinimumPodSize = minimumPodSize;
        minimumEpochInterval = _minimumEpochInterval;
        nextMinimumEpochInterval = minimumEpochInterval;
        
        currentEpochData = Epoch({
            blockhashValue: uint256(blockhash(block.number - 1)),
            blockNumber: block.number
        });
        
        currentEpoch = 0;
        currentEpochBlock = 0;
        numDarknodesPrevious = 0;
    }
    
    function register(
        address darknodeID,
        bytes publicKey,
        uint256 bond
    ) external onlyRefundedOrNever(darknodeID) {
        require(bond >= minimumBond, "insufficient bond");
        require(token.transferFrom(msg.sender, address(this), bond), "bond transfer failed");
        token.transfer(address(darknodeRegistry), bond);
        darknodeRegistry.register(
            darknodeID,
            msg.sender,
            bond,
            publicKey,
            currentEpochData.blockNumber + minimumEpochInterval,
            0
        );
        currentEpochBlock += 1;
        emit LogDarknodeRegistered(darknodeID, bond);
    }
    
    function deregister(address darknodeID) external onlyDeregisterable(darknodeID) {
        darknodeRegistry.updateDeregisteredAt(darknodeID, currentEpochData.blockNumber + minimumEpochInterval);
        currentEpochBlock -= 1;
        emit LogDarknodeDeregistered(darknodeID);
    }
    
    function epoch() external {
        if (previousEpoch.blockNumber == 0) {
            require(msg.sender == owner, "not authorized (first epochs)");
        }
        require(block.number >= currentEpochData.blockNumber + minimumEpochInterval, "epoch interval has not passed");
        
        uint256 blockhashValue = uint256(blockhash(block.number - 1));
        previousEpoch = currentEpochData;
        currentEpochData = Epoch({
            blockhashValue: blockhashValue,
            blockNumber: block.number
        });
        
        numDarknodesPrevious = currentEpoch;
        currentEpoch = numDarknodesPrevious;
        
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
    }
    
    function updateMinimumBond(uint256 value) external onlyOwner {
        nextMinimumBond = value;
    }
    
    function updateMinimumPodSize(uint256 value) external onlyOwner {
        nextMinimumPodSize = value;
    }
    
    function updateSlasher(address value) external onlyOwner {
        nextSlasher = value;
    }
    
    function slash(
        address darknodeID,
        address reporter,
        address recipient
    ) external onlySlasher {
        uint256 bond = darknodeRegistry.bondOf(darknodeID) / 2;
        uint256 reward = bond / 4;
        
        darknodeRegistry.updateBond(darknodeID, bond);
        
        if (isDeregisterable(darknodeID)) {
            darknodeRegistry.updateDeregisteredAt(darknodeID, currentEpochData.blockNumber + minimumEpochInterval);
            currentEpochBlock -= 1;
            emit LogDarknodeDeregistered(darknodeID);
        }
        
        token.transfer(darknodeRegistry.ownerOf(reporter), reward);
        token.transfer(darknodeRegistry.ownerOf(recipient), reward);
    }
    
    function refund(address darknodeID) external onlyDeregisteredForAtLeastOneEpoch(darknodeID) {
        address owner = darknodeRegistry.ownerOf(darknodeID);
        uint256 bond = darknodeRegistry.bondOf(darknodeID);
        darknodeRegistry.deregister(darknodeID);
        token.transfer(owner, bond);
        emit LogDarknodeOwnerRefunded(owner, bond);
    }
    
    function ownerOf(address darknodeID) external view returns (address) {
        return darknodeRegistry.ownerOf(darknodeID);
    }
    
    function bondOf(address darknodeID) external view returns (uint256) {
        return darknodeRegistry.bondOf(darknodeID);
    }
    
    function publicKeyOf(address darknodeID) external view returns (bytes) {
        return darknodeRegistry.publicKeyOf(darknodeID);
    }
    
    function getDarknodes(address start, uint256 count) external view returns (address[]) {
        uint256 n = count;
        if (n == 0) {
            n = currentEpoch;
        }
        return getDarknodesFrom(start, n, false);
    }
    
    function getDarknodesFromPrevious(address start, uint256 count) external view returns (address[]) {
        uint256 n = count;
        if (n == 0) {
            n = numDarknodesPrevious;
        }
        return getDarknodesFrom(start, n, true);
    }
    
    function isPending(address darknodeID) external view returns (bool) {
        uint256 registeredAt = darknodeRegistry.registeredAt(darknodeID);
        return registeredAt != 0 && registeredAt > currentEpochData.blockNumber;
    }
    
    function isDeregistered(address darknodeID) external view returns (bool) {
        uint256 deregisteredAt = darknodeRegistry.deregisteredAt(darknodeID);
        return deregisteredAt != 0 && deregisteredAt > currentEpochData.blockNumber;
    }
    
    function isDeregisterable(address darknodeID) public view returns (bool) {
        uint256 deregisteredAt = darknodeRegistry.deregisteredAt(darknodeID);
        return isDeregistered(darknodeID) && deregisteredAt == 0;
    }
    
    function isRefundedOrNever(address darknodeID) public view returns (bool) {
        uint256 registeredAt = darknodeRegistry.registeredAt(darknodeID);
        uint256 deregisteredAt = darknodeRegistry.deregisteredAt(darknodeID);
        return registeredAt == 0 && deregisteredAt == 0;
    }
    
    function isDeregisteredForAtLeastOneEpoch(address darknodeID) public view returns (bool) {
        return isDeregistered(darknodeID) && darknodeRegistry.deregisteredAt(darknodeID) <= previousEpoch.blockNumber;
    }
    
    function isActive(address darknodeID) public view returns (bool) {
        return isActiveInEpoch(darknodeID, currentEpochData);
    }
    
    function isActiveInPrevious(address darknodeID) public view returns (bool) {
        return isActiveInEpoch(darknodeID, previousEpoch);
    }
    
    function isActiveInEpoch(address darknodeID, Epoch epoch) private view returns (bool) {
        uint256 registeredAt = darknodeRegistry.registeredAt(darknodeID);
        uint256 deregisteredAt = darknodeRegistry.deregisteredAt(darknodeID);
        bool registered = registeredAt != 0 && registeredAt <= epoch.blockNumber;
        bool notDeregistered = deregisteredAt == 0 || deregisteredAt > epoch.blockNumber;
        return registered && notDeregistered;
    }
    
    function getDarknodesFrom(address start, uint256 count, bool previous) private view returns (address[]) {
        uint256 n = count;
        if (n == 0) {
            n = currentEpoch;
        }
        
        address[] memory nodes = new address[](n);
        uint256 i = 0;
        address current = start;
        
        if (current == 0x0) {
            current = darknodeRegistry.head();
        }
        
        while (i < n) {
            if (current == 0x0) {
                break;
            }
            
            bool active;
            if (previous) {
                active = isActiveInPrevious(current);
            } else {
                active = isActive(current);
            }
            
            if (!active) {
                current = darknodeRegistry.next(current);
                continue;
            }
            
            nodes[i] = current;
            current = darknodeRegistry.next(current);
            i += 1;
        }
        
        return nodes;
    }
}

library SafeMath64 {
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

library SafeERC20 {
    using SafeMath for uint256;
    
    function safeTransfer(address token, address to, uint256 value) internal {
        IERC20(token).transfer(to, value);
        require(checkSuccess(), "transfer failed");
    }
    
    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        IERC20(token).transferFrom(from, to, value);
        require(checkSuccess(), "transferFrom failed");
    }
    
    function safeApprove(address token, address spender, uint256 value) internal {
        IERC20(token).approve(spender, value);
        require(checkSuccess(), "approve failed");
    }
    
    function safeTransferFromAndCheck(address token, address from, address to, uint256 value) internal returns (uint256) {
        uint256 before = IERC20(token).balanceOf(to);
        IERC20(token).transferFrom(from, to, value);
        require(checkSuccess(), "transferFrom failed");
        uint256 after = IERC20(token).balanceOf(to);
        return SafeMath.min(value, after.sub(before));
    }
    
    function checkSuccess() private pure returns (bool) {
        uint256 returnValue = 0;
        assembly {
            switch returndatasize
            case 0 {
                returnValue := 1
            }
            case 32 {
                returndatacopy(0x0, 0x0, 32)
                returnValue := mload(0x0)
            }
            default { }
        }
        return returnValue != 0;
    }
}

interface IERC20 {
    function transferFrom(address from, address to, uint256 value) external;
    function approve(address spender, uint256 value) external;
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract DarknodeGateway is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    string public name;
    address constant public ETHEREUM = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    DarknodeRegistryV2 public darknodeRegistry;
    mapping(address => mapping(address => uint256)) public deposits;
    
    event LogDarknodeRegistryUpdated(DarknodeRegistryV2 previous, DarknodeRegistryV2 current);
    
    constructor(string _name, DarknodeRegistryV2 _darknodeRegistry) public {
        name = _name;
        darknodeRegistry = _darknodeRegistry;
    }
    
    function updateDarknodeRegistry(DarknodeRegistryV2 _darknodeRegistry) public onlyOwner {
        emit LogDarknodeRegistryUpdated(darknodeRegistry, _darknodeRegistry);
        darknodeRegistry = _darknodeRegistry;
    }
    
    function deposit(address darknodeID, ERC20 token, uint256 value) public payable {
        uint256 actualValue = value;
        
        if (address(token) == ETHEREUM) {
            require(msg.value == value, "mismatched ether value");
        } else {
            require(msg.value == 0, "unexpected ether value");
            actualValue = IERC20(token).safeTransferFromAndCheck(msg.sender, address(this), value);
        }
        
        deposits[darknodeID][token] = deposits[darknodeID][token].add(actualValue);
    }
    
    function withdraw(address darknodeID, ERC20 token) public {
        address owner = darknodeRegistry.ownerOf(address(darknodeID));
        require(owner != 0x0, "invalid darknode owner");
        
        uint256 value = deposits[darknodeID][token];
        deposits[darknodeID][token] = 0;
        
        if (address(token) == ETHEREUM) {
            owner.transfer(value);
        } else {
            IERC20(token).safeTransfer(owner, value);
        }
    }
}
