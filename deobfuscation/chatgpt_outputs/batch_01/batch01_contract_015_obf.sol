pragma solidity ^0.4.26;

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

    struct State {
        bool postLaunch;
        uint256 totalDonation;
        uint256 totalPlayer;
        uint256 profitPerShare;
        uint256 tokenSupply;
        uint256 magnitude;
        uint256 totalLaunchFundCollected;
        uint256 totalFundCollected;
        address distributionAddress;
        address approvedAddress2;
        address approvedAddress1;
        address custodianAddress;
        address maintenanceAddress;
        uint256 maintenanceFee;
        uint256 tewkenaireFee;
        uint256 exitFee;
        uint256 transferFee;
        uint256 entryFee;
        uint8 decimals;
        string symbol;
        string name;
        uint256 activationTime;
    }

    State public s2c;

    mapping(address => uint256) internal tokenBalanceLedger;
    mapping(address => int256) internal payoutsTo;
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public withdrawals;

    event onDistribute(address indexed customerAddress, uint256 price);
    event onTokenPurchase(address indexed customerAddress, uint256 incomingETH, uint256 tokensMinted, uint timestamp);
    event onTokenSell(address indexed customerAddress, uint256 tokensBurned, uint256 ethereumEarned, uint timestamp);
    event onRoll(address indexed customerAddress, uint256 ethereumRolled, uint256 tokensMinted);
    event onWithdraw(address indexed customerAddress, uint256 ethereumWithdrawn);
    event Transfer(address indexed from, address indexed to, uint256 tokens);

    modifier isActivated() {
        require(now >= s2c.activationTime);
        _;
    }

    modifier onlyCustodian() {
        require(msg.sender == s2c.custodianAddress);
        _;
    }

    modifier onlyTokenHolders() {
        require(myTokens() > 0);
        _;
    }

    modifier onlyDivis() {
        require(myDividends() > 0);
        _;
    }

    constructor() public {
        s2c.maintenanceAddress = address(0xe21AC1CAE34c532a38B604669E18557B2d8840Fc);
        s2c.custodianAddress = address(0x24B23bB643082026227e945C7833B81426057b10);
        s2c.distributionAddress = address(0xfE8D614431E5fea2329B05839f29B553b1Cb99A2);
        s2c.approvedAddress1 = s2c.distributionAddress;
        s2c.approvedAddress2 = s2c.distributionAddress;
        s2c.magnitude = 2 ** 64;
        s2c.maintenanceFee = 10;
        s2c.tewkenaireFee = 10;
        s2c.exitFee = 10;
        s2c.transferFee = 1;
        s2c.entryFee = 10;
        s2c.decimals = 18;
        s2c.symbol = "STABLE";
        s2c.name = "Tewkenaire Stable";
        s2c.activationTime = 1580688000;
    }

    function distribute() public payable returns (uint256) {
        require(msg.value > 0 && s2c.postLaunch == true);
        s2c.totalDonation = s2c.totalDonation.add(msg.value);
        s2c.profitPerShare = s2c.profitPerShare.add((msg.value.mul(s2c.magnitude)).div(s2c.tokenSupply));
        emit onDistribute(msg.sender, msg.value);
    }

    function distributeLaunchFund() public {
        require(s2c.totalLaunchFundCollected > 0 && s2c.postLaunch == false && now >= s2c.activationTime + 24 hours);
        s2c.profitPerShare = s2c.profitPerShare.add((s2c.totalLaunchFundCollected.mul(s2c.magnitude)).div(s2c.tokenSupply));
        s2c.postLaunch = true;
    }

    function buy() public payable returns (uint256) {
        return purchaseTokens(msg.sender, msg.value);
    }

    function buyFor(address beneficiary) public payable returns (uint256) {
        return purchaseTokens(beneficiary, msg.value);
    }

    function() payable public {
        purchaseTokens(msg.sender, msg.value);
    }

    function roll() onlyDivis public {
        address customerAddress = msg.sender;
        uint256 dividends = myDividends();
        payoutsTo[customerAddress] += (int256)(dividends.mul(s2c.magnitude));
        uint256 tokens = purchaseTokens(customerAddress, dividends);
        emit onRoll(customerAddress, dividends, tokens);
    }

    function exit() external {
        address customerAddress = msg.sender;
        uint256 tokens = tokenBalanceLedger[customerAddress];
        if (tokens > 0) sell(tokens);
        withdraw();
    }

    function withdraw() onlyDivis public {
        address customerAddress = msg.sender;
        uint256 dividends = myDividends();
        payoutsTo[customerAddress] += (int256)(dividends.mul(s2c.magnitude));
        customerAddress.transfer(dividends);
        withdrawals[customerAddress] = withdrawals[customerAddress].add(dividends);
        emit onWithdraw(customerAddress, dividends);
    }

    function sell(uint256 amountOfTokens) onlyTokenHolders public {
        address customerAddress = msg.sender;
        require(amountOfTokens <= tokenBalanceLedger[customerAddress]);
        uint256 undividedDividends = SafeMath.div(SafeMath.mul(amountOfTokens, s2c.exitFee), 100);
        uint256 maintenance = SafeMath.div(SafeMath.mul(undividedDividends, s2c.maintenanceFee), 100);
        s2c.maintenanceAddress.transfer(maintenance);
        uint256 tewkenaire = SafeMath.div(SafeMath.mul(undividedDividends, s2c.tewkenaireFee), 100);
        s2c.totalFundCollected = s2c.totalFundCollected.add(tewkenaire);
        s2c.distributionAddress.transfer(tewkenaire);
        uint256 dividends = SafeMath.sub(undividedDividends, SafeMath.add(maintenance, tewkenaire));
        uint256 taxedETH = SafeMath.sub(amountOfTokens, undividedDividends);
        s2c.tokenSupply = SafeMath.sub(s2c.tokenSupply, amountOfTokens);
        tokenBalanceLedger[customerAddress] = SafeMath.sub(tokenBalanceLedger[customerAddress], amountOfTokens);
        int256 updatedPayouts = (int256)(s2c.profitPerShare.mul(amountOfTokens) + (taxedETH.mul(s2c.magnitude)));
        payoutsTo[customerAddress] -= updatedPayouts;
        if (s2c.postLaunch == false) {
            s2c.totalLaunchFundCollected = s2c.totalLaunchFundCollected.add(dividends);
        } else if (s2c.tokenSupply > 0) {
            s2c.profitPerShare = s2c.profitPerShare.add((dividends.mul(s2c.magnitude)).div(s2c.tokenSupply));
        }
        emit Transfer(customerAddress, address(0), amountOfTokens);
        emit onTokenSell(customerAddress, amountOfTokens, taxedETH, now);
    }

    function transfer(address toAddress, uint256 amountOfTokens) onlyTokenHolders external returns (bool) {
        address customerAddress = msg.sender;
        require(amountOfTokens <= tokenBalanceLedger[customerAddress]);
        if (myDividends() > 0) {
            withdraw();
        }
        uint256 tokenFee = SafeMath.div(SafeMath.mul(amountOfTokens, s2c.transferFee), 100);
        uint256 taxedTokens = SafeMath.sub(amountOfTokens, tokenFee);
        uint256 dividends = tokenFee;
        s2c.tokenSupply = SafeMath.sub(s2c.tokenSupply, tokenFee);
        tokenBalanceLedger[customerAddress] = SafeMath.sub(tokenBalanceLedger[customerAddress], amountOfTokens);
        tokenBalanceLedger[toAddress] = SafeMath.add(tokenBalanceLedger[toAddress], taxedTokens);
        payoutsTo[customerAddress] -= (int256)(s2c.profitPerShare.mul(amountOfTokens));
        payoutsTo[toAddress] += (int256)(s2c.profitPerShare.mul(taxedTokens));
        if (s2c.postLaunch == false) {
            s2c.totalLaunchFundCollected = s2c.totalLaunchFundCollected.add(dividends);
        } else {
            s2c.profitPerShare = s2c.profitPerShare.add((dividends.mul(s2c.magnitude)).div(s2c.tokenSupply));
        }
        emit Transfer(customerAddress, toAddress, taxedTokens);
        return true;
    }

    function setName(string _name) onlyOwner public {
        s2c.name = _name;
    }

    function setSymbol(string _symbol) onlyOwner public {
        s2c.symbol = _symbol;
    }

    function approveAddress1(address proposedAddress) onlyOwner public {
        s2c.approvedAddress1 = proposedAddress;
    }

    function approveAddress2(address proposedAddress) onlyCustodian public {
        s2c.approvedAddress2 = proposedAddress;
    }

    function setAtomicSwapAddress() public {
        require(s2c.approvedAddress1 == s2c.approvedAddress2);
        require(tx.origin == s2c.approvedAddress1);
        s2c.distributionAddress = s2c.approvedAddress1;
    }

    function totalEthereumBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function totalSupply() public view returns (uint256) {
        return s2c.tokenSupply;
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
        return tokenBalanceLedger[customerAddress];
    }

    function dividendsOf(address customerAddress) public view returns (uint256) {
        return (uint256)((int256)(s2c.profitPerShare.mul(tokenBalanceLedger[customerAddress])) - payoutsTo[customerAddress]) / s2c.magnitude;
    }

    function sellPrice() public view returns (uint256) {
        uint256 ethereum = 1e18;
        uint256 dividends = SafeMath.div(SafeMath.mul(ethereum, s2c.exitFee), 100);
        uint256 taxedETH = SafeMath.sub(ethereum, dividends);
        return taxedETH;
    }

    function buyPrice() public view returns (uint256) {
        uint256 ethereum = 1e18;
        uint256 dividends = SafeMath.div(SafeMath.mul(ethereum, s2c.entryFee), 100);
        uint256 taxedETH = SafeMath.add(ethereum, dividends);
        return taxedETH;
    }

    function calculateTokensReceived(uint256 ethereumToSpend) public view returns (uint256) {
        uint256 dividends = SafeMath.div(SafeMath.mul(ethereumToSpend, s2c.entryFee), 100);
        uint256 amountOfTokens = SafeMath.sub(ethereumToSpend, dividends);
        return amountOfTokens;
    }

    function calculateEthereumReceived(uint256 tokensToSell) public view returns (uint256) {
        require(tokensToSell <= s2c.tokenSupply);
        uint256 dividends = SafeMath.div(SafeMath.mul(tokensToSell, s2c.exitFee), 100);
        uint256 taxedETH = SafeMath.sub(tokensToSell, dividends);
        return taxedETH;
    }

    function purchaseTokens(address customerAddress, uint256 incomingETH) internal isActivated returns (uint256) {
        if (deposits[customerAddress] == 0) {
            s2c.totalPlayer++;
        }
        deposits[customerAddress] = deposits[customerAddress].add(incomingETH);
        uint256 undividedDividends = SafeMath.div(SafeMath.mul(incomingETH, s2c.entryFee), 100);
        uint256 maintenance = SafeMath.div(SafeMath.mul(undividedDividends, s2c.maintenanceFee), 100);
        s2c.maintenanceAddress.transfer(maintenance);
        uint256 tewkenaire = SafeMath.div(SafeMath.mul(undividedDividends, s2c.tewkenaireFee), 100);
        s2c.totalFundCollected = s2c.totalFundCollected.add(tewkenaire);
        s2c.distributionAddress.transfer(tewkenaire);
        uint256 dividends = SafeMath.sub(undividedDividends, SafeMath.add(tewkenaire, maintenance));
        uint256 amountOfTokens = SafeMath.sub(incomingETH, undividedDividends);
        uint256 fee = dividends.mul(s2c.magnitude);
        require(amountOfTokens > 0 && SafeMath.add(amountOfTokens, s2c.tokenSupply) > s2c.tokenSupply);
        if (s2c.postLaunch == false) {
            s2c.tokenSupply = SafeMath.add(s2c.tokenSupply, amountOfTokens);
            s2c.totalLaunchFundCollected = s2c.totalLaunchFundCollected.add(dividends);
            fee = 0;
        } else if (s2c.tokenSupply > 0) {
            s2c.tokenSupply = SafeMath.add(s2c.tokenSupply, amountOfTokens);
            s2c.profitPerShare = s2c.profitPerShare.add((dividends.mul(s2c.magnitude)).div(s2c.tokenSupply));
            fee = fee.sub(fee.sub(amountOfTokens.mul((dividends.mul(s2c.magnitude)).div(s2c.tokenSupply))));
        } else {
            s2c.tokenSupply = amountOfTokens;
        }
        tokenBalanceLedger[customerAddress] = SafeMath.add(tokenBalanceLedger[customerAddress], amountOfTokens);
        int256 updatedPayouts = (int256)(s2c.profitPerShare.mul(amountOfTokens) - fee);
        payoutsTo[customerAddress] += updatedPayouts;
        emit Transfer(address(0), customerAddress, amountOfTokens);
        emit onTokenPurchase(customerAddress, incomingETH, amountOfTokens, now);
        return amountOfTokens;
    }
}