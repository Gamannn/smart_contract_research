```solidity
pragma solidity ^0.4.13;

contract VentanaTokenConfig {
    string public name = "Ventana";
    string public symbol = "VNT";
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        assert(c >= a);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        c = a - b;
        assert(c <= a);
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        assert(a == 0 || c / a == b);
    }

    function div(uint a, uint b) internal pure returns (uint c) {
        c = a / b;
    }
}

contract ReentryProtected {
    modifier preventReentry() {
        require(!mutex);
        mutex = true;
        _;
        delete mutex;
    }

    modifier noReentry() {
        require(!mutex);
        _;
    }

    bool private mutex;
}

contract ERC20Token {
    using SafeMath for uint;

    string public symbol;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function balanceOf(address owner) public view returns (uint) {
        return balances[owner];
    }

    function allowance(address owner, address spender) public view returns (uint) {
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

contract VentanaTokenAbstract {
    event KYCAddress(address indexed addr, bool indexed kyc);
    event Refunded(address indexed addr, uint indexed amount);
    event ChangedOwner(address indexed oldOwner, address indexed newOwner);
    event ChangeOwnerTo(address indexed newOwner);
    event FundsTransferred(address indexed wallet, uint indexed amount);

    mapping(address => bool) public kycAddresses;
    mapping(address => uint) public etherContributed;

    function fundSucceeded() public view returns (bool);
    function fundFailed() public view returns (bool);
    function usdRaised() public view returns (uint);
    function usdToEth(uint) public view returns (uint);
    function ethToUsd(uint _wei) public view returns (uint);
    function ethToTokens(uint _eth) public view returns (uint);
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

    struct ICOConfig {
        address veredictum;
        address newOwner;
        uint256 endDate;
        uint256 kycEthLimit;
        uint256 maxEthFund;
        uint256 minEthFund;
        uint256 tokensPerEth;
        uint256 etherRaised;
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
        bool icoSuccessful;
        bool abortFuse;
    }

    ICOConfig public config;

    modifier onlyOwner() {
        require(msg.sender == config.owner);
        _;
    }

    function VentanaToken() public {
        require(bytes(symbol).length > 0);
        require(bytes(name).length > 0);
        require(config.owner != address(0));
        require(config.fundWallet != address(0));
        require(config.tokensPerUsd > 0);
        require(config.usdPerEth > 0);
        require(config.minUsdFund > 0);
        require(config.maxUsdFund > config.minUsdFund);
        require(config.startDate > 0);
        require(config.fundingPeriod > 0);

        config.maxTokens = config.maxTokens.mul(1e18);
        balances[config.fundWallet] = config.maxTokens;
        Transfer(address(0), config.fundWallet, config.maxTokens);
    }

    function() public payable {
        proxyPurchase(msg.sender);
    }

    function fundFailed() public view returns (bool) {
        return !config.abortFuse || (now > config.endDate && config.etherRaised < config.minEthFund);
    }

    function fundSucceeded() public view returns (bool) {
        return !fundFailed() && config.etherRaised >= config.minEthFund;
    }

    function ethToUsd(uint _wei) public view returns (uint) {
        return config.usdPerEth.mul(_wei).div(1 ether);
    }

    function usdToEth(uint _usd) public view returns (uint) {
        return _usd.mul(1 ether).div(config.usdPerEth);
    }

    function usdRaised() public view returns (uint) {
        return ethToUsd(config.etherRaised);
    }

    function ethToTokens(uint _wei) public view returns (uint) {
        uint usd = ethToUsd(_wei);
        uint bonus = usd >= 2000000 ? 35 : usd >= 500000 ? 30 : usd >= 100000 ? 20 : usd >= 25000 ? 15 : usd >= 10000 ? 10 : usd >= 5000 ? 5 : 0;
        return _wei.mul(config.tokensPerEth).mul(bonus + 100).div(100);
    }

    function abort() public noReentry onlyOwner returns (bool) {
        require(!config.icoSuccessful);
        delete config.abortFuse;
        return true;
    }

    function proxyPurchase(address addr) public payable noReentry returns (bool) {
        require(!fundFailed());
        require(!config.icoSuccessful);
        require(now <= config.endDate);
        require(msg.value > 0);

        if (!kycAddresses[addr]) {
            require(now >= config.startDate);
            require(etherContributed[addr].add(msg.value) <= config.kycEthLimit);
        }

        uint tokens = ethToTokens(msg.value);
        _transfer(config.fundWallet, addr, tokens);
        etherContributed[addr] = etherContributed[addr].add(msg.value);
        config.etherRaised = config.etherRaised.add(msg.value);
        require(config.etherRaised <= config.maxEthFund);
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
        config.icoSuccessful = true;
        FundsTransferred(config.fundWallet, address(this).balance);
        config.fundWallet.transfer(address(this).balance);
        return true;
    }

    function refund(address addr) public preventReentry returns (bool) {
        require(fundFailed());
        uint contributed = etherContributed[addr];
        _transfer(addr, config.fundWallet, balances[addr]);
        delete etherContributed[addr];
        delete kycAddresses[addr];
        Refunded(addr, contributed);
        if (contributed > 0) {
            addr.transfer(contributed);
        }
        return true;
    }

    function transfer(address to, uint value) public preventReentry returns (bool) {
        require(config.icoSuccessful);
        super.transfer(to, value);
        if (to == config.veredictum) {
            require(Notify(config.veredictum).notify(msg.sender, value));
        }
        return true;
    }

    function transferFrom(address from, address to, uint value) public preventReentry returns (bool) {
        require(config.icoSuccessful);
        super.transferFrom(from, to, value);
        if (to == config.veredictum) {
            require(Notify(config.veredictum).notify(msg.sender, value));
        }
        return true;
    }

    function approve(address spender, uint value) public noReentry returns (bool) {
        require(config.icoSuccessful);
        super.approve(spender, value);
        return true;
    }

    function changeOwner(address newOwner) public noReentry onlyOwner returns (bool) {
        ChangeOwnerTo(newOwner);
        config.newOwner = newOwner;
        return true;
    }

    function acceptOwnership() public noReentry returns (bool) {
        require(msg.sender == config.newOwner);
        ChangedOwner(config.owner, config.newOwner);
        config.owner = config.newOwner;
        return true;
    }

    function changeVeredictum(address addr) public noReentry onlyOwner returns (bool) {
        config.veredictum = addr;
        return true;
    }

    function destroy() public noReentry onlyOwner {
        require(!config.abortFuse);
        require(address(this).balance == 0);
        selfdestruct(config.owner);
    }

    function transferAnyERC20Token(address tokenAddress, uint amount) public onlyOwner preventReentry returns (bool) {
        require(ERC20Token(tokenAddress).transfer(config.owner, amount));
        return true;
    }
}

interface Notify {
    event Notified(address indexed from, uint indexed value);
    function notify(address from, uint value) public returns (bool);
}

contract VeredictumTest is Notify {
    address public vnt;

    function setVnt(address addr) public {
        vnt = addr;
    }

    function notify(address from, uint value) public returns (bool) {
        require(msg.sender == vnt);
        Notified(from, value);
        return true;
    }
}
```