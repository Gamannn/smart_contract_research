pragma solidity ^0.4.11;

contract Ownable {
    address public owner;

    function Ownable() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract Haltable is Ownable {
    bool public halted;

    modifier inNormalState {
        require(!halted);
        _;
    }

    modifier inEmergencyState {
        require(halted);
        _;
    }

    function halt() external onlyOwner inNormalState {
        halted = true;
    }

    function unhalt() external onlyOwner inEmergencyState {
        halted = false;
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC20Basic {
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) balances;

    function transfer(address to, uint256 value) returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        Transfer(msg.sender, to, value);
        return true;
    }

    function balanceOf(address owner) constant returns (uint256 balance) {
        return balances[owner];
    }
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) returns (bool);
    function approve(address spender, uint256 value) returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) allowed;

    function transferFrom(address from, address to, uint256 value) returns (bool) {
        var _allowance = allowed[from][msg.sender];
        balances[to] = balances[to].add(value);
        balances[from] = balances[from].sub(value);
        allowed[from][msg.sender] = _allowance.sub(value);
        Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) returns (bool) {
        require((value == 0) || (allowed[msg.sender][spender] == 0));
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) constant returns (uint256 remaining) {
        return allowed[owner][spender];
    }
}

contract Burnable is StandardToken {
    using SafeMath for uint;

    event Burn(address indexed from, uint value);

    function burn(uint value) returns (bool success) {
        require(value > 0 && balances[msg.sender] >= value);
        balances[msg.sender] = balances[msg.sender].sub(value);
        totalSupply = totalSupply.sub(value);
        Burn(msg.sender, value);
        return true;
    }

    function burnFrom(address from, uint value) returns (bool success) {
        require(from != 0x0 && value > 0 && balances[from] >= value);
        require(value <= allowed[from][msg.sender]);
        balances[from] = balances[from].sub(value);
        totalSupply = totalSupply.sub(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        Burn(from, value);
        return true;
    }

    function transfer(address to, uint value) returns (bool success) {
        require(to != 0x0);
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint value) returns (bool success) {
        require(to != 0x0);
        return super.transferFrom(from, to, value);
    }
}

contract JincorToken is Burnable, Ownable {
    string public constant name = "Jincor Token";
    string public constant symbol = "JCR";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    bool public released;
    address public releaseAgent;
    mapping (address => bool) public transferAgents;

    modifier canTransfer(address _sender) {
        require(released || transferAgents[_sender]);
        _;
    }

    modifier inReleaseState(bool releaseState) {
        require(releaseState == released);
        _;
    }

    modifier onlyReleaseAgent() {
        require(msg.sender == releaseAgent);
        _;
    }

    function JincorToken() {
        totalSupply = 35000000 * 1 ether;
        balances[msg.sender] = totalSupply;
    }

    function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {
        require(addr != 0x0);
        releaseAgent = addr;
    }

    function release() onlyReleaseAgent inReleaseState(false) public {
        released = true;
    }

    function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
        require(addr != 0x0);
        transferAgents[addr] = state;
    }

    function transfer(address to, uint value) canTransfer(msg.sender) returns (bool success) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint value) canTransfer(from) returns (bool success) {
        return super.transferFrom(from, to, value);
    }

    function burn(uint value) onlyOwner returns (bool success) {
        return super.burn(value);
    }

    function burnFrom(address from, uint value) onlyOwner returns (bool success) {
        return super.burnFrom(from, value);
    }
}

contract InvestorWhiteList is Ownable {
    mapping (address => bool) public investorWhiteList;
    mapping (address => address) public referralList;

    function InvestorWhiteList() {
    }

    function addInvestorToWhiteList(address investor) external onlyOwner {
        require(investor != 0x0 && !investorWhiteList[investor]);
        investorWhiteList[investor] = true;
    }

    function removeInvestorFromWhiteList(address investor) external onlyOwner {
        require(investor != 0x0 && investorWhiteList[investor]);
        investorWhiteList[investor] = false;
    }

    function addReferralOf(address investor, address referral) external onlyOwner {
        require(investor != 0x0 && referral != 0x0 && referralList[investor] == 0x0 && investor != referral);
        referralList[investor] = referral;
    }

    function isAllowed(address investor) constant external returns (bool result) {
        return investorWhiteList[investor];
    }

    function getReferralOf(address investor) constant external returns (address result) {
        return referralList[investor];
    }
}

contract PriceReceiver {
    modifier onlyEthPriceProvider() {
        require(msg.sender == ethPriceProvider);
        _;
    }

    modifier onlyBtcPriceProvider() {
        require(msg.sender == btcPriceProvider);
        _;
    }

    function receiveEthPrice(uint ethUsdPrice) external;
    function receiveBtcPrice(uint btcUsdPrice) external;
    function setEthPriceProvider(address provider) external;
    function setBtcPriceProvider(address provider) external;
}

contract JincorTokenICO is Haltable, PriceReceiver {
    using SafeMath for uint;

    string public constant name = "Jincor Token ICO";

    JincorToken public token;
    InvestorWhiteList public investorWhiteList;

    mapping (address => uint) public deposited;

    uint256 public constant VOLUME_5_REF_3 = 100 ether;
    uint256 public constant VOLUME_7_REF_4 = 250 ether;
    uint256 public constant VOLUME_10_REF_5 = 500 ether;
    uint256 public constant VOLUME_12d5_REF_5d5 = 1000 ether;
    uint256 public constant VOLUME_15_REF_6 = 2000 ether;
    uint256 public constant VOLUME_20_REF_7 = 5000 ether;

    bool public crowdsaleFinished;
    bool public softCapReached;

    uint256 public endBlock;
    uint256 public startBlock;

    uint256 public weiRefunded;
    uint256 public tokensSold;
    uint256 public collected;
    uint256 public softCap;
    uint256 public hardCap;

    uint256 public btcUsdRate;
    uint256 public ethUsdRate;
    uint256 public constant jcrUsdRate = 100;

    address public preSaleAddress;
    address public beneficiary;

    address public btcPriceProvider;
    address public ethPriceProvider;

    event SoftCapReached(uint softCap);
    event NewContribution(address indexed holder, uint tokenAmount, uint etherAmount);
    event NewReferralTransfer(address indexed investor, address indexed referral, uint tokenAmount);
    event Refunded(address indexed holder, uint amount);

    modifier icoActive() {
        require(block.number >= startBlock && block.number < endBlock);
        _;
    }

    modifier icoEnded() {
        require(block.number >= endBlock);
        _;
    }

    modifier minInvestment() {
        require(msg.value >= 0.1 * 1 ether);
        _;
    }

    modifier inWhiteList() {
        require(investorWhiteList.isAllowed(msg.sender));
        _;
    }

    function JincorTokenICO(
        uint _hardCapJCR,
        uint _softCapJCR,
        address _token,
        address _beneficiary,
        address _investorWhiteList,
        uint _baseEthUsdPrice,
        uint _baseBtcUsdPrice,
        uint _startBlock,
        uint _endBlock
    ) {
        hardCap = _hardCapJCR.mul(1 ether);
        softCap = _softCapJCR.mul(1 ether);
        token = JincorToken(_token);
        beneficiary = _beneficiary;
        investorWhiteList = InvestorWhiteList(_investorWhiteList);
        startBlock = _startBlock;
        endBlock = _endBlock;
        ethUsdRate = _baseEthUsdPrice;
        btcUsdRate = _baseBtcUsdPrice;
        owner = 0xd1436F0A5e9b063733A67E5dc9Abe45792A423fE;
    }

    function() payable minInvestment inWhiteList {
        doPurchase();
    }

    function refund() external icoEnded {
        require(softCapReached == false);
        require(deposited[msg.sender] > 0);
        uint refund = deposited[msg.sender];
        deposited[msg.sender] = 0;
        msg.sender.transfer(refund);
        weiRefunded = weiRefunded.add(refund);
        Refunded(msg.sender, refund);
    }

    function withdraw() external onlyOwner {
        require(softCapReached);
        beneficiary.transfer(collected);
        token.transfer(beneficiary, token.balanceOf(this));
        crowdsaleFinished = true;
    }

    function calculateBonus(uint tokens) internal constant returns (uint bonus) {
        if (msg.value >= VOLUME_20_REF_7) {
            return tokens.mul(20).div(100);
        }
        if (msg.value >= VOLUME_15_REF_6) {
            return tokens.mul(15).div(100);
        }
        if (msg.value >= VOLUME_12d5_REF_5d5) {
            return tokens.mul(125).div(1000);
        }
        if (msg.value >= VOLUME_10_REF_5) {
            return tokens.mul(10).div(100);
        }
        if (msg.value >= VOLUME_7_REF_4) {
            return tokens.mul(7).div(100);
        }
        if (msg.value >= VOLUME_5_REF_3) {
            return tokens.mul(5).div(100);
        }
        return 0;
    }

    function calculateReferralBonus(uint tokens) internal constant returns (uint bonus) {
        if (msg.value >= VOLUME_20_REF_7) {
            return tokens.mul(7).div(100);
        }
        if (msg.value >= VOLUME_15_REF_6) {
            return tokens.mul(6).div(100);
        }
        if (msg.value >= VOLUME_12d5_REF_5d5) {
            return tokens.mul(55).div(1000);
        }
        if (msg.value >= VOLUME_10_REF_5) {
            return tokens.mul(5).div(100);
        }
        if (msg.value >= VOLUME_7_REF_4) {
            return tokens.mul(4).div(100);
        }
        if (msg.value >= VOLUME_5_REF_3) {
            return tokens.mul(3).div(100);
        }
        return 0;
    }

    function receiveEthPrice(uint ethUsdPrice) external onlyEthPriceProvider {
        require(ethUsdPrice > 0);
        ethUsdRate = ethUsdPrice;
    }

    function receiveBtcPrice(uint btcUsdPrice) external onlyBtcPriceProvider {
        require(btcUsdPrice > 0);
        btcUsdRate = btcUsdPrice;
    }

    function setEthPriceProvider(address provider) external onlyOwner {
        require(provider != 0x0);
        ethPriceProvider = provider;
    }

    function setBtcPriceProvider(address provider) external onlyOwner {
        require(provider != 0x0);
        btcPriceProvider = provider;
    }

    function setNewWhiteList(address newWhiteList) external onlyOwner {
        require(newWhiteList != 0x0);
        investorWhiteList = InvestorWhiteList(newWhiteList);
    }

    function doPurchase() private icoActive inNormalState {
        require(!crowdsaleFinished);
        uint tokens = msg.value.mul(ethUsdRate).div(jcrUsdRate);
        uint referralBonus = calculateReferralBonus(tokens);
        address referral = investorWhiteList.getReferralOf(msg.sender);
        tokens = tokens.add(calculateBonus(tokens));
        uint newTokensSold = tokensSold.add(tokens);
        if (referralBonus > 0 && referral != 0x0) {
            newTokensSold = newTokensSold.add(referralBonus);
        }
        require(newTokensSold <= hardCap);
        if (!softCapReached && newTokensSold >= softCap) {
            softCapReached = true;
            SoftCapReached(softCap);
        }
        collected = collected.add(msg.value);
        tokensSold = newTokensSold;
        deposited[msg.sender] = deposited[msg.sender].add(msg.value);
        token.transfer(msg.sender, tokens);
        NewContribution(msg.sender, tokens, msg.value);
        if (referralBonus > 0 && referral != 0x0) {
            token.transfer(referral, referralBonus);
            NewReferralTransfer(msg.sender, referral, referralBonus);
        }
    }

    function transferOwnership(address newOwner) onlyOwner icoEnded {
        super.transferOwnership(newOwner);
    }
}