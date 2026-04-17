```solidity
pragma solidity ^0.4.18;

contract TokenInfo {
    string public name = "USPAT7493279 loansyndicate";
    string public symbol = "1mdb";
    address public owner = 0xb6cEC5dd8c3A7E1892752a5724496c22ef6d0A37;
    uint public constant decimals = 18;
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract Mutex {
    bool private locked;
    
    function Mutex() internal {
        locked = false;
    }

    modifier preventReentry() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }
}

contract ERC20Token is TokenInfo {
    using SafeMath for uint;

    uint public totalSupply;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function transfer(address to, uint256 tokens) public returns (bool success) {
        return _transfer(msg.sender, to, tokens);
    }

    function approve(address spender, uint256 tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
        require(tokens <= allowed[from][msg.sender]);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        return _transfer(from, to, tokens);
    }

    function _transfer(address from, address to, uint256 tokens) internal returns (bool success) {
        require(tokens <= balances[from]);
        Transfer(from, to, tokens);
        if (tokens == 0) return true;
        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
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
    address public newOwner;

    function isKYCActive() public constant returns (bool) {
        return isActive;
    }

    function isKYCInactive() public constant returns (bool) {
        return !isKYCActive();
    }

    function getKYCStatus(address user) public constant returns (bool);

    function setKYCStatus(address user, bool status) public returns (bool);

    function refund(address user) public returns (bool);

    function finalize() public returns (bool);

    function transferOwnership(address newOwner) public returns (bool);

    function acceptOwnership() public returns (bool);

    function setNewOwner(address newOwner) public returns (bool);

    function destroy() public;
}

contract Crowdsale is Mutex, ERC20Token, KYC {
    using SafeMath for uint;

    uint public constant MAX_TOKENS = 1000000 * 10**decimals;
    uint public constant TOKENS_PER_ETH = 1000;
    uint public constant USD_PER_ETH = 500;
    uint public constant MIN_USD_FUND = 100;
    uint public constant FUNDING_PERIOD = 30 days;
    uint public constant START_DATE = 1523465678;
    uint public etherRaised;
    bool public icoSuccessful;

    function Crowdsale() public {
        totalSupply = MAX_TOKENS;
        balances[owner] = totalSupply;
        Transfer(0x0, owner, totalSupply);
    }

    function isCrowdsaleActive() public constant returns (bool) {
        return !icoSuccessful && now <= START_DATE + FUNDING_PERIOD;
    }

    function isCrowdsaleEnded() public constant returns (bool) {
        return !isCrowdsaleActive() && etherRaised >= MIN_USD_FUND;
    }

    function calculateTokens(uint ethAmount) public constant returns (uint) {
        return ethAmount.mul(TOKENS_PER_ETH).div(1 ether);
    }

    function calculateEth(uint tokenAmount) public constant returns (uint) {
        return tokenAmount.mul(1 ether).div(TOKENS_PER_ETH);
    }

    function getCurrentTokenPrice() public constant returns (uint) {
        return calculateTokens(etherRaised);
    }

    function calculateBonus(uint ethAmount) public constant returns (uint) {
        uint tokens = calculateTokens(ethAmount);
        uint bonus = tokens >= 2000000 ? 35 : tokens >= 500000 ? 30 : tokens >= 100000 ? 20 : tokens >= 25000 ? 15 : tokens >= 10000 ? 10 : tokens >= 5000 ? 5 : tokens >= 1000 ? 1 : 0;
        return ethAmount.mul(MAX_TOKENS).mul(bonus + 100).div(100);
    }

    function finalizeCrowdsale() public onlyOwner preventReentry returns (bool) {
        require(isCrowdsaleEnded());
        icoSuccessful = true;
        FundsTransferred(owner, this.balance);
        owner.transfer(this.balance);
        return true;
    }

    function refund(address user) public returns (bool) {
        require(isCrowdsaleActive());
        uint ethAmount = calculateEth(balances[user]);
        _transfer(user, owner, balances[user]);
        delete balances[user];
        Refunded(user, ethAmount);
        if (ethAmount > 0) {
            user.transfer(ethAmount);
        }
        return true;
    }

    function transferOwnership(address newOwner) public onlyOwner returns (bool) {
        ChangeOwnerTo(newOwner);
        newOwner = newOwner;
        return true;
    }

    function acceptOwnership() public returns (bool) {
        require(msg.sender == newOwner);
        ChangedOwner(owner, newOwner);
        owner = newOwner;
        return true;
    }

    function destroy() public onlyOwner {
        require(!isActive);
        require(this.balance == 0);
        selfdestruct(owner);
    }
}

interface Notifier {
    event Notified(address indexed user, uint amount);

    function notify(address user, uint amount) public returns (bool);
}

contract Notification is Notifier {
    address public notifier;

    function setNotifier(address _notifier) public {
        notifier = _notifier;
    }

    function notify(address user, uint amount) public returns (bool) {
        require(msg.sender == notifier);
        Notified(user, amount);
        return true;
    }
}
```