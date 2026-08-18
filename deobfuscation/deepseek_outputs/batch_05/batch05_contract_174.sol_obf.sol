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

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
    uint256 constant public INITIAL_TOTAL_SUPPLY = 100 * 1E6 * (uint256(10) ** (decimals));

    address private icoAddress;

    modifier onlyIco() {
        require(msg.sender == icoAddress);
        _;
    }

    function BaceToken(address _icoAddress) public {
        require(_icoAddress != address(0));
        icoAddress = _icoAddress;
        totalSupply = totalSupply.add(INITIAL_TOTAL_SUPPLY);
        balances[icoAddress] = INITIAL_TOTAL_SUPPLY;
        Transfer(address(0), icoAddress, INITIAL_TOTAL_SUPPLY);
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

    function refundTokens(address _to, uint256 _value) onlyIco public {
        require(_value <= balances[_to]);
        address refundAddress = _to;
        balances[refundAddress] = balances[refundAddress].sub(_value);
        balances[icoAddress] = balances[icoAddress].add(_value);
        Transfer(_to, icoAddress, _value);
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

    function addWallet(address _wallet) onlyApi public {
        require(_wallet != address(0));
        require(!isWhitelisted(_wallet));
        whitelist[_wallet] = true;
        whitelistLength++;
    }

    function removeWallet(address _wallet) onlyOwner public {
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

contract BaceCrowdsale is Pausable, Whitelistable {
    using SafeMath for uint256;

    uint256 constant private DECIMALS = 18;
    uint256 constant public DECIMALS_18 = 18;
    uint256 constant public DECIMALS_20 = 20;

    address[] public preIcoInvestors;
    mapping(address => uint256) public preIcoEthInvested;
    address[] public preIcoEthInvestors;
    uint256 public preIcoTotalCollected;

    address[] public icoInvestors;
    mapping(address => uint256) public icoEthInvested;
    address[] public icoEthInvestors;
    uint256 public icoTotalCollected;

    uint256 public minInvestments;
    uint256 public maxInvestmentsPreIco;
    uint256 public maxInvestmentsIco;

    uint256 public preIcoSoldTokens;
    uint256 public icoSoldTokens;

    uint256 public exchangeRatePreIco;
    uint256 public exchangeRateIco;

    bool public burnt;

    uint256 public preIcoStartTime;
    uint256 public preIcoFinishTime;
    uint256 public icoStartTime;
    uint256 public icoFinishTime;

    bool public icoInstalled = false;
    uint256 public guardInterval;

    uint256 public hardCapPreIco;
    uint256 public hardCapIco;
    uint256 public minCap;

    uint256 public RESERVED_TOKENS_ANGLE;
    uint256 public RESERVED_TOKENS_BACE_TEAM;
    uint256 public RESERVED_TOKENS_BOUNTY;
    uint256 public RESERVED_TOKENS_ICO;
    uint256 public RESERVED_TOKENS_PRE_ICO;
    uint256 public BACE_ETH;
    uint256 public PREICO_BONUS;
    uint256 public ICO_BONUS;

    address public withdrawalWallet;
    address public backendWallet;

    bool public preIcoFinished = false;

    BaceToken public baceToken;

    modifier onlyIco() {
        require(msg.sender == address(baceToken));
        _;
    }

    function isIcoFailed() public view returns (bool) {
        return icoFinished() && (preIcoSoldTokens.add(icoSoldTokens) < minCap);
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

    function preIcoFinishedCheck() public view returns (bool) {
        return now > preIcoFinishTime;
    }

    function isIcoFinished() public view returns (bool) {
        return icoInstalled && now > icoFinishTime;
    }

    function guardIntervalFinished() public view returns (bool) {
        return now > icoFinishTime.add(guardInterval);
    }

    function setStartTimeIco(uint256 _startTimeIco, uint256 _endTimeIco) onlyOwner public {
        require(_startTimeIco >= now && _endTimeIco > _startTimeIco && _startTimeIco > preIcoFinishTime);
        icoStartTime = _startTimeIco;
        icoFinishTime = _endTimeIco;
        icoInstalled = true;
    }

    function tokensRemainingPreIco() public view returns(uint256) {
        if (preIcoFinished) {
            return 0;
        }
        return hardCapPreIco.sub(preIcoSoldTokens);
    }

    function tokensRemainingIco() public view returns(uint256) {
        if (burnt) {
            return 0;
        }
        if (preIcoFinished) {
            return hardCapIco.sub(icoSoldTokens).sub(preIcoSoldTokens);
        }
        return hardCapIco.sub(preIcoSoldTokens).sub(icoSoldTokens);
    }

    function addPreIcoInvestment(address _investor, uint256 _weiAmount, uint256 _tokenAmount) private {
        if (preIcoInvestors.length == 0 || preIcoInvestors[preIcoInvestors.length - 1] != _investor) {
            if (preIcoInvestors.length == 0 || preIcoInvestors[preIcoInvestors.length - 1] != _investor) {
                preIcoInvestors.push(_investor);
            }
        }
        preIcoSoldTokens = preIcoSoldTokens.add(_tokenAmount);
        if (_weiAmount > 0) {
            if (preIcoEthInvestors.length == 0 || preIcoEthInvestors[preIcoEthInvestors.length - 1] != _investor) {
                preIcoEthInvestors.push(_investor);
            }
            preIcoEthInvested[_investor] = preIcoEthInvested[_investor].add(_weiAmount);
            preIcoTotalCollected = preIcoTotalCollected.add(_weiAmount);
        }
    }

    function addIcoInvestment(address _investor, uint256 _weiAmount, uint256 _tokenAmount) private {
        if (icoInvestors.length == 0 || icoInvestors[icoInvestors.length - 1] != _investor) {
            icoInvestors.push(_investor);
        }
        icoSoldTokens = icoSoldTokens.add(_tokenAmount);
        if (_weiAmount > 0) {
            if (icoEthInvestors.length == 0 || icoEthInvestors[icoEthInvestors.length - 1] != _investor) {
                icoEthInvestors.push(_investor);
            }
            icoEthInvested[_investor] = icoEthInvested[_investor].add(_weiAmount);
            icoTotalCollected = icoTotalCollected.add(_weiAmount);
        }
    }

    function() public payable {
        buyTokens(msg.sender, msg.value);
    }

    function buyTokensByETH() public payable {
        buyTokens(msg.sender, msg.value);
    }

    function buyTokens(address _investor, uint256 _value) private onlyWhitelisted(msg.sender) whenNotPaused {
        require(_investor != address(0) && _value >= minInvestments);

        bool isPreIcoStage = isPreIco();
        bool isIcoStage = isIco();
        require(isPreIcoStage || isIcoStage);

        require((isPreIcoStage && tokensRemainingPreIco() > 0) || (isIcoStage && tokensRemainingIco() > 0));

        uint256 maxInvestment;
        uint256 tokensToSell = 0;
        uint256 refundWei = 0;

        uint256 currentInvestment = isPreIcoStage ? preIcoEthInvested[_investor] : icoEthInvested[_investor];

        if (currentInvestment.add(_value) > maxInvestmentsPreIco) {
            maxInvestment = maxInvestmentsPreIco.sub(currentInvestment);
            refundWei = refundWei.add(_value.sub(maxInvestment));
        } else {
            maxInvestment = _value;
        }

        uint256 exchangeRate = isPreIcoStage ? exchangeRatePreIco : exchangeRateIco;
        uint256 tokensAmount = maxInvestment.mul(exchangeRate);

        uint256 tokensRemaining = isPreIcoStage ? tokensRemainingPreIco() : tokensRemainingIco();
        uint256 currentTokens = isPreIcoStage ? preIcoSoldTokens : icoSoldTokens;

        uint256 tokensToSellFinal;
        uint256 weiToSpend;

        if (currentTokens.add(tokensAmount) > tokensRemaining) {
            tokensToSell = tokensRemaining;
            weiToSpend = tokensToSell.div(exchangeRate);
            refundWei = refundWei.add(maxInvestment.sub(weiToSpend));
        } else {
            tokensToSell = tokensAmount;
            weiToSpend = maxInvestment;
        }

        if (isPreIcoStage) {
            addPreIcoInvestment(_investor, weiToSpend, tokensToSell);
        } else {
            addIcoInvestment(_investor, weiToSpend, tokensToSell);
        }

        baceToken.transferFromIco(_investor, tokensToSell);

        if (refundWei > 0) {
            msg.sender.transfer(refundWei);
        }
    }

    function buyTokensByBackend(address _investor, uint256 _tokenAmount) public onlyWhitelisted(_investor) whenNotPaused {
        require(msg.sender == backendWallet || msg.sender == owner);
        require(_tokenAmount > 0);

        bool isPreIcoStage = isPreIco();
        bool isIcoStage = isIco();
        require(isPreIcoStage || isIcoStage);

        require((isPreIcoStage && tokensRemainingPreIco() > 0) || (isIcoStage && tokensRemainingIco() > 0));

        uint256 exchangeRate = isPreIcoStage ? exchangeRatePreIco : exchangeRateIco;
        uint256 currentTokens = isPreIcoStage ? preIcoSoldTokens : icoSoldTokens;

        require(maxInvestmentsPreIco.mul(exchangeRate) >= currentTokens.add(_tokenAmount));
        require(minInvestments.mul(exchangeRate) <= _tokenAmount);

        uint256 tokensRemaining = isPreIcoStage ? tokensRemainingPreIco() : tokensRemainingIco();
        require(tokensRemaining >= _tokenAmount);

        if (isPreIcoStage) {
            addPreIcoInvestment(_investor, 0, _tokenAmount);
        } else {
            addIcoInvestment(_investor, 0, _tokenAmount);
        }

        baceToken.transferFromIco(_investor, _tokenAmount);
    }

    function withdraw(uint256 _amount) public onlyOwner {
        require(isIcoSuccess() || (isIcoFailed() && guardIntervalFinished()));
        withdrawalWallet.transfer(_amount);
    }

    function refund() public {
        require(isIcoFailed() && !guardIntervalFinished());

        uint256 ethAmountPreIco = preIcoEthInvested[msg.sender];
        uint256 ethAmountIco = icoEthInvested[msg.sender];
        uint256 ethAmount = ethAmountPreIco.add(ethAmountIco);

        uint256 tokensAmountPreIco = preIcoSoldTokens;
        uint256 tokensAmountIco = icoSoldTokens;
        uint256 tokensAmount = tokensAmountPreIco.add(tokensAmountIco);

        require(ethAmount > 0 && tokensAmount > 0);

        preIcoEthInvested[msg.sender] = 0;
        icoEthInvested[msg.sender] = 0;
        preIcoSoldTokens = 0;
        icoSoldTokens = 0;

        msg.sender.transfer(ethAmount);
        baceToken.refundTokens(msg.sender, tokensAmount);
    }

    function setWithdrawalWallet(address _withdrawalWallet) public onlyOwner {
        require(_withdrawalWallet != address(0));
        withdrawalWallet = _withdrawalWallet;
    }

    function setBackendWallet(address _backendWallet) public onlyOwner {
        require(_backendWallet != address(0));
        backendWallet = _backendWallet;
    }

    function burnUnsoldTokens() onlyOwner public {
        require(isIcoFinished());
        baceToken.burnRemainingTokens();
        burnt = true;
    }

    function setMinCap(uint256 _newMinCap) public onlyOwner {
        require(now < preIcoFinishTime);
        minCap = _newMinCap;
    }

    function setPreIcoHardCap(uint256 _newPreIcoHardCap) public onlyOwner onlyIco {
        require(now < preIcoFinishTime);
        require(_newPreIcoHardCap <= hardCapIco);
        hardCapPreIco = _newPreIcoHardCap;
    }

    function setIcoHardCap(uint256 _newIcoHardCap) public onlyOwner onlyIco {
        require(now < preIcoFinishTime);
        require(_newIcoHardCap > hardCapPreIco);
        hardCapIco = _newIcoHardCap;
    }

    function getIcoInvestorsCount() public view returns(uint256) {
        return icoInvestors.length;
    }

    function getPreIcoInvestorsCount() public view returns(uint256) {
        return preIcoInvestors.length;
    }

    function getIcoEthInvestorsCount() public view returns(uint256) {
        return icoEthInvestors.length;
    }

    function getPreIcoEthInvestorsCount() public view returns(uint256) {
        return preIcoEthInvestors.length;
    }

    function getBackendWallet() public view returns(address) {
        return backendWallet;
    }

    function getWithdrawalWallet() public view returns(address) {
        return withdrawalWallet;
    }
}

contract BaceCrowdsaleFactory {
    BaceCrowdsale public crowdsale;

    function BaceCrowdsaleFactory (
        uint256 _preIcoStartTime,
        uint256 _preIcoFinishTime,
        address _angelInvestors,
        address _founders,
        address _backend,
        address _withdrawal,
        uint256 _minInvestments,
        uint256 _maxInvestments,
        bool _testMode
    ) public {
        crowdsale = new BaceCrowdsale(
            _preIcoStartTime,
            _preIcoFinishTime,
            _angelInvestors,
            _founders,
            _backend,
            _withdrawal,
            _minInvestments,
            _maxInvestments,
            _testMode
        );

        Whitelist whitelist = crowdsale.whitelist();
        whitelist.transferOwnership(msg.sender);

        BaceToken token = crowdsale.baceToken();
        token.transferOwnership(msg.sender);

        crowdsale.transferOwnership(msg.sender);
    }
}
