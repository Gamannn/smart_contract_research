```solidity
pragma solidity ^0.4.21;

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

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

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    
    mapping(address => uint256) balances;
    
    function totalSupply() public view returns (uint256) {
        return tokenData.totalSupply;
    }
    
    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }
}

contract BurnableToken is BasicToken {
    event Burn(address indexed burner, uint256 value);
    
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }
    
    function _burn(address who, uint256 value) internal {
        require(value <= balances[who]);
        balances[who] = balances[who].sub(value);
        tokenData.totalSupply = tokenData.totalSupply.sub(value);
        emit Burn(who, value);
        emit Transfer(who, address(0), value);
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
    
    function increaseApproval(address spender, uint addedValue) public returns (bool) {
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
    
    function decreaseApproval(address spender, uint subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][spender];
        if (subtractedValue > oldValue) {
            allowed[msg.sender][spender] = 0;
        } else {
            allowed[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
}

contract StandardBurnableToken is BurnableToken, StandardToken {
    function burnFrom(address from, uint256 value) public {
        require(value <= allowed[from][msg.sender]);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        _burn(from, value);
    }
}

contract CQSToken is StandardBurnableToken {
    struct TokenData {
        bool icoStart;
        address adminAddr;
        address crowdSaleAddr;
        uint256 adminAllowance;
        uint256 crowdSaleAllowance;
        uint256 ADMIN_ALLOWANCE;
        uint256 CROWDSALE_ALLOWANCE;
        uint256 INITIAL_SUPPLY;
        string website;
        address owner;
        uint8 decimals;
        string symbol;
        string name;
        uint256 totalSupply;
    }
    
    TokenData public tokenData;
    
    mapping(address => uint256) public tokensTransferred;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier validDestination(address to) {
        require(to != address(0x0));
        require(to != address(this));
        require(to != tokenData.owner);
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == tokenData.owner);
        _;
    }
    
    constructor(address _admin) public {
        require(msg.sender != _admin);
        tokenData.owner = msg.sender;
        tokenData.totalSupply = tokenData.INITIAL_SUPPLY;
        tokenData.crowdSaleAllowance = tokenData.CROWDSALE_ALLOWANCE;
        tokenData.adminAllowance = tokenData.ADMIN_ALLOWANCE;
        
        balances[msg.sender] = tokenData.totalSupply.sub(tokenData.adminAllowance);
        emit Transfer(address(0x0), msg.sender, tokenData.totalSupply.sub(tokenData.adminAllowance));
        
        balances[_admin] = tokenData.adminAllowance;
        emit Transfer(address(0x0), _admin, tokenData.adminAllowance);
        
        tokenData.adminAddr = _admin;
        approve(tokenData.adminAddr, tokenData.adminAllowance);
    }
    
    function startICO() external onlyOwner {
        tokenData.icoStart = true;
    }
    
    function stopICO() external onlyOwner {
        tokenData.icoStart = false;
    }
    
    function setCrowdsale(address _crowdSaleAddr, uint256 _amountForSale) external onlyOwner {
        require(_amountForSale <= tokenData.crowdSaleAllowance);
        uint amount = (_amountForSale == 0) ? tokenData.crowdSaleAllowance : _amountForSale;
        approve(tokenData.crowdSaleAddr, 0);
        approve(_crowdSaleAddr, amount);
        tokenData.crowdSaleAddr = _crowdSaleAddr;
    }
    
    function transfer(address to, uint256 value) public validDestination(to) returns (bool) {
        if(tokenData.icoStart && (msg.sender != tokenData.owner || msg.sender != tokenData.adminAddr)) {
            require((tokensTransferred[msg.sender].add(value)).mul(2) <= balances[msg.sender].add(tokensTransferred[msg.sender]));
            tokensTransferred[msg.sender] = tokensTransferred[msg.sender].add(value);
            return super.transfer(to, value);
        } else {
            return super.transfer(to, value);
        }
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(tokenData.owner, newOwner);
        tokenData.owner = newOwner;
    }
    
    function burn(uint256 value) public {
        require(msg.sender == tokenData.owner || msg.sender == tokenData.adminAddr);
        _burn(msg.sender, value);
    }
    
    function burnFromAdmin(uint256 value) external onlyOwner {
        _burn(tokenData.adminAddr, value);
    }
    
    function changeWebsite(string _website) external onlyOwner {
        tokenData.website = _website;
    }
}

contract CQSSale {
    using SafeMath for uint256;
    
    CQSToken public tokenReward;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public contributions;
    
    event GoalReached(address _beneficiary, uint _amountRaised);
    event CapReached(address _beneficiary, uint _amountRaised);
    event FundTransfer(address _backer, uint _amount, bool _isContribution);
    event Pause();
    event Unpause();
    
    struct SaleData {
        bool paused;
        bool rentrancy_lock;
        uint256 HIGH_RANGE_RATE;
        uint256 LOW_RANGE_RATE;
        uint256 rate;
        uint256 refundAmount;
        uint256 amountRaised;
        address owner;
        uint256 endTime;
        uint256 startTime;
        bool saleClosed;
        bool fundingCapReached;
        bool fundingGoalReached;
        uint256 minContribution;
        uint256 fundingCap;
        uint256 fundingGoal;
        address beneficiary;
    }
    
    SaleData public saleData;
    
    address public owner;
    
    modifier beforeDeadline() {
        require(currentTime() < saleData.endTime);
        _;
    }
    
    modifier afterDeadline() {
        require(currentTime() >= saleData.endTime);
        _;
    }
    
    modifier afterStartTime() {
        require(currentTime() >= saleData.startTime);
        _;
    }
    
    modifier saleNotClosed() {
        require(!saleData.saleClosed);
        _;
    }
    
    modifier nonReentrant() {
        require(!saleData.rentrancy_lock);
        saleData.rentrancy_lock = true;
        _;
        saleData.rentrancy_lock = false;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier whenNotPaused() {
        require(!saleData.paused);
        _;
    }
    
    modifier whenPaused() {
        require(saleData.paused);
        _;
    }
    
    function pause() onlyOwner whenNotPaused public {
        saleData.paused = true;
        tokenReward.stopICO();
        emit Pause();
    }
    
    function unpause() onlyOwner whenPaused public {
        saleData.paused = false;
        tokenReward.startICO();
        emit Unpause();
    }
    
    constructor(
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint fundingCapInEthers,
        uint minimumContributionInWei,
        uint start,
        uint end,
        uint rateCQSToEther,
        address addressOfTokenUsedAsReward
    ) public {
        require(ifSuccessfulSendTo != address(0) && ifSuccessfulSendTo != address(this));
        require(addressOfTokenUsedAsReward != address(0) && addressOfTokenUsedAsReward != address(this));
        require(fundingGoalInEthers <= fundingCapInEthers);
        require(end > 0);
        
        saleData.beneficiary = ifSuccessfulSendTo;
        saleData.fundingGoal = fundingGoalInEthers * 1 ether;
        saleData.fundingCap = fundingCapInEthers * 1 ether;
        saleData.minContribution = minimumContributionInWei;
        saleData.startTime = start;
        saleData.endTime = end;
        saleData.rate = rateCQSToEther;
        
        tokenReward = CQSToken(addressOfTokenUsedAsReward);
        owner = msg.sender;
    }
    
    function () external payable whenNotPaused beforeDeadline afterStartTime saleNotClosed nonReentrant {
        require(msg.value >= saleData.minContribution);
        uint amount = msg.value;
        uint currentBalance = balanceOf[msg.sender];
        balanceOf[msg.sender] = currentBalance.add(amount);
        saleData.amountRaised = saleData.amountRaised.add(amount);
        
        uint numTokens = amount.mul(saleData.rate);
        if (tokenReward.transferFrom(tokenReward.owner(), msg.sender, numTokens)) {
            emit FundTransfer(msg.sender, amount, true);
            contributions[msg.sender] = contributions[msg.sender].add(amount);
            checkFundingGoal();
            checkFundingCap();
        } else {
            revert();
        }
    }
    
    function terminate() external onlyOwner {
        saleData.saleClosed = true;
        tokenReward.stopICO();
    }
    
    function setRate(uint _rate) external onlyOwner {
        require(_rate >= saleData.LOW_RANGE_RATE && _rate <= saleData.HIGH_RANGE_RATE);
        saleData.rate = _rate;
    }
    
    function ownerAllocateTokens(address to, uint amountWei, uint amountMiniCQS) external onlyOwner nonReentrant {
        if (!tokenReward.transferFrom(tokenReward.owner(), to, amountMiniCQS)) {
            revert();
        }
        balanceOf[to] = balanceOf[to].add(amountWei);
        saleData.amountRaised = saleData.amountRaised.add(amountWei);
        emit FundTransfer(to, amountWei, true);
        checkFundingGoal();
        checkFundingCap();
    }
    
    function ownerSafeWithdrawal() external onlyOwner nonReentrant {
        require(saleData.fundingGoalReached);
        uint balanceToSend = address(this).balance;
        saleData.beneficiary.transfer(balanceToSend);
        emit FundTransfer(saleData.beneficiary, balanceToSend, false);
    }
    
    function ownerUnlockFund() external afterDeadline onlyOwner {
        saleData.fundingGoalReached = false;
    }
    
    function safeWithdrawal() external afterDeadline nonReentrant {
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
    
    function currentTime() public view returns (uint _currentTime) {
        return block.timestamp;
    }
    
    function convertToMiniCQS(uint amount) internal view returns (uint) {
        return amount * (10 ** uint(tokenReward.decimals()));
    }
    
    function changeStartTime(uint256 _startTime) external onlyOwner {
        saleData.startTime = _startTime;
    }
    
    function changeEndTime(uint256 _endTime) external onlyOwner {
        saleData.endTime = _endTime;
    }
}
```