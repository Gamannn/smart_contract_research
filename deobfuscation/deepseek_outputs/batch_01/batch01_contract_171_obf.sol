```solidity
pragma solidity ^0.4.20;

contract POSC {
    // Events
    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address indexed referredBy
    );
    
    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 ethereumEarned
    );
    
    event onReinvestment(
        address indexed customerAddress,
        uint256 ethereumReinvested,
        uint256 tokensMinted
    );
    
    event onWithdraw(
        address indexed customerAddress,
        uint256 ethereumWithdrawn
    );
    
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );
    
    // Modifiers
    modifier onlyBagholders() {
        require(myTokens() > 0);
        _;
    }
    
    modifier onlyStronghands() {
        require(myDividends(true) > 0);
        _;
    }
    
    modifier onlyAdministrator() {
        require(msg.sender == administrator);
        _;
    }
    
    modifier antiEarlyWhale(uint256 _amountOfEthereum) {
        address _customerAddress = msg.sender;
        
        if (onlyAmbassadors && ((totalEthereumBalance() - _amountOfEthereum) <= ambassadorQuota_)) {
            require(
                ambassadors_[_customerAddress] == true &&
                (ambassadorAccumulatedQuota_[_customerAddress] + _amountOfEthereum) <= ambassadorMaxPurchase_
            );
            ambassadorAccumulatedQuota_[_customerAddress] = SafeMath.add(
                ambassadorAccumulatedQuota_[_customerAddress],
                _amountOfEthereum
            );
            _;
        } else {
            onlyAmbassadors = false;
            _;
        }
    }
    
    // Public variables
    string public name = "POSC";
    string public symbol = "PSC";
    
    // Internal mappings
    mapping(address => bool) internal ambassadors_;
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) internal ambassadorAccumulatedQuota_;
    mapping(bytes32 => bool) public administrators;
    
    // Contract state
    bool public onlyAmbassadors = true;
    uint256 public profitPerShare_ = 0;
    uint256 public tokenSupply_ = 0;
    uint256 public ambassadorQuota_ = 20 ether;
    uint256 public ambassadorMaxPurchase_ = 1 ether;
    uint256 public stakingRequirement = 100e18;
    uint256 constant magnitude = 2**64;
    uint256 constant tokenPriceInitial_ = 0.0000001 ether;
    uint8 constant dividendFee_ = 5;
    uint8 constant decimals = 18;
    address public administrator;
    
    function POSC() public {
        administrator = msg.sender;
        name = "POSC";
        symbol = "PSC";
        ambassadors_[0x4D802cC9ca75ccd72d1Ba4fA3624994a6C380A04] = true;
    }
    
    function buy(address _referredBy) public payable returns(uint256) {
        return purchaseTokens(msg.value, _referredBy);
    }
    
    function() payable public {
        purchaseTokens(msg.value, 0x0);
    }
    
    function reinvest() onlyStronghands() public {
        uint256 _dividends = myDividends(false);
        address _customerAddress = msg.sender;
        
        payoutsTo_[_customerAddress] += (int256)(_dividends * magnitude);
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        
        uint256 _tokens = purchaseTokens(_dividends, 0x0);
        emit onReinvestment(_customerAddress, _dividends, _tokens);
    }
    
    function exit() public {
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        
        if (_tokens > 0) {
            sell(_tokens);
        }
        withdraw();
    }
    
    function withdraw() onlyStronghands() public {
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false);
        
        payoutsTo_[_customerAddress] += (int256)(_dividends * magnitude);
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        
        _customerAddress.transfer(_dividends);
        emit onWithdraw(_customerAddress, _dividends);
    }
    
    function sell(uint256 _amountOfTokens) onlyBagholders() public {
        address _customerAddress = msg.sender;
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);
        
        int256 _updatedPayouts = (int256)(profitPerShare_ * _tokens + (_taxedEthereum * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;
        
        if (tokenSupply_ > 0) {
            profitPerShare_ = SafeMath.add(
                profitPerShare_,
                (_dividends * magnitude) / tokenSupply_
            );
        }
        
        emit onTokenSell(_customerAddress, _tokens, _taxedEthereum);
    }
    
    function transfer(address _toAddress, uint256 _amountOfTokens) onlyBagholders() public returns(bool) {
        address _customerAddress = msg.sender;
        require(!onlyAmbassadors && _amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        
        if (myDividends(true) > 0) {
            withdraw();
        }
        
        uint256 _tokenFee = SafeMath.div(SafeMath.mul(_amountOfTokens, dividendFee_), 100);
        uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
        uint256 _dividends = tokensToEthereum_(_tokenFee);
        
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokenFee);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _taxedTokens);
        
        payoutsTo_[_customerAddress] -= (int256)(profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256)(profitPerShare_ * _taxedTokens);
        
        profitPerShare_ = SafeMath.add(
            profitPerShare_,
            (_dividends * magnitude) / tokenSupply_
        );
        
        emit Transfer(_customerAddress, _toAddress, _taxedTokens);
        return true;
    }
    
    function disableInitialStage() onlyAdministrator() public {
        onlyAmbassadors = false;
    }
    
    function setAdministrator(address newowner) onlyAdministrator() public {
        administrator = newowner;
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
    
    // View functions
    function totalEthereumBalance() public view returns(uint) {
        return this.balance;
    }
    
    function totalSupply() public view returns(uint256) {
        return tokenSupply_;
    }
    
    function myTokens() public view returns(uint256) {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }
    
    function myDividends(bool _includeReferralBonus) public view returns(uint256) {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? 
            dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : 
            dividendsOf(_customerAddress);
    }
    
    function balanceOf(address _customerAddress) view public returns(uint256) {
        return tokenBalanceLedger_[_customerAddress];
    }
    
    function dividendsOf(address _customerAddress) view public returns(uint256) {
        return (uint256)((int256)(profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }
    
    function sellPrice() public view returns(string) {
        return "0.001";
    }
    
    function buyPrice() public view returns(string) {
        return "0.001";
    }
    
    function calculateTokensReceived(uint256 _ethereumToSpend) public view returns(uint256) {
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereumToSpend, dividendFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(_ethereumToSpend, _dividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        return _amountOfTokens;
    }
    
    function calculateEthereumReceived(uint256 _tokensToSell) public view returns(uint256) {
        require(_tokensToSell <= tokenSupply_);
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        return _taxedEthereum;
    }
    
    // Internal functions
    function purchaseTokens(uint256 _incomingEthereum, address _referredBy) 
        antiEarlyWhale(_incomingEthereum) 
        internal 
        returns(uint256) 
    {
        address _customerAddress = msg.sender;
        
        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingEthereum, dividendFee_), 100);
        uint256 _referralBonus = SafeMath.div(SafeMath.mul(_undividedDividends, 3), 10);
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, _undividedDividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        uint256 _fee = _dividends * magnitude;
        
        require(
            _amountOfTokens > 0 && 
            SafeMath.add(_amountOfTokens, tokenSupply_) > tokenSupply_
        );
        
        if (
            _referredBy != 0x0000000000000000000000000000000000000000 &&
            _referredBy != _customerAddress &&
            tokenBalanceLedger_[_referredBy] >= stakingRequirement
        ) {
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
        } else {
            _dividends = SafeMath.add(_dividends, _referralBonus);
            _fee = _dividends * magnitude;
        }
        
        if (tokenSupply_ > 0) {
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
            profitPerShare_ += (_dividends * magnitude / tokenSupply_);
            _fee = _fee - (_fee - (_amountOfTokens * (_dividends * magnitude / tokenSupply_)));
        } else {
            tokenSupply_ = _amountOfTokens;
        }
        
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        
        int256 _updatedPayouts = (int256)((profitPerShare_ * _amountOfTokens) - _fee);
        payoutsTo_[_customerAddress] += _updatedPayouts;
        
        emit onTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, _referredBy);
        
        return _amountOfTokens;
    }
    
    function ethereumToTokens_(uint256 _ethereum) internal view returns(uint256) {
        return (_ethereum * 1000);
    }
    
    function tokensToEthereum_(uint256 _tokens) internal view returns(uint256) {
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
```