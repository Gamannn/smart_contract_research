```solidity
pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
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

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract BaseLBSCSale {
    using SafeMath for uint256;
    
    mapping(address => uint256) public balanceOf;
    
    event GoalReached(address beneficiary, uint amountRaised);
    event CapReached(address beneficiary, uint amountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    event Pause();
    event Unpause();
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    struct SaleData {
        bool transferEnabled;
        address adminAddr;
        uint256 adminAllowance;
        uint256 ADMIN_ALLOWANCE;
        uint256 INITIAL_SUPPLY;
        uint8 decimals;
        string symbol;
        string name;
        uint256 totalSupply_;
        address owner;
        address manager;
        bool rentrancy_lock;
        uint256 rate;
        uint256 refundAmount;
        uint256 amountRaised;
        uint256 endTime;
        uint256 startTime;
        bool saleClosed;
        bool fundingCapReached;
        bool fundingGoalReached;
        uint256 minContribution;
        uint256 fundingCap;
        uint256 fundingGoal;
        address beneficiary;
        bool paused;
    }
    
    SaleData public saleData;
    
    modifier onlyOwner() {
        require(msg.sender == saleData.owner, "Only the owner is allowed to call this.");
        _;
    }
    
    modifier onlyOwnerOrManager() {
        require(msg.sender == saleData.owner || msg.sender == saleData.manager, "Only owner or manager is allowed to call this");
        _;
    }
    
    modifier beforeDeadline() {
        require(currentTime() < saleData.endTime, "Validation: Before endtime");
        _;
    }
    
    modifier afterDeadline() {
        require(currentTime() >= saleData.endTime, "Validation: After endtime");
        _;
    }
    
    modifier afterStartTime() {
        require(currentTime() >= saleData.startTime, "Validation: After starttime");
        _;
    }
    
    modifier saleNotClosed() {
        require(!saleData.saleClosed, "Sale is not yet ended");
        _;
    }
    
    modifier nonReentrant() {
        require(!saleData.rentrancy_lock, "Validation: Reentrancy");
        saleData.rentrancy_lock = true;
        _;
        saleData.rentrancy_lock = false;
    }
    
    modifier whenNotPaused() {
        require(!saleData.paused, "You are not allowed to access this time.");
        _;
    }
    
    modifier whenPaused() {
        require(saleData.paused, "You are not allowed to access this time.");
        _;
    }
    
    constructor() public {
        saleData.owner = msg.sender;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Owner cannot be 0 address.");
        emit OwnershipTransferred(saleData.owner, newOwner);
        saleData.owner = newOwner;
    }
    
    function pause() public onlyOwnerOrManager whenNotPaused {
        saleData.paused = true;
        emit Pause();
    }
    
    function unpause() public onlyOwnerOrManager whenPaused {
        saleData.paused = false;
        emit Unpause();
    }
    
    function currentTime() public view returns (uint) {
        return block.timestamp;
    }
    
    function terminate() external onlyOwnerOrManager {
        saleData.saleClosed = true;
    }
    
    function setRate(uint rate) public onlyOwnerOrManager {
        saleData.rate = rate;
    }
    
    function ownerUnlockFund() external afterDeadline onlyOwner {
        saleData.fundingGoalReached = false;
    }
    
    function checkFundingGoal() internal {
        if (!saleData.fundingGoalReached) {
            if (saleData.amountRaised >= saleData.fundingGoal) {
                saleData.fundingGoalReached = true;
                emit GoalReached(saleData.beneficiary, saleData.amountRaised);
            }
        }
    }
    
    function checkFundingCap() internal {
        if (!saleData.fundingCapReached) {
            if (saleData.amountRaised >= saleData.fundingCap) {
                saleData.fundingCapReached = true;
                saleData.saleClosed = true;
                emit CapReached(saleData.beneficiary, saleData.amountRaised);
            }
        }
    }
    
    function changeStartTime(uint256 startTime) external onlyOwnerOrManager {
        saleData.startTime = startTime;
    }
    
    function changeEndTime(uint256 endTime) external onlyOwnerOrManager {
        saleData.endTime = endTime;
    }
    
    function changeMinContribution(uint256 newValue) external onlyOwnerOrManager {
        saleData.minContribution = newValue * (10 ** saleData.decimals);
    }
}

contract BaseLBSCToken {
    using SafeMath for uint256;
    
    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed burner, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Mint(address indexed to, uint256 amount);
    
    address public owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner is allowed to call this.");
        _;
    }
    
    constructor() public {
        owner = msg.sender;
    }
    
    function totalSupply() public view returns (uint256) {
        return BaseLBSCSale(this).saleData().totalSupply_;
    }
    
    function transfer(address to, uint256 value) public returns (bool) {
        require(value <= balances[msg.sender], "You do not have sufficient balance.");
        require(to != address(0), "You cannot send tokens to 0 address");
        
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(value <= balances[from], "You do not have sufficient balance.");
        require(value <= allowed[from][msg.sender], "You do not have allowance.");
        require(to != address(0), "You cannot send tokens to 0 address");
        
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
        if (subtractedValue >= oldValue) {
            allowed[msg.sender][spender] = 0;
        } else {
            allowed[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
    
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }
    
    function _burn(address who, uint256 value) internal {
        require(value <= balances[who], "Insufficient balance of tokens");
        balances[who] = balances[who].sub(value);
        BaseLBSCSale(this).saleData().totalSupply_ = BaseLBSCSale(this).saleData().totalSupply_.sub(value);
        emit Burn(who, value);
        emit Transfer(who, address(0), value);
    }
    
    function burnFrom(address from, uint256 value) public {
        require(value <= allowed[from][msg.sender], "Insufficient allowance to burn tokens.");
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        _burn(from, value);
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Owner cannot be 0 address.");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract LBSCToken is BaseLBSCToken {
    modifier validDestination(address to) {
        require(to != address(0x0), "Cannot send to 0 address");
        require(to != address(this), "Cannot send to contract address");
        _;
    }
    
    constructor(address admin) public {
        require(msg.sender != admin, "Owner and admin cannot be the same");
        
        BaseLBSCSale(this).saleData().totalSupply_ = BaseLBSCSale(this).saleData().INITIAL_SUPPLY;
        BaseLBSCSale(this).saleData().adminAllowance = BaseLBSCSale(this).saleData().ADMIN_ALLOWANCE;
        
        balances[admin] = BaseLBSCSale(this).saleData().adminAllowance;
        emit Transfer(address(0x0), admin, BaseLBSCSale(this).saleData().adminAllowance);
        
        BaseLBSCSale(this).saleData().adminAddr = admin;
        approve(BaseLBSCSale(this).saleData().adminAddr, BaseLBSCSale(this).saleData().adminAllowance);
    }
    
    function transfer(address to, uint256 value) public validDestination(to) returns (bool) {
        return super.transfer(to, value);
    }
    
    function transferFrom(address from, address to, uint256 value) public validDestination(to) returns (bool) {
        bool result = super.transferFrom(from, to, value);
        if (result) {
            if (msg.sender == BaseLBSCSale(this).saleData().adminAddr) {
                BaseLBSCSale(this).saleData().adminAllowance = BaseLBSCSale(this).saleData().adminAllowance.sub(value);
            }
        }
        return result;
    }
}

contract LBSCSale is BaseLBSCSale {
    using SafeMath for uint256;
    
    LBSCToken public tokenReward;
    mapping(address => bool) public approvedUsers;
    
    constructor(
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint fundingCapInEthers,
        uint minimumContribution,
        uint start,
        uint end,
        uint rateLBSCToEther,
        address addressOfTokenUsedAsReward,
        address manager
    ) public {
        require(ifSuccessfulSendTo != address(0) && ifSuccessfulSendTo != address(this), "Beneficiary cannot be 0 address");
        require(addressOfTokenUsedAsReward != address(0) && addressOfTokenUsedAsReward != address(this), "Token address cannot be 0 address");
        require(fundingGoalInEthers <= fundingCapInEthers, "Funding goal should be less that funding cap.");
        require(end > 0, "Endtime cannot be 0");
        
        saleData.beneficiary = ifSuccessfulSendTo;
        saleData.fundingGoal = fundingGoalInEthers;
        saleData.fundingCap = fundingCapInEthers;
        saleData.minContribution = minimumContribution;
        saleData.startTime = start;
        saleData.endTime = end;
        saleData.rate = rateLBSCToEther;
        tokenReward = LBSCToken(addressOfTokenUsedAsReward);
        saleData.manager = manager;
        saleData.decimals = tokenReward.decimals();
    }
    
    function () public payable whenNotPaused beforeDeadline afterStartTime saleNotClosed nonReentrant {
        require(msg.value >= saleData.minContribution, "Value should be greater than minimum contribution");
        require(isApprovedUser(msg.sender), "Only the approved users are allowed to participate in ICO");
        
        uint amount = msg.value;
        uint currentBalance = balanceOf[msg.sender];
        balanceOf[msg.sender] = currentBalance.add(amount);
        saleData.amountRaised = saleData.amountRaised.add(amount);
        
        uint numTokens = amount.mul(saleData.rate);
        
        if (tokenReward.transferFrom(tokenReward.owner(), msg.sender, numTokens)) {
            emit FundTransfer(msg.sender, amount, true);
            checkFundingGoal();
            checkFundingCap();
        } else {
            revert("Transaction Failed. Please try again later.");
        }
    }
    
    function ownerAllocateTokens(address to, uint amountInEth, uint amountLBSC) public onlyOwnerOrManager nonReentrant {
        if (!tokenReward.transferFrom(tokenReward.owner(), to, convertToMini(amountLBSC))) {
            revert("Transfer failed. Please check allowance");
        }
        
        uint amountWei = convertToMini(amountInEth);
        balanceOf[to] = balanceOf[to].add(amountWei);
        saleData.amountRaised = saleData.amountRaised.add(amountWei);
        
        emit FundTransfer(to, amountWei, true);
        checkFundingGoal();
        checkFundingCap();
    }
    
    function ownerSafeWithdrawal() public onlyOwner nonReentrant {
        require(saleData.fundingGoalReached, "Check funding goal");
        uint balanceToSend = address(this).balance;
        saleData.beneficiary.transfer(balanceToSend);
        emit FundTransfer(saleData.beneficiary, balanceToSend, false);
    }
    
    function safeWithdrawal() public afterDeadline nonReentrant {
        if (!saleData.fundingGoalReached) {
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                msg.sender.transfer(amount);
                emit FundTransfer(msg.sender, amount, false);
                saleData.refundAmount = saleData.refundAmount.add(amount);
            }
        }
    }
    
    function convertToMini(uint amount) internal view returns (uint) {
        return amount * (10 ** saleData.decimals);
    }
    
    function approveUser(address user) external onlyOwnerOrManager {
        approvedUsers[user] = true;
    }
    
    function disapproveUser(address user) external onlyOwnerOrManager {
        approvedUsers[user] = false;
    }
    
    function changeManager(address manager) external onlyOwnerOrManager {
        saleData.manager = manager;
    }
    
    function isApprovedUser(address user) internal view returns (bool) {
        return approvedUsers[user];
    }
    
    function changeTokenAddress(address tokenAddress) external onlyOwnerOrManager {
        tokenReward = LBSCToken(tokenAddress);
    }
}
```