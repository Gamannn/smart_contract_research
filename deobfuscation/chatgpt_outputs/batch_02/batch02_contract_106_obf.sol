pragma solidity ^0.4.18;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Token {
    function balanceOf(address owner) public constant returns (uint256 balance);
    function transfer(address to, uint256 value) public returns (bool success);
}

contract Admined {
    address public admin;

    function Admined(address initialAdmin) public {
        admin = initialAdmin;
        AdminedEvent(admin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    function transferAdminship(address newAdmin) onlyAdmin public {
        admin = newAdmin;
        TransferAdminshipEvent(admin);
    }

    event TransferAdminshipEvent(address newAdmin);
    event AdminedEvent(address admin);
}

contract Crowdsale is Admined {
    using SafeMath for uint256;

    enum State { EarlyBird, PreSale, TokenSale, ITO, Successful }
    State public currentState = State.EarlyBird;

    uint256 public priceOfEth;
    uint256 public tokensPerEth;
    string public campaignUrl;
    Token public tokenReward;

    event LogFundingSuccessful(uint totalRaised);
    event LogFunderInitialized(address creator, string url, uint256 tokensPerEth);
    event LogContributorsPayout(address contributor, uint amount);
    event PriceUpdate(uint256 newPrice);
    event StageDistributed(State stage, uint256 amount);

    modifier notSuccessful() {
        require(currentState != State.Successful);
        _;
    }

    function Crowdsale(string url, Token tokenAddress, uint256 initialPrice) public {
        admin = msg.sender;
        campaignUrl = url;
        tokenReward = Token(tokenAddress);
        priceOfEth = initialPrice;
        tokensPerEth = priceOfEth.mul(6666666666666666667).div(1000000000000000000);
        LogFunderInitialized(admin, campaignUrl, tokensPerEth);
        PriceUpdate(tokensPerEth);
    }

    function updatePriceOfEth(uint256 newPrice) onlyAdmin public {
        priceOfEth = newPrice;
        tokensPerEth = priceOfEth.mul(6666666666666666667).div(1000000000000000000);
        PriceUpdate(tokensPerEth);
    }

    function contribute() public payable notSuccessful {
        uint256 tokensBought;
        uint256 amountRaised = msg.value.mul(tokensPerEth);

        if (currentState == State.EarlyBird) {
            tokensBought = msg.value.mul(tokensPerEth).mul(4);
            require(tokenReward.balanceOf(this).add(tokensBought) <= 200000000 * (10 ** 18));
        } else if (currentState == State.PreSale) {
            tokensBought = msg.value.mul(tokensPerEth).div(1.5);
            require(tokenReward.balanceOf(this).add(tokensBought) <= 500000000 * (10 ** 18));
        } else if (currentState == State.TokenSale) {
            tokensBought = msg.value.mul(tokensPerEth);
            require(tokenReward.balanceOf(this).add(tokensBought) <= 800000000 * (10 ** 18));
        } else if (currentState == State.ITO) {
            tokensBought = msg.value.mul(tokensPerEth);
            require(tokenReward.balanceOf(this).add(tokensBought) <= 1000000000 * (10 ** 18));
        }

        tokenReward.transfer(msg.sender, tokensBought);
        LogFundingSuccessful(amountRaised);
        LogContributorsPayout(msg.sender, tokensBought);
        checkState();
    }

    function checkState() public {
        if (currentState != State.Successful) {
            if (currentState == State.EarlyBird && now > 38 days) {
                StageDistributed(currentState, tokenReward.balanceOf(this));
                currentState = State.PreSale;
            } else if (currentState == State.PreSale && now > 127 days) {
                StageDistributed(currentState, tokenReward.balanceOf(this));
                currentState = State.TokenSale;
            } else if (currentState == State.TokenSale && now > 219 days) {
                StageDistributed(currentState, tokenReward.balanceOf(this));
                currentState = State.ITO;
            } else if (currentState == State.ITO && now > 372 days) {
                StageDistributed(currentState, tokenReward.balanceOf(this));
                currentState = State.Successful;
                LogFundingSuccessful(tokenReward.balanceOf(this));
                payout();
            }
        }
    }

    function payout() public {
        require(currentState == State.Successful);
        uint256 balance = tokenReward.balanceOf(this);
        require(tokenReward.transfer(admin, balance));
        LogContributorsPayout(admin, balance);
    }
}