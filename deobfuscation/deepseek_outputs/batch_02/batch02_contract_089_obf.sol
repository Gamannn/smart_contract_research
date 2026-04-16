```solidity
pragma solidity ^0.4.25;

contract InvestmentContract {
    mapping(address => uint256) public tokenBalance;
    mapping(address => uint256) public userBalance;
    
    address public owner;
    uint256 public startTime;
    uint256 public lockPeriod;
    uint256 public softCap;
    uint256 public hardCap;
    uint256 public totalInvested;
    uint256 public tokenSupply;
    uint256 public tokenPrice;
    bool public softCapReached;
    uint256 public softCapReachedTime;
    
    modifier onlyAfterLockPeriod() {
        require(now > startTime + lockPeriod && !softCapReached);
        _;
    }
    
    constructor() public {
        owner = msg.sender;
        startTime = now;
        lockPeriod = 1483300;
        softCap = 10000000 ether;
        hardCap = 2500000 ether;
        tokenPrice = 0.0004 ether;
    }
    
    function() public payable {
        investInternal(msg.sender, msg.value, address(0), address(0));
    }
    
    function investWithReferrals(address referrer1, address referrer2) public payable {
        require(msg.value > 0);
        investInternal(msg.sender, msg.value, referrer1, referrer2);
    }
    
    function investInternal(address investor, uint256 amount, address referrer1, address referrer2) internal {
        tokenBalance[investor] += amount;
        totalInvested += amount;
        
        if (tokenSupply >= softCap) {
            softCapReached = true;
            softCapReachedTime = now;
        }
        
        uint256 referrer1Fee = amount * 6 / 100;
        uint256 referrer2Fee = amount * 3 / 100;
        uint256 ownerAmount = amount - referrer1Fee - referrer2Fee;
        
        if (referrer1 != address(0) && tokenBalance[referrer1] >= 125 ether) {
            userBalance[referrer1] += referrer1Fee;
        } else {
            userBalance[owner] += referrer1Fee;
        }
        
        if (referrer2 != address(0) && tokenBalance[referrer2] >= 125 ether) {
            userBalance[referrer2] += referrer2Fee;
        } else {
            userBalance[owner] += referrer2Fee;
        }
        
        userBalance[owner] += ownerAmount;
        
        emit OnInvest(investor, amount, amount, referrer1, referrer2, now);
    }
    
    function withdrawAll() public {
        require(softCapReached);
        uint256 amount = userBalance[msg.sender];
        require(amount > 0);
        userBalance[msg.sender] = 0;
        msg.sender.transfer(amount);
        emit OnWithdraw(msg.sender, amount, now);
    }
    
    function withdrawPartial(uint256 amount) public {
        require(amount > 0);
        require(softCapReached);
        uint256 balance = userBalance[msg.sender];
        require(balance >= amount);
        userBalance[msg.sender] = balance - amount;
        msg.sender.transfer(amount);
        emit OnWithdraw(msg.sender, amount, now);
    }
    
    function withdrawTo(uint256 amount, address recipient) public {
        require(amount > 0);
        require(softCapReached);
        uint256 balance = userBalance[msg.sender];
        require(balance >= amount);
        userBalance[msg.sender] = balance - amount;
        recipient.transfer(amount);
        emit OnWithdrawTo(msg.sender, recipient, amount, now);
    }
    
    function deinvest() public onlyAfterLockPeriod {
        uint256 tokens = tokenBalance[msg.sender];
        require(tokens > 0);
        tokenBalance[msg.sender] = 0;
        tokenSupply -= tokens;
        uint256 refundAmount = tokens * tokenPrice / 1e18;
        msg.sender.transfer(refundAmount);
        emit OnDeinvest(msg.sender, tokens, refundAmount, tokenSupply);
    }
    
    function exchangeForESM() public {
        require(softCapReached);
        uint256 tokens = tokenBalance[msg.sender];
        require(tokens > 0);
        tokenBalance[msg.sender] = 0;
        tokenSupply -= tokens;
        emit OnExchangeForESM(msg.sender, tokens, now);
    }
    
    function transferTokens(address recipient) public {
        uint256 tokens = tokenBalance[msg.sender];
        require(tokens > 0);
        tokenBalance[msg.sender] = 0;
        tokenBalance[recipient] += tokens;
        emit OnTransfer(msg.sender, recipient, tokens, now);
    }
    
    event OnInvest(
        address investor,
        uint256 amount,
        uint256 tokens,
        address referrer1,
        address referrer2,
        uint256 timestamp
    );
    
    event OnWithdraw(
        address indexed investor,
        uint256 amount,
        uint256 timestamp
    );
    
    event OnWithdrawTo(
        address indexed investor,
        address indexed recipient,
        uint256 amount,
        uint256 timestamp
    );
    
    event OnDeinvest(
        address indexed investor,
        uint256 tokens,
        uint256 refundAmount,
        uint256 totalTokenSupply
    );
    
    event OnExchangeForESM(
        address indexed investor,
        uint256 tokens,
        uint256 timestamp
    );
    
    event OnTransfer(
        address from,
        address to,
        uint256 tokens,
        uint256 timestamp
    );
}
```