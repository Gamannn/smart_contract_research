```solidity
pragma solidity ^0.5.0;

contract IERC20 {
    function transfer(address to, uint256 amount) public returns (bool);
    function approve(address spender, uint256 amount) public returns (bool);
    function transferFrom(address from, address to, uint256 amount) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function balanceOf(address account) public view returns (uint256);
    function totalSupply() public view returns (uint256);
}

contract IAugurUniverse {
    function createYesNoMarket(
        uint256 endTime,
        uint256 feeInWei,
        address designatedReporter,
        address extraInfo,
        bytes32 topic,
        string memory description,
        string memory info
    ) public payable;
}

contract AccessControl {
    mapping(address => uint256) public accessLevel;
    
    event AccessLevelSet(address indexed user, uint256 level, address indexed setter);
    event AccessRevoked(address indexed user, uint256 previousLevel, address indexed revoker);
    
    constructor() public {
        accessLevel[msg.sender] = 4;
    }
    
    modifier requireAccessLevel(uint256 level) {
        require(accessLevel[msg.sender] >= level, "Insufficient access level");
        _;
    }
    
    modifier requireExactAccessLevel(uint256 level) {
        require(accessLevel[msg.sender] == level, "Exact access level required");
        _;
    }
    
    function setAccessLevel(address user, uint256 level) public requireExactAccessLevel(4) {
        require(accessLevel[user] < 4, "Cannot modify admin access");
        require(level >= 0 && level <= 4, "Invalid access level");
        
        accessLevel[user] = level;
        emit AccessLevelSet(user, level, msg.sender);
    }
    
    function revokeAccess(address user) public requireExactAccessLevel(4) {
        require(accessLevel[user] < 4, "Cannot revoke admin access");
        
        uint256 previousLevel = accessLevel[user];
        accessLevel[user] = 0;
        emit AccessRevoked(user, previousLevel, msg.sender);
    }
    
    function getAccessLevel(address user) public view returns (uint256) {
        return accessLevel[user];
    }
    
    function getMyAccessLevel() public view returns (uint256) {
        return accessLevel[msg.sender];
    }
}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address account) public view returns (uint256);
    function transfer(address to, uint256 amount) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
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
        return a / b;
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
    
    mapping(address => uint256) balances;
    uint256 totalSupply_;
    
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {
    mapping(address => mapping(address => uint256)) internal allowed;
    
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balances[from]);
        require(value <= allowed[from][msg.sender]);
        
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }
    
    function increaseApproval(address spender, uint256 addedValue) public returns (bool) {
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
    
    function decreaseApproval(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 oldValue = allowed[msg.sender][spender];
        if (subtractedValue > oldValue) {
            allowed[msg.sender][spender] = 0;
        } else {
            allowed[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
}

contract TestTokenERC20 is StandardToken {
    string public constant name = "TestTokenERC20";
    string public constant symbol = "T20";
    uint8 public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 10000 * (10 ** uint256(decimals));
    
    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
    }
}

contract StakingContract {
    using SafeMath for uint256;
    
    struct Stake {
        uint256 unlockTime;
        uint256 amount;
        address staker;
    }
    
    struct StakeContract {
        uint256 totalStaked;
        uint256 currentStakeIndex;
        Stake[] stakes;
        bool isActive;
    }
    
    event Staked(address indexed staker, uint256 amount, uint256 unlockTime, bytes data);
    event Unstaked(address indexed staker, uint256 amount, uint256 unlockTime, bytes data);
    
    mapping(address => StakeContract) public stakes;
    TestTokenERC20 public stakingToken;
    address public stakingTokenAddress;
    
    constructor() public {}
    
    modifier requireStake(address staker, uint256 amount) {
        require(
            stakingToken.transferFrom(staker, address(this), amount),
            "Stake required"
        );
        _;
    }
    
    function setStakingToken(address tokenAddress) public {
        stakingTokenAddress = tokenAddress;
        stakingToken = TestTokenERC20(stakingTokenAddress);
    }
    
    function stake(uint256 amount) public returns (bool) {
        _stake(msg.sender, amount);
        return true;
    }
    
    function _stake(address staker, uint256 amount) internal requireStake(msg.sender, amount) {
        if (!stakes[msg.sender].isActive) {
            stakes[msg.sender].isActive = true;
        }
        
        stakes[staker].totalStaked = stakes[staker].totalStaked.add(amount);
        stakes[msg.sender].stakes.push(
            Stake(
                block.timestamp.add(2000),
                amount,
                staker
            )
        );
    }
    
    function _unstake(uint256 amount) internal {
        Stake storage currentStake = stakes[msg.sender].stakes[stakes[msg.sender].currentStakeIndex];
        
        require(
            currentStake.unlockTime <= block.timestamp,
            "Stake hasn't unlocked yet"
        );
        require(
            currentStake.amount == amount,
            "Unstake amount doesn't match current stake"
        );
        require(
            stakingToken.transfer(msg.sender, amount),
            "Unable to withdraw stake"
        );
        
        stakes[currentStake.staker].totalStaked = stakes[currentStake.staker]
            .totalStaked.sub(currentStake.amount);
        currentStake.amount = 0;
        stakes[msg.sender].currentStakeIndex++;
    }
}

contract TokenManager is AccessControl {
    using SafeMath for uint256;
    
    mapping(address => uint256) public userBalances;
    uint256 public totalTokenBalance;
    uint256 public stakedTokensReceivable;
    uint256 public approvedTokensPayable;
    
    address public tokenAddress;
    address public stakingContractAddress;
    address public augurUniverseAddress;
    
    event UserBalanceChange(address indexed user, uint256 oldBalance, uint256 newBalance);
    event TokenWithdrawal(address indexed user, uint256 amount);
    event TokensStaked(address indexed staker, uint256 amount);
    
    function approve(address spender, uint256 amount) public requireExactAccessLevel(4) returns (bool) {
        return TestTokenERC20(tokenAddress).approve(spender, amount);
    }
    
    function transferFrom(address from, address to, uint256 amount) public requireExactAccessLevel(4) returns (bool) {
        return TestTokenERC20(tokenAddress).transferFrom(from, to, amount);
    }
    
    function transfer(address to, uint256 amount) public requireExactAccessLevel(4) returns (bool) {
        return TestTokenERC20(tokenAddress).transfer(to, amount);
    }
    
    function increaseApproval(address spender, uint256 addedValue) public requireExactAccessLevel(4) returns (bool) {
        return TestTokenERC20(tokenAddress).increaseApproval(spender, addedValue);
    }
    
    function decreaseApproval(address spender, uint256 subtractedValue) public requireExactAccessLevel(4) returns (bool) {
        return TestTokenERC20(tokenAddress).decreaseApproval(spender, subtractedValue);
    }
    
    function stakeTokens(uint256 amount) public returns (bool) {
        require(
            StakingContract(stakingContractAddress).stake(amount),
            "Staking must be successful"
        );
        stakedTokensReceivable = stakedTokensReceivable.add(amount);
        approvedTokensPayable = approvedTokensPayable.add(amount);
        return true;
    }
    
    function approveTokens(address user, uint256 amount) public returns (bool) {
        require(
            TestTokenERC20(tokenAddress).approve(user, amount),
            "Approval must be successful"
        );
        approvedTokensPayable = approvedTokensPayable.add(amount);
        return true;
    }
    
    function receiveEther() public payable {}
    
    function createMarket(
        uint256 endTime,
        uint256 feeInWei,
        address designatedReporter,
        address extraInfo,
        bytes32 topic,
        string memory description,
        string memory info
    ) public payable {
        IAugurUniverse(augurUniverseAddress).createYesNoMarket(
            endTime,
            feeInWei,
            designatedReporter,
            extraInfo,
            topic,
            description,
            info
        );
    }
    
    function setTokenAddress(address newTokenAddress) external {
        tokenAddress = newTokenAddress;
    }
    
    function setStakingContractAddress(address newStakingContractAddress) external {
        stakingContractAddress = newStakingContractAddress;
    }
    
    function setAugurUniverseAddress(address newAugurUniverseAddress) external {
        augurUniverseAddress = address(IAugurUniverse(newAugurUniverseAddress));
    }
    
    function deposit(address user) public {
        uint256 allowance = TestTokenERC20(tokenAddress).allowance(user, address(this));
        uint256 currentBalance = userBalances[user];
        uint256 newBalance = currentBalance.add(allowance);
        
        require(
            TestTokenERC20(tokenAddress).transferFrom(user, address(this), allowance),
            "Transfer failed"
        );
        
        userBalances[user] = newBalance;
        totalTokenBalance = totalTokenBalance.add(allowance);
        
        emit UserBalanceChange(user, currentBalance, newBalance);
    }
    
    function addToUserBalance(address user, uint256 amount) external {
        uint256 currentBalance = userBalances[user];
        uint256 newBalance = currentBalance.add(amount);
        
        userBalances[user] = newBalance;
        totalTokenBalance = totalTokenBalance.add(amount);
        
        emit UserBalanceChange(user, currentBalance, newBalance);
    }
    
    function getContractTokenBalance() public view returns (uint256) {
        return TestTokenERC20(tokenAddress).balanceOf(address(this));
    }
    
    function getTokenStats() public view returns (uint256, uint256, uint256, uint256) {
        return (
            stakedTokensReceivable,
            approvedTokensPayable,
            totalTokenBalance,
            TestTokenERC20(tokenAddress).balanceOf(address(stakingContractAddress))
        );
    }
    
    function withdrawTokens(address user, uint256 amount) public returns (bool) {
        uint256 currentBalance = userBalances[user];
        require(amount <= currentBalance, "Withdraw amount greater than current balance");
        
        uint256 newBalance = currentBalance.sub(amount);
        require(
            TestTokenERC20(tokenAddress).transfer(user, amount),
            "Error during transfer"
        );
        
        userBalances[user] = newBalance;
        totalTokenBalance = totalTokenBalance.sub(amount);
        
        emit TokenWithdrawal(user, amount);
        emit UserBalanceChange(user, currentBalance, newBalance);
        return true;
    }
    
    function depositForSelf() public {
        deposit(msg.sender);
    }
    
    function withdraw(uint256 amount) public {
        withdrawTokens(msg.sender, amount);
        emit TokenWithdrawal(msg.sender, amount);
    }
    
    function getUserTokenBalance(address user) public view returns (uint256) {
        return userBalances[user];
    }
    
    function getTokenAddress() public view returns (address) {
        return tokenAddress;
    }
}
```