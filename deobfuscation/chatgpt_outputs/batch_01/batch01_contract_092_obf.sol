```solidity
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
    modifier onlyTokenHolders {
        require(myTokens() > 0);
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == contractData.admin);
        _;
    }

    modifier onlyBoss2 {
        require(msg.sender == contractData.boss2);
        _;
    }

    modifier onlyBoss3 {
        require(msg.sender == contractData.boss3);
        _;
    }

    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) public referralBalance_;
    mapping(address => uint256) public repayBalance_;
    mapping(address => bool) public mayPassRepay;

    constructor() public {
        contractData.admin = msg.sender;
        mayPassRepay[contractData.boss1] = true;
        mayPassRepay[contractData.boss2] = true;
        mayPassRepay[contractData.boss3] = true;
    }

    function buy(address ref1, address ref2, address ref3) public payable returns (uint256) {
        require(msg.value >= contractData.minimalInvestment, "Value is below minimal investment.");
        require(contractData.saleOpen, "Sales stopped for the moment.");
        return purchaseTokens(msg.value, ref1, ref2, ref3);
    }

    function() external payable {
        require(msg.value >= contractData.minimalInvestment, "Value is below minimal investment.");
        require(contractData.saleOpen, "Sales stopped for the moment.");
        purchaseTokens(msg.value, address(0x0), address(0x0), address(0x0));
    }

    function reinvest() public {
        address customerAddress = msg.sender;
        uint256 amount = referralBalance_[customerAddress];
        require(amount > 0);
        referralBalance_[customerAddress] = 0;
        uint256 tokens = purchaseTokens(amount, address(0x0), address(0x0), address(0x0));
        emit OnReinvestment(customerAddress, amount, tokens, false, now);
    }

    function remoteReinvest(uint256 amount) public {
        if (IRemoteWallet(contractData.refBase).invest(msg.sender, address(this), amount, 4)) {
            uint256 tokens = purchaseTokens(amount, address(0x0), address(0x0), address(0x0));
            emit OnReinvestment(msg.sender, amount, tokens, true, now);
        }
    }

    function fund() public payable {
        emit OnFund(msg.sender, msg.value, now);
    }

    function exit() public {
        address customerAddress = msg.sender;
        uint256 repayAmount = repayBalance_[customerAddress];
        if (repayAmount > 0) getRepay();
        withdraw();
    }

    function withdraw() public {
        address payable customerAddress = msg.sender;
        uint256 amount = referralBalance_[customerAddress];
        require(amount > 0);
        referralBalance_[customerAddress] = 0;
        customerAddress.transfer(amount);
        emit OnWithdraw(customerAddress, amount, now);
    }

    function getRepay() public {
        address payable customerAddress = msg.sender;
        uint256 repayAmount = repayBalance_[customerAddress];
        require(repayAmount > 0);
        repayBalance_[customerAddress] = 0;
        uint256 tokens = tokenBalanceLedger_[customerAddress];
        tokenBalanceLedger_[customerAddress] = 0;
        contractData.tokenSupply_ = contractData.tokenSupply_ - tokens;
        customerAddress.transfer(repayAmount);
        emit OnGotRepay(customerAddress, repayAmount, now);
    }

    function myTokens() public view returns (uint256) {
        address customerAddress = msg.sender;
        return tokenBalanceLedger_[customerAddress];
    }

    function purchaseTokens(uint256 incomingEthereum, address ref1, address ref2, address ref3) internal returns (uint256) {
        address customerAddress = msg.sender;
        uint8 totalReferralFee = contractData.refLevel1_ + contractData.refLevel2_ + contractData.refLevel3_;
        require(totalReferralFee <= 99);
        uint256[7] memory uIntValues = [
            incomingEthereum * totalReferralFee / 100,
            0,
            0,
            0,
            0,
            0,
            0
        ];
        uIntValues[1] = uIntValues[0] * contractData.refLevel1_ / totalReferralFee;
        uIntValues[2] = uIntValues[0] * contractData.refLevel2_ / totalReferralFee;
        uIntValues[3] = uIntValues[0] * contractData.refLevel3_ / totalReferralFee;
        uint256 taxedEthereum = incomingEthereum - uIntValues[0];
        uint256 amountOfTokens = ethereumToTokens_(incomingEthereum);
        require(amountOfTokens > 0);

        if (ref1 != address(0x0) && tokenBalanceLedger_[ref1] * contractData.tokenPrice >= contractData.stakingRequirement) {
            if (contractData.refBase == address(0x0)) {
                referralBalance_[ref1] += uIntValues[1];
            } else {
                ICustomersFundable(contractData.refBase).fundCustomer.value(uIntValues[1])(ref1, 1);
                uIntValues[4] = uIntValues[1];
            }
        } else {
            referralBalance_[contractData.boss1] += uIntValues[1];
            ref1 = address(0x0);
        }

        if (ref2 != address(0x0) && tokenBalanceLedger_[ref2] * contractData.tokenPrice >= contractData.stakingRequirement) {
            if (contractData.refBase == address(0x0)) {
                referralBalance_[ref2] += uIntValues[2];
            } else {
                ICustomersFundable(contractData.refBase).fundCustomer.value(uIntValues[2])(ref2, 2);
                uIntValues[5] = uIntValues[2];
            }
        } else {
            referralBalance_[contractData.boss1] += uIntValues[2];
            ref2 = address(0x0);
        }

        if (ref3 != address(0x0) && tokenBalanceLedger_[ref3] * contractData.tokenPrice >= contractData.stakingRequirement) {
            if (contractData.refBase == address(0x0)) {
                referralBalance_[ref3] += uIntValues[3];
            } else {
                ICustomersFundable(contractData.refBase).fundCustomer.value(uIntValues[3])(ref3, 3);
                uIntValues[6] = uIntValues[3];
            }
        } else {
            referralBalance_[contractData.boss1] += uIntValues[3];
            ref3 = address(0x0);
        }

        referralBalance_[contractData.boss2] += taxedEthereum;
        contractData.tokenSupply_ += amountOfTokens;
        tokenBalanceLedger_[customerAddress] += amountOfTokens;
        emit OnTokenPurchase(customerAddress, incomingEthereum, amountOfTokens, ref1, ref2, ref3, uIntValues[4], uIntValues[5], uIntValues[6], now);
        return amountOfTokens;
    }

    function ethereumToTokens_(uint256 ethereum) public pure returns (uint256) {
        uint256 tokensReceived = ethereum * 1e18 / contractData.tokenPrice;
        return tokensReceived;
    }

    function tokensToEthereum_(uint256 tokens) public pure returns (uint256) {
        uint256 etherReceived = tokens / contractData.tokenPrice * 1e18;
        return etherReceived;
    }

    function mint(address customerAddress, uint256 amount) public onlyBoss3 {
        contractData.tokenSupply_ += amount;
        tokenBalanceLedger_[customerAddress] += amount;
        emit OnMint(customerAddress, amount, now);
    }

    function setRefBonus(uint8 level1, uint8 level2, uint8 level3, uint256 minInvest, uint256 staking) public {
        require(msg.sender == contractData.boss3 || msg.sender == contractData.admin);
        contractData.refLevel1_ = level1;
        contractData.refLevel2_ = level2;
        contractData.refLevel3_ = level3;
        contractData.minimalInvestment = minInvest;
        contractData.stakingRequirement = staking;
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
        if (contractData.refBase == address(0x0)) {
            referralBalance_[customerAddress] += msg.value;
        } else {
            ICustomersFundable(contractData.refBase).fundCustomer.value(msg.value)(msg.sender, 5);
        }
        emit OnInterestPassed(customerAddress, msg.value, ethRate, rate, now);
    }

    function saleStop() public onlyAdmin {
        contractData.saleOpen = false;
        emit OnSaleStop(now);
    }

    function saleStart() public onlyAdmin {
        contractData.saleOpen = true;
        emit OnSaleStart(now);
    }

    function deposeBoss3(address newBoss3) public onlyAdmin {
        emit OnBoss3Deposed(contractData.boss3, newBoss3, now);
        contractData.boss3 = newBoss3;
    }

    function setRefBase(address newRefBase) public onlyAdmin {
        emit OnRefBaseSet(contractData.refBase, newRefBase, now);
        contractData.refBase = newRefBase;
    }

    function seize(address customerAddress, address receiver) public {
        require(msg.sender == contractData.boss1 || msg.sender == contractData.boss2);
        uint256 tokens = tokenBalanceLedger_[customerAddress];
        if (tokens > 0) {
            tokenBalanceLedger_[customerAddress] = 0;
            tokenBalanceLedger_[receiver] += tokens;
        }
        uint256 referralAmount = referralBalance_[customerAddress];
        if (referralAmount > 0) {
            referralBalance_[customerAddress] = 0;
            referralBalance_[receiver] += referralAmount;
        }
        uint256 repay = repayBalance_[customerAddress];
        if (repay > 0) {
            repayBalance_[customerAddress] = 0;
            referralBalance_[receiver] += repay;
        }
        emit OnSeize(customerAddress, receiver, tokens, referralAmount, repay, now);
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
    event OnSeize(address indexed customerAddress, address indexed receiver, uint256 tokens, uint256 referralAmount, uint256 repayValue, uint256 timestamp);
    event OnFund(address indexed source, uint256 amount, uint256 timestamp);

    struct ContractData {
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
        uint8 decimals;
        string name;
        string symbol;
    }

    ContractData contractData = ContractData(
        address(0x0),
        true,
        0,
        0,
        2.5 ether,
        0.001 ether,
        2,
        3,
        9,
        0xf4632894bF968467091Dec1373CC1Bf5d15ef6B1,
        0xf43414ABb5a05c3037910506571e4333E16a4bf4,
        0xCa27fF938C760391E76b7aDa887288caF9BF6Ada,
        address(0),
        18,
        "NTS80",
        "NTS 80"
    );
}
```