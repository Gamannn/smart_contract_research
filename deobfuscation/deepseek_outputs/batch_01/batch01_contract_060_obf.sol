pragma solidity ^0.4.16;

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

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) returns (bool);
    function approve(address spender, uint256 value) returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) balances;

    function transfer(address _to, uint256 _value) returns (bool) {
        require(_to != address(0));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
}

contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) allowed;

    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        require(_to != address(0));
        var _allowance = allowed[_from][msg.sender];
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint _addedValue) returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) returns (bool success) {
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

contract Ownable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(0x0, _to, _amount);
        return true;
    }

    function finishMinting() onlyOwner returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
}

contract usingMyWillConsts {
    Constants.TOKEN_DECIMALS
}

contract MyWillToken is usingMyWillConsts, MintableToken {
    mapping(address => bool) excluded;

    function name() constant public returns (string _name) {
        return "MyWill Coin";
    }

    function symbol() constant public returns (bytes32 _symbol) {
        return "WIL";
    }

    function decimals() constant public returns (uint8 _decimals) {
        return Constants.TOKEN_DECIMALS_UINT8;
    }

    function crowdsaleFinished() onlyOwner {
        Constants.paused = false;
    }

    function addExcluded(address _toExclude) onlyOwner {
        excluded[_toExclude] = true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        require(!Constants.paused || excluded[_from]);
        return super.transferFrom(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) returns (bool) {
        require(!Constants.paused || excluded[msg.sender]);
        return super.transfer(_to, _value);
    }
}

contract Crowdsale {
    using SafeMath for uint;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint value, uint amount);

    function Crowdsale(uint32 _startTime, uint32 _endTime, uint _hardCap, address _wallet) {
        require(_startTime >= now);
        require(_endTime >= _startTime);
        require(_wallet != 0x0);
        require(_hardCap > 0);
        Constants.token = createTokenContract();
        Constants.startTime = _startTime;
        Constants.endTime = _endTime;
        Constants.hardCap = _hardCap;
        Constants.wallet = _wallet;
    }

    function createTokenContract() internal returns (MintableToken) {
        return new MintableToken();
    }

    function getRate(uint amount) internal constant returns (uint);
    function getBaseRate() internal constant returns (uint);

    function getRateScale() internal constant returns (uint) {
        return 1;
    }

    function() payable {
        buyTokens(msg.sender, msg.value);
    }

    function buyTokens(address beneficiary, uint amountWei) internal {
        require(beneficiary != 0x0);
        uint totalSupply = Constants.token.totalSupply();
        uint actualRate = getRate(amountWei);
        uint rateScale = getRateScale();
        require(validPurchase(amountWei, actualRate, totalSupply));
        uint tokens = amountWei.mul(actualRate).div(rateScale);
        uint change = 0;
        if (tokens.add(totalSupply) > Constants.hardCap) {
            uint maxTokens = Constants.hardCap.sub(totalSupply);
            uint realAmount = maxTokens.mul(rateScale).div(actualRate);
            tokens = realAmount.mul(actualRate).div(rateScale);
            change = amountWei - realAmount;
            amountWei = realAmount;
        }
        Constants.weiRaised = Constants.weiRaised.add(amountWei);
        Constants.soldTokens = Constants.soldTokens.add(tokens);
        Constants.token.mint(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, amountWei, tokens);
        if (change != 0) {
            msg.sender.transfer(change);
        }
        forwardFunds(amountWei);
    }

    function forwardFunds(uint amountWei) internal {
        Constants.wallet.transfer(amountWei);
    }

    function validPurchase(uint _amountWei, uint _actualRate, uint totalSupply) internal constant returns (bool) {
        bool withinPeriod = now >= Constants.startTime && now <= Constants.endTime;
        bool nonZeroPurchase = _amountWei != 0;
        bool hardCapNotReached = totalSupply <= Constants.hardCap.sub(_actualRate);
        return withinPeriod && nonZeroPurchase && hardCapNotReached;
    }

    function hasEnded() public constant returns (bool) {
        return now > Constants.endTime || Constants.token.totalSupply() > Constants.hardCap.sub(getBaseRate());
    }

    function hasStarted() public constant returns (bool) {
        return now >= Constants.startTime;
    }

    function hasEnded(uint _value) public constant returns (bool) {
        uint actualRate = getRate(_value);
        return now > Constants.endTime || Constants.token.totalSupply() > Constants.hardCap.sub(actualRate);
    }
}

contract FinalizableCrowdsale is Crowdsale, Ownable {
    using SafeMath for uint256;
    event Finalized();

    function FinalizableCrowdsale(uint32 _startTime, uint32 _endTime, uint _hardCap, address _wallet) Crowdsale(_startTime, _endTime, _hardCap, _wallet) {
    }

    function finalize() onlyOwner notFinalized {
        require(hasEnded());
        finalization();
        Finalized();
        Constants.isFinalized = true;
    }

    function finalization() internal {
    }

    modifier notFinalized() {
        require(!Constants.isFinalized);
        _;
    }
}

contract RefundVault is Ownable {
    using SafeMath for uint256;

    enum State {Active, Refunding, Closed}

    mapping (address => uint256) public deposited;
    State public state;

    event Closed();
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);

    function RefundVault(address _wallet) {
        require(_wallet != 0x0);
        wallet = _wallet;
        state = State.Active;
    }

    function deposit(address investor) onlyOwner payable {
        require(state == State.Active);
        deposited[investor] = deposited[investor].add(msg.value);
    }

    function close() onlyOwner {
        require(state == State.Active);
        state = State.Closed;
        Closed();
        wallet.transfer(this.balance);
    }

    function enableRefunds() onlyOwner {
        require(state == State.Active);
        state = State.Refunding;
        RefundsEnabled();
    }

    function refund(address investor) onlyOwner {
        require(state == State.Refunding);
        uint256 depositedValue = deposited[investor];
        deposited[investor] = 0;
        investor.transfer(depositedValue);
        Refunded(investor, depositedValue);
    }
}

contract RefundableCrowdsale is FinalizableCrowdsale {
    using SafeMath for uint256;
    RefundVault public vault;

    function RefundableCrowdsale(uint32 _startTime, uint32 _endTime, uint _hardCap, address _wallet, uint _goal) FinalizableCrowdsale(_startTime, _endTime, _hardCap, _wallet) {
        require(_goal > 0);
        vault = new RefundVault(Constants.wallet);
        Constants.goal = _goal;
    }

    function forwardFunds(uint amountWei) internal {
        if (goalReached()) {
            Constants.wallet.transfer(amountWei);
        } else {
            vault.deposit.value(amountWei)(msg.sender);
        }
    }

    function claimRefund() public {
        require(Constants.isFinalized);
        require(!goalReached());
        vault.refund(msg.sender);
    }

    function closeVault() public onlyOwner {
        require(goalReached());
        vault.close();
    }

    function finalization() internal {
        super.finalization();
        if (goalReached()) {
            vault.close();
        } else {
            vault.enableRefunds();
        }
    }

    function goalReached() public constant returns (bool) {
        return Constants.weiRaised >= Constants.goal;
    }
}

contract MyWillRateProviderI {
    function getRate(address buyer, uint totalSold, uint amountWei) public constant returns (uint);
    function getRateScale() public constant returns (uint);
    function getBaseRate() public constant returns (uint);
}

contract MyWillRateProvider is usingMyWillConsts, MyWillRateProviderI, Ownable {
    Constants.TOKEN_DECIMAL_MULTIPLIER Constants.TOKEN_DECIMAL_MULTIPLIER Constants.TOKEN_DECIMAL_MULTIPLIER Constants.RATE_SCALE Constants.RATE_SCALE Constants.RATE_SCALE Constants.RATE_SCALE

    struct ExclusiveRate {
        uint32 workUntil;
        uint rate;
        uint16 bonusPercent1000;
        bool exists;
    }

    mapping(address => ExclusiveRate) exclusiveRate;

    function getRateScale() public constant returns (uint) {
        return Constants.RATE_SCALE;
    }

    function getBaseRate() public constant returns (uint) {
        return Constants.BASE_RATE;
    }

    function getRate(address buyer, uint totalSold, uint amountWei) public constant returns (uint) {
        uint rate;
        if (totalSold < Constants.STEP_30) {
            rate = Constants.RATE_30;
        } else if (totalSold < Constants.STEP_20) {
            rate = Constants.RATE_20;
        } else if (totalSold < Constants.STEP_10) {
            rate = Constants.RATE_10;
        } else {
            rate = Constants.BASE_RATE;
        }
        if (amountWei >= 1000 ether) {
            rate += rate * 13 / 100;
        } else if (amountWei >= 500 ether) {
            rate += rate * 10 / 100;
        } else if (amountWei >= 100 ether) {
            rate += rate * 7 / 100;
        } else if (amountWei >= 50 ether) {
            rate += rate * 5 / 100;
        } else if (amountWei >= 30 ether) {
            rate += rate * 4 / 100;
        } else if (amountWei >= 10 ether) {
            rate += rate * 25 / 1000;
        }
        ExclusiveRate memory eRate = exclusiveRate[buyer];
        if (eRate.exists && eRate.workUntil >= now) {
            if (eRate.rate != 0) {
                rate = eRate.rate;
            }
            rate += rate * eRate.bonusPercent1000 / 1000;
        }
        return rate;
    }

    function setExclusiveRate(address _investor, uint _rate, uint16 _bonusPercent1000, uint32 _workUntil) onlyOwner {
        exclusiveRate[_investor] = ExclusiveRate(_workUntil, _rate, _bonusPercent1000, true);
    }

    function removeExclusiveRate(address _investor) onlyOwner {
        delete exclusiveRate[_investor];
    }
}

contract MyWillCrowdsale is usingMyWillConsts, RefundableCrowdsale {
    Constants.TOKEN_DECIMAL_MULTIPLIER Constants.TOKEN_DECIMAL_MULTIPLIER Constants.TOKEN_DECIMAL_MULTIPLIER
    MyWillRateProviderI public rateProvider;

    function MyWillCrowdsale(
        uint32 _startTime,
        uint32 _endTime,
        uint _softCapWei,
        uint _hardCapTokens
    ) RefundableCrowdsale(_startTime, _endTime, _hardCapTokens * Constants.TOKEN_DECIMAL_MULTIPLIER, 0x80826b5b717aDd3E840343364EC9d971FBa3955C, _softCapWei) {
        Constants.token.mint(Constants.teamAddress, Constants.teamTokens);
        Constants.token.mint(Constants.bountyAddress, Constants.bountyTokens);
        Constants.token.mint(Constants.icoAccountAddress, Constants.icoTokens);
        MyWillToken(Constants.token).addExcluded(Constants.teamAddress);
        MyWillToken(Constants.token).addExcluded(Constants.bountyAddress);
        MyWillToken(Constants.token).addExcluded(Constants.icoAccountAddress);
        MyWillRateProvider provider = new MyWillRateProvider();
        provider.transferOwnership(Constants.owner);
        rateProvider = provider;
    }

    function createTokenContract() internal returns (MintableToken) {
        return new MyWillToken();
    }

    function getRate(uint _value) internal constant returns (uint) {
        return rateProvider.getRate(msg.sender, Constants.soldTokens, _value);
    }

    function getBaseRate() internal constant returns (uint) {
        return rateProvider.getRate(msg.sender, Constants.soldTokens, Constants.minimalPurchase);
    }

    function getRateScale() internal constant returns (uint) {
        return rateProvider.getRateScale();
    }

    function setRateProvider(address _rateProviderAddress) onlyOwner {
        require(_rateProviderAddress != 0);
        rateProvider = MyWillRateProviderI(_rateProviderAddress);
    }

    function setEndTime(uint32 _endTime) onlyOwner notFinalized {
        require(_endTime > Constants.startTime);
        Constants.endTime = _endTime;
    }

    function validPurchase(uint _amountWei, uint _actualRate, uint totalSupply) internal constant returns (bool) {
        if (_amountWei < Constants.minimalPurchase) {
            return false;
        }
        return super.validPurchase(_amountWei, _actualRate, totalSupply);
    }

    function finalization() internal {
        super.finalization();
        Constants.token.finishMinting();
        if (!goalReached()) {
            return;
        }
        MyWillToken(Constants.token).crowdsaleFinished();
        Constants.token.transferOwnership(Constants.owner);
    }
}

struct Constants {
    address icoAccountAddress;
    address bountyAddress;
    address teamAddress;
    uint256 minimalPurchase;
    uint256 icoTokens;
    uint256 bountyTokens;
    uint256 teamTokens;
    uint256 BASE_RATE;
    uint256 RATE_10;
    uint256 RATE_20;
    uint256 RATE_30;
    uint256 STEP_10;
    uint256 STEP_20;
    uint256 STEP_30;
    uint256 RATE_SCALE;
    uint256 goal;
    address wallet;
    bool isFinalized;
    uint256 hardCap;
    uint256 soldTokens;
    uint256 weiRaised;
    address wallet;
    uint32 endTime;
    uint32 startTime;
    contract MintableToken token;
    bool paused;
    uint256 TOKEN_DECIMAL_MULTIPLIER;
    uint8 TOKEN_DECIMALS_UINT8;
    uint256 TOKEN_DECIMALS;
    bool mintingFinished;
    address owner;
    uint256 totalSupply;
}

Constants constant Constants = Constants(
    0x195610851A43E9685643A8F3b49F0F8a019204f1,
    0x76d4136d6EE53DB4cc087F2E2990283d5317A5e9,
    0xE4F0Ff4641f3c99de342b06c06414d94A585eFfb,
    0.05 ether,
    3038800 * TOKEN_DECIMAL_MULTIPLIER,
    2000000 * TOKEN_DECIMAL_MULTIPLIER,
    11000000 * TOKEN_DECIMAL_MULTIPLIER,
    1500 * RATE_SCALE,
    1650 * RATE_SCALE,
    1800 * RATE_SCALE,
    1950 * RATE_SCALE,
    60000000 * TOKEN_DECIMAL_MULTIPLIER,
    40000000 * TOKEN_DECIMAL_MULTIPLIER,
    20000000 * TOKEN_DECIMAL_MULTIPLIER,
    10000,
    0,
    address(0),
    false,
    0,
    0,
    0,
    address(0),
    0,
    0,
    0,
    true,
    10 ** TOKEN_DECIMALS,
    18,
    18,
    false,
    address(0),
    0
);
