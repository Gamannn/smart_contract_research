```solidity
pragma solidity ^0.4.23;

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

    constructor() public {
        owner = msg.sender;
    }

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

contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20Detailed is ERC20 {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Exchange is Ownable {
    using SafeMath for uint256;

    address public feeAccount;
    uint256 public makerFee;
    uint256 public takerFee;
    uint256 public inactivityReleasePeriod;

    mapping(address => mapping(address => uint256)) public tokens;
    mapping(bytes32 => uint256) public orderFills;
    mapping(bytes32 => bool) public traded;

    event Trade(address indexed maker, uint256 makerAmount, address indexed taker, uint256 takerAmount, address makerToken, address takerToken);
    event Deposit(address indexed token, address indexed user, uint256 amount, uint256 balance);
    event Withdraw(address indexed token, address indexed user, uint256 amount, uint256 balance);
    event MakerFeeUpdated(uint256 previousFee, uint256 newFee);
    event TakerFeeUpdated(uint256 previousFee, uint256 newFee);

    modifier onlyAdmin() {
        require(msg.sender == owner || admins[msg.sender]);
        _;
    }

    constructor(uint256 _makerFee, uint256 _takerFee, address _feeAccount, uint256 _inactivityReleasePeriod) public {
        owner = msg.sender;
        makerFee = _makerFee;
        takerFee = _takerFee;
        feeAccount = _feeAccount;
        inactivityReleasePeriod = _inactivityReleasePeriod;
    }

    function setMakerFee(uint256 _makerFee) public onlyAdmin {
        require(_makerFee <= 10 finney);
        require(makerFee != _makerFee);
        uint256 previousFee = makerFee;
        makerFee = _makerFee;
        emit MakerFeeUpdated(previousFee, makerFee);
    }

    function setTakerFee(uint256 _takerFee) public onlyAdmin {
        require(_takerFee <= 20 finney);
        require(takerFee != _takerFee);
        uint256 previousFee = takerFee;
        takerFee = _takerFee;
        emit TakerFeeUpdated(previousFee, takerFee);
    }

    function setInactivityReleasePeriod(uint256 _inactivityReleasePeriod) public onlyAdmin returns (bool) {
        require(_inactivityReleasePeriod <= 50000);
        inactivityReleasePeriod = _inactivityReleasePeriod;
        return true;
    }

    function setAdmin(address admin, bool isAdmin) public onlyOwner {
        admins[admin] = isAdmin;
    }

    function depositToken(address token, uint256 amount) public {
        require(ERC20(token).transferFrom(msg.sender, address(this), amount));
        tokens[token][msg.sender] = tokens[token][msg.sender].add(amount);
        emit Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
    }

    function deposit() payable public {
        tokens[address(0)][msg.sender] = tokens[address(0)][msg.sender].add(msg.value);
        emit Deposit(address(0), msg.sender, msg.value, tokens[address(0)][msg.sender]);
    }

    function withdrawToken(address token, uint256 amount) public returns (bool) {
        require(block.number.sub(lastActiveTransaction[msg.sender]) >= inactivityReleasePeriod);
        require(tokens[token][msg.sender] >= amount);
        tokens[token][msg.sender] = tokens[token][msg.sender].sub(amount);
        if (token == address(0)) {
            msg.sender.transfer(amount);
        } else {
            require(ERC20(token).transfer(msg.sender, amount));
        }
        emit Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
        return true;
    }

    function trade(
        address makerToken,
        uint256 makerAmount,
        address takerToken,
        uint256 takerAmount,
        address maker,
        address taker,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 fee
    ) public onlyAdmin returns (bool) {
        if (fee > 30 finney) fee = 30 finney;
        if (makerToken == address(0)) {
            require(tokens[address(0)][maker] >= fee.add(makerAmount));
        } else {
            require(tokens[address(0)][maker] >= fee);
            require(tokens[makerToken][maker] >= makerAmount);
        }
        bytes32 orderHash = keccak256(abi.encodePacked(address(this), makerToken, makerAmount, takerToken, takerAmount, fee));
        require(!traded[orderHash]);
        traded[orderHash] = true;
        require(ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", orderHash)), v, r, s) == maker);
        if (makerToken == address(0)) {
            tokens[address(0)][maker] = tokens[address(0)][maker].sub(fee.add(makerAmount));
            tokens[address(0)][feeAccount] = tokens[address(0)][feeAccount].add(fee);
            taker.transfer(makerAmount);
        } else {
            tokens[makerToken][maker] = tokens[makerToken][maker].sub(makerAmount);
            tokens[address(0)][maker] = tokens[address(0)][maker].sub(fee);
            tokens[address(0)][feeAccount] = tokens[address(0)][feeAccount].add(fee);
            require(ERC20(makerToken).transfer(taker, makerAmount));
        }
        lastActiveTransaction[maker] = block.number;
        emit Trade(maker, makerAmount, taker, takerAmount, makerToken, takerToken);
        return true;
    }

    function balanceOf(address token, address user) public view returns (uint256) {
        return tokens[token][user];
    }
}
```