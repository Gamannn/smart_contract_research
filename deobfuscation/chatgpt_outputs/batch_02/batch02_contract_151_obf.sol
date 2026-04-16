```solidity
pragma solidity ^0.4.23;

contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address tokenOwner) public view returns (uint256);
    function transfer(address to, uint256 tokens) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
}

contract ERC20ExtendedInterface is ERC20Interface {
    function allowance(address tokenOwner, address spender) public view returns (uint256);
    function approve(address spender, uint256 tokens) public returns (bool);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
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

    function pow(uint256 a, uint256 b) internal pure returns (uint256) {
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
    mapping(address => bool) public operators;
    mapping(bytes32 => bool) public withdrawn;
    mapping(bytes32 => bool) public paymentDelegation;
    mapping(bytes32 => uint256) public orderFills;
    mapping(bytes32 => uint256) public paymentHashes;

    event Deposit(address token, address user, address to, uint256 amount, uint256 balance);
    event Payment(uint256 amount, uint256 fee, uint256 orderAmount, uint256 orderFee, uint256 orderNonce, uint256 orderHash, address user, address to, address feeAccount);
    event Withdraw(address token, address user, address to, uint256 amount);
    event RequestHardWithdraw(address user, bool requested);
    event Delegation(address user, address delegate, bool authorized);

    modifier onlyAdminOrOperator() {
        require(msg.sender == owner || operators[msg.sender] || admins[msg.sender]);
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner || admins[msg.sender]);
        _;
    }

    constructor(address _feeAccount, uint256 _inactivityReleasePeriod) public {
        owner = msg.sender;
        feeAccount = _feeAccount;
        inactivityReleasePeriod = _inactivityReleasePeriod;
    }

    function requestHardWithdraw(bool requested) public {
        require(block.number.sub(lastActiveTransaction[msg.sender]) >= inactivityReleasePeriod);
        hardWithdrawRequests[msg.sender] = requested;
        lastActiveTransaction[msg.sender] = block.number;
        emit RequestHardWithdraw(msg.sender, requested);
    }

    function withdraw(address token, uint256 amount) public returns (bool) {
        require(block.number.sub(lastActiveTransaction[msg.sender]) >= inactivityReleasePeriod);
        require(tokens[token][msg.sender] >= amount);
        require(hardWithdrawRequests[msg.sender] == true);

        tokens[token][msg.sender] = tokens[token][msg.sender].sub(amount);

        if (token == address(0)) {
            msg.sender.transfer(amount);
        } else {
            require(ERC20ExtendedInterface(token).transfer(msg.sender, amount));
        }

        emit Withdraw(token, msg.sender, msg.sender, amount);
        return true;
    }

    function setInactivityReleasePeriod(uint256 _inactivityReleasePeriod) onlyAdminOrOperator public returns (bool) {
        require(_inactivityReleasePeriod <= 2000000);
        require(_inactivityReleasePeriod >= 6000);
        inactivityReleasePeriod = _inactivityReleasePeriod;
        return true;
    }

    function setAdmin(address admin, bool authorized) onlyOwner public {
        admins[admin] = authorized;
    }

    function setOperator(address operator, bool authorized) onlyAdmin public {
        operators[operator] = authorized;
    }

    function setFeeAccount(address _feeAccount) onlyAdmin public {
        feeAccount = _feeAccount;
    }

    function depositToken(address token, address to, uint256 amount) public {
        require(ERC20ExtendedInterface(token).transferFrom(msg.sender, address(this), amount));
        tokens[token][to] = tokens[token][to].add(amount);
        lastActiveTransaction[msg.sender] = block.number;
        emit Deposit(token, msg.sender, to, amount, tokens[token][msg.sender]);
    }

    function deposit() payable public {
        tokens[address(0)][msg.sender] = tokens[address(0)][msg.sender].add(msg.value);
        lastActiveTransaction[msg.sender] = block.number;
        emit Deposit(address(0), msg.sender, msg.sender, msg.value, tokens[address(0)][msg.sender]);
    }

    function trade(address tokenBuy, uint256 amountBuy, address tokenSell, uint256 amountSell, uint256 expires, uint256 nonce, address user, uint8 v, bytes32 r, bytes32 s) onlyAdminOrOperator public returns (bool) {
        require(block.number < expires);
        bytes32 hash = keccak256(abi.encodePacked(address(this), tokenBuy, amountBuy, tokenSell, amountSell, expires, nonce, user));
        require(!withdrawn[hash]);
        withdrawn[hash] = true;
        require(ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), v, r, s) == user);

        tokens[tokenBuy][user] = tokens[tokenBuy][user].sub(amountBuy);
        tokens[tokenSell][user] = tokens[tokenSell][user].add(amountSell);
        tokens[tokenSell][feeAccount] = tokens[tokenSell][feeAccount].add(amountSell.div(1000));

        lastActiveTransaction[user] = block.number;
        emit Payment(amountBuy, amountSell, expires, nonce, hash, user, user, feeAccount);
        return true;
    }

    function balanceOf(address token, address user) view public returns (uint256) {
        return tokens[token][user];
    }

    function cancelOrder(address tokenBuy, address tokenSell, uint256 amountBuy, uint256 amountSell, uint256 expires, uint256 nonce, uint8 v, bytes32 r, bytes32 s) onlyAdminOrOperator public returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(address(this), tokenBuy, amountBuy, tokenSell, amountSell, expires, nonce));
        require(!paymentDelegation[hash]);
        paymentDelegation[hash] = true;
        require(ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), v, r, s) == msg.sender);
        emit Delegation(msg.sender, tokenSell, false);
        return false;
    }

    function authorizePayment(address user, address delegate, uint256 amount, uint8 v, bytes32 r, bytes32 s, bool authorized) onlyAdminOrOperator public returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(address(this), user, delegate, amount));
        require(!paymentDelegation[hash]);
        paymentDelegation[hash] = true;
        require(ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), v, r, s) == user);
        emit Delegation(user, delegate, authorized);
        return authorized;
    }

    function executeTrade(uint256[6] values, address[3] addresses, uint8 v, bytes32[2] rs) onlyAdminOrOperator public returns (bool) {
        require(block.number < values[2]);
        bytes32 hash = keccak256(abi.encodePacked(address(this), values[0], values[1], values[2], values[3], addresses[0], addresses[1]));
        address user = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), v, rs[0], rs[1]);
        require(user == addresses[2] || paymentDelegation[keccak256(abi.encodePacked(addresses[2], user))]);
        require(tokens[addresses[0]][addresses[2]] >= values[5]);
        require(orderFills[hash].add(values[4]) <= values[0]);
        require(paymentHashes[hash].add(values[5]) <= values[3]);

        tokens[addresses[0]][addresses[2]] = tokens[addresses[0]][addresses[2]].sub(values[4]);
        tokens[addresses[0]][addresses[1]] = tokens[addresses[0]][addresses[1]].add(values[4]);
        tokens[addresses[0]][addresses[2]] = tokens[addresses[0]][addresses[2]].sub(values[5]);
        tokens[addresses[0]][feeAccount] = tokens[addresses[0]][feeAccount].add(values[5].div(1000));

        orderFills[hash] = orderFills[hash].add(values[4]);
        paymentHashes[hash] = paymentHashes[hash].add(values[5]);

        emit Payment(values[0], values[1], values[2], values[3], values[4], values[5], addresses[0], addresses[1], addresses[2]);
        lastActiveTransaction[addresses[1]] = block.number;
        lastActiveTransaction[addresses[2]] = block.number;
        return true;
    }

    function getIntFunc(uint256 index) internal view returns (uint256) {
        return _integer_constant[index];
    }

    function getBoolFunc(uint256 index) internal view returns (bool) {
        return _bool_constant[index];
    }

    function getStrFunc(uint256 index) internal view returns (string storage) {
        return _string_constant[index];
    }

    uint256[] public _integer_constant = [4, 0, 2000000, 3, 5, 2, 6000, 1];
    bool[] public _bool_constant = [false, true];
    string[] public _string_constant = ["\x19Ethereum Signed Message:\n32"];
}
```