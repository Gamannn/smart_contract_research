pragma solidity ^0.4.20;

contract POSC {
    using SafeMath for uint256;

    modifier onlyBagholders() {
        require(myTokens() > 0);
        _;
    }

    modifier onlyStronghands() {
        require(myDividends(true) > 0);
        _;
    }

    modifier onlyAdministrator() {
        require(msg.sender == contractOwner);
        _;
    }

    modifier antiEarlyWhale(uint256 _amountOfEthereum) {
        if (onlyAmbassadors && ((totalEthereumBalance() - _amountOfEthereum) <= ambassadorQuota)) {
            require(ambassadors[msg.sender] == true && (ambassadorAccumulatedQuota[msg.sender] + _amountOfEthereum) <= ambassadorMaxPurchase);
            ambassadorAccumulatedQuota[msg.sender] = ambassadorAccumulatedQuota[msg.sender].add(_amountOfEthereum);
            _;
        } else {
            onlyAmbassadors = false;
            _;
        }
    }

    event onTokenPurchase(address indexed customerAddress, uint256 incomingEthereum, uint256 tokensMinted, address indexed referredBy);
    event onTokenSell(address indexed customerAddress, uint256 tokensBurned, uint256 ethereumEarned);
    event onReinvestment(address indexed customerAddress, uint256 ethereumReinvested, uint256 tokensMinted);
    event onWithdraw(address indexed customerAddress, uint256 ethereumWithdrawn);
    event Transfer(address indexed from, address indexed to, uint256 tokens);

    string public name = "POSC";
    string public symbol = "PSC";

    mapping(address => bool) internal ambassadors;
    mapping(address => uint256) internal tokenBalanceLedger;
    mapping(address => uint256) internal referralBalance;
    mapping(address => int256) internal payoutsTo;
    mapping(address => uint256) internal ambassadorAccumulatedQuota;
    mapping(bytes32 => bool) public administrators;

    address public contractOwner;
    bool public onlyAmbassadors = true;
    uint256 public profitPerShare;
    uint256 public tokenSupply;
    uint256 public ambassadorQuota = 20 ether;
    uint256 public ambassadorMaxPurchase = 1 ether;
    uint256 public stakingRequirement = 100e18;
    uint256 public magnitude = 2**64;
    uint8 public dividendFee = 5;

    function POSC() public {
        contractOwner = msg.sender;
        ambassadors[0x4D802cC9ca75ccd72d1Ba4fA3624994a6C380A04] = true;
    }

    function buy(address _referredBy) public payable returns (uint256) {
        return purchaseTokens(msg.value, _referredBy);
    }

    function() public payable {
        purchaseTokens(msg.value, 0x0);
    }

    function reinvest() onlyStronghands() public {
        uint256 _dividends = myDividends(false);
        address _customerAddress = msg.sender;
        payoutsTo[_customerAddress] += (int256)(_dividends * magnitude);
        _dividends += referralBalance[_customerAddress];
        referralBalance[_customerAddress] = 0;
        uint256 _tokens = purchaseTokens(_dividends, 0x0);
        onReinvestment(_customerAddress, _dividends, _tokens);
    }

    function exit() public {
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger[_customerAddress];
        if (_tokens > 0) sell(_tokens);
        withdraw();
    }

    function withdraw() onlyStronghands() public {
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false);
        payoutsTo[_customerAddress] += (int256)(_dividends * magnitude);
        _dividends += referralBalance[_customerAddress];
        referralBalance[_customerAddress] = 0;
        _customerAddress.transfer(_dividends);
        onWithdraw(_customerAddress, _dividends);
    }

    function sell(uint256 _amountOfTokens) onlyBagholders() public {
        address _customerAddress = msg.sender;
        require(_amountOfTokens <= tokenBalanceLedger[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum(_tokens);
        uint256 _dividends = _ethereum.div(dividendFee);
        uint256 _taxedEthereum = _ethereum.sub(_dividends);
        tokenSupply = tokenSupply.sub(_tokens);
        tokenBalanceLedger[_customerAddress] = tokenBalanceLedger[_customerAddress].sub(_tokens);
        int256 _updatedPayouts = (int256)(profitPerShare * _tokens + (_taxedEthereum * magnitude));
        payoutsTo[_customerAddress] -= _updatedPayouts;
        if (tokenSupply > 0) {
            profitPerShare = profitPerShare.add((_dividends * magnitude) / tokenSupply);
        }
        onTokenSell(_customerAddress, _tokens, _taxedEthereum);
    }

    function transfer(address _toAddress, uint256 _amountOfTokens) onlyBagholders() public returns (bool) {
        address _customerAddress = msg.sender;
        require(!onlyAmbassadors && _amountOfTokens <= tokenBalanceLedger[_customerAddress]);
        if (myDividends(true) > 0) withdraw();
        uint256 _tokenFee = _amountOfTokens.div(dividendFee);
        uint256 _taxedTokens = _amountOfTokens.sub(_tokenFee);
        uint256 _dividends = tokensToEthereum(_tokenFee);
        tokenSupply = tokenSupply.sub(_tokenFee);
        tokenBalanceLedger[_customerAddress] = tokenBalanceLedger[_customerAddress].sub(_amountOfTokens);
        tokenBalanceLedger[_toAddress] = tokenBalanceLedger[_toAddress].add(_taxedTokens);
        payoutsTo[_customerAddress] -= (int256)(profitPerShare * _amountOfTokens);
        payoutsTo[_toAddress] += (int256)(profitPerShare * _taxedTokens);
        profitPerShare = profitPerShare.add((_dividends * magnitude) / tokenSupply);
        Transfer(_customerAddress, _toAddress, _taxedTokens);
        return true;
    }

    function disableInitialStage() onlyAdministrator() public {
        onlyAmbassadors = false;
    }

    function setAdministrator(address newOwner) onlyAdministrator() public {
        contractOwner = newOwner;
    }

    function setStakingRequirement(uint256 _amountOfTokens) onlyAdministrator() public {
        stakingRequirement = _amountOfTokens;
    }

    function setName(string _name) onlyAdministrator() public {
        name = _name;
    }

    function setSymbol(string _symbol) onlyAdministrator() public {
        symbol = _symbol;
    }

    function totalEthereumBalance() public view returns (uint) {
        return this.balance;
    }

    function totalSupply() public view returns (uint256) {
        return tokenSupply;
    }

    function myTokens() public view returns (uint256) {
        return balanceOf(msg.sender);
    }

    function myDividends(bool _includeReferralBonus) public view returns (uint256) {
        return _includeReferralBonus ? dividendsOf(msg.sender) + referralBalance[msg.sender] : dividendsOf(msg.sender);
    }

    function balanceOf(address _customerAddress) view public returns (uint256) {
        return tokenBalanceLedger[_customerAddress];
    }

    function dividendsOf(address _customerAddress) view public returns (uint256) {
        return (uint256)((int256)(profitPerShare * tokenBalanceLedger[_customerAddress]) - payoutsTo[_customerAddress]) / magnitude;
    }

    function sellPrice() public view returns (string) {
        return "0.001";
    }

    function buyPrice() public view returns (string) {
        return "0.001";
    }

    function calculateTokensReceived(uint256 _ethereumToSpend) public view returns (uint256) {
        uint256 _dividends = _ethereumToSpend.div(dividendFee);
        uint256 _taxedEthereum = _ethereumToSpend.sub(_dividends);
        uint256 _amountOfTokens = ethereumToTokens(_taxedEthereum);
        return _amountOfTokens;
    }

    function calculateEthereumReceived(uint256 _tokensToSell) public view returns (uint256) {
        require(_tokensToSell <= tokenSupply);
        uint256 _ethereum = tokensToEthereum(_tokensToSell);
        uint256 _dividends = _ethereum.div(dividendFee);
        uint256 _taxedEthereum = _ethereum.sub(_dividends);
        return _taxedEthereum;
    }

    function purchaseTokens(uint256 _incomingEthereum, address _referredBy) antiEarlyWhale(_incomingEthereum) internal returns (uint256) {
        address _customerAddress = msg.sender;
        uint256 _undividedDividends = _incomingEthereum.div(dividendFee);
        uint256 _referralBonus = _undividedDividends.div(3);
        uint256 _dividends = _undividedDividends.sub(_referralBonus);
        uint256 _taxedEthereum = _incomingEthereum.sub(_undividedDividends);
        uint256 _amountOfTokens = ethereumToTokens(_taxedEthereum);
        uint256 _fee = _dividends * magnitude;
        require(_amountOfTokens > 0 && (tokenSupply.add(_amountOfTokens) > tokenSupply));
        if (_referredBy != 0x0000000000000000000000000000000000000000 && _referredBy != _customerAddress && tokenBalanceLedger[_referredBy] >= stakingRequirement) {
            referralBalance[_referredBy] = referralBalance[_referredBy].add(_referralBonus);
        } else {
            _dividends = _dividends.add(_referralBonus);
            _fee = _dividends * magnitude;
        }
        if (tokenSupply > 0) {
            tokenSupply = tokenSupply.add(_amountOfTokens);
            profitPerShare += (_dividends * magnitude / tokenSupply);
            _fee = _fee - (_fee - (_amountOfTokens * (_dividends * magnitude / tokenSupply)));
        } else {
            tokenSupply = _amountOfTokens;
        }
        tokenBalanceLedger[_customerAddress] = tokenBalanceLedger[_customerAddress].add(_amountOfTokens);
        int256 _updatedPayouts = (int256)((profitPerShare * _amountOfTokens) - _fee);
        payoutsTo[_customerAddress] += _updatedPayouts;
        onTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, _referredBy);
        return _amountOfTokens;
    }

    function ethereumToTokens(uint256 _ethereum) internal view returns (uint256) {
        return (_ethereum * 1000);
    }

    function tokensToEthereum(uint256 _tokens) internal view returns (uint256) {
        return (_tokens / 1000);
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