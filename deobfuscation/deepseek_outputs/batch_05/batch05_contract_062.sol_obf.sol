```solidity
pragma solidity ^0.4.16;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

interface Token {
    function transfer(address to, uint256 amount) public returns (bool success);
    function balanceOf(address owner) public constant returns (uint256 balance);
}

contract ICO {
    using SafeMath for uint256;
    
    enum State { PreSale, ICO, Successful }
    
    State public state = State.PreSale;
    uint256 public startTime = now;
    uint256 public totalRaised;
    uint256 public currentBalance;
    uint256 public preSaleDeadline;
    uint256 public ICODeadline;
    uint256 public completedAt;
    
    Token public tokenReward;
    address public creator;
    string public campaignUrl;
    
    uint256[4] public tokenExchangeRates;
    
    event LogBeneficiaryPaid(address beneficiary);
    event LogFundingSuccessful(uint256 totalRaised);
    event LogICOInitialized(
        address creator,
        string campaignUrl,
        uint256 preSaleDeadline,
        uint256 ICODeadline
    );
    event LogFundingReceived(address contributor, uint256 amount, uint256 totalRaised);
    event LogContributorsPayout(address contributor, uint256 amount);
    event LogWithdrawal(address beneficiary, uint256 amount);
    
    modifier notFinished() {
        require(state != State.Successful);
        _;
    }
    
    function ICO(
        string _campaignUrl,
        Token _tokenAddress
    ) public {
        creator = msg.sender;
        campaignUrl = _campaignUrl;
        tokenReward = _tokenAddress;
        
        preSaleDeadline = startTime.add(2 weeks);
        ICODeadline = preSaleDeadline.add(3 weeks);
        
        tokenExchangeRates = [7800, 6600, 18, 1209600];
        
        LogICOInitialized(
            creator,
            campaignUrl,
            preSaleDeadline,
            ICODeadline
        );
    }
    
    function contribute() public notFinished payable {
        uint256 tokenAmount;
        
        totalRaised = totalRaised.add(msg.value);
        currentBalance = totalRaised;
        
        if (state == State.PreSale && now < startTime + 2 weeks) {
            tokenAmount = uint256(msg.value).mul(tokenExchangeRates[0]);
            
            if (totalRaised.add(tokenAmount) > 10000000 * (10**18)) {
                revert();
            }
        } else if (state == State.PreSale && now < startTime + 2 weeks) {
            tokenAmount = uint256(msg.value).mul(tokenExchangeRates[1]);
            
            if (totalRaised.add(tokenAmount) > 10000000 * (10**18)) {
                revert();
            }
        } else if (state == State.ICO && now < startTime + 3 weeks) {
            tokenAmount = uint256(msg.value).mul(tokenExchangeRates[2]);
        } else {
            revert();
        }
        
        tokenReward.transfer(msg.sender, tokenAmount);
        LogFundingReceived(msg.sender, msg.value, totalRaised);
        LogContributorsPayout(msg.sender, tokenAmount);
        checkFundingState();
    }
    
    function checkFundingState() public {
        if (now > preSaleDeadline && now < ICODeadline) {
            state = State.ICO;
        } else if (now > ICODeadline && state == State.ICO) {
            state = State.Successful;
            completedAt = now;
            LogFundingSuccessful(totalRaised);
            withdraw();
        }
    }
    
    function withdraw() public {
        require(state == State.Successful);
        
        uint256 remainingTokens;
        remainingTokens = tokenReward.balanceOf(this);
        currentBalance = 0;
        
        tokenReward.transfer(creator, remainingTokens);
        require(creator.send(this.balance));
        
        LogBeneficiaryPaid(creator);
        LogWithdrawal(creator, remainingTokens);
    }
    
    function () public payable {
        require(msg.value > 1 finney);
        contribute();
    }
}
```