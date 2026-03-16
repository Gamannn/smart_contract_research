```solidity
pragma solidity ^0.4.20;

contract AcceptsEighterbank {
    Eightherbank public tokenContract;
    
    function AcceptsEighterbank(address _tokenContract) public {
        tokenContract = Eightherbank(_tokenContract);
    }
    
    modifier onlyTokenContract {
        require(msg.sender == address(tokenContract));
        _;
    }
    
    function tokenFallback(address _from, uint256 _value, bytes _data) external returns (bool);
}

contract Eightherbank {
    // Modifiers
    modifier onlyBagholders() {
        require(myTokens() > 0);
        _;
    }
    
    modifier onlyStronghands() {
        require(myDividends(true) > 0);
        _;
    }
    
    modifier notContract() {
        require(msg.sender == tx.origin);
        _;
    }
    
    modifier onlyAdministrator() {
        require(msg.sender == config.administrator);
        _;
    }
    
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
    
    // Public variables
    string public name = "8therbank";
    string public symbol = "8TH";
    
    // Mappings
    mapping(address => bool) internal ambassadors_;
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) internal ambassadorAccumulatedQuota_;
    mapping(address => bool) public canAcceptTokens_;
    
    // Configuration structure
    struct Config {
        uint256 profitPerShare_;
        uint256 tokenSupply_;
        uint256 ACTIVATION_TIME;
        bool onlyAmbassadors;
        uint256 ambassadorQuota_;
        uint256 ambassadorMaxPurchase_;
        address devFeeAddress;
        address promoFeeAddress;
        address partnerFeeAddress;
        address serverFeeAddress;
        uint256 stakingRequirement;
        uint256 magnitude;
        uint256 tokenPriceInitial_;
        uint8 refferalFee_;
        uint8 transferFee_;
        uint8 dividendFee_;
        uint8 decimals;
        address administrator;
    }
    
    Config config = Config(
        0,
        0,
        1574013600,
        true,
        100 ether,
        1 ether,
        msg.sender,
        0xE377f23F3C2238FE9EB59776549Ec785CbF42e1b,
        0xdde972dc6B0fBE22B575a1066eF038fd7A60Fd98,
        msg.sender,
        1800e18,
        2**64,
        0.00005556 ether,
        33,
        5,
        10,
        18,
        address(0)
    );
    
    // Anti-early whale modifier
    modifier antiEarlyWhale(uint256 _amountOfEthereum) {
        if (now >= config.ACTIVATION_TIME) {
            config.onlyAmbassadors = false;
        }
        
        if (config.onlyAmbassadors) {
            require(
                (ambassadors_[msg.sender] == true && 
                (ambassadorAccumulatedQuota_[msg.sender] + _amountOfEthereum) <= config.ambassadorMaxPurchase_)
            );
            ambassadorAccumulatedQuota_[msg.sender] = SafeMath.add(ambassadorAccumulatedQuota_[msg.sender], _amountOfEthereum);
            _;
        } else {
            config.onlyAmbassadors = false;
            _;
        }
    }
    
    // Constructor
    function Eightherbank() public {
        config.administrator = msg.sender;
        name = "8therbank";
        symbol = "8TH";
        config.decimals = 18;
        
        // Set ambassadors
        ambassadors_[0x60bc6fa49588bbB9e3273E1fc421f383393E2fc3] = true;
        ambassadors_[0x074F21a36217d7615d0202faA926aEFEBB5a9999] = true;
        ambassadors_[0xEe54D208f62368B4efFe176CB548A317dcAe963F] = true;
        ambassadors_[0x843f2C19bc6df9E32B482E2F9ad6C078001088b1] = true;
        ambassadors_[0xE377f23F3C2238FE9EB59776549Ec785CbF42e1b] = true;
        ambassadors_[0xACa4E2730b57dA82476D6d1fA2a85A8f686F108b] = true;
        ambassadors_[0x24B23bB643082026227e945C7833B81426057b10] = true;
        ambassadors_[0x5138240E96360ad64010C27eB0c685A8b2eDE4F2] = true;
        ambassadors_[0xAFC1a5cB605bBd1aa5F6415458BC45cD7554d08b] = true;
        ambassadors_[0xAA7A7C2DECB180f68F11E975e6D92B5Dc06083A6] = true;
        ambassadors_[0x73018870D10173ae6F71Cac3047ED3b6d175F274] = true;
        ambassadors_[0x53e1eB6a53d9354d43155f76861C5a2AC80ef361] = true;
        ambassadors_[0xCdB84A89BB3D2ad99a39AfAd0068DC11B8280FbC] = true;
        ambassadors_[0xF1018aCEAd986C97BccffaC40246D701E7b6C58b] = true;
        ambassadors_[0x340570F0fe147f60C259753A7491059eB6526c2D] = true;
        ambassadors_[0xbE57E8Cde352a6a55B103f826AC8c324aCD68aDf] = true;
        ambassadors_[0x05aF7f355E914197FB3548c7Ab67887dD187D808] = true;
        ambassadors_[0x190A2409fc6434483D4c2CAb804E75e3Bc5ebFa6] = true;
        ambassadors_[0x52DC007F9D85c4949AF4Db4E7863e48f7f4Fe93D] = true;
        ambassadors_[0x92421097F5a6b24B45e94A5297e220622DCdbd5a] = true;
    }
    
    // Public functions
    function buyFor(address _customerAddress, address _referredBy) public payable returns (uint256) {
        return purchaseTokens(_customerAddress, msg.value, _referredBy);
    }
    
    function buy(address _referredBy) public payable returns(uint256) {
        return purchaseTokens(msg.sender, msg.value, _referredBy);
    }
    
    function() payable public {
        purchaseTokens(msg.sender, msg.value, 0x0);
    }
    
    function reinvest() onlyStronghands() public {
        uint256 _dividends = myDividends(false);
        address _customerAddress = msg.sender;
        
        payoutsTo_[_customerAddress] += (int256) (_dividends * config.magnitude);
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        
        uint256 _tokens = purchaseTokens(_customerAddress, _dividends, 0x0);
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
        
        payoutsTo_[_customerAddress] += (int256) (_dividends * config.magnitude);
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
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, config.dividendFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        
        config.tokenSupply_ = SafeMath.sub(config.tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);
        
        int256 _updatedPayouts = (int256) (config.profitPerShare_ * _tokens + (_taxedEthereum * config.magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;
        
        if (config.tokenSupply_ > 0) {
            config.profitPerShare_ = SafeMath.add(config.profitPerShare_, (_dividends * config.magnitude) / config.tokenSupply_);
        }
        
        emit onTokenSell(_customerAddress, _tokens, _taxedEthereum);
    }
    
    function transfer(address _toAddress, uint256 _amountOfTokens) onlyBagholders() public returns(bool) {
        address _customerAddress = msg.sender;
        require(!config.onlyAmbassadors && _amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        
        uint256 _tokenFee = SafeMath.div(SafeMath.mul(_amountOfTokens, config.transferFee_), 100);
        uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
        uint256 _dividends = tokensToEthereum_(_tokenFee);
        
        config.tokenSupply_ = SafeMath.sub(config.tokenSupply_, _tokenFee);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _taxedTokens);
        
        payoutsTo_[_customerAddress] -= (int256) (config.profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (config.profitPerShare_ * _taxedTokens);
        
        config.profitPerShare_ = SafeMath.add(config.profitPerShare_, (_dividends * config.magnitude) / config.tokenSupply_);
        
        emit Transfer(_customerAddress, _toAddress, _taxedTokens);
        return true;
    }
    
    function transferAndCall(address _to, uint256 _value, bytes _data) external returns (bool) {
        require(_to != address(0));
        require(canAcceptTokens_[_to] == true);
        require(transfer(_to, _value));
        
        if (isContract(_to)) {
            AcceptsEighterbank receiver = AcceptsEighterbank(_to);
            require(receiver.tokenFallback(msg.sender, _value, _data));
        }
        
        return true;
    }
    
    function isContract(address _addr) private constant returns (bool is_contract) {
        uint length;
        assembly {
            length := extcodesize(_addr)
        }
        return length > 0;
    }
    
    // Administrator functions
    function disableInitialStage() onlyAdministrator() public {
        config.onlyAmbassadors = false;
    }
    
    function changePartner(address _partnerAddress) public {
        require(config.administrator == msg.sender);
        config.partnerFeeAddress = _partnerAddress;
    }
    
    function changePromoter(address _promotorAddress) public {
        require(config.administrator == msg.sender);
        config.promoFeeAddress = _promotorAddress;
    }
    
    function changeDev(address _devAddress) public {
        require(config.administrator == msg.sender);
        config.devFeeAddress = _devAddress;
    }
    
    function setAdministrator(address newowner) onlyAdministrator() public {
        config.administrator = newowner;
    }
    
    function setStakingRequirement(uint256 _amountOfTokens) onlyAdministrator() public {
        config.stakingRequirement = _amountOfTokens;
    }
    
    function setCanAcceptTokens(address _address, bool _value) onlyAdministrator() public {
        canAcceptTokens_[_address] = _value;
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
    
    function totalTokenSupply() public view returns(uint256) {
        return config.tokenSupply_;
    }
    
    function myTokens() public view returns(uint256) {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }
    
    function myDividends(bool _includeReferralBonus) public view returns(uint256) {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress);
    }
    
    function balanceOf(address _customerAddress) view public returns(uint256) {
        return tokenBalanceLedger_[_customerAddress];
    }
    
    function dividendsOf(address _customerAddress) view public returns(uint256) {
        return (uint256) ((int256)(config.profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / config.magnitude;
    }
    
    function sellPrice() public view returns(string) {
        return "0.00005";
    }
    
    function buyPrice() public view returns(string) {
        return "0.00005556";
    }
    
    function calculateTokensReceived(uint256 _ethereumToSpend) public view returns(uint256) {
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereumToSpend, config.dividendFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(_ethereumToSpend, _dividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        return _amountOfTokens;
    }
    
    function calculateEthereumReceived(uint256 _tokensToSell) public view returns(uint256) {
        require(_tokensToSell <= config.tokenSupply_);
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, config.dividendFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        return _taxedEthereum;
    }
    
    // Internal functions
    function purchaseTokens(address _customerAddress, uint256 _incomingEthereum, address _referredBy) 
        antiEarlyWhale(_incomingEthereum) 
        internal 
        returns(uint256) 
    {
        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingEthereum, config.dividendFee_), 100);
        uint256 _referralBonus = SafeMath.div(SafeMath.mul(_undividedDividends, config.refferalFee_), 100);
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, _undividedDividends);
        
        // Fee distribution
        _taxedEthereum = SafeMath.sub(_taxedEthereum, SafeMath.div(SafeMath.mul(_incomingEthereum, 1), 100)); // 1% server fee
        _taxedEthereum = SafeMath.sub(_taxedEthereum, SafeMath.div(SafeMath.mul(_incomingEthereum, 1), 100)); // 1% partner fee
        _taxedEthereum = SafeMath.sub(_taxedEthereum, SafeMath.div(SafeMath.mul(_incomingEthereum, 1), 200)); // 0.5% promo fee
        _taxedEthereum = SafeMath.sub(_taxedEthereum, SafeMath.div(SafeMath.mul(_incomingEthereum, 1), 200)); // 0.5% dev fee
        
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        uint256 _fee = _dividends * config.magnitude;
        
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens, config.tokenSupply_) > config.tokenSupply_));
        
        if (_referredBy != 0x0000000000000000000000000000000000000000 && 
            _referredBy != _customerAddress && 
            tokenBalanceLedger_[_referredBy] >= config.stakingRequirement) 
        {
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
        } else {
            _dividends = SafeMath.add(_dividends, _referralBonus);
            _fee = _dividends * config.magnitude;
        }
        
        if (config.tokenSupply_ > 0) {
           