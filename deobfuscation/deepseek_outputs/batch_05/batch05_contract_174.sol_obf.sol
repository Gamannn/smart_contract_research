```solidity
pragma solidity ^0.4.18;

contract Ownable {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    function Ownable() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();
    
    bool public paused = false;
    
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    
    modifier whenPaused() {
        require(paused);
        _;
    }
    
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }
    
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
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
}

contract ERC20Basic {
    uint256 public totalSupply;
    
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    
    mapping(address => uint256) balances;
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) internal allowed;
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

contract BaceToken is StandardToken, Pausable {
    string constant public name = "Bace Token";
    string constant public symbol = "BACE";
    uint8 constant public decimals = 18;
    uint256 constant public INITIAL_TOTAL_SUPPLY = 100 * 1E6 * (10 ** uint256(decimals));
    
    address private icoAddress;
    
    modifier onlyIco() {
        require(msg.sender == icoAddress);
        _;
    }
    
    function BaceToken(address _icoAddress) public {
        require(_icoAddress != address(0));
        icoAddress = _icoAddress;
        totalSupply = totalSupply.add(INITIAL_TOTAL_SUPPLY);
        balances[_icoAddress] = balances[_icoAddress].add(INITIAL_TOTAL_SUPPLY);
        Transfer(address(0), _icoAddress, INITIAL_TOTAL_SUPPLY);
    }
    
    function transfer(address _to, uint256 _value) whenNotPaused public returns (bool) {
        super.transfer(_to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) whenNotPaused public returns (bool) {
        super.transferFrom(_from, _to, _value);
    }
    
    function transferFromIco(address _to, uint256 _value) onlyIco public returns (bool) {
        super.transfer(_to, _value);
    }
    
    function burnRemainingTokens() onlyIco public {
        uint256 remainingTokens = balanceOf(icoAddress);
        balances[icoAddress] = balances[icoAddress].sub(remainingTokens);
        totalSupply = totalSupply.sub(remainingTokens);
        Transfer(icoAddress, address(0), remainingTokens);
    }
    
    function refundTokens(address _from, uint256 _value) onlyIco public {
        require(_value <= balances[_from]);
        address investor = _from;
        balances[investor] = balances[investor].sub(_value);
        balances[icoAddress] = balances[icoAddress].add(_value);
        Transfer(_from, icoAddress, _value);
    }
}

contract Whitelist is Ownable {
    mapping(address => bool) whitelist;
    uint256 public whitelistLength = 0;
    address private apiAddress;
    
    modifier onlyApi() {
        require(msg.sender == apiAddress);
        _;
    }
    
    function setApiAddress(address _apiAddress) onlyOwner public {
        require(_apiAddress != address(0));
        apiAddress = _apiAddress;
    }
    
    function addToWhitelist(address _wallet) onlyApi public {
        require(_wallet != address(0));
        require(!isWhitelisted(_wallet));
        whitelist[_wallet] = true;
        whitelistLength++;
    }
    
    function removeFromWhitelist(address _wallet) onlyOwner public {
        require(_wallet != address(0));
        require(isWhitelisted(_wallet));
        whitelist[_wallet] = false;
        whitelistLength--;
    }
    
    function isWhitelisted(address _wallet) view public returns (bool) {
        return whitelist[_wallet];
    }
}

contract Whitelistable {
    Whitelist public whitelist;
    
    modifier onlyWhitelisted(address _wallet) {
        require(whitelist.isWhitelisted(_wallet));
        _;
    }
    
    function Whitelistable() public {
        whitelist = new Whitelist();
    }
}

contract BaceIco is Pausable, Whitelistable {
    using SafeMath for uint256;
    
    uint256 constant private DECIMALS = 18;
    uint256 constant public RESERVED_TOKENS_ANGEL = 10 * 1E6 * (10 ** DECIMALS);
    uint256 constant public RESERVED_TOKENS_TEAM = 10 * 1E6 * (10 ** DECIMALS);
    uint256 constant public PREICO_BONUS = 70;
    uint256 constant public HARDCAP_TOKENS_PRE_ICO = 1800 * (10 ** DECIMALS);
    uint256 constant public HARDCAP_TOKENS_ICO = 10 * 1E6 * (10 ** DECIMALS);
    
    address[] public preIcoInvestors;
    mapping(address => uint256) public preIcoInvestments;
    
    address[] public icoInvestors;
    mapping(address => uint256) public icoInvestments;
    
    address[] public preIcoTokenHolders;
    mapping(address => uint256) public preIcoTokens;
    
    address[] public icoTokenHolders;
    mapping(address => uint256) public icoTokens;
    
    uint256 public minInvestment;
    uint256 public maxInvestmentPreIco;
    uint256 public maxInvestmentIco;
    
    uint256 public preIcoSoldTokens;
    uint256 public icoSoldTokens;
    
    uint256 public exchangeRatePreIco;
    uint256 public exchangeRateIco;
    
    bool public burnt;
    
    BaceToken public token;
    
    uint256 public preIcoStartTime;
    uint256 public preIcoFinishTime;
    uint256 public icoStartTime;
    uint256 public icoFinishTime;
    bool public icoInstalled;
    uint256 public guardInterval;
    
    uint256 public preIcoTotalCollected;
    uint256 public icoTotalCollected;
    
    address public withdrawalWallet;
    address public backendWallet;
    
    uint256 public minCap;
    uint256 public hardCapPreIco;
    uint256 public hardCapIco;
    
    bool public testMode;
    
    function BaceIco(
        uint256 _preIcoStartTime,
        uint256 _preIcoFinishTime,
        address _angelInvestor,
        address _founderWallet,
        address _backendWallet,
        address _withdrawalWallet,
        uint256 _maxInvestmentPreIco,
        uint256 _maxInvestmentIco,
        bool _testMode
    ) public Whitelistable() {
        require(_angelInvestor != address(0) && _founderWallet != address(0) && 
                _backendWallet != address(0) && _withdrawalWallet != address(0));
        require(_preIcoStartTime >= now && _preIcoFinishTime > _preIcoStartTime);
        require(_maxInvestmentPreIco != 0 && _maxInvestmentIco != 0 && 
                _maxInvestmentPreIco > _maxInvestmentIco);
        
        token = new BaceToken(this);
        
        minInvestment = 1 ether;
        maxInvestmentPreIco = _maxInvestmentPreIco;
        maxInvestmentIco = _maxInvestmentIco;
        
        preIcoStartTime = _preIcoStartTime;
        preIcoFinishTime = _preIcoFinishTime;
        icoStartTime = 0;
        icoFinishTime = 0;
        icoInstalled = false;
        guardInterval = uint256(86400).mul(7);
        
        preIcoTotalCollected = 0;
        icoTotalCollected = 0;
        
        hardCapPreIco = HARDCAP_TOKENS_PRE_ICO;
        hardCapIco = HARDCAP_TOKENS_ICO;
        
        exchangeRatePreIco = 1800;
        exchangeRateIco = exchangeRatePreIco;
        
        burnt = false;
        
        backendWallet = _backendWallet;
        withdrawalWallet = _withdrawalWallet;
        
        whitelist.transferOwnership(msg.sender);
        token.transferFromIco(_angelInvestor, RESERVED_TOKENS_ANGEL);
        token.transferFromIco(_founderWallet, RESERVED_TOKENS_TEAM);
        token.transferOwnership(msg.sender);
    }
    
    modifier icoNotFinished() {
        require(!isIcoFinished());
        _;
    }
    
    function isIcoFailed() public view returns (bool) {
        return isIcoFinished() && icoSoldTokens < minCap;
    }
    
    function isIcoSuccess() public view returns (bool) {
        return isIcoFinished() && icoSoldTokens.add(preIcoSoldTokens) >= minCap;
    }
    
    function isPreIco() public view returns (bool) {
        return now > preIcoStartTime && now < preIcoFinishTime;
    }
    
    function isIco() public view returns (bool) {
        return icoInstalled && now > icoStartTime && now < icoFinishTime;
    }
    
    function isPreIcoFinished() public view returns (bool) {
        return now > preIcoFinishTime;
    }
    
    function isIcoFinished() public view returns (bool) {
        return icoInstalled && now > icoFinishTime;
    }
    
    function isGuardIntervalFinished() public view returns (bool) {
        return now > icoFinishTime.add(guardInterval);
    }
    
    function setStartTimeIco(uint256 _startTimeIco, uint256 _endTimeIco) onlyOwner public {
        require(_startTimeIco >= now && _endTimeIco > _startTimeIco && 
                _startTimeIco > preIcoFinishTime);
        icoStartTime = _startTimeIco;
        icoFinishTime = _endTimeIco;
        icoInstalled = true;
    }
    
    function tokensRemainingPreIco() public view returns(uint256) {
        if (burnt) {
            return 0;
        }
        return hardCapPreIco.sub(preIcoSoldTokens);
    }
    
    function tokensRemainingIco() public view returns(uint256) {
        if (burnt) {
            return 0;
        }
        if (isPreIco()) {
            return hardCapIco.sub(hardCapPreIco).sub(icoSoldTokens);
        }
        return hardCapIco.sub(preIcoSoldTokens).sub(icoSoldTokens);
    }
    
    function addPreIcoInvestment(address _investor, uint256 _weiAmount, uint256 _tokensAmount) private {
        if (preIcoTokens[_investor] == 0) {
            preIcoTokenHolders.push(_investor);
        }
        preIcoTokens[_investor] = preIcoTokens[_investor].add(_tokensAmount);
        preIcoSoldTokens = preIcoSoldTokens.add(_tokensAmount);
        
        if (_weiAmount > 0) {
            if (preIcoInvestments[_investor] == 0) {
                preIcoInvestors.push(_investor);
            }
            preIcoInvestments[_investor] = preIcoInvestments[_investor].add(_weiAmount);
            preIcoTotalCollected = preIcoTotalCollected.add(_weiAmount);
        }
    }
    
    function addIcoInvestment(address _investor, uint256 _weiAmount, uint256 _tokensAmount) private {
        if (icoTokens[_investor] == 0) {
            icoTokenHolders.push(_investor);
        }
        icoTokens[_investor] = icoTokens[_investor].add(_tokensAmount);
        icoSoldTokens = icoSoldTokens.add(_tokensAmount);
        
        if (_weiAmount > 0) {
            if (icoInvestments[_investor] == 0) {
                icoInvestors.push(_investor);
            }
            icoInvestments[_investor] = icoInvestments[_investor].add(_weiAmount);
            icoTotalCollected = icoTotalCollected.add(_weiAmount);
        }
    }
    
    function() public payable {
        processInvestment(msg.sender, msg.value);
    }
    
    function buyTokens() public payable {
        processInvestment(msg.sender, msg.value);
    }
    
    function processInvestment(address _investor, uint256 _weiAmount) private onlyWhitelisted(msg.sender) whenNotPaused {
        require(_investor != address(0) && _weiAmount >= minInvestment);
        bool isPreIcoStage = isPreIco();
        bool isIcoStage = isIco();
        require(isPreIcoStage || isIcoStage);
        require((isPreIcoStage && tokensRemainingPreIco() > 0) || 
                (isIcoStage && tokensRemainingIco() > 0));
        
        uint256 weiToProcess;
        uint256 weiToReturn = 0;
        uint256 currentInvestment = isPreIcoStage ? preIcoInvestments[_investor] : icoInvestments[_investor];
        uint256 maxInvestment = isPreIcoStage ? maxInvestmentPreIco : maxInvestmentIco;
        
        if (currentInvestment.add(_weiAmount) > maxInvestment) {
            weiToProcess = maxInvestment.sub(currentInvestment);
            weiToReturn = weiToReturn.add(_weiAmount.sub(weiToProcess));
        } else {
            weiToProcess = _weiAmount;
        }
        
        uint256 exchangeRate = isPreIcoStage ? exchangeRatePreIco : exchangeRateIco;
        uint256 tokensToBuy = weiToProcess.mul(exchangeRate);
        uint256 tokensRemaining = isPreIcoStage ? tokensRemainingPreIco() : tokensRemainingIco();
        uint256 currentTokens = isPreIcoStage ? preIcoTokens[_investor] : icoTokens[_investor];
        uint256 tokensToSell;
        uint256 weiUsed;
        
        if (current