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

contract Token {
    function transfer(address to, uint256 value) public returns (bool);
    function balanceOf(address owner) public constant returns (uint256);
}

contract Crowdsale {
    using SafeMath for uint256;

    enum State { PreSale, ICO, Successful }
    State public state = State.PreSale;

    uint256 public startTime = now;
    uint256 public preSaleDeadline;
    uint256 public icoDeadline;
    uint256 public totalRaised;
    Token public tokenReward;
    address public beneficiary;
    string public campaignUrl;

    event LogBeneficiaryPaid(address beneficiaryAddress);
    event LogFundingSuccessful(uint totalRaised);
    event LogICOInitialized(address creator, string url, uint256 preSaleDeadline, uint256 icoDeadline);
    event LogContributorsPayout(address contributor, uint amount);

    modifier notSuccessful() {
        require(state != State.Successful);
        _;
    }

    function Crowdsale(string _campaignUrl, Token _tokenReward) public {
        beneficiary = msg.sender;
        campaignUrl = _campaignUrl;
        tokenReward = _tokenReward;
        preSaleDeadline = startTime.add(3 weeks);
        icoDeadline = preSaleDeadline.add(3 weeks);
        LogICOInitialized(beneficiary, campaignUrl, preSaleDeadline, icoDeadline);
    }

    function contribute() public notSuccessful payable {
        uint256 amount = msg.value;
        totalRaised = totalRaised.add(amount);

        uint256 tokens;
        if (state == State.PreSale && now < preSaleDeadline) {
            tokens = amount.mul(1000);
            if (totalRaised.add(tokens) > 10000000 * (10**18)) {
                revert();
            }
        } else if (state == State.ICO && now < icoDeadline) {
            tokens = amount.mul(500);
            if (totalRaised.add(tokens) > 10000000 * (10**18)) {
                revert();
            }
        } else {
            revert();
        }

        tokenReward.transfer(msg.sender, tokens);
        LogContributorsPayout(msg.sender, tokens);
        checkState();
    }

    function checkState() public {
        if (now > preSaleDeadline && now < icoDeadline) {
            state = State.ICO;
        } else if (now > icoDeadline && state == State.ICO) {
            state = State.Successful;
            LogFundingSuccessful(totalRaised);
            payout();
        }
    }

    function payout() public {
        require(state == State.Successful);
        uint256 balance = tokenReward.balanceOf(this);
        totalRaised = 0;
        tokenReward.transfer(beneficiary, balance);
        require(beneficiary.send(this.balance));
        LogBeneficiaryPaid(beneficiary);
    }

    function () public payable {
        require(msg.value > 1 finney);
        contribute();
    }
}
```