pragma solidity ^0.4.13;

contract VentanaTokenConfig {
    string public name = "Ventana";
    string public symbol = "VNT";
}

library SafeMath {
    function add(uint a, uint b) internal returns (uint c) {
        c = a + b;
        assert(c >= a);
    }
    
    function sub(uint a, uint b) internal returns (uint c) {
        c = a - b;
        assert(c <= a);
    }
    
    function mul(uint a, uint b) internal returns (uint c) {
        c = a * b;
        assert(a == 0 || c / a == b);
    }
    
    function div(uint a, uint b) internal returns (uint c) {
        c = a / b;
    }
}

contract ReentryProtected {
    bool private reentrancyMutex;
    
    modifier preventReentry() {
        require(!reentrancyMutex);
        reentrancyMutex = true;
        _;
        delete reentrancyMutex;
    }
    
    modifier noReentry() {
        require(!reentrancyMutex);
        _;
    }
}

contract ERC20Token {
    using SafeMath for uint;
    
    string public symbol;
    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function balanceOf(address who) public constant returns (uint) {
        return balances[who];
    }
    
    function allowance(address owner, address spender) public constant returns (uint) {
        return allowed[owner][spender];
    }
    
    function transfer(address to, uint256 value) public returns (bool) {
        return transferFrom(msg.sender, to, value);
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(value <= allowed[from][msg.sender]);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        return internalTransfer(from, to, value);
    }
    
    function internalTransfer(address from, address to, uint value) internal returns (bool) {
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

contract VentanaTokenAbstract {
    event KYCAddress(address indexed addr, bool indexed kyc);
    event Refunded(address indexed addr, uint indexed amount);
    event ChangedOwner(address indexed oldOwner, address indexed newOwner);
    event ChangeOwnerTo(address indexed newOwner);
    event FundsTransferred(address indexed wallet, uint indexed amount);
    
    mapping (address => bool) public kycAddresses;
    mapping (address => uint) public etherContributed;
    
    function fundSucceeded() public constant returns (bool);
    function fundFailed() public constant returns (bool);
    function usdRaised() public constant returns (uint);
    function usdToEth(uint) public constant returns (uint);
    function ethToUsd(uint _wei) public constant returns (uint);
    function ethToTokens(uint _eth) public constant returns (uint);
    function proxyPurchase(address addr) payable returns (bool);
    function finaliseICO() public returns (bool);
    function addKycAddress(address addr, bool kyc) public returns (bool);
    function refund(address addr) public returns (bool);
    function abort() public returns (bool);
    function changeVeredictum(address addr) public returns (bool);
    function transferAnyERC20Token(address tokenAddress, uint amount) returns (bool);
}

contract VentanaToken is ReentryProtected, ERC20Token, VentanaTokenAbstract, VentanaTokenConfig {
    using SafeMath for uint;
    
    struct TokenData {
        address vnt;
        uint256 endDate;
        uint256 kycEthLimit;
        uint256 maxEthFund;
        uint256 minEthFund;
        uint256 tokensPerEth;
        uint256 etherRaised;
        address veredictum;
        address newOwner;
        uint8 decimals;
        bool icoSuccessful;
        bool abortFuse;
        uint256 totalSupply;
        bool reentrancyMutex;
        uint256 fundingPeriod;
        uint256 startDate;
        uint256 maxTokens;
        uint256 kycUsdLimit;
        uint256 maxUsdFund;
        uint256 minUsdFund;
        uint256 usdPerEth;
        uint256 tokensPerUsd;
        address fundWallet;
        address owner;
    }
    
    TokenData private data;
    
    modifier onlyOwner() {
        require(msg.sender == data.owner);
        _;
    }
    
    function VentanaToken() {
        require(bytes(symbol).length > 0);
        require(bytes(name).length > 0);
        require(data.owner != 0x0);
        require(data.fundWallet != 0x0);
        require(data.tokensPerUsd > 0);
        require(data.usdPerEth > 0);
        require(data.minUsdFund > 0);
        require(data.maxUsdFund > data.minUsdFund);
        require(data.startDate > 0);
        require(data.fundingPeriod > 0);
        
        data.totalSupply = data.maxTokens * 1e18;
        balances[data.fundWallet] = data.totalSupply;
        Transfer(0x0, data.fundWallet, data.totalSupply);
    }
    
    function () payable {
        proxyPurchase(msg.sender);
    }
    
    function fundFailed() public constant returns (bool) {
        return !data.abortFuse || (now > data.endDate && data.etherRaised < data.minEthFund);
    }
    
    function fundSucceeded() public constant returns (bool) {
        return !fundFailed() && data.etherRaised >= data.minEthFund;
    }
    
    function ethToUsd(uint _wei) public constant returns (uint) {
        return data.usdPerEth.mul(_wei).div(1 ether);
    }
    
    function usdToEth(uint _usd) public constant returns (uint) {
        return _usd.mul(1 ether).div(data.usdPerEth);
    }
    
    function usdRaised() public constant returns (uint) {
        return ethToUsd(data.etherRaised);
    }
    
    function ethToTokens(uint _wei) public constant returns (uint) {
        uint usd = ethToUsd(_wei);
        uint bonus = usd >= 2000000 ? 35 : 
                     usd >= 500000 ? 30 : 
                     usd >= 100000 ? 20 : 
                     usd >= 25000 ? 15 : 
                     usd >= 10000 ? 10 : 
                     usd >= 5000 ? 5 : 0;
        return _wei.mul(data.tokensPerEth).mul(bonus + 100).div(100);
    }
    
    function abort() public noReentry onlyOwner returns (bool) {
        require(!data.icoSuccessful);
        delete data.abortFuse;
        return true;
    }
    
    function proxyPurchase(address buyer) payable noReentry returns (bool) {
        require(!fundFailed());
        require(!data.icoSuccessful);
        require(now <= data.endDate);
        require(msg.value > 0);
        
        if (!kycAddresses[buyer]) {
            require(now >= data.startDate);
            require((etherContributed[buyer].add(msg.value)) <= data.kycEthLimit);
        }
        
        uint tokens = ethToTokens(msg.value);
        internalTransfer(data.fundWallet, buyer, tokens);
        
        etherContributed[buyer] = etherContributed[buyer].add(msg.value);
        data.etherRaised = data.etherRaised.add(msg.value);
        
        require(data.etherRaised <= data.maxEthFund);
        return true;
    }
    
    function addKycAddress(address addr, bool kyc) public noReentry onlyOwner returns (bool) {
        require(!fundFailed());
        kycAddresses[addr] = kyc;
        KYCAddress(addr, kyc);
        return true;
    }
    
    function finaliseICO() public onlyOwner preventReentry returns (bool) {
        require(fundSucceeded());
        data.icoSuccessful = true;
        FundsTransferred(data.fundWallet, this.balance);
        data.fundWallet.transfer(this.balance);
        return true;
    }
    
    function refund(address addr) public preventReentry returns (bool) {
        require(fundFailed());
        uint amount = etherContributed[addr];
        internalTransfer(addr, data.fundWallet, balances[addr]);
        delete etherContributed[addr];
        delete kycAddresses[addr];
        Refunded(addr, amount);
        if (amount > 0) {
            addr.transfer(amount);
        }
        return true;
    }
    
    function transfer(address to, uint value) public preventReentry returns (bool) {
        require(data.icoSuccessful);
        super.transfer(to, value);
        if (to == data.veredictum) {
            require(Notify(data.veredictum).notify(msg.sender, value));
        }
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public preventReentry returns (bool) {
        require(data.icoSuccessful);
        super.transferFrom(from, to, value);
        if (to == data.veredictum) {
            require(Notify(data.veredictum).notify(msg.sender, value));
        }
        return true;
    }
    
    function approve(address spender, uint value) public noReentry returns (bool) {
        require(data.icoSuccessful);
        super.approve(spender, value);
        return true;
    }
    
    function changeOwner(address newOwner) public noReentry onlyOwner returns (bool) {
        ChangeOwnerTo(newOwner);
        data.newOwner = newOwner;
        return true;
    }
    
    function acceptOwnership() public noReentry returns (bool) {
        require(msg.sender == data.newOwner);
        ChangedOwner(data.owner, data.newOwner);
        data.owner = data.newOwner;
        return true;
    }
    
    function changeVeredictum(address addr) public noReentry onlyOwner returns (bool) {
        data.veredictum = addr;
        return true;
    }
    
    function destroy() public noReentry onlyOwner {
        require(!data.abortFuse);
        require(this.balance == 0);
        selfdestruct(data.owner);
    }
    
    function transferAnyERC20Token(address tokenAddress, uint amount) public onlyOwner preventReentry returns (bool) {
        require(ERC20Token(tokenAddress).transfer(data.owner, amount));
        return true;
    }
}

interface Notify {
    event Notified(address indexed from, uint indexed value);
    function notify(address from, uint value) public returns (bool);
}

contract VeredictumTest is Notify {
    address public vnt;
    
    function setVnt(address addr) {
        vnt = addr;
    }
    
    function notify(address from, uint value) public returns (bool) {
        require(msg.sender == vnt);
        Notified(from, value);
        return true;
    }
}