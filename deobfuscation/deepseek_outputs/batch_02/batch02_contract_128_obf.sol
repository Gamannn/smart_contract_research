```solidity
pragma solidity ^0.4.18;

contract MigrationTarget {
    function migrate(address from, uint256 balance, uint256 quarters, uint256 totalQuarters, bool isDeveloper) public;
}

contract Ownable {
    address public owner;
    
    event OwnershipChanged(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function Ownable() public {
        owner = msg.sender;
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipChanged(owner, newOwner);
        owner = newOwner;
    }
}

contract ERC20Basic {
    uint256 public totalSupply;
    
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function allowance(address owner, address spender) view public returns (uint256);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    
    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(balances[msg.sender] >= value);
        require(balances[to] + value > balances[to]);
        
        uint256 previousBalances = balances[msg.sender] + balances[to];
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        
        emit Transfer(msg.sender, to, value);
        assert(balances[msg.sender] + balances[to] == previousBalances);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(value <= allowed[from][msg.sender]);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        return transferInternal(from, to, value);
    }
    
    function balanceOf(address owner) view public returns (uint256) {
        return balances[owner];
    }
    
    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function allowance(address owner, address spender) view public returns (uint256) {
        return allowed[owner][spender];
    }
    
    function transferInternal(address from, address to, uint256 value) internal returns (bool) {
        require(to != address(0));
        require(balances[from] >= value);
        require(balances[to] + value > balances[to]);
        
        uint256 previousBalances = balances[from] + balances[to];
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        
        emit Transfer(from, to, value);
        assert(balances[from] + balances[to] == previousBalances);
        return true;
    }
    
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;
}

contract DividendToken is BasicToken {
    using SafeMath for uint256;
    
    mapping(address => bool) public restrictedAccounts;
    
    event RestrictedStatusChanged(address indexed account, bool restricted);
    
    struct Account {
        uint256 balance;
        uint256 lastDividendPoint;
    }
    
    mapping(address => Account) public accounts;
    uint256 public totalDividendPoints;
    uint256 public unclaimedDividends;
    
    function updateAccount(address account) internal {
        uint256 owing = dividendsOwing(account);
        accounts[account].lastDividendPoint = totalDividendPoints;
        
        if (owing > 0) {
            unclaimedDividends = unclaimedDividends.sub(owing);
            accounts[account].balance = accounts[account].balance.add(owing);
        }
    }
    
    function disburse() public payable {
        require(msg.value > 0);
        uint256 amount = msg.value;
        totalDividendPoints = totalDividendPoints.add(amount);
        unclaimedDividends = unclaimedDividends.add(amount);
    }
    
    function transfer(address to, uint256 value) public returns (bool) {
        require(restrictedAccounts[msg.sender] == false);
        updateAccount(to);
        updateAccount(msg.sender);
        return super.transfer(to, value);
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        updateAccount(to);
        updateAccount(from);
        return super.transferFrom(from, to, value);
    }
    
    function withdrawDividends() public {
        updateAccount(msg.sender);
        uint256 amount = accounts[msg.sender].balance;
        require(amount > 0);
        accounts[msg.sender].balance = 0;
        msg.sender.transfer(amount);
    }
    
    function dividendsOwing(address account) internal view returns (uint256) {
        uint256 newDividendPoints = totalDividendPoints.sub(accounts[account].lastDividendPoint);
        return balances[account].mul(newDividendPoints).div(totalSupply);
    }
}

contract Crowdsale is Ownable, DividendToken {
    using SafeMath for uint256;
    
    string public name = "Crowdsale";
    string public symbol = "CS";
    uint8 public decimals = 18;
    
    bool public whitelistEnabled = true;
    mapping(address => bool) public whitelistedAccounts;
    
    struct Stage {
        uint8 stageNumber;
        uint256 exchangeRate;
        uint256 startBlock;
        uint256 endBlock;
        uint256 cap;
    }
    
    mapping(uint8 => Stage) public stages;
    uint8 public currentStage;
    
    address public ethWallet;
    uint256 public reservedFunds;
    uint256 public hardCap;
    
    event MintTokens(address indexed to, uint256 amount);
    event StageStarted(uint8 stage, uint256 totalSupply, uint256 balance);
    event StageEnded(uint8 stage, uint256 totalSupply, uint256 balance);
    event WhitelistStatusChanged(address indexed account, bool whitelisted);
    event WhitelistChanged(bool enabled);
    
    function Crowdsale(address wallet) public {
        ethWallet = wallet;
        reservedFunds = 0;
        hardCap = 15000000 * (10 ** uint256(decimals));
    }
    
    function mintTokens(address to, uint256 value) internal {
        require(value > 0);
        balances[to] = balances[to].add(value);
        totalSupply = totalSupply.add(value);
        require(totalSupply <= hardCap);
        emit MintTokens(to, value);
    }
    
    function() public payable {
        buyTokens();
    }
    
    function buyTokens() public payable {
        require(whitelistEnabled == false || whitelistedAccounts[msg.sender] == true);
        require(msg.value > 0);
        
        Stage memory stage = stages[currentStage];
        require(block.number >= stage.startBlock && block.number <= stage.endBlock);
        
        uint256 tokens = msg.value.mul(stage.exchangeRate);
        require(totalSupply.add(tokens) <= stage.cap);
        
        mintTokens(msg.sender, tokens);
        ethWallet.transfer(msg.value);
    }
    
    function addStage(
        uint256 exchangeRate,
        uint256 cap,
        uint256 startBlock,
        uint256 endBlock
    ) public onlyOwner {
        require(exchangeRate > 0 && cap > 0);
        require(startBlock > block.number);
        require(startBlock < endBlock);
        
        Stage memory previousStage = stages[currentStage];
        if (previousStage.endBlock > 0) {
            emit StageEnded(currentStage, totalSupply, address(this).balance);
        }
        
        currentStage = currentStage + 1;
        Stage memory newStage = Stage({
            stageNumber: currentStage,
            exchangeRate: exchangeRate,
            startBlock: startBlock,
            endBlock: endBlock,
            cap: cap
        });
        
        stages[currentStage] = newStage;
        emit StageStarted(currentStage, totalSupply, address(this).balance);
    }
    
    function withdrawFunds() public onlyOwner {
        ethWallet.transfer(address(this).balance);
    }
    
    function getCurrentStage() view public returns (
        uint8 stageNumber,
        uint256 exchangeRate,
        uint256 startBlock,
        uint256 endBlock,
        uint256 cap
    ) {
        Stage memory stage = stages[currentStage];
        stageNumber = stage.stageNumber;
        exchangeRate = stage.exchangeRate;
        startBlock = stage.startBlock;
        endBlock = stage.endBlock;
        cap = stage.cap;
    }
    
    function setWhitelistStatus(address account, bool whitelisted) public onlyOwner {
        whitelistedAccounts[account] = whitelisted;
        emit WhitelistStatusChanged(account, whitelisted);
    }
    
    function setRestrictedStatus(address account, bool restricted) public onlyOwner {
        restrictedAccounts[account] = restricted;
        emit RestrictedStatusChanged(account, restricted);
    }
    
    function setWhitelistEnabled(bool enabled) public onlyOwner {
        whitelistEnabled = enabled;
        emit WhitelistChanged(enabled);
    }
}

interface TokenRecipient {
    function receiveApproval(address from, uint256 value, address token, bytes extraData) external;
}

contract Quarters is Ownable, BasicToken {
    string public name = "Quarters";
    string public symbol = "Q";
    uint256 public outstandingQuarters;
    
    mapping(address => uint256) public totalQuarters;
    
    event EthRateChanged(uint16 oldRate, uint16 newRate);
    event Burn(address indexed burner, uint256 value);
    event QuartersOrdered(address indexed buyer, uint256 ethAmount, uint256 quarterAmount);
    event DeveloperStatusChanged(address indexed developer, bool isDeveloper);
    event TrancheIncreased(uint256 tranche, uint256 outstandingQuarters, uint256 totalSupply);
    event MegaEarnings(address indexed developer, uint256 quarters, uint256 ethAmount, uint256 tranche, uint256 outstandingQuarters, uint256 totalSupply);
    event Withdraw(address indexed developer, uint256 quarters, uint256 ethAmount, uint256 tranche, uint256 outstandingQuarters, uint256 totalSupply);
    event BaseRateChanged(uint256 ethAmount, uint256 tranche, uint256 outstandingQuarters, uint256 contractBalance, uint256 totalSupply);
    event Reward(address indexed developer, uint256 quarters, uint256 outstandingQuarters, uint256 totalSupply);
    
    modifier onlyActiveDeveloper() {
        require(developers[msg.sender] == true);
        _;
    }
    
    uint16 public ethRate = 4000;
    uint256 public tranche = 10000000;
    address public ethWallet;
    uint256 public reserveETH = 0;
    
    uint32 public microRate = 50;
    uint32 public megaRate = 50000;
    uint32 public smallRate = 75;
    uint32 public mediumRate = 2000;
    uint32 public largeRate = 90;
    uint32 public rewardRate = 100;
    uint32 public baseRate = 115;
    
    uint8 public trancheNumerator = 1;
    uint8 public trancheDenominator = 10;
    
    mapping(address => bool) public developers;
    mapping(address => uint256) public rewards;
    
    function Quarters(address wallet, uint256 initialTranche) public {
        ethWallet = wallet;
        tranche = initialTranche;
    }
    
    function setEthRate(uint16 newRate) onlyOwner public {
        require(newRate > 0);
        emit EthRateChanged(ethRate, newRate);
        ethRate = newRate;
    }
    
    function setReserveETH(uint256 amount) onlyOwner public {
        reserveETH = amount;
    }
    
    function setRates(
        uint32 micro,
        uint32 mega,
        uint32 small,
        uint32 medium,
        uint32 large,
        uint32 reward,
        uint32 base,
        uint32 microRate2
    ) onlyOwner public {
        if (micro > 0 && mega > 0) {
            microRate = micro;
            megaRate = mega;
        }
        
        if (small > 0 && medium > 0) {
            smallRate = small;
            mediumRate = medium;
        }
        
        if (large > 0 && reward > 0) {
            largeRate = large;
            rewardRate = reward;
        }
        
        if (base > 0) {
            baseRate = base;
        }
        
        if (microRate2 > 0) {
            microRate = microRate2;
        }
    }
    
    function setTrancheRatio(uint8 numerator, uint8 denominator) onlyOwner public {
        require(numerator > 0 && denominator > 0);
        trancheNumerator = numerator;
        trancheDenominator = denominator;
    }
    
    function setTranche(uint256 newTranche) onlyOwner public {
        require(newTranche > 0);
        tranche = newTranche;
    }
    
    function rewardDeveloper(address developer) internal {
        require(developer != address(0));
        uint256 reward = 0;
        
        if (rewards[developer] == 0) {
            reward = totalSupply;
        } else if (rewardRate > 0) {
            reward = totalQuarters[developer].mul(baseRate).div(rewardRate);
        }
        
        if (reward > 0) {
            rewards[developer] = tranche;
            balances[developer] = balances[developer].add(reward);
            allowed[developer][msg.sender] = allowed[developer][msg.sender].add(reward);
            totalSupply = totalSupply.add(reward);
            outstandingQuarters = outstandingQuarters.add(reward);
            
            uint256 ethAmount = (reward.mul(10 ** 18)).div(ethRate);
            if (reserveETH >= ethAmount) {
                reserveETH = reserveETH.sub(ethAmount);
            } else {
                reserveETH = 0;
            }
            
            updateTranche();
            emit Approval(developer, msg.sender, reward);
            emit Reward(developer, reward, outstandingQuarters, totalSupply);
        }
    }
    
    function setDeveloperStatus(address developer, bool isDeveloper) onlyOwner public {
        developers[developer] = isDeveloper;
        emit DeveloperStatusChanged(developer, isDeveloper);
    }
    
    function approveAndCall(address spender, uint256 value, bytes extraData) public returns (bool) {
        TokenRecipient recipient = TokenRecipient(spender);
        if (approve(spender, value)) {
            recipient.receiveApproval(msg.sender, value, this, extraData);
            return true;
        }
        return false;
    }
    
    function burn(uint256 value) public returns (bool) {
        require(balances[msg.sender] >= value);
        balances[msg.sender] = balances[msg.sender].sub(value);
        totalSupply = totalSupply.sub(value);
        outstandingQuarters = outstandingQuarters.sub(value);
        emit Burn(msg.sender, value);
        emit BaseRateChanged(getContractBalance(), tranche, outstandingQuarters, address(this).balance, totalSupply);
        return true;
    }
    
    function burnFrom(address from, uint256 value) public returns (bool) {
        require(balances[from] >= value);
        require(value <= allowed[from][msg.sender]);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        balances[from] = balances[from].sub(value);
        totalSupply = totalSupply.sub(value);
        outstandingQuarters = outstandingQuarters.sub(value);
        emit Burn(from, value);
        emit BaseRateChanged(getContractBalance(), tranche, outstandingQuarters, address(this).balance, totalSupply);
        return true;
    }
    
    function() payable public {
        buyQuarters(msg.sender);
    }
    
    function buyQuartersFor(address beneficiary) payable public {
        uint256 value = buyQuarters(beneficiary);
        allowed[beneficiary][msg.sender] = allowed[beneficiary][msg.sender].add(value);
        emit Approval(beneficiary, msg.sender, value);
    }
    
    function updateTranche() internal {
        if (totalSupply >= tranche) {
            tranche = tranche.mul(trancheNumerator).div(trancheDenominator);
            emit TrancheIncreased(tranche, outstandingQuarters, totalSupply);
        }
    }
    
    function buyQuarters(address beneficiary) internal returns (uint256) {
        require(beneficiary != address(0));
        uint256 quarters = (msg.value.mul(ethRate)).div(10 ** 18);
        require(quarters > 0);
        
        if (quarters > tranche) {
            quarters = tranche;
        }
        
        totalSupply = totalSupply.add(quarters);
        balances[beneficiary] = balances[beneficiary].add(quarters);
        totalQuarters[beneficiary] = totalQuarters[beneficiary].add(quarters);
        outstandingQuarters = outstandingQuarters.add(quarters);
        
        updateTranche();
        emit QuartersOrdered(beneficiary, msg.value, quarters);
        emit BaseRateChanged(getContractBalance(), tranche, outstandingQuarters, address(this).balance, totalSupply);
        
        ethWallet.transfer(msg.value.mul(15).div(100));
        return quarters;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        rewardDeveloper(from);
        require(value <= allowed[from][msg.sender]);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        
        if (transferInternal(from, to, value