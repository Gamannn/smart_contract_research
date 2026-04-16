```solidity
pragma solidity ^0.4.16;

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        return a / b;
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
    mapping(address => mapping(address => uint256)) allowed;

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
    address public owner;

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

    bool public mintingFinished = false;

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

contract MyWillToken is MintableToken {
    string public name = "MyWill Coin";
    string public symbol = "WIL";
    uint8 public decimals = 18;

    bool public paused = true;
    mapping(address => bool) public excluded;

    function crowdsaleFinished() onlyOwner {
        paused = false;
    }

    function addExcluded(address _toExclude) onlyOwner {
        excluded[_toExclude] = true;
    }

    function transfer(address _to, uint256 _value) returns (bool) {
        require(!paused || excluded[msg.sender]);
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        require(!paused || excluded[_from]);
        return super.transferFrom(_from, _to, _value);
    }
}

contract Crowdsale {
    using SafeMath for uint;

    MintableToken public token;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public hardCap;
    address public wallet;
    uint256 public weiRaised;
    uint256 public soldTokens;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    function Crowdsale(uint32 _startTime, uint32 _endTime, uint _hardCap, address _wallet) {
        require(_startTime >= now);
        require(_endTime >= _startTime);
        require(_wallet != 0x0);
        require(_hardCap > 0);

        token = createTokenContract();
        startTime = _startTime;
        endTime = _endTime;
        hardCap = _hardCap;
        wallet = _wallet;
    }

    function createTokenContract() internal returns (MintableToken) {
        return new MintableToken();
    }

    function getRate(uint256 amount) internal constant returns (uint256);
    function getBaseRate() internal constant returns (uint256);
    function getRateScale() internal constant returns (uint256) {
        return 1;
    }

    function () payable {
        buyTokens(msg.sender, msg.value);
    }

    function buyTokens(address beneficiary, uint256 amountWei) internal {
        require(beneficiary != 0x0);

        uint256 totalSupply = token.totalSupply();
        uint256 actualRate = getRate(amountWei);
        uint256 rateScale = getRateScale();

        require(validPurchase(amountWei, actualRate, totalSupply));

        uint256 tokens = amountWei.mul(actualRate).div(rateScale);
        uint256 change = 0;

        if (tokens.add(totalSupply) > hardCap) {
            uint256 maxTokens = hardCap.sub(totalSupply);
            uint256 realAmount = maxTokens.mul(rateScale).div(actualRate);
            tokens = realAmount.mul(actualRate).div(rateScale);
            change = amountWei.sub(realAmount);
            amountWei = realAmount;
        }

        weiRaised = weiRaised.add(amountWei);
        soldTokens = soldTokens.add(tokens);

        token.mint(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, amountWei, tokens);

        if (change != 0) {
            msg.sender.transfer(change);
        }

        forwardFunds(amountWei);
    }

    function forwardFunds(uint256 amountWei) internal {
        wallet.transfer(amountWei);
    }

    function validPurchase(uint256 _amountWei, uint256 _actualRate, uint256 totalSupply) internal constant returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = _amountWei != 0;
        bool hardCapNotReached = totalSupply <= hardCap.sub(_actualRate);
        return withinPeriod && nonZeroPurchase && hardCapNotReached;
    }

    function hasEnded() public constant returns (bool) {
        return now > endTime || token.totalSupply() > hardCap.sub(getBaseRate());
    }

    function hasStarted() public constant returns (bool) {
        return now >= startTime;
    }

    function hasEnded(uint256 _value) public constant returns (bool) {
        uint256 actualRate = getRate(_value);
        return now > endTime || token.totalSupply() > hardCap.sub(actualRate);
    }
}

contract FinalizableCrowdsale is Crowdsale, Ownable {
    using SafeMath for uint256;

    bool public isFinalized = false;

    event Finalized();

    function FinalizableCrowdsale(uint32 _startTime, uint32 _endTime, uint _hardCap, address _wallet)
        Crowdsale(_startTime, _endTime, _hardCap, _wallet) {
    }

    function finalize() onlyOwner notFinalized {
        require(hasEnded());
        finalization();
        Finalized();
        isFinalized = true;
    }

    function finalization() internal {
    }

    modifier notFinalized() {
        require(!isFinalized);
        _;
    }
}

contract RefundVault is Ownable {
    using SafeMath for uint256;

    enum State { Active, Refunding, Closed }

    mapping(address => uint256) public deposited;
    State public state;
    address public wallet;

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

    uint256 public goal;
    RefundVault public vault;

    function RefundableCrowdsale(uint32 _startTime, uint32 _endTime, uint _hardCap, address _wallet, uint _goal)
        FinalizableCrowdsale(_startTime, _endTime, _hardCap, _wallet) {
        require(_goal > 0);
        vault = new RefundVault(wallet);
        goal = _goal;
    }

    function forwardFunds(uint256 amountWei) internal {
        if (goalReached()) {
            wallet.transfer(amountWei);
        } else {
            vault.deposit.value(amountWei)(msg.sender);
        }
    }

    function claimRefund() public {
        require(isFinalized);
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
        return weiRaised >= goal;
    }
}

contract MyWillRateProviderI {
    function getRate(address buyer, uint totalSold, uint amountWei) public constant returns (uint);
    function getRateScale() public constant returns (uint);
    function getBaseRate() public constant returns (uint);
}

contract MyWillRateProvider is MyWillRateProviderI, Ownable {
    using SafeMath for uint256;

    struct ExclusiveRate {
        uint32 workUntil;
        uint rate;
        uint16 bonusPercent1000;
        bool exists;
    }

    mapping(address => ExclusiveRate) exclusiveRate;

    function getRateScale() public constant returns (uint) {
        return 10000;
    }

    function getBaseRate() public constant returns (uint) {
        return 1500;
    }

    function getRate(address buyer, uint totalSold, uint amountWei) public constant returns (uint) {
        uint rate;
        if (totalSold < 20000000 * 10 ** 18) {
            rate = 1950;
        } else if (totalSold < 40000000 * 10 ** 18) {
            rate = 1800;
        } else if (totalSold < 60000000 * 10 ** 18) {
            rate = 1650;
        } else {
            rate = 1500;
        }

        if (amountWei >= 1000 ether) {
            rate += rate.mul(13).div(100);
        } else if (amountWei >= 500 ether) {
            rate += rate.mul(10).div(100);
        } else if (amountWei >= 100 ether) {
            rate += rate.mul(7).div(100);
        } else if (amountWei >= 50 ether) {
            rate += rate.mul(5).div(100);
        } else if (amountWei >= 30 ether) {
            rate += rate.mul(4).div(100);
        } else if (amountWei >= 10 ether) {
            rate += rate.mul(25).div(1000);
        }

        ExclusiveRate memory eRate = exclusiveRate[buyer];
        if (eRate.exists && eRate.workUntil >= now) {
            if (eRate.rate != 0) {
                rate = eRate.rate;
            }
            rate += rate.mul(eRate.bonusPercent1000).div(1000);
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

contract MyWillCrowdsale is RefundableCrowdsale {
    using SafeMath for uint256;

    MyWillRateProviderI public rateProvider;

    function MyWillCrowdsale(
        uint32 _startTime,
        uint32 _endTime,
        uint _softCapWei,
        uint _hardCapTokens
    )
        RefundableCrowdsale(_startTime, _endTime, _hardCapTokens * 10 ** 18, 0x80826b5b717aDd3E840343364EC9d971FBa3955C, _softCapWei)
    {
        token.mint(0xE4F0Ff4641f3c99de342b06c06414d94A585eFfb, 11000000 * 10 ** 18);
        token.mint(0x76d4136d6EE53DB4cc087F2E2990283d5317A5e9, 2000000 * 10 ** 18);
        token.mint(0x195610851A43E9685643A8F3b49F0F8a019204f1, 3038800 * 10 ** 18);

        MyWillToken(token).addExcluded(0xE4F0Ff4641f3c99de342b06c06414d94A585eFfb);
        MyWillToken(token).addExcluded(0x76d4136d6EE53DB4cc087F2E2990283d5317A5e9);
        MyWillToken(token).addExcluded(0x195610851A43E9685643A8F3b49F0F8a019204f1);

        MyWillRateProvider provider = new MyWillRateProvider();
        provider.transferOwnership(owner);
        rateProvider = provider;
    }

    function createTokenContract() internal returns (MintableToken) {
        return new MyWillToken();
    }

    function getRate(uint256 _value) internal constant returns (uint256) {
        return rateProvider.getRate(msg.sender, soldTokens, _value);
    }

    function getBaseRate() internal constant returns (uint256) {
        return rateProvider.getRate(msg.sender, soldTokens, 0.05 ether);
    }

    function getRateScale() internal constant returns (uint256) {
        return rateProvider.getRateScale();
    }

    function setRateProvider(address _rateProviderAddress) onlyOwner {
        require(_rateProviderAddress != 0);
        rateProvider = MyWillRateProviderI(_rateProviderAddress);
    }

    function setEndTime(uint32 _endTime) onlyOwner notFinalized {
        require(_endTime > startTime);
        endTime = _endTime;
    }

    function validPurchase(uint256 _amountWei, uint256 _actualRate, uint256 totalSupply) internal constant returns (bool) {
        if (_amountWei < 0.05 ether) {
            return false;
        }
        return super.validPurchase(_amountWei, _actualRate, totalSupply);
    }

    function finalization() internal {
        super.finalization();
        token.finishMinting();
        if (!goalReached()) {
            return;
        }
        MyWillToken(token).crowdsaleFinished();
        token.transferOwnership(owner);
    }
}
```