pragma solidity ^0.4.26;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
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

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = address(0xe21AC1CAE34c532a38B604669E18557B2d8840Fc);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract EKS is Ownable {
    using SafeMath for uint256;

    modifier isActivated {
        require(now >= ACTIVATION_TIME);
        _;
    }

    modifier onlyCustodian() {
        require(msg.sender == custodianAddress);
        _;
    }

    modifier onlyTokenHolders {
        require(myTokens() > 0);
        _;
    }

    modifier onlyDividendHolders {
        require(myDividends() > 0);
        _;
    }

    event onDistribute(
        address indexed customerAddress,
        uint256 price
    );

    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingETH,
        uint256 tokensMinted,
        uint timestamp
    );

    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 ethereumEarned,
        uint timestamp
    );

    event onRoll(
        address indexed customerAddress,
        uint256 ethereumRolled,
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

    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public withdrawals;

    bool public postLaunch;
    uint256 public totalDonation;
    uint256 public totalPlayer;
    uint256 public profitPerShare_;
    uint256 public tokenSupply_;
    uint256 public magnitude;
    uint256 public totalLaunchFundCollected;
    uint256 public totalFundCollected;
    address public distributionAddress;
    address public approvedAddress1;
    address public approvedAddress2;
    address public custodianAddress;
    address public maintenanceAddress;
    uint256 public maintenanceFee_;
    uint256 public tewkenaireFee_;
    uint256 public exitFee_;
    uint256 public transferFee_;
    uint256 public entryFee_;
    uint8 public decimals;
    string public symbol;
    string public name;
    uint256 public ACTIVATION_TIME;

    constructor() public {
        maintenanceAddress = address(0xe21AC1CAE34c532a38B604669E18557B2d8840Fc);
        custodianAddress = address(0x24B23bB643082026227e945C7833B81426057b10);
        distributionAddress = address(0xfE8D614431E5fea2329B05839f29B553b1Cb99A2);
        approvedAddress1 = distributionAddress;
        approvedAddress2 = distributionAddress;

        postLaunch = false;
        totalDonation = 0;
        totalPlayer = 0;
        profitPerShare_ = 0;
        tokenSupply_ = 0;
        magnitude = 2 ** 64;
        totalLaunchFundCollected = 0;
        totalFundCollected = 0;
        maintenanceFee_ = 10;
        tewkenaireFee_ = 10;
        exitFee_ = 10;
        transferFee_ = 1;
        entryFee_ = 10;
        decimals = 18;
        symbol = "STABLE";
        name = "Tewkenaire Stable";
        ACTIVATION_TIME = 1580688000;
    }

    function distribute() public payable returns (uint256) {
        require(msg.value > 0 && postLaunch == true);
        totalDonation += msg.value;
        profitPerShare_ = profitPerShare_.add((msg.value.mul(magnitude)).div(tokenSupply_));
        emit onDistribute(msg.sender, msg.value);
    }

    function distributeLaunchFund() public {
        require(totalLaunchFundCollected > 0 && postLaunch == false && now >= ACTIVATION_TIME + 24 hours);
        profitPerShare_ = profitPerShare_.add((totalLaunchFundCollected.mul(magnitude)).div(tokenSupply_));
        postLaunch = true;
    }

    function buy() public payable returns (uint256) {
        return purchaseTokens(msg.sender, msg.value);
    }

    function buyFor(address customerAddress) public payable returns (uint256) {
        return purchaseTokens(customerAddress, msg.value);
    }

    function() payable public {
        purchaseTokens(msg.sender, msg.value);
    }

    function roll() onlyDividendHolders public {
        address customerAddress = msg.sender;
        uint256 _dividends = myDividends();
        payoutsTo_[customerAddress] += (int256) (_dividends.mul(magnitude));
        uint256 _tokens = purchaseTokens(customerAddress, _dividends);
        emit onRoll(customerAddress, _dividends, _tokens);
    }

    function exit() external {
        address customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[customerAddress];
        if (_tokens > 0) {
            sell(_tokens);
        }
        withdraw();
    }

    function withdraw() onlyDividendHolders public {
        address customerAddress = msg.sender;
        uint256 _dividends = myDividends();
        payoutsTo_[customerAddress] += (int256) (_dividends.mul(magnitude));
        customerAddress.transfer(_dividends);
        withdrawals[customerAddress] += _dividends;
        emit onWithdraw(customerAddress, _dividends);
    }

    function sell(uint256 _amountOfTokens) onlyTokenHolders public {
        address customerAddress = msg.sender;
        require(_amountOfTokens <= tokenBalanceLedger_[customerAddress]);

        uint256 _undividedDividends = _amountOfTokens.mul(exitFee_).div(100);
        uint256 _maintenance = _undividedDividends.mul(maintenanceFee_).div(100);
        maintenanceAddress.transfer(_maintenance);
        uint256 _tewkenaire = _undividedDividends.mul(tewkenaireFee_).div(100);
        totalFundCollected += _tewkenaire;
        distributionAddress.transfer(_tewkenaire);
        uint256 _dividends = _undividedDividends.sub(_maintenance.add(_tewkenaire));
        uint256 _taxedETH = _amountOfTokens.sub(_undividedDividends);

        tokenSupply_ = tokenSupply_.sub(_amountOfTokens);
        tokenBalanceLedger_[customerAddress] = tokenBalanceLedger_[customerAddress].sub(_amountOfTokens);

        int256 _updatedPayouts = (int256) (profitPerShare_.mul(_amountOfTokens).add(_taxedETH.mul(magnitude)));
        payoutsTo_[customerAddress] -= _updatedPayouts;

        if (postLaunch == false) {
            totalLaunchFundCollected = totalLaunchFundCollected.add(_dividends);
        } else if (tokenSupply_ > 0) {
            profitPerShare_ = profitPerShare_.add((_dividends.mul(magnitude)).div(tokenSupply_));
        }

        emit Transfer(customerAddress, address(0), _amountOfTokens);
        emit onTokenSell(customerAddress, _amountOfTokens, _taxedETH, now);
    }

    function transfer(address _toAddress, uint256 _amountOfTokens) onlyTokenHolders external returns (bool){
        address customerAddress = msg.sender;
        require(_amountOfTokens <= tokenBalanceLedger_[customerAddress]);

        if (myDividends() > 0) {
            withdraw();
        }

        uint256 _tokenFee = _amountOfTokens.mul(transferFee_).div(100);
        uint256 _taxedTokens = _amountOfTokens.sub(_tokenFee);
        uint256 _dividends = _tokenFee;

        tokenSupply_ = tokenSupply_.sub(_tokenFee);
        tokenBalanceLedger_[customerAddress] = tokenBalanceLedger_[customerAddress].sub(_amountOfTokens);
        tokenBalanceLedger_[_toAddress] = tokenBalanceLedger_[_toAddress].add(_taxedTokens);

        payoutsTo_[customerAddress] -= (int256) (profitPerShare_.mul(_amountOfTokens));
        payoutsTo_[_toAddress] += (int256) (profitPerShare_.mul(_taxedTokens));

        if (postLaunch == false) {
            totalLaunchFundCollected = totalLaunchFundCollected.add(_dividends);
        } else {
            profitPerShare_ = profitPerShare_.add((_dividends.mul(magnitude)).div(tokenSupply_));
        }

        emit Transfer(customerAddress, _toAddress, _taxedTokens);
        return true;
    }

    function setName(string _name) onlyOwner public {
        name = _name;
    }

    function setSymbol(string _symbol) onlyOwner public {
        symbol = _symbol;
    }

    function approveAddress1(address _proposedAddress) onlyOwner public {
        approvedAddress1 = _proposedAddress;
    }

    function approveAddress2(address _proposedAddress) onlyCustodian public {
        approvedAddress2 = _proposedAddress;
    }

    function setAtomicSwapAddress() public {
        require(approvedAddress1 == approvedAddress2);
        require(tx.origin == approvedAddress1);
        distributionAddress = approvedAddress1;
    }

    function totalEthereumBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function totalSupply() public view returns (uint256) {
        return tokenSupply_;
    }

    function myTokens() public view returns (uint256) {
        address customerAddress = msg.sender;
        return balanceOf(customerAddress);
    }

    function myDividends() public view returns (uint256) {
        address customerAddress = msg.sender;
        return dividendsOf(customerAddress);
    }

    function balanceOf(address customerAddress) public view returns (uint256) {
        return tokenBalanceLedger_[customerAddress];
    }

    function dividendsOf(address customerAddress) public view returns (uint256) {
        return (uint256) ((int256) (profitPerShare_.mul(tokenBalanceLedger_[customerAddress])) - payoutsTo_[customerAddress]) / magnitude;
    }

    function sellPrice() public view returns (uint256) {
        uint256 _ethereum = 1e18;
        uint256 _dividends = _ethereum.mul(exitFee_).div(100);
        uint256 _taxedETH = _ethereum.sub(_dividends);
        return _taxedETH;
    }

    function buyPrice() public view returns (uint256) {
        uint256 _ethereum = 1e18;
        uint256 _dividends = _ethereum.mul(entryFee_).div(100);
        uint256 _taxedETH = _ethereum.add(_dividends);
        return _taxedETH;
    }

    function calculateTokensReceived(uint256 _ethereumToSpend) public view returns (uint256) {
        uint256 _dividends = _ethereumToSpend.mul(entryFee_).div(100);
        uint256 _amountOfTokens = _ethereumToSpend.sub(_dividends);
        return _amountOfTokens;
    }

    function calculateEthereumReceived(uint256 _tokensToSell) public view returns (uint256) {
        require(_tokensToSell <= tokenSupply_);
        uint256 _dividends = _tokensToSell.mul(exitFee_).div(100);
        uint256 _taxedETH = _tokensToSell.sub(_dividends);
        return _taxedETH;
    }

    function purchaseTokens(address customerAddress, uint256 _incomingETH) internal isActivated returns (uint256) {
        if (deposits[customerAddress] == 0) {
            totalPlayer++;
        }
        deposits[customerAddress] += _incomingETH;

        uint256 _undividedDividends = _incomingETH.mul(entryFee_).div(100);
        uint256 _maintenance = _undividedDividends.mul(maintenanceFee_).div(100);
        maintenanceAddress.transfer(_maintenance);
        uint256 _tewkenaire = _undividedDividends.mul(tewkenaireFee_).div(100);
        totalFundCollected += _tewkenaire;
        distributionAddress.transfer(_tewkenaire);
        uint256 _dividends = _undividedDividends.sub(_tewkenaire.add(_maintenance));
        uint256 _amountOfTokens = _incomingETH.sub(_undividedDividends);
        uint256 _fee = _dividends.mul(magnitude);

        require(_amountOfTokens > 0 && _amountOfTokens.add(tokenSupply_) > tokenSupply_);

        if (postLaunch == false) {
            tokenSupply_ = tokenSupply_.add(_amountOfTokens);
            totalLaunchFundCollected = totalLaunchFundCollected.add(_dividends);
            _fee = 0;
        } else if (tokenSupply_ > 0) {
            tokenSupply_ = tokenSupply_.add(_amountOfTokens);
            profitPerShare_ += (_dividends.mul(magnitude).div(tokenSupply_));
            _fee = _fee.sub(_fee.sub(_amountOfTokens.mul(_dividends.mul(magnitude).div(tokenSupply_))));
        } else {
            tokenSupply_ = _amountOfTokens;
        }

        tokenBalanceLedger_[customerAddress] = tokenBalanceLedger_[customerAddress].add(_amountOfTokens);
        int256 _updatedPayouts = (int256) (profitPerShare_.mul(_amountOfTokens).sub(_fee));
        payoutsTo_[customerAddress] += _updatedPayouts;

        emit Transfer(address(0), customerAddress, _amountOfTokens);
        emit onTokenPurchase(customerAddress, _incomingETH, _amountOfTokens, now);
        return _amountOfTokens;
    }
}