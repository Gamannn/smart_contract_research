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

    struct SaleState {
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

    SaleState public saleState;

    mapping(address => uint256) public balanceOf;

    event GoalReached(address beneficiary, uint amountRaised);
    event CapReached(address beneficiary, uint amountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    event Pause();
    event Unpause();
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == saleState.owner, "Only the owner is allowed to call this.");
        _;
    }

    modifier onlyOwnerOrManager {
        require(msg.sender == saleState.owner || msg.sender == saleState.manager, "Only owner or manager is allowed to call this");
        _;
    }

    modifier beforeDeadline() {
        require(currentTime() < saleState.endTime, "Validation: Before endtime");
        _;
    }

    modifier afterDeadline() {
        require(currentTime() >= saleState.endTime, "Validation: After endtime");
        _;
    }

    modifier afterStartTime() {
        require(currentTime() >= saleState.startTime, "Validation: After starttime");
        _;
    }

    modifier saleNotClosed() {
        require(!saleState.saleClosed, "Sale is not yet ended");
        _;
    }

    modifier nonReentrant() {
        require(!saleState.rentrancy_lock, "Validation: Reentrancy");
        saleState.rentrancy_lock = true;
        _;
        saleState.rentrancy_lock = false;
    }

    modifier whenNotPaused() {
        require(!saleState.paused, "You are not allowed to access this time.");
        _;
    }

    modifier whenPaused() {
        require(saleState.paused, "You are not allowed to access this time.");
        _;
    }

    constructor() public {
        saleState.owner = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Owner cannot be 0 address.");
        emit OwnershipTransferred(saleState.owner, newOwner);
        saleState.owner = newOwner;
    }

    function pause() public onlyOwnerOrManager whenNotPaused {
        saleState.paused = true;
        emit Pause();
    }

    function unpause() public onlyOwnerOrManager whenPaused {
        saleState.paused = false;
        emit Unpause();
    }

    function currentTime() public view returns (uint currentTime) {
        return block.timestamp;
    }

    function terminate() external onlyOwnerOrManager {
        saleState.saleClosed = true;
    }

    function setRate(uint rate) public onlyOwnerOrManager {
        saleState.rate = rate;
    }

    function ownerUnlockFund() external afterDeadline onlyOwner {
        saleState.fundingGoalReached = false;
    }

    function checkFundingGoal() internal {
        if (!saleState.fundingGoalReached) {
            if (saleState.amountRaised >= saleState.fundingGoal) {
                saleState.fundingGoalReached = true;
                emit GoalReached(saleState.beneficiary, saleState.amountRaised);
            }
        }
    }

    function checkFundingCap() internal {
        if (!saleState.fundingCapReached) {
            if (saleState.amountRaised >= saleState.fundingCap) {
                saleState.fundingCapReached = true;
                saleState.saleClosed = true;
                emit CapReached(saleState.beneficiary, saleState.amountRaised);
            }
        }
    }

    function changeStartTime(uint256 startTime) external onlyOwnerOrManager {
        saleState.startTime = startTime;
    }

    function changeEndTime(uint256 endTime) external onlyOwnerOrManager {
        saleState.endTime = endTime;
    }

    function changeMinContribution(uint256 newValue) external onlyOwnerOrManager {
        saleState.minContribution = newValue * (10 ** saleState.decimals);
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
        return saleState.totalSupply_;
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
        saleState.totalSupply_ = saleState.totalSupply_.sub(value);
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

        saleState.totalSupply_ = saleState.INITIAL_SUPPLY;
        saleState.adminAllowance = saleState.ADMIN_ALLOWANCE;
        balances[admin] = saleState.adminAllowance;
        emit Transfer(address(0x0), admin, saleState.adminAllowance);
        saleState.adminAddr = admin;
        approve(saleState.adminAddr, saleState.adminAllowance);
    }

    function transfer(address to, uint256 value) public validDestination(to) returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public validDestination(to) returns (bool) {
        bool result = super.transferFrom(from, to, value);
        if (result) {
            if (msg.sender == saleState.adminAddr) {
                saleState.adminAllowance = saleState.adminAllowance.sub(value);
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
        require(fundingGoalInEthers <= fundingCapInEthers, "Funding goal should be less than funding cap.");
        require(end > 0, "Endtime cannot be 0");

        saleState.beneficiary = ifSuccessfulSendTo;
        saleState.fundingGoal = fundingGoalInEthers;
        saleState.fundingCap = fundingCapInEthers;
        saleState.minContribution = minimumContribution;
        saleState.startTime = start;
        saleState.endTime = end;
        saleState.rate = rateLBSCToEther;
        tokenReward = LBSCToken(addressOfTokenUsedAsReward);
        saleState.manager = manager;
        saleState.decimals = tokenReward.decimals();
    }

    function() public payable whenNotPaused beforeDeadline afterStartTime saleNotClosed nonReentrant {
        require(msg.value >= saleState.minContribution, "Value should be greater than minimum contribution");
        require(isApprovedUser(msg.sender), "Only the approved users are allowed to participate in ICO");

        uint amount = msg.value;
        uint currentBalance = balanceOf[msg.sender];
        balanceOf[msg.sender] = currentBalance.add(amount);
        saleState.amountRaised = saleState.amountRaised.add(amount);

        uint numTokens = amount.mul(saleState.rate);
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
        saleState.amountRaised = saleState.amountRaised.add(amountWei);
        emit FundTransfer(to, amountWei, true);
        checkFundingGoal();
        checkFundingCap();
    }

    function ownerSafeWithdrawal() public onlyOwner nonReentrant {
        require(saleState.fundingGoalReached, "Check funding goal");

        uint balanceToSend = address(this).balance;
        saleState.beneficiary.transfer(balanceToSend);
        emit FundTransfer(saleState.beneficiary, balanceToSend, false);
    }

    function safeWithdrawal() public afterDeadline nonReentrant {
        if (!saleState.fundingGoalReached) {
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                msg.sender.transfer(amount);
                emit FundTransfer(msg.sender, amount, false);
                saleState.refundAmount = saleState.refundAmount.add(amount);
            }
        }
    }

    function convertToMini(uint amount) internal view returns (uint) {
        return amount * (10 ** saleState.decimals);
    }

    function approveUser(address user) external onlyOwnerOrManager {
        approvedUsers[user] = true;
    }

    function disapproveUser(address user) external onlyOwnerOrManager {
        approvedUsers[user] = false;
    }

    function changeManager(address manager) external onlyOwnerOrManager {
        saleState.manager = manager;
    }

    function isApprovedUser(address user) internal view returns (bool) {
        return approvedUsers[user];
    }

    function changeTokenAddress(address tokenAddress) external onlyOwnerOrManager {
        tokenReward = LBSCToken(tokenAddress);
    }
}
```