pragma solidity ^0.4.18;

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

contract ReentrancyGuard {
    bool private locked;
    modifier preventReentry() {
        require(!locked);
        locked = true;
        _;
        delete locked;
    }
}

contract ERC20Interface {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ERC20Token is ERC20Interface, ReentrancyGuard {
    using SafeMath for uint;
    uint public totalSupply;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
    function balanceOf(address tokenOwner) public constant returns (uint) {
        return balances[tokenOwner];
    }
    
    function allowance(address tokenOwner, address spender) public constant returns (uint) {
        return allowed[tokenOwner][spender];
    }
    
    function transfer(address to, uint tokens) public returns (bool) {
        return transferFrom(msg.sender, to, tokens);
    }
    
    function transferFrom(address from, address to, uint tokens) public returns (bool) {
        require(tokens <= allowed[from][msg.sender]);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        return doTransfer(from, to, tokens);
    }
    
    function doTransfer(address from, address to, uint tokens) internal returns (bool) {
        require(tokens <= balances[from]);
        Transfer(from, to, tokens);
        if(tokens == 0) return true;
        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        return true;
    }
    
    function approve(address spender, uint tokens) public returns (bool) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }
}

contract ICOInterface {
    event KYCAddress(address indexed addr, bool indexed status);
    event Refunded(address indexed addr, uint indexed amount);
    event ChangedOwner(address indexed oldOwner, address indexed newOwner);
    event ChangeOwnerTo(address indexed newOwner);
    event FundsTransferred(address indexed wallet, uint indexed amount);
    
    bool public icoActive = true;
    uint8 public constant decimals = 18;
    address public owner;
    
    function icoSuccessful() public constant returns (bool);
    function icoEnded() public constant returns (bool);
    function tokensIssued() public constant returns (uint);
    function usdToTokens(uint usdCents) public constant returns(uint);
    function tokensToUsd(uint tokens) public constant returns(uint);
    function ethToTokens(uint ethWei) public constant returns (uint);
    function tokensForEth(uint ethWei) public constant returns (uint);
    function buyTokens(address beneficiary) payable returns (bool);
    function finaliseICO() public returns (bool);
    function setKYCAddress(address addr, bool status) public returns (bool);
    function refund(address addr) public returns (bool);
    function abort() public returns (bool);
    function changeOwner(address newOwner) public returns (bool);
    function acceptOwnership() public returns (bool);
    function setTransferAgent(address addr) public returns (bool);
    function destroy() public;
    function transferAnyERC20Token(address tokenAddress, uint tokens) returns (bool);
}

contract NotificationReceiver {
    event Notified(address indexed from, uint amount);
    function notify(address from, uint amount) public returns (bool);
}

contract NotificationContract is NotificationReceiver {
    address public notificationReceiver;
    function NotificationContract(address addr) {
        notificationReceiver = addr;
    }
    function notify(address from, uint amount) public returns (bool) {
        require(msg.sender == notificationReceiver);
        Notified(from, amount);
        return true;
    }
}

contract ICOContract is ReentrancyGuard, ERC20Token, ICOInterface {
    using SafeMath for uint;
    
    uint public constant TOKENS_PER_USD = 2;
    uint public constant TOKENS_PER_ETH = 1 ether * USD_PER_ETH / TOKENS_PER_USD;
    uint public constant MAX_TOKENS = 1 ether * MAX_USD_FUND / TOKENS_PER_USD;
    
    string public name = "USPAT7493279 loansyndicate";
    string public symbol = "1mdb";
    address public owner;
    address public fundWallet = 0xb6cEC5dd8c3A7E1892752a5724496c22ef6d0A37;
    uint public constant MIN_USD_FUND = 2000000;
    uint public constant MAX_USD_FUND = 10000000;
    uint public constant START_DATE = 1523465678;
    uint public constant FUNDING_PERIOD = 15552000;
    uint public constant USD_PER_ETH = 500;
    
    uint public etherRaised;
    mapping(address => uint) etherContributed;
    mapping(address => bool) kycAddresses;
    bool public icoSuccessful;
    bool public aborted;
    address public transferAgent;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function ICOContract() {
        require(bytes(name).length > 0);
        require(owner != 0x0);
        require(fundWallet != 0x0);
        require(TOKENS_PER_USD > 0);
        require(USD_PER_ETH > 0);
        require(MIN_USD_FUND > 0);
        require(MAX_USD_FUND > MIN_USD_FUND);
        require(FUNDING_PERIOD > 0);
        
        owner = msg.sender;
        totalSupply = MAX_TOKENS;
        balances[fundWallet] = totalSupply;
        Transfer(0x0, fundWallet, totalSupply);
    }
    
    function() payable {
        buyTokens(msg.sender);
    }
    
    function buyTokens(address beneficiary) payable preventReentry returns (bool) {
        require(!icoEnded());
        require(!aborted);
        require(now <= START_DATE + FUNDING_PERIOD);
        require(msg.value > 0);
        
        if(!kycAddresses[beneficiary]) {
            require(now >= START_DATE);
            require((etherContributed[beneficiary].add(msg.value)) <= MAX_CONTRIBUTION);
        }
        
        uint tokens = tokensForEth(msg.value);
        require(tokens > 0);
        doTransfer(fundWallet, beneficiary, tokens);
        etherContributed[beneficiary] = etherContributed[beneficiary].add(msg.value);
        etherRaised = etherRaised.add(msg.value);
        require(etherRaised <= MAX_ETH);
        return true;
    }
    
    function icoEnded() public constant returns (bool) {
        return !icoActive || (now > START_DATE + FUNDING_PERIOD && etherRaised < MIN_ETH);
    }
    
    function icoSuccessful() public constant returns (bool) {
        return !icoEnded() && etherRaised >= MIN_ETH;
    }
    
    function ethToTokens(uint ethWei) public constant returns (uint) {
        return USD_PER_ETH.mul(ethWei).div(1 ether);
    }
    
    function tokensToUsd(uint tokens) public constant returns (uint) {
        return tokens.mul(1 ether).div(USD_PER_ETH);
    }
    
    function tokensIssued() public constant returns (uint) {
        return ethToTokens(etherRaised);
    }
    
    function tokensForEth(uint ethWei) public constant returns (uint) {
        uint usdCents = ethToTokens(ethWei);
        uint bonusPercent = usdCents >= 2000000 ? 35 :
                           usdCents >= 500000 ? 30 :
                           usdCents >= 100000 ? 20 :
                           usdCents >= 25000 ? 15 :
                           usdCents >= 10000 ? 10 :
                           usdCents >= 5000 ? 5 :
                           usdCents >= 1000 ? 1 : 0;
        return ethWei.mul(TOKENS_PER_ETH).mul(bonusPercent + 100).div(100);
    }
    
    uint constant MAX_CONTRIBUTION = 1 ether * 15000 / USD_PER_ETH;
    uint constant MIN_ETH = 1 ether * MIN_USD_FUND / USD_PER_ETH;
    uint constant MAX_ETH = 1 ether * MAX_USD_FUND / USD_PER_ETH;
    
    function abort() public onlyOwner preventReentry returns (bool) {
        require(!icoSuccessful());
        delete icoActive;
        return true;
    }
    
    function setKYCAddress(address addr, bool status) public onlyOwner preventReentry returns (bool) {
        require(!icoEnded());
        kycAddresses[addr] = status;
        KYCAddress(addr, status);
        return true;
    }
    
    function finaliseICO() public onlyOwner preventReentry returns (bool) {
        require(icoSuccessful());
        aborted = true;
        FundsTransferred(fundWallet, this.balance);
        fundWallet.transfer(this.balance);
        return true;
    }
    
    function refund(address addr) public preventReentry returns (bool) {
        require(icoEnded());
        require(!icoSuccessful());
        uint amount = etherContributed[addr];
        doTransfer(addr, fundWallet, balances[addr]);
        delete etherContributed[addr];
        delete kycAddresses[addr];
        Refunded(addr, amount);
        if (amount > 0) {
            addr.transfer(amount);
        }
        return true;
    }
    
    function transfer(address to, uint tokens) public preventReentry returns (bool) {
        require(icoSuccessful());
        super.transfer(to, tokens);
        if (to == transferAgent) {
            require(NotificationReceiver(transferAgent).notify(msg.sender, tokens));
        }
        return true;
    }
    
    function transferFrom(address from, address to, uint tokens) public preventReentry returns (bool) {
        require(icoSuccessful());
        super.transferFrom(from, to, tokens);
        if (to == transferAgent) {
            require(NotificationReceiver(transferAgent).notify(msg.sender, tokens));
        }
        return true;
    }
    
    function approve(address spender, uint tokens) public preventReentry returns (bool) {
        require(aborted);
        super.approve(spender, tokens);
        return true;
    }
    
    function changeOwner(address newOwner) public onlyOwner preventReentry returns (bool) {
        ChangeOwnerTo(newOwner);
        owner = newOwner;
        return true;
    }
    
    function acceptOwnership() public preventReentry returns (bool) {
        require(msg.sender == owner);
        ChangedOwner(owner, owner);
        owner = owner;
        return true;
    }
    
    function setTransferAgent(address addr) public onlyOwner preventReentry returns (bool) {
        transferAgent = addr;
        return true;
    }
    
    function destroy() public onlyOwner preventReentry {
        require(!icoActive);
        require(this.balance == 0);
        selfdestruct(owner);
    }
    
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner preventReentry returns (bool) {
        require(ERC20Interface(tokenAddress).transfer(owner, tokens));
        return true;
    }
}