pragma solidity 0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address tokenOwner) public view returns (uint256 balance);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
}

contract AdminControl {
    mapping(address => uint8) public adminLevels;

    constructor() internal {
        adminLevels[msg.sender] = 2;
        emit AdminshipUpdated(msg.sender, 2);
    }

    modifier onlyAdmin(uint8 level) {
        require(adminLevels[msg.sender] >= level);
        _;
    }

    function updateAdminLevel(address admin, uint8 level) public onlyAdmin(2) {
        require(admin != address(0));
        adminLevels[admin] = level;
        emit AdminshipUpdated(admin, level);
    }

    event AdminshipUpdated(address admin, uint8 level);
}

contract Crowdsale is AdminControl {
    using SafeMath for uint256;

    enum State { PreSale, MainSale, OnHold, Failed, Successful }
    State public currentState = State.PreSale;

    ERC20Interface public token;
    mapping(address => uint256) public contributions;
    mapping(address => uint256) public payouts;
    mapping(address => uint256) public pendingPayouts;
    uint256[5] public bonusRates = [2520, 2070, 1980, 1890, 1800];
    mapping(address => bool) public whitelisted;
    mapping(address => bool) public payoutEligible;

    event FundraisingInitialized(address admin);
    event MainSaleDateSet(uint256 date);
    event FundingReceived(address contributor, uint amount, uint totalRaised);
    event BeneficiaryPaid(address beneficiary);
    event ContributorsPayout(address contributor, uint amount);
    event Refund(address contributor, uint amount);
    event FundingSuccessful(uint totalRaised);
    event FundingFailed(uint totalRaised);

    modifier inProgress() {
        require(currentState != State.Successful && currentState != State.OnHold && currentState != State.Failed);
        _;
    }

    struct CrowdsaleData {
        string name;
        address beneficiary;
        uint256 hardCap;
        uint256 softCap;
        uint256 totalRaised;
        uint256 totalTokensSold;
        uint256 totalContributors;
        uint256 endTime;
        uint256 mainSaleEndTime;
        uint256 mainSaleStartTime;
        uint256 preSaleEndTime;
        uint256 preSaleStartTime;
    }

    CrowdsaleData public crowdsaleData = CrowdsaleData(
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

    constructor(ERC20Interface _token) public {
        crowdsaleData.beneficiary = msg.sender;
        token = _token;
        emit FundraisingInitialized(crowdsaleData.beneficiary);
    }

    function updateWhitelist(address user, bool status) public onlyAdmin(1) {
        whitelisted[user] = status;
    }

    function updatePayoutEligibility(address user, bool status) public onlyAdmin(1) {
        payoutEligible[user] = status;
    }

    function setMainSaleDate(uint256 date) public onlyAdmin(2) {
        require(currentState == State.OnHold);
        require(date > now);
        crowdsaleData.mainSaleStartTime = date;
        crowdsaleData.mainSaleEndTime = date.add(12 weeks);
        currentState = State.MainSale;
        emit MainSaleDateSet(crowdsaleData.mainSaleStartTime);
    }

    function contribute() public inProgress payable {
        require(whitelisted[msg.sender] == true);
        require(msg.value >= 0.1 ether);

        uint256 tokensToTransfer = 0;
        crowdsaleData.totalRaised = crowdsaleData.totalRaised.add(msg.value);
        contributions[msg.sender] = contributions[msg.sender].add(msg.value);

        if (currentState == State.PreSale) {
            require(now >= crowdsaleData.preSaleStartTime);
            tokensToTransfer = msg.value.mul(bonusRates[0]);
            crowdsaleData.totalTokensSold = crowdsaleData.totalTokensSold.add(tokensToTransfer);
        } else if (currentState == State.MainSale) {
            require(now >= crowdsaleData.mainSaleStartTime);
            if (now <= crowdsaleData.mainSaleStartTime.add(1 weeks)) {
                tokensToTransfer = msg.value.mul(bonusRates[1]);
            } else if (now <= crowdsaleData.mainSaleStartTime.add(2 weeks)) {
                tokensToTransfer = msg.value.mul(bonusRates[2]);
            } else if (now <= crowdsaleData.mainSaleStartTime.add(3 weeks)) {
                tokensToTransfer = msg.value.mul(bonusRates[3]);
            } else {
                tokensToTransfer = msg.value.mul(bonusRates[4]);
            }
        }

        require(crowdsaleData.totalTokensSold.add(tokensToTransfer) <= crowdsaleData.hardCap);

        if (payoutEligible[msg.sender] == true) {
            uint256 pendingAmount = pendingPayouts[msg.sender];
            pendingPayouts[msg.sender] = 0;
            require(token.transfer(msg.sender, tokensToTransfer.add(pendingAmount)));
            payouts[msg.sender] = payouts[msg.sender].add(tokensToTransfer.add(pendingAmount));
            emit ContributorsPayout(msg.sender, tokensToTransfer.add(pendingAmount));
        } else {
            pendingPayouts[msg.sender] = pendingPayouts[msg.sender].add(tokensToTransfer);
        }

        crowdsaleData.totalTokensSold = crowdsaleData.totalTokensSold.add(tokensToTransfer);
        emit FundingReceived(msg.sender, msg.value, crowdsaleData.totalRaised);
        checkStatus();
    }

    function checkStatus() public {
        if (crowdsaleData.totalTokensSold == crowdsaleData.hardCap && currentState != State.Successful) {
            currentState = State.Successful;
            crowdsaleData.endTime = now;
            emit FundingSuccessful(crowdsaleData.totalRaised);
            finalize();
        } else if (currentState == State.PreSale && now > crowdsaleData.preSaleEndTime) {
            currentState = State.OnHold;
        } else if (currentState == State.MainSale && now > crowdsaleData.mainSaleEndTime) {
            if (crowdsaleData.totalTokensSold >= crowdsaleData.softCap) {
                currentState = State.Successful;
                crowdsaleData.endTime = now;
                emit FundingSuccessful(crowdsaleData.totalRaised);
                finalize();
            } else {
                currentState = State.Failed;
                crowdsaleData.endTime = now;
                emit FundingFailed(crowdsaleData.totalRaised);
            }
        }
    }

    function finalize() public {
        require(currentState == State.Successful);
        if (now > crowdsaleData.endTime.add(14 days)) {
            uint256 remainingTokens = token.balanceOf(this);
            token.transfer(crowdsaleData.beneficiary, remainingTokens);
            emit ContributorsPayout(crowdsaleData.beneficiary, remainingTokens);
        }
        crowdsaleData.beneficiary.transfer(address(this).balance);
        emit BeneficiaryPaid(crowdsaleData.beneficiary);
    }

    function claimTokens() public {
        require(payoutEligible[msg.sender] == true);
        uint256 tokens = pendingPayouts[msg.sender];
        pendingPayouts[msg.sender] = 0;
        require(token.transfer(msg.sender, tokens));
        payouts[msg.sender] = payouts[msg.sender].add(tokens);
        emit ContributorsPayout(msg.sender, tokens);
    }

    function adminClaimTokens(address user) public onlyAdmin(1) {
        require(payoutEligible[user] == true);
        uint256 tokens = pendingPayouts[user];
        pendingPayouts[user] = 0;
        require(token.transfer(user, tokens));
        payouts[user] = payouts[user].add(tokens);
        emit ContributorsPayout(user, tokens);
    }

    function handleFailure() public {
        require(currentState == State.Failed);
        if (now < crowdsaleData.endTime.add(90 days)) {
            uint256 refundAmount = payouts[msg.sender];
            payouts[msg.sender] = 0;
            pendingPayouts[msg.sender] = 0;
            uint256 contribution = contributions[msg.sender];
            contributions[msg.sender] = 0;
            require(token.transferFrom(msg.sender, address(this), refundAmount));
            msg.sender.transfer(contribution);
            emit Refund(msg.sender, contribution);
        } else {
            require(adminLevels[msg.sender] >= 2);
            uint256 remainingTokens = token.balanceOf(this);
            crowdsaleData.beneficiary.transfer(address(this).balance);
            token.transfer(crowdsaleData.beneficiary, remainingTokens);
            emit BeneficiaryPaid(crowdsaleData.beneficiary);
            emit ContributorsPayout(crowdsaleData.beneficiary, remainingTokens);
        }
    }

    function claimStuckTokens(ERC20Interface _token) public onlyAdmin(2) {
        require(_token != token);
        uint256 stuckTokens = _token.balanceOf(this);
        _token.transfer(msg.sender, stuckTokens);
    }

    function () public payable {
        contribute();
    }
}