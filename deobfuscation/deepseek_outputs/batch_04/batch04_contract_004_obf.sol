pragma solidity ^0.4.24;

contract Mizhen {
    using SafeMath for uint256;

    modifier onlyTokenHolders(uint256 _amountOfTokens) {
        address _customerAddress = msg.sender;
        require((_amountOfTokens > 0) && (_amountOfTokens <= tokenBalanceLedger_[_customerAddress]));
        _;
    }

    modifier onlyAmbassadors() {
        address _customerAddress = msg.sender;
        require(dividendsOf(_customerAddress) > 0);
        _;
    }

    modifier onlyAdministrator() {
        address _customerAddress = msg.sender;
        require(administrators[_customerAddress] == true);
        _;
    }

    modifier onlyAmbassadors2() {
        uint256 _incomingEthereum = msg.value;
        uint256 _tokenPriceInitial = (tokenPriceInitial_ * 100) / 85;
        require((_incomingEthereum >= _tokenPriceInitial) && (tokenSupply_ >= calculateTokensReceived(_incomingEthereum)));
        _;
    }

    event OnTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        uint256 totalSupply,
        uint256 timestamp
    );

    event OnTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 ethereumEarned,
        uint256 totalSupply,
        uint256 timestamp
    );

    event OnReinvestment(
        address indexed customerAddress,
        uint256 ethereumReinvested,
        uint256 tokensMinted,
        uint256 totalSupply,
        uint256 timestamp
    );

    event OnWithdraw(
        address indexed customerAddress,
        uint256 ethereumWithdrawn
    );

    event OnTotalProfitPot(
        uint256 totalProfitPot
    );

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );

    uint256 constant internal magnitude = 1e19;

    mapping(address => bool) public ambassadors;
    mapping(address => uint256) public tokenBalanceLedger_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => bool) public administrators;

    uint256 public tokenSupply_ = 0;
    uint256 public profitPerShare_ = 0;
    uint256 public totalProfitPot = 0;

    uint256 constant internal tokenPriceInitial_ = 21000000;
    uint256 constant internal tokenPriceIncremental_ = 2100000;

    uint8 constant internal dividendFee_ = 5;
    uint8 constant internal toCommunity_ = 10;
    uint8 constant internal ambassadorAccumulatedQuota_ = 18;

    uint256 public totalEthereumBalance = 0;
    uint256 public totalTokenSold = 0;

    string public name = "Mizhen";
    string public symbol = "MZB";

    address payable internal communityAddress = 0x43e8587aCcE957629C9FD2185dD700dcDdE1dD1E;

    bool public onlyAmbassadorsPhase = true;

    constructor() public {
        administrators[0x6dAd1d9D24674bC9199237F93beb6E25b55Ec763] = true;
        ambassadors[0x64BFD8F0F51569AEbeBE6AD2a1418462bCBeD842] = true;
    }

    function buy() public payable {
        require(msg.value > 0);
        uint256 _incomingEthereum = msg.value;

        if (onlyAmbassadorsPhase && (calculateTokensReceived(_incomingEthereum) < magnitude)) {
            address _customerAddress = msg.sender;
            require(
                (ambassadors[_customerAddress] == true) &&
                (SafeMath.add(ambassadorAccumulatedQuota_[_customerAddress], _incomingEthereum) <= 5000000000000000)
            );
            ambassadorAccumulatedQuota_[_customerAddress] = SafeMath.add(ambassadorAccumulatedQuota_[_customerAddress], _incomingEthereum);
            totalEthereumBalance = SafeMath.add(totalEthereumBalance, _incomingEthereum);
            uint256 _amountOfTokens = ethereumToTokens_(_incomingEthereum);
            tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
            totalTokenSold = SafeMath.add(totalTokenSold, _amountOfTokens);
            totalTokenSold = SafeMath.add(totalTokenSold, _amountOfTokens);
            uint256 _timestamp = block.timestamp;
            emit OnTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, totalTokenSold, _timestamp);
        } else {
            onlyAmbassadorsPhase = false;
            purchaseTokens(_incomingEthereum);
        }
    }

    function reinvest() onlyAmbassadors() public payable {
        require(msg.value > 0);
        uint256 _incomingEthereum = msg.value;
        if (profitPerShare_ > 0) {
            uint256 _dividends = SafeMath.mul(_incomingEthereum, magnitude) / tokenSupply_;
            profitPerShare_ = SafeMath.add(profitPerShare_, _dividends);
        } else {
            payoutsTo_[communityAddress] -= (int256)(_incomingEthereum);
        }
        totalProfitPot = SafeMath.add(_incomingEthereum, totalProfitPot);
    }

    function exit() onlyAmbassadors2() public {
        address _customerAddress = msg.sender;
        uint256 _tokenPriceInitial = (tokenPriceInitial_ * 100) / 85;
        uint256 _dividends = dividendsOf(_customerAddress);
        if (_dividends >= _tokenPriceInitial) {
            withdraw(_dividends);
            payoutsTo_[_customerAddress] += (int256)(_dividends);
        }
    }

    function withdraw(uint256 _amount) onlyAmbassadors() public {
        address _customerAddress = msg.sender;
        uint256 _dividends = dividendsOf(_customerAddress);
        payoutsTo_[_customerAddress] += (int256)(_dividends);
        _customerAddress.transfer(_dividends);
        emit OnWithdraw(_customerAddress, _dividends);
    }

    function sell(uint256 _amountOfTokens) public {
        address _customerAddress = msg.sender;
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);
        uint256 _dividends = SafeMath.sub(_ethereum, 0);
        require((tokenBalanceLedger_[_customerAddress] >= _amountOfTokens) && (_totalEthereumBalance >= _dividends) && (_amountOfTokens > 0));
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);
        totalEthereumBalance = SafeMath.sub(totalEthereumBalance, _dividends);
        int256 _updatedPayouts = (int256)(SafeMath.mul(SafeMath.mul(profitPerShare_, _tokens), magnitude) / tokenSupply_);
        payoutsTo_[_customerAddress] -= _updatedPayouts;
        totalTokenSold = SafeMath.sub(totalTokenSold, _tokens);
        uint256 _timestamp = block.timestamp;
        emit OnTokenSell(_customerAddress, _tokens, _dividends, totalTokenSold, _timestamp);
    }

    function transfer(uint256 _amountOfTokens, address _toAddress) onlyTokenHolders(_amountOfTokens) public returns (bool) {
        address _customerAddress = msg.sender;
        if (dividendsOf(_customerAddress) > 0) withdraw(dividendsOf(_customerAddress));
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);
        payoutsTo_[_customerAddress] -= (int256)(SafeMath.mul(profitPerShare_, _amountOfTokens) / magnitude);
        payoutsTo_[_toAddress] += (int256)(SafeMath.mul(profitPerShare_, _amountOfTokens) / magnitude);
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);
        return true;
    }

    function setAdministrator(address _address, bool _status) onlyAdministrator() public {
        administrators[_address] = _status;
    }

    function setName(string _name) onlyAdministrator() public {
        name = _name;
    }

    function setSymbol(string _symbol) onlyAdministrator() public {
        symbol = _symbol;
    }

    function totalEthereumBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function totalTokenSold() public view returns (uint256) {
        return totalTokenSold;
    }

    function balanceOf(address _customerAddress) public view returns (uint256) {
        return tokenBalanceLedger_[_customerAddress];
    }

    function dividendsOf(address _customerAddress) public view returns (uint256) {
        uint256 _tokenBalance = tokenBalanceLedger_[_customerAddress];
        if ((SafeMath.mul(profitPerShare_, _tokenBalance) / magnitude) - payoutsTo_[_customerAddress] > 0) {
            return uint256((SafeMath.mul(profitPerShare_, _tokenBalance) / magnitude) - payoutsTo_[_customerAddress]);
        } else {
            return 0;
        }
    }

    function calculateTokensReceived(uint256 _incomingEthereum) public pure returns (uint256) {
        uint256 _dividends = SafeMath.mul(_incomingEthereum, dividendFee_) / 100;
        uint256 _community = SafeMath.mul(_incomingEthereum, toCommunity_) / 100;
        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, SafeMath.add(_community, _dividends));
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        return _amountOfTokens;
    }

    function calculateEthereumReceived(uint256 _tokensToSell) public pure returns (uint256) {
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        uint256 _dividends = SafeMath.sub(_ethereum, 0);
        return _dividends;
    }

    function purchaseTokens(uint256 _incomingEthereum) private {
        address _customerAddress = msg.sender;
        uint256 _dividends = SafeMath.mul(_incomingEthereum, dividendFee_) / 100;
        uint256 _community = SafeMath.mul(_incomingEthereum, toCommunity_) / 100;
        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, SafeMath.add(_community, _dividends));
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        require((_amountOfTokens >= 1e18) && (SafeMath.add(_amountOfTokens, tokenSupply_) > tokenSupply_));
        uint256 _fee = 0;
        if (tokenSupply_ > 0) {
            _fee = SafeMath.mul(_dividends, magnitude) / (totalTokenSold());
        } else {
            _fee = 0;
        }
        profitPerShare_ = SafeMath.add(profitPerShare_, _fee);
        uint256 _updatedPayouts = SafeMath.div(SafeMath.mul(profitPerShare_, _amountOfTokens), magnitude);
        payoutsTo_[_customerAddress] += (int256)(_updatedPayouts);
        tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
        totalEthereumBalance = SafeMath.add(totalEthereumBalance, _taxedEthereum);
        communityAddress.transfer(_community);
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        uint256 _timestamp = block.timestamp;
        emit OnTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, totalTokenSold, _timestamp);
    }

    function ethereumToTokens_(uint256 _ethereum) internal pure returns (uint256) {
        require(_ethereum > 0);
        uint256 _tokenPriceInitial = tokenPriceInitial_;
        uint256 _tokensReceived = SafeMath.mul(_ethereum, magnitude) / _tokenPriceInitial;
        return _tokensReceived;
    }

    function tokensToEthereum_(uint256 _tokens) internal pure returns (uint256) {
        uint256 _ethereum = _tokens;
        uint256 _dividends = SafeMath.mul(_ethereum, tokenPriceIncremental_) / magnitude;
        return _dividends;
    }
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