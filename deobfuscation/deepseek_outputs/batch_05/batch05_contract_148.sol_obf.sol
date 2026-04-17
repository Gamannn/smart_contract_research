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
    mapping(address => bool) public admins;
    mapping(bytes32 => bool) public withdrawn;
    mapping(bytes32 => uint256) public orderFills;
    
    event Deposit(address token, address user, uint256 amount, uint256 balance);
    event Payment(uint256 amount, uint256 price, uint256 nonce, address token, address user, address recipient);
    event Withdraw(address token, address user, uint256 amount, uint256 balance);
    event RequestHardWithdraw(address user, bool active);
    event ProcessingFeeUpdated(uint256 previousFee, uint256 newFee);
    
    modifier onlyAdmin() {
        require(msg.sender == owner || admins[msg.sender]);
        _;
    }
    
    constructor(address _feeAccount, uint256 _inactivityReleasePeriod) public {
        owner = msg.sender;
        feeAccount = _feeAccount;
        inactivityReleasePeriod = _inactivityReleasePeriod;
    }
    
    function setHardWithdraw(bool active) public {
        require(block.number.sub(lastActiveTransaction[msg.sender]) >= inactivityReleasePeriod);
        hardWithdrawActive[msg.sender] = active;
        lastActiveTransaction[msg.sender] = block.number;
        emit RequestHardWithdraw(msg.sender, active);
    }
    
    function hardWithdraw(address token, uint256 amount) public returns (bool) {
        require(block.number.sub(lastActiveTransaction[msg.sender]) >= inactivityReleasePeriod);
        require(tokens[token][msg.sender] >= amount);
        require(hardWithdrawActive[msg.sender] == true);
        
        tokens[token][msg.sender] = tokens[token][msg.sender].sub(amount);
        
        if (token == address(0)) {
            msg.sender.transfer(amount);
        } else {
            require(ERC20(token).transfer(msg.sender, amount));
        }
        
        emit Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
        return true;
    }
    
    function setInactivityReleasePeriod(uint256 blocks) onlyAdmin public returns (bool) {
        require(blocks <= 100000);
        require(blocks >= 6000);
        inactivityReleasePeriod = blocks;
        return true;
    }
    
    function setAdmin(address admin, bool isAdmin) onlyOwner public {
        admins[admin] = isAdmin;
    }
    
    function setFeeAccount(address newFeeAccount) onlyOwner public {
        feeAccount = newFeeAccount;
    }
    
    function deposit(address token, uint256 amount) public {
        depositToken(token, msg.sender, amount);
    }
    
    function depositToken(address token, address user, uint256 amount) public {
        tokens[token][user] = tokens[token][user].add(amount);
        lastActiveTransaction[user] = block.number;
        require(ERC20(token).transferFrom(user, address(this), amount));
        emit Deposit(token, user, amount, tokens[token][user]);
    }
    
    function depositEther() payable public {
        tokens[address(0)][msg.sender] = tokens[address(0)][msg.sender].add(msg.value);
        lastActiveTransaction[msg.sender] = block.number;
        emit Deposit(address(0), msg.sender, msg.value, tokens[address(0)][msg.sender]);
    }
    
    function adminWithdraw(address token, uint256 amount, address user, uint256 nonce, uint8 v, bytes32 r, bytes32 s, uint256 fee) onlyAdmin public returns (bool) {
        require(fee <= amount);
        
        if (token == address(0)) {
            require(tokens[address(0)][user] >= fee.add(amount));
        } else {
            require(tokens[token][user] >= fee.add(amount));
        }
        
        bytes32 hash = keccak256(address(this), token, amount, user, nonce, fee);
        require(!withdrawn[hash]);
        withdrawn[hash] = true;
        
        require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == user);
        
        if (token == address(0)) {
            tokens[address(0)][user] = tokens[address(0)][user].sub(fee.add(amount));
            tokens[address(0)][feeAccount] = tokens[address(0)][feeAccount].add(fee);
        } else {
            tokens[token][user] = tokens[token][user].sub(fee.add(amount));
            tokens[token][feeAccount] = tokens[token][feeAccount].add(fee);
            require(ERC20(token).transfer(user, amount));
        }
        
        lastActiveTransaction[user] = block.number;
        emit Withdraw(token, user, amount, tokens[token][user]);
        return true;
    }
    
    function balanceOf(address token, address user) view public returns (uint256) {
        return tokens[token][user];
    }
    
    function trade(uint256[4] amounts, address[3] addresses, uint8 v, bytes32[2] rs) onlyAdmin public returns (bool) {
        require(block.number < amounts[2]);
        
        bytes32 orderHash = keccak256(address(this), amounts[0], amounts[1], amounts[2], amounts[3], addresses[0], addresses[1]);
        require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", orderHash), v, rs[0], rs[1]) == addresses[2]);
        
        require(tokens[addresses[0]][addresses[2]] >= amounts[0]);
        require(orderFills[orderHash].add(amounts[0]) <= amounts[0]);
        
        tokens[addresses[0]][addresses[2]] = tokens[addresses[0]][addresses[2]].sub(amounts[0]);
        tokens[addresses[0]][addresses[1]] = tokens[addresses[0]][addresses[1]].add(amounts[0]);
        tokens[addresses[0]][addresses[1]] = tokens[addresses[0]][addresses[1]].sub(amounts[3]);
        tokens[addresses[0]][feeAccount] = tokens[addresses[0]][feeAccount].add(amounts[3]);
        
        orderFills[orderHash] = orderFills[orderHash].add(amounts[0]);
        
        emit Payment(amounts[0], amounts[1], amounts[2], addresses[0], addresses[1], addresses[2]);
        
        lastActiveTransaction[addresses[1]] = block.number;
        lastActiveTransaction[addresses[2]] = block.number;
        return true;
    }
    
    mapping(address => bool) public hardWithdrawActive;
    mapping(address => uint256) public lastActiveTransaction;
}
```