```solidity
pragma solidity ^0.4.23;

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
        require(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    
    function power(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a ** b;
        require(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Exchange is Ownable {
    using SafeMath for uint256;
    
    address public feeAccount;
    uint256 public inactivityReleasePeriod;
    
    mapping(address => mapping(address => uint256)) public tokens;
    mapping(address => bool) public hardWithdrawRequests;
    mapping(address => bool) public admins;
    mapping(address => bool) public managers;
    mapping(bytes32 => bool) public withdrawn;
    mapping(bytes32 => bool) public paymentDelegations;
    mapping(bytes32 => uint256) public orderFills;
    mapping(bytes32 => uint256) public orderCancels;
    
    mapping(address => mapping(address => bool)) public delegated;
    
    mapping(address => uint256) public lastActiveTransaction;
    
    event Deposit(address token, address user, address to, uint256 amount, uint256 balance);
    event Payment(uint256 amountBuy, uint256 amountSell, uint256 expires, uint256 nonce, uint256 amount, uint256 tradeNonce, address token, address buyer, address seller);
    event Withdraw(address token, address user, address to, uint256 amount);
    event RequestHardWithdraw(address user, bool active);
    event Delegation(address user, address delegate, bool status);
    
    modifier onlyAdmin() {
        require(msg.sender == owner || managers[msg.sender] || admins[msg.sender]);
        _;
    }
    
    modifier onlyManager() {
        require(msg.sender == owner || admins[msg.sender]);
        _;
    }
    
    constructor(address _feeAccount, uint256 _inactivityReleasePeriod) public {
        owner = msg.sender;
        feeAccount = _feeAccount;
        inactivityReleasePeriod = _inactivityReleasePeriod;
    }
    
    function requestHardWithdraw(bool active) public {
        require(block.number.sub(lastActiveTransaction[msg.sender]) >= inactivityReleasePeriod);
        hardWithdrawRequests[msg.sender] = active;
        lastActiveTransaction[msg.sender] = block.number;
        emit RequestHardWithdraw(msg.sender, active);
    }
    
    function hardWithdraw(address token, uint256 amount) public returns (bool) {
        require(block.number.sub(lastActiveTransaction[msg.sender]) >= inactivityReleasePeriod);
        require(tokens[token][msg.sender] >= amount);
        require(hardWithdrawRequests[msg.sender] == true);
        
        tokens[token][msg.sender] = tokens[token][msg.sender].sub(amount);
        
        if (token == address(0)) {
            msg.sender.transfer(amount);
        } else {
            require(ERC20(token).transfer(msg.sender, amount));
        }
        
        emit Withdraw(token, msg.sender, msg.sender, amount);
        return true;
    }
    
    function setInactivityReleasePeriod(uint256 _inactivityReleasePeriod) onlyAdmin public returns (bool) {
        require(_inactivityReleasePeriod <= 2000000);
        require(_inactivityReleasePeriod >= 6000);
        inactivityReleasePeriod = _inactivityReleasePeriod;
        return true;
    }
    
    function setAdmin(address admin, bool isAdmin) onlyOwner public {
        admins[admin] = isAdmin;
    }
    
    function setManager(address manager, bool isManager) onlyManager public {
        managers[manager] = isManager;
    }
    
    function setFeeAccount(address _feeAccount) onlyManager public {
        feeAccount = _feeAccount;
    }
    
    function depositToken(address token, address to, uint256 amount) public {
        deposit(token, msg.sender, to, amount);
    }
    
    function deposit(address token, address from, address to, uint256 amount) public {
        tokens[token][to] = tokens[token][to].add(amount);
        lastActiveTransaction[from] = block.number;
        require(ERC20(token).transferFrom(from, address(this), amount));
        emit Deposit(token, from, to, amount, tokens[token][from]);
    }
    
    function depositEther(address to) payable public {
        tokens[address(0)][to] = tokens[address(0)][to].add(msg.value);
        lastActiveTransaction[msg.sender] = block.number;
        emit Deposit(address(0), msg.sender, to, msg.value, tokens[address(0)][msg.sender]);
    }
    
    function withdraw(address token, uint256 amount, address user, address to, uint256 nonce, uint8 v, bytes32 r, bytes32 s, uint256 feeWithdrawal) onlyAdmin public returns (bool) {
        if (token == address(0)) {
            require(tokens[address(0)][user] >= feeWithdrawal.mul(amount));
        } else {
            require(tokens[token][user] >= feeWithdrawal.mul(amount));
        }
        
        bytes32 hash = keccak256(address(this), token, amount, user, to, nonce, feeWithdrawal);
        require(!withdrawn[hash]);
        withdrawn[hash] = true;
        
        require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == user);
        
        if (token == address(0)) {
            tokens[address(0)][user] = tokens[address(0)][user].sub(feeWithdrawal.mul(amount));
            tokens[address(0)][feeAccount] = tokens[address(0)][feeAccount].add(feeWithdrawal);
        } else {
            tokens[token][user] = tokens[token][user].sub(feeWithdrawal.mul(amount));
            tokens[token][feeAccount] = tokens[token][feeAccount].add(feeWithdrawal);
        }
        
        require(ERC20(token).transfer(to, amount));
        
        lastActiveTransaction[user] = block.number;
        emit Withdraw(token, user, to, amount);
        return true;
    }
    
    function balanceOf(address token, address user) view public returns (uint256) {
        return tokens[token][user];
    }
    
    function cancelDelegation(address user, address delegate) onlyAdmin public returns (bool) {
        delegated[user][delegate] = false;
        emit Delegation(user, delegate, false);
        return false;
    }
    
    function delegate(address user, address delegate, uint256 nonce, uint8 v, bytes32 r, bytes32 s, bool status) onlyAdmin public returns (bool) {
        bytes32 hash = keccak256(address(this), user, delegate, nonce);
        require(!paymentDelegations[hash]);
        paymentDelegations[hash] = true;
        
        require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == user);
        
        delegated[user][delegate] = status;
        emit Delegation(user, delegate, status);
        return status;
    }
    
    function trade(uint256[6] orderValues, address[3] orderAddresses, uint8 v, bytes32[2] rs) onlyAdmin public returns (bool) {
        require(block.number < orderValues[2]);
        
        bytes32 orderHash = keccak256(address(this), orderValues[0], orderValues[1], orderValues[2], orderValues[3], orderAddresses[0], orderAddresses[1]);
        address signer = ecrecover(keccak256("\x19Ethereum Signed Message:\n32", orderHash), v, rs[0], rs[1]);
        
        require(signer == orderAddresses[2] || delegated[orderAddresses[2]][signer]);
        require(tokens[orderAddresses[0]][orderAddresses[2]] >= orderValues[4]);
        require(orderFills[orderHash].add(orderValues[4]) <= orderValues[0]);
        require(orderCancels[orderHash].add(orderValues[5]) <= orderValues[3]);
        
        tokens[orderAddresses[0]][orderAddresses[2]] = tokens[orderAddresses[0]][orderAddresses[2]].sub(orderValues[4]);
        tokens[orderAddresses[0]][orderAddresses[1]] = tokens[orderAddresses[0]][orderAddresses[1]].add(orderValues[4]);
        tokens[orderAddresses[0]][orderAddresses[2]] = tokens[orderAddresses[0]][orderAddresses[2]].sub(orderValues[5]);
        tokens[orderAddresses[0]][feeAccount] = tokens[orderAddresses[0]][feeAccount].add(orderValues[5]);
        
        orderFills[orderHash] = orderFills[orderHash].add(orderValues[4]);
        orderCancels[orderHash] = orderCancels[orderHash].add(orderValues[5]);
        
        emit Payment(orderValues[0], orderValues[1], orderValues[2], orderValues[3], orderValues[4], orderValues[5], orderAddresses[0], orderAddresses[1], orderAddresses[2]);
        
        lastActiveTransaction[orderAddresses[1]] = block.number;
        lastActiveTransaction[orderAddresses[2]] = block.number;
        return true;
    }
}
```