```solidity
pragma solidity 0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

interface ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Adminable {
    mapping(address => uint8) public adminLevel;
    
    constructor() internal {
        adminLevel[msg.sender] = 2;
        emit AdminshipUpdated(msg.sender, 2);
    }
    
    modifier requireAdminLevel(uint8 level) {
        require(adminLevel[msg.sender] >= level);
        _;
    }
    
    function setAdminLevel(address admin, uint8 level) public requireAdminLevel(2) {
        require(admin != address(0));
        adminLevel[admin] = level;
        emit AdminshipUpdated(admin, level);
    }
    
    event AdminshipUpdated(address admin, uint8 level);
}

contract Crowdsale is Adminable {
    using SafeMath for uint256;
    
    enum State { PreSale, MainSale, OnHold, Failed, Successful }
    State public currentState = State.PreSale;
    
    ERC20 public token;
    
    mapping (address => uint256) public contributions;
    mapping (address => uint256) public tokensClaimed;
    mapping (address => uint256) public tokensPending;
    
    uint256[5] public bonusRates = [2520, 2070, 1980, 1890, 1800];
    
    mapping (address => bool) public whitelist;
    mapping (address => bool) public kycVerified;
    
    event LogFundrisingInitialized(address beneficiary);
    event LogMainSaleDateSet(uint256 mainSaleStart);
    event LogFundingReceived(address contributor, uint amount, uint totalRaised);
    event LogBeneficiaryPaid(address beneficiary);
    event LogContributorsPayout(address contributor, uint amount);
    event LogRefund(address contributor, uint amount);
    event LogFundingSuccessful(uint totalRaised);
    event LogFundingFailed(uint totalRaised);
    
    modifier notFinalState() {
        require(currentState != State.Successful && 
                currentState != State.OnHold && 
                currentState != State.Failed);
        _;
    }
    
    constructor(ERC20 tokenAddress) public {
        campaign.beneficiary = msg.sender;
        token = tokenAddress;
        emit LogFundrisingInitialized(campaign.beneficiary);
    }
    
    function setWhitelist(address user, bool status) public requireAdminLevel(1) {
        whitelist[user] = status;
    }
    
    function setKYCVerified(address user, bool status) public requireAdminLevel(1) {
        kycVerified[user] = status;
    }
    
    function setMainSaleStart(uint256 startTime) public requireAdminLevel(2) {
        require(currentState == State.OnHold);
        require(startTime > now);
        campaign.mainSaleStart = startTime;
        campaign.mainSaleEnd = campaign.mainSaleStart.add(12 weeks);
        currentState = State.MainSale;
        emit LogMainSaleDateSet(campaign.mainSaleStart);
    }
    
    function contribute() public notFinalState payable {
        require(whitelist[msg.sender] == true);
        require(msg.value >= 0.1 ether);
        
        uint256 tokensToIssue = 0;
        campaign.totalRaised = campaign.totalRaised.add(msg.value);
        contributions[msg.sender] = contributions[msg.sender].add(msg.value);
        
        if (currentState == State.PreSale) {
            require(now >= campaign.preSaleStart);
            tokensToIssue = msg.value.mul(bonusRates[0]);
            campaign.preSaleTokensIssued = campaign.preSaleTokensIssued.add(tokensToIssue);
        } else if (currentState == State.MainSale) {
            require(now >= campaign.mainSaleStart);
            
            if (now <= campaign.mainSaleStart.add(1 weeks)) {
                tokensToIssue = msg.value.mul(bonusRates[1]);
            } else if (now <= campaign.mainSaleStart.add(2 weeks)) {
                tokensToIssue = msg.value.mul(bonusRates[2]);
            } else if (now <= campaign.mainSaleStart.add(3 weeks)) {
                tokensToIssue = msg.value.mul(bonusRates[3]);
            } else {
                tokensToIssue = msg.value.mul(bonusRates[4]);
            }
        }
        
        require(campaign.tokensIssued.add(tokensToIssue) <= campaign.hardCap);
        
        if (kycVerified[msg.sender] == true) {
            uint256 pendingTokens = tokensPending[msg.sender];
            tokensPending[msg.sender] = 0;
            require(token.transfer(msg.sender, tokensToIssue.add(pendingTokens)));
            tokensClaimed[msg.sender] = tokensClaimed[msg.sender].add(tokensToIssue.add(pendingTokens));
            emit LogContributorsPayout(msg.sender, tokensToIssue.add(pendingTokens));
        } else {
            tokensPending[msg.sender] = tokensPending[msg.sender].add(tokensToIssue);
        }
        
        campaign.tokensIssued = campaign.tokensIssued.add(tokensToIssue);
        emit LogFundingReceived(msg.sender, msg.value, campaign.totalRaised);
        checkStatus();
    }
    
    function checkStatus() public {
        if (campaign.tokensIssued == campaign.hardCap && currentState != State.Successful) {
            currentState = State.Successful;
            campaign.successTime = now;
            emit LogFundingSuccessful(campaign.totalRaised);
            finalize();
        } else if (currentState == State.PreSale && now > campaign.preSaleEnd) {
            currentState = State.OnHold;
        } else if (currentState == State.MainSale && now > campaign.mainSaleEnd) {
            if (campaign.tokensIssued >= campaign.softCap) {
                currentState = State.Successful;
                campaign.successTime = now;
                emit LogFundingSuccessful(campaign.totalRaised);
                finalize();
            } else {
                currentState = State.Failed;
                campaign.successTime = now;
                emit LogFundingFailed(campaign.totalRaised);
            }
        }
    }
    
    function finalize() public {
        require(currentState == State.Successful);
        
        if (now > campaign.successTime.add(14 days)) {
            uint256 remainingTokens = token.balanceOf(this);
            token.transfer(campaign.beneficiary, remainingTokens);
            emit LogContributorsPayout(campaign.beneficiary, remainingTokens);
        }
        
        campaign.beneficiary.transfer(address(this).balance);
        emit LogBeneficiaryPaid(campaign.beneficiary);
    }
    
    function emergencyWithdraw() public requireAdminLevel(2) {
        require(campaign.tokensIssued >= campaign.softCap);
        campaign.beneficiary.transfer(address(this).balance);
        emit LogBeneficiaryPaid(campaign.beneficiary);
    }
    
    function claimTokens() public {
        require(kycVerified[msg.sender] == true);
        uint256 pending = tokensPending[msg.sender];
        tokensPending[msg.sender] = 0;
        require(token.transfer(msg.sender, pending));
        tokensClaimed[msg.sender] = tokensClaimed[msg.sender].add(pending);
        emit LogContributorsPayout(msg.sender, pending);
    }
    
    function claimTokensFor(address user) public requireAdminLevel(1) {
        require(kycVerified[user] == true);
        uint256 pending = tokensPending[user];
        tokensPending[user] = 0;
        require(token.transfer(user, pending));
        tokensClaimed[user] = tokensClaimed[user].add(pending);
        emit LogContributorsPayout(user, pending);
    }
    
    function refund() public {
        require(currentState == State.Failed);
        
        if (now < campaign.successTime.add(90 days)) {
            uint256 claimedTokens = tokensClaimed[msg.sender];
            tokensClaimed[msg.sender] = 0;
            tokensPending[msg.sender] = 0;
            uint256 contributionAmount = contributions[msg.sender];
            contributions[msg.sender] = 0;
            require(token.transferFrom(msg.sender, address(this), claimedTokens));
            msg.sender.transfer(contributionAmount);
            emit LogRefund(msg.sender, contributionAmount);
        } else {
            require(adminLevel[msg.sender] >= 2);
            uint256 remainingTokens = token.balanceOf(this);
            campaign.beneficiary.transfer(address(this).balance);
            token.transfer(campaign.beneficiary, remainingTokens);
            emit LogBeneficiaryPaid(campaign.beneficiary);
            emit LogContributorsPayout(campaign.beneficiary, remainingTokens);
        }
    }
    
    function recoverTokens(ERC20 tokenAddress) public requireAdminLevel(2) {
        require(tokenAddress != token);
        uint256 balance = tokenAddress.balanceOf(this);
        tokenAddress.transfer(msg.sender, balance);
    }
    
    function () public payable {
        contribute();
    }
    
    struct Campaign {
        string version;
        address beneficiary;
        uint256 hardCap;
        uint256 softCap;
        uint256 tokensIssued;
        uint256 preSaleTokensIssued;
        uint256 totalRaised;
        uint256 successTime;
        uint256 mainSaleEnd;
        uint256 mainSaleStart;
        uint256 preSaleEnd;
        uint256 preSaleStart;
    }
    
    Campaign campaign = Campaign(
        '1',
        address(0),
        140000000 * (10 ** 18),
        11000000 * (10 ** 18),
        0,
        0,
        0,
        0,
        0,
        0,
        1529452799,
        now
    );
}
```