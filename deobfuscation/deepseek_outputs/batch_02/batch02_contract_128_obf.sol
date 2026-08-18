pragma solidity ^0.4.18;

contract MigrationContract {
    function migrate(address _owner, uint256 _balance, uint256 _reward, uint256 _quarters, bool _developer) public;
}

contract Ownable {
    address public owner;
    
    event OwnershipChanged(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function Ownable() public {
        owner = msg.sender;
    }
    
    /**
     * @dev Allows the current owner to transfer control of the contract to a new owner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipChanged(owner, newOwner);
        owner = newOwner;
    }
}

contract Token {
    uint256 public totalSupply;
    
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) view public returns (uint256 remaining);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
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

contract StandardToken is Token {
    function _transfer(address _from, address _to, uint _value) internal returns (bool success) {
        require(_to != address(0));
        require(balances[_from] >= _value);
        require(balances[_to] + _value > balances[_to]);
        
        uint256 previousBalances = balances[_from] + balances[_to];
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balances[_from] + balances[_to] == previousBalances);
        return true;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        return _transfer(msg.sender, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowed[_from][msg.sender]);
        allowed[_from][msg.sender] -= _value;
        return _transfer(_from, _to, _value);
    }
    
    function balanceOf(address _owner) view public returns (uint256 balance) {
        return balances[_owner];
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
}

contract BurnableToken is StandardToken {
    using SafeMath for uint256;
    
    mapping(address => bool) public restricted;
    
    event RestrictedStatusChanged(address indexed account, bool status);
    
    struct Account {
        uint256 balance;
        uint256 lastUpdate;
    }
    
    mapping(address => Account) public accounts;
    
    uint256 public totalRoyalty;
    uint256 public unclaimedRoyalty;
    
    function _updateAccount(address account) internal {
        accounts[account].lastUpdate = totalRoyalty;
        
        if (unclaimedRoyalty > 0) {
            unclaimedRoyalty = unclaimedRoyalty.sub(unclaimedRoyalty);
            accounts[account].balance = accounts[account].balance.add(unclaimedRoyalty);
        }
    }
    
    function disburse() public payable {
        require(msg.value > 0);
        uint256 amount = msg.value;
        totalRoyalty = totalRoyalty.add(amount);
        unclaimedRoyalty = unclaimedRoyalty;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(restricted[msg.sender] == false);
        _updateAccount(_to);
        _updateAccount(msg.sender);
        return super.transfer(_to, _value);
    }
    
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        _updateAccount(_to);
        _updateAccount(_from);
        return super.transferFrom(_from, _to, _value);
    }
    
    function withdrawRoyalty() public {
        _updateAccount(msg.sender);
        uint256 amount = accounts[msg.sender].balance;
        require(amount > 0);
        accounts[msg.sender].balance = 0;
        msg.sender.transfer(amount);
    }
}

contract Crowdsale is Ownable, BurnableToken {
    using SafeMath for uint256;
    
    string public name = "Crowdsale";
    string public symbol = "C";
    uint8 public decimals = 18;
    
    bool public saleActive = true;
    
    uint256 public cap;
    uint256 public raised;
    
    event MintTokens(address indexed _to, uint256 _amount);
    event StageStarted(uint8 stage, uint256 _totalSupply);
    event StageEnded(uint8 stage, uint256 _totalSupply, uint256 _raised);
    event WhitelistStatusChanged(address indexed account, bool status);
    event WhitelistChanged(bool status);
    
    address public ethWallet;
    
    mapping (uint8 => Stage) public stages;
    uint8 public currentStage;
    
    struct Stage {
        uint256 startBlock;
        uint256 endBlock;
        uint256 rate;
        uint256 cap;
    }
    
    function Crowdsale(address _ethWallet) public {
        ethWallet = _ethWallet;
        _mint(ethWallet, 10000000);
    }
    
    function _mint(address account, uint256 amount) internal {
        require(amount > 0);
        balances[account] = balances[account].add(amount);
        totalSupply = totalSupply.add(amount);
        require(totalSupply <= 15000000);
        emit MintTokens(account, amount);
    }
    
    function () public payable {
        buyTokens();
    }
    
    function buyTokens() public payable {
        require(saleActive == false || whitelisted[msg.sender] == true);
        require(msg.value > 0);
        
        Stage memory stage = stages[currentStage];
        require(block.number >= stage.startBlock && block.number <= stage.endBlock);
        
        uint256 tokens = msg.value * stage.rate;
        require(totalSupply.add(tokens) <= stage.cap);
        
        _mint(msg.sender, tokens);
    }
    
    function setStage(
        uint256 _rate,
        uint256 _cap,
        uint256 _startBlock,
        uint256 _endBlock
    ) public onlyOwner {
        require(_rate > 0 && _cap > 0);
        require(_startBlock > block.number);
        require(_startBlock < _endBlock);
        
        Stage memory oldStage = stages[currentStage];
        
        if (oldStage.endBlock > 0) {
            emit StageEnded(currentStage, totalSupply, raised);
        }
        
        currentStage++;
        
        Stage memory newStage = Stage({
            startBlock: _startBlock,
            endBlock: _endBlock,
            rate: _rate,
            cap: _cap
        });
        
        stages[currentStage] = newStage;
        emit StageStarted(currentStage, address(this).balance);
    }
    
    function withdrawFunds() public onlyOwner {
        ethWallet.transfer(address(this).balance);
    }
    
    function getStageInfo() view public returns (
        uint8 startBlock,
        uint256 rate,
        uint256 endBlock,
        uint256 cap,
        uint256 totalSupply
    ) {
        Stage memory stage = stages[currentStage];
        startBlock = stage.startBlock;
        rate = stage.rate;
        endBlock = stage.endBlock;
        cap = stage.cap;
        totalSupply = stage.cap;
    }
    
    function setWhitelistStatus(address account, bool status) public onlyOwner {
        whitelisted[account] = status;
        emit WhitelistStatusChanged(account, status);
    }
    
    function setRestrictedStatus(address account, bool status) public onlyOwner {
        restricted[account] = status;
        emit RestrictedStatusChanged(account, status);
    }
    
    function setSaleActive(bool status) public onlyOwner {
        saleActive = status;
        emit WhitelistChanged(status);
    }
}

interface TokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}

contract QuarterToken is Ownable, StandardToken {
    string public name = "Quarter Token";
    string public symbol = "Q";
    uint256 public totalBurned;
    
    mapping (address => uint256) public outstandingQuarters;
    
    event EthRateChanged(uint16 ethRate, uint16 rewardRate);
    event Burn(address indexed burner, uint256 value);
    event QuartersOrdered(address indexed buyer, uint256 ethAmount, uint256 quarterAmount);
    event DeveloperStatusChanged(address indexed developer, bool status);
    event TrancheIncreased(uint256 oldRate, uint256 newRate, uint256 totalSupply);
    event MegaEarnings(address indexed developer, uint256 amount, uint256 rate, uint256 totalSupply, uint256 totalBurned, uint256 outstanding);
    event Withdraw(address indexed developer, uint256 amount, uint256 rate, uint256 totalSupply, uint256 totalBurned, uint256 outstanding);
    event BaseRateChanged(uint256 rate, uint256 rewardRate, uint256 totalBurned, uint256 balance, uint256 totalSupply);
    event Reward(address indexed account, uint256 amount, uint256 totalBurned, uint256 totalSupply);
    
    modifier onlyActiveDeveloper() {
        require(developers[msg.sender] == true);
        _;
    }
    
    function QuarterToken(
        address _migrationTarget,
        uint256 _initialSupply
    ) {
        migrationTarget = _migrationTarget;
        rewardRate = _initialSupply;
    }
    
    function setEthRate(uint16 _ethRate) onlyOwner public {
        require(_ethRate > 0);
        ethRate = _ethRate;
        emit EthRateChanged(ethRate, rewardRate);
    }
    
    function setRewardRate(uint256 _rewardRate) onlyOwner public {
        rewardRate = _rewardRate;
    }
    
    function setTranches(
        uint32 _microRate,
        uint32 _microDenominator,
        uint32 _smallRate,
        uint32 _smallDenominator,
        uint32 _mediumRate,
        uint32 _mediumDenominator,
        uint32 _largeRate,
        uint32 _largeDenominator,
        uint32 _megaRate,
        uint32 _megaDenominator
    ) onlyOwner {
        microRate = _microRate;
        microDenominator = _microDenominator;
        
        if (smallRate > 0 && _smallDenominator > 0) {
            smallRate = _smallRate;
            smallDenominator = _smallDenominator;
        }
        
        if (_mediumRate > 0 && _mediumDenominator > 0) {
            mediumRate = _mediumRate;
            mediumDenominator = _mediumDenominator;
        }
        
        if (_largeRate > 0 && _largeDenominator > 0) {
            largeRate = _largeRate;
            largeDenominator = _largeDenominator;
        }
        
        if (_megaRate > 0 && _megaDenominator > 0) {
            megaRate = _megaRate;
            megaDenominator = _megaDenominator;
        }
    }
    
    function setTrancheNumerator(uint8 _trancheNumerator) onlyOwner public {
        require(_trancheNumerator > 0 && _trancheDenominator > 0);
        trancheNumerator = _trancheNumerator;
        trancheDenominator = _trancheDenominator;
    }
    
    function setRewardAmount(uint256 _rewardAmount) onlyOwner public {
        require(_rewardAmount > 0);
        rewardAmount = _rewardAmount;
    }
    
    function _updateDeveloper(address _developer) internal {
        require(_developer != address(0));
        
        uint256 reward = 0;
        
        if (outstandingQuarters[_developer] == 0) {
            reward = totalSupply;
        } else if (outstandingQuarters[_developer] > 0) {
            reward = outstandingQuarters[_developer] * rewardRate / rewardDenominator;
        }
        
        if (reserveETH > 0) {
            developers[_developer] = true;
            balances[_developer] += reward;
            allowed[_developer][msg.sender] += reward;
            totalSupply += reward;
            outstandingQuarters[_developer] = totalSupply;
            
            uint256 amount = (reward * (10 ** 18)) / ethRate;
            
            if (reserveETH >= amount) {
                reserveETH -= amount;
            } else {
                reserveETH = 0;
            }
            
            _updateTranche();
            emit Approval(_developer, msg.sender, reward);
            emit Reward(_developer, reward, totalBurned, totalSupply);
        }
    }
    
    function setDeveloperStatus(address _developer, bool _status) onlyOwner public {
        developers[_developer] = _status;
        emit DeveloperStatusChanged(_developer, _status);
    }
    
    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        TokenRecipient spender = TokenRecipient(_spender);
        
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, _extraData);
            return true;
        }
        return false;
    }
    
    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        totalSupply -= _value;
        totalBurned -= _value;
        emit Burn(msg.sender, _value);
        emit BaseRateChanged(getBaseRate(), rewardRate, totalBurned, address(this).balance, totalSupply);
        return true;
    }
    
    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);
        require(_value <= allowed[_from][msg.sender]);
        allowed[_from][msg.sender] -= _value;
        totalSupply -= _value;
        totalBurned -= _value;
        emit Burn(_from, _value);
        emit BaseRateChanged(getBaseRate(), rewardRate, totalBurned, address(this).balance, totalSupply);
        return true;
    }
    
    /**
     * Buy quarters by sending ethers to contract address (no data)
     */
    function () payable public {
        buyQuarters(msg.sender);
    }
    
    function buyQuarters(address _buyer) payable public {
        uint256 _value = _buyQuarters(_buyer);
        allowed[_buyer][msg.sender] += _value;
        emit Approval(_buyer, msg.sender, _value);
    }
    
    function _updateTranche() internal {
        if (totalSupply >= rewardRate) {
            ethRate = ethRate * trancheNumerator / trancheDenominator;
            emit TrancheIncreased(address(this).balance, totalBurned);
        }
    }
    
    function _buyQuarters(address _buyer) internal returns (uint256) {
        require(_buyer != address(0));
        
        uint256 amount = (msg.value * ethRate) / 10 ** 18;
        
        if (amount > trancheLimit) {
            amount = trancheLimit;
        }
        
        totalSupply += amount;
        balances[_buyer] += amount;
        outstandingQuarters[_buyer] += amount;
        totalBurned += amount;
        
        _updateTranche();
        emit QuartersOrdered(_buyer, msg.value, amount);
        emit BaseRateChanged(getBaseRate(), rewardRate, totalBurned, address(this).balance, totalSupply);
        
        Crowdsale(migrationTarget).buyTokens.value(msg.value * 15 / 100)();
        
        return amount;
    }
    
    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        _updateDeveloper(_from);
        require(_value <= allowed[_from][msg.sender]);
        allowed[_from][msg.sender] -= _value;
        
        if (_transfer(_from, _to, _value)) {
            allowed[_to][msg.sender] += _value;
            emit Approval(_to, msg.sender, _value);
            return true;
        }
        return false;
    }
    
    function withdraw(uint256 _amount) onlyActiveDeveloper public {
        require(balances[msg.sender] >= _amount);
        
        uint256 rate = getBaseRate();
        require(rate > 0);
        
        uint256 amount = _amount * rate;
        uint256 bonus = _getBonus(_amount);
        uint256 totalAmount = totalBurned * amount / 100;
        
        if (totalAmount > address(this).balance) {
            totalAmount = address(this).balance;
        } else {
            totalAmount = totalAmount;
        }
        
        balances[msg.sender] -= _amount;
        totalBurned -= _amount;
        
        if (ethRate == megaRate) {
            emit MegaEarnings(msg.sender, amount, rate, outstandingQuarters[msg.sender], totalBurned);
        }
        
        emit Withdraw(msg.sender, amount, rate, outstandingQuarters[msg.sender], totalBurned);
        emit BaseRateChanged(getBaseRate(), rewardRate, totalBurned, address(this).balance, totalSupply);
        
        msg.sender.transfer(amount);
    }
    
    function deposit() public payable {
        reserveETH += msg.value;
    }
    
    function getBaseRate() view public returns (uint256) {
        if (totalBurned > 0) {
            return (address(this).balance - reserveETH) / outstandingQuarters[msg.sender];
        }
        return (address(this).balance - reserveETH);
    }
    
    function _getBonus(uint256 _amount) view public returns (uint32) {
        if (_amount * microRate > rewardRate) {
            return microDenominator;
        } else if (_amount * smallRate > rewardRate) {
            return smallDenominator;
        } else if (_amount * mediumRate > rewardRate) {
            return mediumDenominator;
        } else if (_amount * largeRate > rewardRate) {
            return largeDenominator;
        }
        return megaDenominator;
    }
    
    bool public migrationEnabled = false;
    
    event Migrate(address indexed _from, uint256 _value);
    
    function migrate() public {
        require(migrationTarget != address(0));
        
        uint256 balance = balances[msg.sender];
        require(balance > 0);
        
        balances[msg.sender] = 0;
        totalSupply = totalSupply - balance;
        totalBurned = totalBurned - balance;
        outstandingQuarters[msg.sender] = 0;
        developers[msg.sender] = false;
        
        emit Migrate(msg.sender, balance);
        
        MigrationContract(migrationTarget).migrate(
            msg.sender,
            balance,
            outstandingQuarters[msg.sender],
            outstandingQuarters[msg.sender],
            developers[msg.sender]
        );
    }
    
    function setMigrationTarget(address _target) onlyOwner public {
        migrationTarget = _target;
    }
}

function getBoolFunc(uint256 index) internal view returns(bool) {
    return _bool_constant[index];
}

function getIntFunc(uint256 index) internal view returns(uint256) {
    return _integer_constant[index];
}

function getStrFunc(uint256 index) internal view returns(string storage) {
    return _string_constant[index];
}

bool[] public _bool_constant = [true, false];
uint256[] public _integer_constant = [10, 2000, 4, 25, 75, 40, 15000000, 18, 0, 10000000, 50, 50000, 2, 4000, 15, 115, 40000, 90, 1, 20];
string[] public _string_constant = ["Quarter Token", "Q", "Crowdsale"];
