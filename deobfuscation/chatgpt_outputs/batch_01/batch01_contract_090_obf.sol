```solidity
pragma solidity ^0.4.21;

contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address tokenOwner) public view returns (uint256);
    function transfer(address to, uint256 tokens) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
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

contract BasicToken is ERC20Interface {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    function totalSupply() public view returns (uint256) {
        return s2c.totalSupply;
    }

    function transfer(address to, uint256 tokens) public returns (bool) {
        require(to != address(0));
        require(tokens <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
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
        s2c.totalSupply = s2c.totalSupply.sub(value);
        emit Burn(who, value);
        emit Transfer(who, address(0), value);
    }
}

contract ERC20 is ERC20Interface {
    function allowance(address tokenOwner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool);
    function approve(address spender, uint256 tokens) public returns (bool);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) internal allowed;

    function transferFrom(address from, address to, uint256 tokens) public returns (bool) {
        require(to != address(0));
        require(tokens <= balances[from]);
        require(tokens <= allowed[from][msg.sender]);

        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function approve(address spender, uint256 tokens) public returns (bool) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint256) {
        return allowed[tokenOwner][spender];
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
    struct TokenDetails {
        bool paused;
        bool rentrancyLock;
        uint256 highRangeRate;
        uint256 lowRangeRate;
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
        bool icoStart;
        address adminAddr;
        address crowdSaleAddr;
        uint256 adminAllowance;
        uint256 crowdSaleAllowance;
        uint256 adminAllowanceConst;
        uint256 crowdSaleAllowanceConst;
        uint256 initialSupply;
        string website;
        address tokenOwner;
        uint8 decimals;
        string symbol;
        string name;
        uint256 totalSupply;
    }

    TokenDetails s2c = TokenDetails(
        false, false, 500000, 1, 50000, 0, 0, address(0), 0, 0, false, false, false, 0, 0, 0, address(0), false, address(0), address(0), 0, 0, 400000000 * (10 ** uint256(18)), 1600000000 * (10 ** uint256(18)), 2000000000 * (10 ** uint256(18)), "www.cqsexchange.io", address(0), 18, "CQS", "CQS", 0
    );

    mapping(address => uint256) public tokensTransferred;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier validDestination(address to) {
        require(to != address(0x0));
        require(to != address(this));
        require(to != s2c.owner);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == s2c.owner);
        _;
    }

    constructor(address _admin) public {
        require(msg.sender != _admin);
        s2c.owner = msg.sender;
        s2c.totalSupply = s2c.initialSupply;
        s2c.crowdSaleAllowance = s2c.crowdSaleAllowanceConst;
        s2c.adminAllowance = s2c.adminAllowanceConst;
        balances[msg.sender] = s2c.totalSupply.sub(s2c.adminAllowance);
        emit Transfer(address(0x0), msg.sender, s2c.totalSupply.sub(s2c.adminAllowance));
        balances[_admin] = s2c.adminAllowance;
        emit Transfer(address(0x0), _admin, s2c.adminAllowance);
        s2c.adminAddr = _admin;
        approve(s2c.adminAddr, s2c.adminAllowance);
    }

    function startICO() external onlyOwner {
        s2c.icoStart = true;
    }

    function stopICO() external onlyOwner {
        s2c.icoStart = false;
    }

    function setCrowdsale(address _crowdSaleAddr, uint256 _amountForSale) external onlyOwner {
        require(_amountForSale <= s2c.crowdSaleAllowance);
        uint amount = (_amountForSale == 0) ? s2c.crowdSaleAllowance : _amountForSale;
        approve(s2c.crowdSaleAddr, 0);
        approve(_crowdSaleAddr, amount);
        s2c.crowdSaleAddr = _crowdSaleAddr;
    }

    function transfer(address to, uint256 tokens) public validDestination(to) returns (bool) {
        if(s2c.icoStart && (msg.sender != s2c.owner || msg.sender != s2c.adminAddr)){
            require((tokensTransferred[msg.sender].add(tokens)).mul(2) <= balances[msg.sender].add(tokensTransferred[msg.sender]));
            tokensTransferred[msg.sender] = tokensTransferred[msg.sender].add(tokens);
            return super.transfer(to, tokens);
        } else {
            return super.transfer(to, tokens);
        }
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(s2c.owner, newOwner);
        s2c.owner = newOwner;
    }

    function burn(uint256 value) public {
        require(msg.sender == s2c.owner || msg.sender == s2c.adminAddr);
        _burn(msg.sender, value);
    }

    function burnFromAdmin(uint256 value) external onlyOwner {
        _burn(s2c.adminAddr, value);
    }

    function changeWebsite(string _website) external onlyOwner {
        s2c.website = _website;
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

    modifier beforeDeadline() {
        require(currentTime() < s2c.endTime);
        _;
    }

    modifier afterDeadline() {
        require(currentTime() >= s2c.endTime);
        _;
    }

    modifier afterStartTime() {
        require(currentTime() >= s2c.startTime);
        _;
    }

    modifier saleNotClosed() {
        require(!s2c.saleClosed);
        _;
    }

    modifier nonReentrant() {
        require(!s2c.rentrancyLock);
        s2c.rentrancyLock = true;
        _;
        s2c.rentrancyLock = false;
    }

    modifier onlyOwner() {
        require(msg.sender == s2c.owner);
        _;
    }

    modifier whenNotPaused() {
        require(!s2c.paused);
        _;
    }

    modifier whenPaused() {
        require(s2c.paused);
        _;
    }

    function pause() onlyOwner whenNotPaused public {
        s2c.paused = true;
        tokenReward.stopICO();
        emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
        s2c.paused = false;
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

        s2c.beneficiary = ifSuccessfulSendTo;
        s2c.fundingGoal = fundingGoalInEthers * 1 ether;
        s2c.fundingCap = fundingCapInEthers * 1 ether;
        s2c.minContribution = minimumContributionInWei;
        s2c.startTime = start;
        s2c.endTime = end;
        s2c.rate = rateCQSToEther;
        tokenReward = CQSToken(addressOfTokenUsedAsReward);
        s2c.owner = msg.sender;
    }

    function () external payable whenNotPaused beforeDeadline afterStartTime saleNotClosed nonReentrant {
        require(msg.value >= s2c.minContribution);
        uint amount = msg.value;
        uint currentBalance = balanceOf[msg.sender];
        balanceOf[msg.sender] = currentBalance.add(amount);
        s2c.amountRaised = s2c.amountRaised.add(amount);
        uint numTokens = amount.mul(s2c.rate);
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
        s2c.saleClosed = true;
        tokenReward.stopICO();
    }

    function setRate(uint _rate) external onlyOwner {
        require(_rate >= s2c.lowRangeRate && _rate <= s2c.highRangeRate);
        s2c.rate = _rate;
    }

    function ownerAllocateTokens(address to, uint amountWei, uint amountMiniCQS) external onlyOwner nonReentrant {
        if (!tokenReward.transferFrom(tokenReward.owner(), to, amountMiniCQS)) {
            revert();
        }
        balanceOf[to] = balanceOf[to].add(amountWei);
        s2c.amountRaised = s2c.amountRaised.add(amountWei);
        emit FundTransfer(to, amountWei, true);
        checkFundingGoal();
        checkFundingCap();
    }

    function ownerSafeWithdrawal() external onlyOwner nonReentrant {
        require(s2c.fundingGoalReached);
        uint balanceToSend = address(this).balance;
        s2c.beneficiary.transfer(balanceToSend);
        emit FundTransfer(s2c.beneficiary, balanceToSend, false);
    }

    function ownerUnlockFund() external afterDeadline onlyOwner {
        s2c.fundingGoalReached = false;
    }

    function safeWithdrawal() external afterDeadline nonReentrant {
        if (!s2c.fundingGoalReached) {
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                msg.sender.transfer(amount);
                emit FundTransfer(msg.sender, amount, false);
                s2c.refundAmount = s2c.refundAmount.add(amount);
            }
        }
    }

    function checkFundingGoal() internal {
        if (!s2c.fundingGoalReached) {
            if (s2c.amountRaised >= s2c.fundingGoal) {
                s2c.fundingGoalReached = true;
                emit GoalReached(s2c.beneficiary, s2c.amountRaised);
            }
        }
    }

    function checkFundingCap() internal {
        if (!s2c.fundingCapReached) {
            if (s2c.amountRaised >= s2c.fundingCap) {
                s2c.fundingCapReached = true;
                s2c.saleClosed = true;
                emit CapReached(s2c.beneficiary, s2c.amountRaised);
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
        s2c.startTime = _startTime;
    }

    function changeEndTime(uint256 _endTime) external onlyOwner {
        s2c.endTime = _endTime;
    }
}
```