pragma solidity ^0.4.13;

contract SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b != 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
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

    function divToMul(uint256 number, uint256 numerator, uint256 denominator) internal returns (uint256) {
        return div(mul(number, numerator), denominator);
    }

    function mulToDiv(uint256 number, uint256 numerator, uint256 denominator) internal returns (uint256) {
        return mul(div(number, numerator), denominator);
    }

    function volumeBonus(uint256 etherValue) internal returns (uint256) {
        if (etherValue >= 10000000000000000000000) return 55;
        if (etherValue >= 5000000000000000000000) return 50;
        if (etherValue >= 1000000000000000000000) return 45;
        if (etherValue >= 200000000000000000000) return 40;
        if (etherValue >= 100000000000000000000) return 35;
        if (etherValue >= 50000000000000000000) return 30;
        if (etherValue >= 30000000000000000000) return 25;
        if (etherValue >= 20000000000000000000) return 20;
        if (etherValue >= 10000000000000000000) return 15;
        if (etherValue >= 5000000000000000000) return 10;
        if (etherValue >= 1000000000000000000) return 5;
        return 0;
    }

    function dateBonus(uint startIco, uint currentType, uint datetime) internal returns (uint256) {
        if (currentType == 2) {
            uint daysFromStart = (datetime - startIco) / config.DAY_IN_SECONDS + 1;
            if (daysFromStart == 1) return 30;
            if (daysFromStart == 2) return 29;
            if (daysFromStart == 3) return 28;
            if (daysFromStart == 4) return 27;
            if (daysFromStart == 5) return 26;
            if (daysFromStart == 6) return 25;
            if (daysFromStart == 7) return 24;
            if (daysFromStart == 8) return 23;
            if (daysFromStart == 9) return 22;
            if (daysFromStart == 10) return 21;
            if (daysFromStart == 11) return 20;
            if (daysFromStart == 12) return 19;
            if (daysFromStart == 13) return 18;
            if (daysFromStart == 14) return 17;
            if (daysFromStart == 15) return 16;
            if (daysFromStart == 16) return 15;
            if (daysFromStart == 17) return 14;
            if (daysFromStart == 18) return 13;
            if (daysFromStart == 19) return 12;
            if (daysFromStart == 20) return 11;
            if (daysFromStart == 21) return 10;
            if (daysFromStart == 22) return 9;
            if (daysFromStart == 23) return 8;
            if (daysFromStart == 24) return 7;
            if (daysFromStart == 25) return 6;
            if (daysFromStart == 26) return 5;
            if (daysFromStart == 27) return 4;
            if (daysFromStart == 28) return 3;
            if (daysFromStart == 29) return 2;
            if (daysFromStart == 30) return 1;
            if (daysFromStart == 31) return 1;
            if (daysFromStart == 32) return 1;
        }
        if (currentType == 1) {
            uint daysFromPresaleStart = (datetime - startIco) / config.DAY_IN_SECONDS + 1;
            if (daysFromPresaleStart == 1) return 54;
            if (daysFromPresaleStart == 2) return 51;
            if (daysFromPresaleStart == 3) return 48;
            if (daysFromPresaleStart == 4) return 45;
            if (daysFromPresaleStart == 5) return 42;
            if (daysFromPresaleStart == 6) return 39;
            if (daysFromPresaleStart == 7) return 36;
            if (daysFromPresaleStart == 8) return 33;
            if (daysFromPresaleStart == 9) return 30;
            if (daysFromPresaleStart == 10) return 27;
            if (daysFromPresaleStart == 11) return 24;
            if (daysFromPresaleStart == 12) return 21;
            if (daysFromPresaleStart == 13) return 18;
            if (daysFromPresaleStart == 14) return 15;
            if (daysFromPresaleStart == 15) return 12;
            if (daysFromPresaleStart == 16) return 9;
            if (daysFromPresaleStart == 17) return 6;
            if (daysFromPresaleStart == 18) return 4;
            if (daysFromPresaleStart == 19) return 0;
        }
        return 0;
    }
}

contract AbstractToken {
    function totalSupply() constant returns (uint256) {}
    function balanceOf(address owner) constant returns (uint256 balance);
    function transfer(address to, uint256 value) returns (bool success);
    function transferFrom(address from, address to, uint256 value) returns (bool success);
    function approve(address spender, uint256 value) returns (bool success);
    function allowance(address owner, address spender) constant returns (uint256 remaining);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Issuance(address indexed to, uint256 value);
}

contract StandardToken is AbstractToken {
    mapping (address => uint256) balances;
    mapping (address => bool) ownerAppended;
    mapping (address => mapping (address => uint256)) allowed;
    address[] public owners;

    function transfer(address to, uint256 value) returns (bool success) {
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

    function transferFrom(address from, address to, uint256 value) returns (bool success) {
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

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address spender, uint256 value) returns (bool success) {
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address _owner, address spender) constant returns (uint256 remaining) {
        return allowed[_owner][spender];
    }
}

contract VINNDTokenContract is StandardToken, SafeMath {
    string public constant name = "VINND";
    string public constant symbol = "VIN";
    
    modifier onlyIcoContract() {
        require(msg.sender == config.icoContract);
        _;
    }

    function VINNDTokenContract(address _icoContract) payable {
        assert(_icoContract != 0x0);
        config.icoContract = _icoContract;
    }

    function burnTokens(address from, uint value) onlyIcoContract {
        assert(from != 0x0);
        require(value > 0);
        balances[from] = sub(balances[from], value);
    }

    function emitTokens(address to, uint value) onlyIcoContract {
        assert(to != 0x0);
        require(value > 0);
        balances[to] = add(balances[to], value);
        if (!ownerAppended[to]) {
            ownerAppended[to] = true;
            owners.push(to);
        }
    }

    function getOwner(uint index) constant returns (address, uint256) {
        return (owners[index], balances[owners[index]]);
    }

    function getOwnerCount() constant returns (uint) {
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
        require(msg.sender == config.icoOwner);
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
            require(config.startPresaleDate < now && now < config.endPresaleDate);
        } else {
            require(config.startICODate < now && now < config.endICODate);
        }
        _;
    }

    function VINContract() payable {
        VINToken = new VINNDTokenContract(this);
        config.icoOwner = msg.sender;
    }

    function initialize(address _founder, address _bounty) onlyManager {
        assert(currentStage != Stage.Init);
        assert(_founder != 0x0);
        assert(_bounty != 0x0);
        require(!config.setFounder);
        require(!config.setBounty);
        config.founder = _founder;
        config.bountyOwner = _bounty;
        VINToken.emitTokens(_bounty, config.totalBountyTokens);
        config.setFounder = true;
        config.setBounty = true;
        currentStage = Stage.Init;
    }

    function setType(Type _type) public onlyManager onStageStopped {
        currentType = _type;
    }

    function setStage(Stage _stage) public onlyManager {
        currentStage = _stage;
    }

    function setNewOwner(address _newicoOwner) onlyManager {
        assert(_newicoOwner != 0x0);
        config.icoOwner = _newicoOwner;
    }

    function buyTokens(address _buyer, uint datetime, uint etherValue) private {
        assert(_buyer != 0x0);
        require(etherValue > 0);
        uint dateBonusPercent = 0;
        uint tokensToEmit = 0;
        if (currentType == Type.PRESALE) {
            tokensToEmit = etherValue * config.PRICE;
            dateBonusPercent = dateBonus(config.startPresaleDate, 1, datetime);
        } else {
            tokensToEmit = etherValue * config.ICOPRICE;
            dateBonusPercent = dateBonus(config.startICODate, 2, datetime);
        }
        uint volumeBonusPercent = volumeBonus(etherValue);
        uint totalBonusPercent = dateBonusPercent + volumeBonusPercent;
        if (totalBonusPercent > 0) {
            tokensToEmit = tokensToEmit + divToMul(tokensToEmit, totalBonusPercent, 100);
        }
        if (currentType == Type.PRESALE) {
            require(add(config.totalSoldOnPresale, tokensToEmit) <= config.presaleCap);
            config.totalSoldOnPresale = add(config.totalSoldOnPresale, tokensToEmit);
        } else {
            require(add(config.totalSoldOnICO, tokensToEmit) <= config.ICOCap);
            config.totalSoldOnICO = add(config.totalSoldOnICO, tokensToEmit);
        }
        VINToken.emitTokens(_buyer, tokensToEmit);
        config.totalEther = add(config.totalEther, etherValue);
    }

    function () payable onStageRunning checkType checkDateTime {
        buyTokens(msg.sender, now, msg.value);
    }

    function burnTokens(address from, uint value) onlyManager {
        VINToken.burnTokens(from, value);
    }

    function sendTokensToFounders() onlyManager whenInitialized {
        require(!config.sentTokensToFounders && now >= config.foundersRewardTime);
        uint tokensSold = add(config.totalSoldOnICO, config.totalSoldOnPresale);
        uint totalTokenToSold = add(config.ICOCap, config.presaleCap);
        uint x = mul(mul(tokensSold, config.totalCap), 35);
        uint y = mul(100, totalTokenToSold);
        uint result = div(x, y);
        VINToken.emitTokens(config.founder, result);
        config.sentTokensToFounders = true;
    }

    function emitTokensToOtherWallet(address _buyer, uint _datetime, uint _ether) onlyManager checkType {
        assert(_buyer != 0x0);
        buyTokens(_buyer, _datetime, _ether * 10 ** 18);
    }

    struct Config {
        uint256 totalEther;
        bool setBounty;
        bool setFounder;
        bool sentTokensToFounders;
        uint256 totalSoldOnPresale;
        uint256 totalSoldOnICO;
        uint256 foundersRewardTime;
        uint256 ICOPRICE;
        uint256 PRICE;
        uint256 totalBountyTokens;
        uint256 presaleCap;
        uint256 ICOCap;
        uint256 totalCap;
        address bountyOwner;
        address founder;
        address icoOwner;
        uint256 endICODate;
        uint256 startICODate;
        uint256 endPresaleDate;
        uint256 startPresaleDate;
        address icoContract;
        uint256 decimals;
        uint256 totalSupply;
        uint256 icoPrice;
        uint256 preIcoPrice;
        uint256 BASE;
        uint256 DAY_IN_SECONDS;
    }
    
    Config config = Config(
        0,
        false,
        false,
        false,
        0,
        0,
        1519084800,
        1500,
        3000,
        14444444000000000000000000,
        28888888000000000000000000,
        534444444000000000000000000,
        888888888000000000000000000,
        address(0),
        address(0),
        address(0),
        1518998399,
        1516233600,
        1514591999,
        1512950400,
        0x0,
        18,
        0,
        1500,
        3000,
        1000000000000000000,
        86400
    );
}