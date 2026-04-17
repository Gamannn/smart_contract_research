```solidity
pragma solidity ^0.4.18;

contract DepositOfferInfo {
    string public name = "Depositoffer.com USPat7376612";
    string public symbol = "DOT";
    address public owner;
    address public fundWallet;
    uint public constant TOKENS_PER_USD = 2;
    uint public constant USD_PER_ETH = 380;
    uint public constant START_DATE = 1520776337;
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

contract ReentrancyGuard {
    bool private locked;
    
    modifier noReentrancy() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }
}

contract ERC20Interface {
    uint public totalSupply;
    string public symbol;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function balanceOf(address who) public constant returns (uint);
    function allowance(address owner, address spender) public constant returns (uint);
    function transfer(address to, uint value) public returns (bool);
    function transferFrom(address from, address to, uint value) public returns (bool);
    function approve(address spender, uint value) public returns (bool);
}

contract ICOInterface {
    event KYCAddress(address indexed investor, bool indexed approved);
    event Refunded(address indexed investor, uint indexed amount);
    event ChangedOwner(address indexed oldOwner, address indexed newOwner);
    event ChangeOwnerTo(address indexed newOwner);
    event FundsTransferred(address indexed wallet, uint indexed amount);
    
    bool public icoActive = true;
    bool public icoSuccessful;
    address public pendingOwner;
    uint public etherRaised;
    
    function usdRaised() public constant returns (uint);
    function etherToUsd(uint etherAmount) public constant returns(uint);
    function usdToTokens(uint usdAmount) public constant returns (uint);
    function tokensForEther(uint etherAmount) public constant returns (uint);
    function finalizeICO() public returns (bool);
    function buyTokens(address investor) payable returns (bool);
    function refund() public returns (bool);
    function setKYC(address investor, bool approved) public returns (bool);
    function refundInvestor(address investor) public returns (bool);
    function abortICO() public returns (bool);
    function sweepFunds() public returns (bool);
    function transfer(address to, uint value) public returns (bool);
    function transferFrom(address from, address to, uint value) public returns (bool);
    function approve(address spender, uint value) public returns (bool);
    function changeOwner(address newOwner) public returns (bool);
    function acceptOwnership() public returns (bool);
    function setDepositContract(address depositContract) public returns (bool);
    function destroyContract() public;
    function recoverTokens(address tokenAddress, uint amount) returns (bool);
}

contract DepositOfferToken is ReentrancyGuard, ERC20Interface, ICOInterface, DepositOfferInfo {
    using SafeMath for uint;
    
    uint public constant MAX_USD_FUND = TOKENS_PER_USD * USD_PER_ETH;
    uint public constant MIN_USD_FUND = 1 ether * MIN_ETH_FUND / USD_PER_ETH;
    uint public constant MIN_ETH_FUND = 1 ether * MIN_USD_AMOUNT / USD_PER_ETH;
    uint public constant MAX_INDIVIDUAL_FUND = 1 ether * MAX_USD_AMOUNT / USD_PER_ETH;
    
    uint public constant MIN_USD_AMOUNT = 50000;
    uint public constant MAX_USD_AMOUNT = 10000000000;
    uint public constant END_DATE = START_DATE + 15552000;
    uint public constant DECIMALS = 18;
    uint public constant TOTAL_SUPPLY = 2000000 * (10 ** DECIMALS);
    
    mapping(address => uint) public etherContributed;
    mapping(address => bool) public kycAddress;
    
    address public depositContract;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyFundWallet() {
        require(msg.sender == fundWallet);
        _;
    }
    
    modifier icoActive() {
        require(icoActive);
        _;
    }
    
    modifier icoEnded() {
        require(!icoActive);
        _;
    }
    
    constructor() public {
        require(owner != 0x0);
        require(fundWallet != 0x0);
        require(TOKENS_PER_USD > 0);
        require(USD_PER_ETH > 0);
        require(MIN_USD_AMOUNT > 0);
        require(MAX_USD_AMOUNT > MIN_USD_AMOUNT);
        require(START_DATE > 0);
        require(END_DATE > 0);
        
        totalSupply = TOTAL_SUPPLY;
        balanceOf[fundWallet] = totalSupply;
        Transfer(0x0, fundWallet, totalSupply);
    }
    
    function () public payable {
        buyTokens(msg.sender);
    }
    
    function icoFailed() public constant returns (bool) {
        return icoActive && (now > END_DATE && etherRaised < MIN_ETH_FUND);
    }
    
    function icoSucceeded() public constant returns (bool) {
        return !icoFailed() && etherRaised >= MIN_ETH_FUND;
    }
    
    function usdToTokens(uint usdAmount) public constant returns (uint) {
        return usdAmount.mul(TOKENS_PER_USD);
    }
    
    function etherToUsd(uint etherAmount) public constant returns (uint) {
        return etherAmount.mul(1 ether).div(USD_PER_ETH);
    }
    
    function usdRaised() public constant returns (uint) {
        return etherToUsd(etherRaised);
    }
    
    function tokensForEther(uint etherAmount) public constant returns (uint) {
        uint usdAmount = etherToUsd(etherAmount);
        uint bonusPercent = 0;
        
        if (usdAmount >= 10000) {
            bonusPercent = 10;
        }
        
        return etherAmount.mul(MAX_USD_FUND).mul(bonusPercent + 100).div(100);
    }
    
    function abortICO() public onlyOwner onlyFundWallet returns (bool) {
        require(!icoSuccessful);
        icoActive = false;
        return true;
    }
    
    function buyTokens(address investor) payable icoActive returns (bool) {
        require(!icoFailed());
        require(!icoSuccessful);
        require(now <= END_DATE);
        require(msg.value > 0);
        
        if(!kycAddress[investor]) {
            require(now >= START_DATE);
            require((etherContributed[investor].add(msg.value)) <= MAX_INDIVIDUAL_FUND);
        }
        
        uint tokens = tokensForEther(msg.value);
        transfer(fundWallet, investor, tokens);
        
        etherContributed[investor] = etherContributed[investor].add(msg.value);
        etherRaised = etherRaised.add(msg.value);
        
        return true;
    }
    
    function setKYC(address investor, bool approved) public onlyOwner onlyFundWallet returns (bool) {
        require(!icoFailed());
        kycAddress[investor] = approved;
        KYCAddress(investor, approved);
        return true;
    }
    
    function sweepFunds() public onlyFundWallet icoEnded returns (bool) {
        require(icoSucceeded());
        icoSuccessful = true;
        FundsTransferred(fundWallet, this.balance);
        fundWallet.transfer(this.balance);
        return true;
    }
    
    function refundInvestor(address investor) public icoEnded returns (bool) {
        require(icoFailed());
        uint amount = etherContributed[investor];
        transfer(investor, fundWallet, balanceOf[investor]);
        
        delete etherContributed[investor];
        delete kycAddress[investor];
        Refunded(investor, amount);
        
        if (amount > 0) {
            investor.transfer(amount);
        }
        return true;
    }
    
    function transfer(address to, uint value) public noReentrancy returns (bool) {
        require(icoSuccessful);
        super.transfer(to, value);
        
        if (to == depositContract) {
            require(DepositContract(depositContract).notify(msg.sender, value));
        }
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public noReentrancy returns (bool) {
        require(icoSuccessful);
        super.transferFrom(from, to, value);
        
        if (to == depositContract) {
            require(DepositContract(depositContract).notify(from, value));
        }
        return true;
    }
    
    function approve(address spender, uint value) public noReentrancy returns (bool) {
        require(icoSuccessful);
        super.approve(spender, value);
        return true;
    }
    
    function changeOwner(address newOwner) public onlyOwner onlyFundWallet returns (bool) {
        ChangeOwnerTo(newOwner);
        pendingOwner = newOwner;
        return true;
    }
    
    function acceptOwnership() public onlyOwner returns (bool) {
        require(msg.sender == pendingOwner);
        ChangedOwner(owner, pendingOwner);
        owner = pendingOwner;
        return true;
    }
    
    function setDepositContract(address depositContractAddress) public onlyOwner onlyFundWallet returns (bool) {
        depositContract = depositContractAddress;
        return true;
    }
    
    function destroyContract() public onlyOwner onlyFundWallet {
        require(!icoActive);
        require(this.balance == 0);
        selfdestruct(owner);
    }
    
    function recoverTokens(address tokenAddress, uint amount) public onlyFundWallet icoEnded returns (bool) {
        require(ERC20Interface(tokenAddress).transfer(owner, amount));
        return true;
    }
}

interface DepositContract {
    event Notified(address indexed from, uint indexed amount);
    function notify(address from, uint amount) public returns (bool);
}

contract DepositContractImpl is DepositContract {
    address public dot;
    
    function setdot(address tokenAddress) {
        dot = tokenAddress;
    }
    
    function notify(address from, uint amount) public returns (bool) {
        require(msg.sender == dot);
        Notified(from, amount);
        return true;
    }
}
```