```solidity
pragma solidity ^0.4.18;

contract DepositOffer {
    string public name = "Depositoffer.com USPat7376612";
    string public symbol = "DOT";
    address public owner;
    address public fundWallet;
    uint public constant TOKENS_PER_USD = 2;
    uint public constant USD_PER_ETH = 380;
    uint public constant START_DATE = 1520776337;
}

library SafeMath {
    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        return a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0);
        uint c = a / b;
        return c;
    }
}

contract ERC20 {
    bool internal mutex;
    modifier noReentrancy() {
        require(!mutex);
        mutex = true;
        _;
        mutex = false;
    }
}

contract Token is ERC20 {
    using SafeMath for uint;

    uint public totalSupply;
    string public symbol;
    mapping(address => mapping(address => uint)) internal allowed;
    mapping(address => uint) internal balances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function balanceOf(address owner) public constant returns (uint) {
        return balances[owner];
    }

    function allowance(address owner, address spender) public constant returns (uint) {
        return allowed[owner][spender];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        return _transfer(msg.sender, to, value);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(value <= allowed[from][msg.sender]);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        return _transfer(from, to, value);
    }

    function _transfer(address from, address to, uint value) internal returns (bool) {
        require(value <= balances[from]);
        Transfer(from, to, value);
        if (value == 0) return true;
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }
}

contract KYC {
    event KYCAddress(address indexed user, bool indexed status);
    event Refunded(address indexed user, uint indexed amount);
    event ChangedOwner(address indexed oldOwner, address indexed newOwner);
    event ChangeOwnerTo(address indexed newOwner);
    event FundsTransferred(address indexed to, uint indexed amount);

    bool public isActive = true;
    bool public isFinalized;
    address public pendingOwner;
    uint public etherRaised;

    function getEtherRaised() public constant returns (uint);
    function getTokens(uint) public constant returns(uint);
    function calculateTokens(uint etherAmount) public constant returns (uint);
    function calculateBonus(uint etherAmount) public constant returns (uint);
    function contribute(address user) payable returns (bool);
    function finalize() public returns (bool);
    function setKYC(address user, bool status) public returns (bool);
    function refund(address user) public returns (bool);
    function finalizeICO() public returns (bool);
    function changeOwner(address newOwner) public returns (bool);
    function notify(address user, uint amount) public returns (bool);
}

contract DepositOfferToken is ERC20, Token, KYC, DepositOffer {
    using SafeMath for uint;

    uint public constant MAX_USD_FUND = TOKENS_PER_USD * USD_PER_ETH;
    uint public constant MIN_USD_FUND = 1 ether * 100 / USD_PER_ETH;
    uint public constant MAX_ETH_FUND = 1 ether * 50000 / USD_PER_ETH;
    uint public constant MIN_ETH_FUND = 1 ether * 2000000 / USD_PER_ETH;

    function DepositOfferToken() public {
        require(owner != 0x0);
        require(fundWallet != 0x0);
        require(TOKENS_PER_USD > 0);
        require(USD_PER_ETH > 0);
        require(50000 > 0);
        require(2000000 > 0);
        require(START_DATE > 0);
        totalSupply = 10000000000 * 1e18;
        balances[fundWallet] = totalSupply;
        Transfer(0x0, fundWallet, totalSupply);
    }

    function () payable {
        contribute(msg.sender);
    }

    function contribute(address user) payable noReentrancy returns (bool) {
        require(!isFinalized);
        require(now <= START_DATE);
        require(msg.value > 0);
        if (!isActive) {
            require(now >= START_DATE);
            require((balances[user].add(msg.value)) <= MAX_ETH_FUND);
        }
        uint tokens = calculateBonus(msg.value);
        _transfer(fundWallet, user, tokens);
        balances[user] = balances[user].add(msg.value);
        etherRaised = etherRaised.add(msg.value);
        return true;
    }

    function setKYC(address user, bool status) public noReentrancy returns (bool) {
        require(!isFinalized);
        KYCAddress(user, status);
        return true;
    }

    function finalize() public noReentrancy returns (bool) {
        require(getEtherRaised() >= MIN_USD_FUND);
        isFinalized = true;
        FundsTransferred(fundWallet, this.balance);
        fundWallet.transfer(this.balance);
        return true;
    }

    function refund(address user) public noReentrancy returns (bool) {
        require(isFinalized);
        uint amount = balances[user];
        _transfer(user, fundWallet, balances[user]);
        delete balances[user];
        Refunded(user, amount);
        if (amount > 0) {
            user.transfer(amount);
        }
        return true;
    }

    function changeOwner(address newOwner) public noReentrancy returns (bool) {
        ChangeOwnerTo(newOwner);
        pendingOwner = newOwner;
        return true;
    }

    function finalizeICO() public noReentrancy returns (bool) {
        require(msg.sender == pendingOwner);
        ChangedOwner(owner, pendingOwner);
        owner = pendingOwner;
        return true;
    }

    function notify(address user, uint amount) public noReentrancy returns (bool) {
        require(isFinalized);
        super.notify(user, amount);
        return true;
    }
}

interface Notifier {
    event Notified(address indexed user, uint indexed amount);
    function notify(address user, uint amount) public returns (bool);
}

contract Notification is Notifier {
    address public notifier;

    function setNotifier(address user) public {
        notifier = user;
    }

    function notify(address user, uint amount) public returns (bool) {
        require(msg.sender == notifier);
        Notified(user, amount);
        return true;
    }
}
```