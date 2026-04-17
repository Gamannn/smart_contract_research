pragma solidity ^0.4.23;

contract TokenInterface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address owner) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Token is TokenInterface {
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
    mapping(address => bool) public admins;
    mapping(bytes32 => bool) public withdrawn;
    mapping(bytes32 => uint256) public orderFills;

    event Deposit(address token, address user, uint256 amount, uint256 balance);
    event Withdraw(address token, address user, uint256 amount, uint256 balance);
    event RequestHardWithdraw(address user, bool requested);
    event ProcessingFeeUpdated(uint256 oldFee, uint256 newFee);

    modifier onlyAdmin() {
        require(msg.sender == owner || admins[msg.sender]);
        _;
    }

    constructor(address feeAccountAddress, uint256 inactivityPeriod) public {
        owner = msg.sender;
        feeAccount = feeAccountAddress;
        inactivityReleasePeriod = inactivityPeriod;
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
            require(Token(token).transfer(msg.sender, amount));
        }

        emit Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
        return true;
    }

    function updateInactivityReleasePeriod(uint256 newPeriod) public onlyAdmin returns (bool) {
        require(newPeriod <= 100000);
        require(newPeriod >= 6000);
        inactivityReleasePeriod = newPeriod;
        return true;
    }

    function setAdmin(address admin, bool isAdmin) public onlyOwner {
        admins[admin] = isAdmin;
    }

    function setFeeAccount(address newFeeAccount) public onlyOwner {
        feeAccount = newFeeAccount;
    }

    function depositToken(address token, uint256 amount) public {
        require(Token(token).transferFrom(msg.sender, address(this), amount));
        tokens[token][msg.sender] = tokens[token][msg.sender].add(amount);
        lastActiveTransaction[msg.sender] = block.number;
        emit Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
    }

    function deposit() payable public {
        tokens[address(0)][msg.sender] = tokens[address(0)][msg.sender].add(msg.value);
        lastActiveTransaction[msg.sender] = block.number;
        emit Deposit(address(0), msg.sender, msg.value, tokens[address(0)][msg.sender]);
    }

    function adminWithdraw(address token, uint256 amount, address user, uint256 nonce, uint8 v, bytes32 r, bytes32 s, uint256 fee) public onlyAdmin returns (bool) {
        require(fee <= amount);

        if (token == address(0)) {
            require(tokens[address(0)][user] >= amount.add(fee));
        } else {
            require(tokens[token][user] >= amount.add(fee));
        }

        bytes32 hash = keccak256(abi.encodePacked(address(this), token, amount, user, nonce, fee));
        require(!withdrawn[hash]);

        withdrawn[hash] = true;
        require(ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), v, r, s) == user);

        if (token == address(0)) {
            tokens[address(0)][user] = tokens[address(0)][user].sub(amount.add(fee));
            tokens[address(0)][feeAccount] = tokens[address(0)][feeAccount].add(fee);
            user.transfer(amount);
        } else {
            tokens[token][user] = tokens[token][user].sub(amount.add(fee));
            tokens[token][feeAccount] = tokens[token][feeAccount].add(fee);
            require(Token(token).transfer(user, amount));
        }

        lastActiveTransaction[user] = block.number;
        emit Withdraw(token, user, amount, tokens[token][user]);
        return true;
    }

    function balanceOf(address token, address user) view public returns (uint256) {
        return tokens[token][user];
    }

    function trade(uint256[4] values, address[3] addresses, uint8 v, bytes32[2] rs) public onlyAdmin returns (bool) {
        require(block.number < values[2]);

        bytes32 hash = keccak256(abi.encodePacked(address(this), values[0], values[1], values[2], values[3], addresses[0], addresses[1]));
        require(ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), v, rs[0], rs[1]) == addresses[2]);

        require(tokens[addresses[0]][addresses[2]] >= values[0]);
        require(orderFills[hash].add(values[0]) <= values[0]);

        tokens[addresses[0]][addresses[2]] = tokens[addresses[0]][addresses[2]].sub(values[0]);
        tokens[addresses[0]][addresses[1]] = tokens[addresses[0]][addresses[1]].add(values[2]);
        tokens[addresses[0]][feeAccount] = tokens[addresses[0]][feeAccount].add(values[3]);

        orderFills[hash] = orderFills[hash].add(values[0]);

        emit Payment(values[0], values[1], values[2], addresses[0], addresses[1], addresses[2]);
        lastActiveTransaction[addresses[1]] = block.number;
        lastActiveTransaction[addresses[2]] = block.number;
        return true;
    }
}