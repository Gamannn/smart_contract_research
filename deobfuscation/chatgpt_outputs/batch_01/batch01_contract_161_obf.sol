```solidity
pragma solidity ^0.4.13;

contract SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b != 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function divToMul(uint256 number, uint256 numerator, uint256 denominator) internal pure returns (uint256) {
        return div(mul(number, numerator), denominator);
    }

    function mulToDiv(uint256 number, uint256 numerator, uint256 denominator) internal pure returns (uint256) {
        return mul(div(number, numerator), denominator);
    }

    function volumeBonus(uint256 etherValue) internal pure returns (uint256) {
        if (etherValue >= 10000 ether) return 55;
        if (etherValue >= 5000 ether) return 50;
        if (etherValue >= 1000 ether) return 45;
        if (etherValue >= 200 ether) return 40;
        if (etherValue >= 100 ether) return 35;
        if (etherValue >= 50 ether) return 30;
        if (etherValue >= 30 ether) return 25;
        if (etherValue >= 20 ether) return 20;
        if (etherValue >= 10 ether) return 15;
        if (etherValue >= 5 ether) return 10;
        if (etherValue >= 1 ether) return 5;
        return 0;
    }

    function dateBonus(uint startIco, uint currentType, uint datetime) internal pure returns (uint256) {
        uint daysFromStart = (datetime - startIco) / 1 days + 1;
        if (currentType == 2) {
            if (daysFromStart <= 31) return 31 - daysFromStart + 1;
        } else if (currentType == 1) {
            if (daysFromStart <= 19) return 54 - (daysFromStart - 1) * 3;
        }
        return 0;
    }
}

contract AbstractToken {
    function totalSupply() public view returns (uint256);
    function balanceOf(address owner) public view returns (uint256 balance);
    function transfer(address to, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function approve(address spender, uint256 value) public returns (bool success);
    function allowance(address owner, address spender) public view returns (uint256 remaining);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Issuance(address indexed to, uint256 value);
}

contract StandardToken is AbstractToken, SafeMath {
    mapping (address => uint256) balances;
    mapping (address => bool) ownerAppended;
    mapping (address => mapping (address => uint256)) allowed;
    address[] public owners;

    function transfer(address to, uint256 value) public returns (bool success) {
        if (balances[msg.sender] >= value && balances[to] + value > balances[to]) {
            balances[msg.sender] -= value;
            balances[to] += value;
            if (!ownerAppended[to]) {
                ownerAppended[to] = true;
                owners.push(to);
            }
            Transfer(msg.sender, to, value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        if (balances[from] >= value && allowed[from][msg.sender] >= value && balances[to] + value > balances[to]) {
            balances[to] += value;
            balances[from] -= value;
            allowed[from][msg.sender] -= value;
            if (!ownerAppended[to]) {
                ownerAppended[to] = true;
                owners.push(to);
            }
            Transfer(from, to, value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address owner) public view returns (uint256 balance) {
        return balances[owner];
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256 remaining) {
        return allowed[owner][spender];
    }
}

contract VINNDTokenContract is StandardToken, SafeMath {
    string public constant name = "VINND";
    string public constant symbol = "VIN";

    modifier onlyIcoContract() {
        require(msg.sender == icoContract);
        _;
    }

    address public icoContract;

    function VINNDTokenContract(address _icoContract) public payable {
        assert(_icoContract != address(0));
        icoContract = _icoContract;
    }

    function burnTokens(address from, uint value) public onlyIcoContract {
        assert(from != address(0));
        require(value > 0);
        balances[from] = sub(balances[from], value);
    }

    function emitTokens(address to, uint value) public onlyIcoContract {
        assert(to != address(0));
        require(value > 0);
        balances[to] = add(balances[to], value);
        if (!ownerAppended[to]) {
            ownerAppended[to] = true;
            owners.push(to);
        }
    }

    function getOwner(uint index) public view returns (address, uint256) {
        return (owners[index], balances[owners[index]]);
    }

    function getOwnerCount() public view returns (uint) {
        return owners.length;
    }
}

contract VINContract is SafeMath {
    VINNDTokenContract public VINToken;

    enum Stage { Pause, Init, Running, Stopped }
    enum Type { PRESALE, ICO }

    Stage public currentStage = Stage.Pause;
    Type public currentType = Type.PRESALE;

    modifier whenInitialized() {
        require(currentStage >= Stage.Init);
        _;
    }

    modifier onlyManager() {
        require(msg.sender == icoOwner);
        _;
    }

    modifier onStageRunning() {
        require(currentStage == Stage.Running);
        _;
    }

    modifier onStageStopped() {
        require(currentStage == Stage.Stopped);
        _;
    }

    modifier checkType() {
        require(currentType == Type.ICO || currentType == Type.PRESALE);
        _;
    }

    modifier checkDateTime() {
        if (currentType == Type.PRESALE) {
            require(startPresaleDate < now && now < endPresaleDate);
        } else {
            require(startICODate < now && now < endICODate);
        }
        _;
    }

    address public icoOwner;
    uint256 public startPresaleDate;
    uint256 public endPresaleDate;
    uint256 public startICODate;
    uint256 public endICODate;
    uint256 public totalEther;
    bool public setBounty;
    bool public setFounder;
    bool public sentTokensToFounders;
    uint256 public totalSoldOnPresale;
    uint256 public totalSoldOnICO;
    uint256 public foundersRewardTime;
    uint256 public ICOPRICE;
    uint256 public PRICE;
    uint256 public totalBountyTokens;
    uint256 public presaleCap;
    uint256 public ICOCap;
    uint256 public totalCap;
    address public bountyOwner;
    address public founder;

    function VINContract() public payable {
        VINToken = new VINNDTokenContract(this);
        icoOwner = msg.sender;
    }

    function initialize(address _founder, address _bounty) public onlyManager {
        assert(currentStage != Stage.Init);
        assert(_founder != address(0));
        assert(_bounty != address(0));
        require(!setFounder);
        require(!setBounty);
        founder = _founder;
        bountyOwner = _bounty;
        VINToken.emitTokens(_bounty, totalBountyTokens);
        setFounder = true;
        setBounty = true;
        currentStage = Stage.Init;
    }

    function setType(Type _type) public onlyManager onStageStopped {
        currentType = _type;
    }

    function setStage(Stage _stage) public onlyManager {
        currentStage = _stage;
    }

    function setNewOwner(address _newicoOwner) public onlyManager {
        assert(_newicoOwner != address(0));
        icoOwner = _newicoOwner;
    }

    function buyTokens(address _buyer, uint datetime, uint etherAmount) private {
        assert(_buyer != address(0));
        require(etherAmount > 0);
        uint dateBonusPercent = 0;
        uint tokensToEmit = 0;
        if (currentType == Type.PRESALE) {
            tokensToEmit = etherAmount * PRICE;
            dateBonusPercent = dateBonus(startPresaleDate, 1, datetime);
        } else {
            tokensToEmit = etherAmount * ICOPRICE;
            dateBonusPercent = dateBonus(startICODate, 2, datetime);
        }
        uint volumeBonusPercent = volumeBonus(etherAmount);
        uint totalBonusPercent = dateBonusPercent + volumeBonusPercent;
        if (totalBonusPercent > 0) {
            tokensToEmit = tokensToEmit + divToMul(tokensToEmit, totalBonusPercent, 100);
        }
        if (currentType == Type.PRESALE) {
            require(add(totalSoldOnPresale, tokensToEmit) <= presaleCap);
            totalSoldOnPresale = add(totalSoldOnPresale, tokensToEmit);
        } else {
            require(add(totalSoldOnICO, tokensToEmit) <= ICOCap);
            totalSoldOnICO = add(totalSoldOnICO, tokensToEmit);
        }
        VINToken.emitTokens(_buyer, tokensToEmit);
        totalEther = add(totalEther, etherAmount);
    }

    function () public payable onStageRunning checkType checkDateTime {
        buyTokens(msg.sender, now, msg.value);
    }

    function burnTokens(address from, uint value) public onlyManager {
        VINToken.burnTokens(from, value);
    }

    function sendTokensToFounders() public onlyManager whenInitialized {
        require(!sentTokensToFounders && now >= foundersRewardTime);
        uint tokensSold = add(totalSoldOnICO, totalSoldOnPresale);
        uint totalTokenToSold = add(ICOCap, presaleCap);
        uint x = mul(mul(tokensSold, totalCap), 35);
        uint y = mul(100, totalTokenToSold);
        uint result = div(x, y);
        VINToken.emitTokens(founder, result);
        sentTokensToFounders = true;
    }

    function emitTokensToOtherWallet(address _buyer, uint _datetime, uint _ether) public onlyManager checkType {
        assert(_buyer != address(0));
        buyTokens(_buyer, _datetime, _ether * 10 ** 18);
    }
}
```