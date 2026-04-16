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

interface Token {
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
}

contract Admined {
    address public admin;

    event TransferAdminship(address newAdmin);
    event Admined(address admin);

    function Admined(address _admin) public {
        admin = _admin;
        Admined(admin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    function transferAdminship(address newAdmin) onlyAdmin public {
        admin = newAdmin;
        TransferAdminship(admin);
    }
}

contract Crowdsale is Admined {
    using SafeMath for uint256;

    enum State {
        EarlyBird,
        PreSale,
        TokenSale,
        ITO,
        Successful
    }

    uint256 public priceOfEthOnEUR;
    State public state = State.EarlyBird;
    uint256 public price;
    string public campaignUrl;

    uint256 public totalRaised;
    uint256 public totalDistributed;
    uint256 public stageDistributed;
    uint256 public completedAt;
    address public creator;
    Token public token;

    event LogFundingSuccessful(uint256 totalRaised);
    event LogFunderInitialized(
        address creator,
        string campaignUrl,
        uint256 price
    );
    event LogContributorsPayout(address contributor, uint256 amount);
    event PriceUpdate(uint256 price);
    event StageDistributed(State state, uint256 amount);

    modifier notFinished() {
        require(state != State.Successful);
        _;
    }

    function Crowdsale(
        string _campaignUrl,
        Token _token,
        uint256 _priceOfEthOnEUR
    ) public Admined(msg.sender) {
        creator = msg.sender;
        campaignUrl = _campaignUrl;
        token = Token(_token);
        priceOfEthOnEUR = _priceOfEthOnEUR;
        price = SafeMath.div(priceOfEthOnEUR.mul(6666666666666666667), 1000000000000000000);
        LogFunderInitialized(creator, campaignUrl, price);
        PriceUpdate(price);
    }

    function setPriceOfEthOnEUR(uint256 _newPriceOfEthOnEUR) onlyAdmin public {
        priceOfEthOnEUR = _newPriceOfEthOnEUR;
        price = SafeMath.div(priceOfEthOnEUR.mul(6666666666666666667), 1000000000000000000);
        PriceUpdate(price);
    }

    function contribute() public payable notFinished {
        uint256 tokenBought;
        totalRaised = totalRaised.add(msg.value);

        if (state == State.EarlyBird) {
            tokenBought = msg.value.mul(price);
            tokenBought = tokenBought.mul(4);
            require(stageDistributed.add(tokenBought) <= 200000000 * (10 ** 18));
        } else if (state == State.PreSale) {
            tokenBought = msg.value.mul(price);
            tokenBought = tokenBought.mul(15).div(10);
            tokenBought = tokenBought.div(10);
            require(stageDistributed.add(tokenBought) <= 500000000 * (10 ** 18));
        } else if (state == State.TokenSale) {
            tokenBought = msg.value.mul(price);
            require(stageDistributed.add(tokenBought) <= 800000000 * (10 ** 18));
        } else if (state == State.ITO) {
            tokenBought = msg.value.mul(price);
            require(stageDistributed.add(tokenBought) <= 1000000000 * (10 ** 18));
        }

        totalDistributed = totalDistributed.add(tokenBought);
        stageDistributed = stageDistributed.add(tokenBought);
        token.transfer(msg.sender, tokenBought);
        LogContributorsPayout(msg.sender, tokenBought);
        updateState();
    }

    function updateState() public {
        if (state != State.Successful) {
            if (state == State.EarlyBird && now > completedAt.add(38 days)) {
                StageDistributed(state, stageDistributed);
                state = State.PreSale;
                stageDistributed = 0;
            } else if (state == State.PreSale && now > completedAt.add(127 days)) {
                StageDistributed(state, stageDistributed);
                state = State.TokenSale;
                stageDistributed = 0;
            } else if (state == State.TokenSale && now > completedAt.add(219 days)) {
                StageDistributed(state, stageDistributed);
                state = State.ITO;
                stageDistributed = 0;
            } else if (state == State.ITO && now > completedAt.add(372 days)) {
                StageDistributed(state, stageDistributed);
                state = State.Successful;
                completedAt = now;
                LogFundingSuccessful(totalRaised);
                withdrawFunds();
            }
        }
    }

    function withdrawFunds() public {
        require(state == State.Successful);
        uint256 remainder = token.balanceOf(this);
        require(creator.send(this.balance));
        token.transfer(creator, remainder);
        LogContributorsPayout(creator, remainder);
    }

    function() public payable {
        contribute();
    }
}