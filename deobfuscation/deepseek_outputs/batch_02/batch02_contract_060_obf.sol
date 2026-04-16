```solidity
pragma solidity ^0.4.19;

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

contract Ownable {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    function Ownable(address _owner) public {
        owner = _owner;
    }
    
    modifier onlyOwner() {
        require(tx.origin == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Stoppable is Ownable {
    bool public halted;
    
    event SaleStopped(address owner, uint256 timestamp);
    
    modifier notHalted() {
        require(!halted);
        _;
    }
    
    modifier onlyWhenHalted() {
        require(halted);
        _;
    }
    
    function isHalted() public view returns (bool) {
        return halted;
    }
    
    function stopSale() public onlyOwner {
        halted = true;
        SaleStopped(msg.sender, now);
    }
}

contract Crowdsale is Stoppable {
    using SafeMath for uint256;
    
    bool private commissionCollected = false;
    ERC20 public token;
    uint256 public rate;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public weiRaised;
    uint256 public tokensSent;
    address public commissionWallet;
    
    mapping(address => uint256) public contributions;
    mapping(address => uint256) public tokenBalances;
    
    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount, uint256 timestamp);
    event BeneficiaryWithdrawal(address beneficiary, uint256 amount, uint256 timestamp);
    event CommissionCollected(address commissionWallet, uint256 amount, uint256 timestamp);
    
    function Crowdsale(
        address _tokenAddress,
        uint256 _rate,
        uint256 _startTime,
        uint256 _endTime,
        address _commissionWallet,
        address _owner
    ) public Ownable(_owner) {
        require(_startTime > now);
        require(_startTime < _endTime);
        
        token = ERC20(_tokenAddress);
        rate = _rate;
        startTime = _startTime;
        endTime = _endTime;
        commissionWallet = _commissionWallet;
    }
    
    function collectCommission() onlyOwner external {
        commissionCollected = true;
        uint256 balance = getTokenBalance();
        uint256 commission = balance.div(100);
        tokensSent = commission;
    }
    
    function getTokenBalance() public view returns(uint256) {
        return token.balanceOf(owner, this);
    }
    
    function isApproved() public view returns(bool) {
        return token.allowance(owner, this) > 0;
    }
    
    function getRate() public view returns(uint256) {
        return rate;
    }
    
    function buyTokens() public notHalted payable {
        uint256 weiAmount = msg.value;
        uint256 tokens = calculateTokens(weiAmount);
        validatePurchase(tokens);
        processPurchase(msg.sender, weiAmount, tokens);
        TokenPurchase(msg.sender, msg.value, tokens, now);
    }
    
    function validatePurchase(uint256 _tokens) public view {
        uint256 balance = getTokenBalance();
        balance = balance.sub(tokensSent);
        require(balance >= _tokens);
    }
    
    function processPurchase(address _purchaser, uint256 _weiAmount, uint256 _tokens) internal {
        require(token.transferFrom(owner, _purchaser, _tokens));
        
        contributions[_purchaser] = contributions[_purchaser].add(_weiAmount);
        tokenBalances[_purchaser] = tokenBalances[_purchaser].add(_tokens);
        weiRaised = weiRaised.add(_weiAmount);
        tokensSent = tokensSent.add(_tokens);
    }
    
    function calculateTokens(uint256 _weiAmount) internal view returns(uint256) {
        return _weiAmount.div(rate);
    }
    
    function hasEnded() public view returns (bool) {
        return now > endTime || halted;
    }
    
    function validatePurchaseInternal(uint256 _tokens) internal view returns (bool) {
        require(!hasEnded());
        validatePurchase(_tokens);
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        require(withinPeriod && nonZeroPurchase);
        return true;
    }
    
    function canWithdraw() public view returns(bool) {
        return contributions[msg.sender] > 0 && isHalted();
    }
    
    function withdrawContribution() public onlyWhenHalted {
        uint256 contribution = contributions[msg.sender];
        require(contribution > 0);
        contributions[msg.sender] = 0;
        msg.sender.transfer(contribution);
    }
    
    function withdrawRaised() public onlyOwner notHalted returns(bool) {
        require(hasEnded());
        owner.transfer(weiRaised);
        BeneficiaryWithdrawal(owner, weiRaised, now);
        return true;
    }
    
    function collectCommissionInternal() public notHalted returns(bool) {
        require(msg.sender == commissionWallet);
        require(hasEnded());
        uint256 onePercent = tokensSent.div(100);
        processPurchase(commissionWallet, 0, onePercent);
        CommissionCollected(commissionWallet, onePercent, now);
        return true;
    }
}

interface ERC20 {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address owner, address spender) public constant returns (uint256);
    function allowance(address owner, address spender) public constant returns (uint256);
}
```