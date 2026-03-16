```solidity
pragma solidity ^0.4.21;

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

contract ERC20 {
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MultiOwnable {
    mapping(address => bool) public isOwner;
    address[] public ownerHistory;

    event OwnerAddedEvent(address indexed newOwner);
    event OwnerRemovedEvent(address indexed oldOwner);

    constructor() public {
        address owner = msg.sender;
        ownerHistory.push(owner);
        isOwner[owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender]);
        _;
    }

    function ownerHistoryCount() public view returns (uint) {
        return ownerHistory.length;
    }

    function addOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        require(!isOwner[newOwner]);
        ownerHistory.push(newOwner);
        isOwner[newOwner] = true;
        emit OwnerAddedEvent(newOwner);
    }

    function removeOwner(address oldOwner) public onlyOwner {
        require(isOwner[oldOwner]);
        isOwner[oldOwner] = false;
        emit OwnerRemovedEvent(oldOwner);
    }
}

contract Pausable is MultiOwnable {
    bool public paused = false;

    modifier ifNotPaused() {
        require(!paused);
        _;
    }

    modifier ifPaused() {
        require(paused);
        _;
    }

    function pause() external onlyOwner ifNotPaused {
        paused = true;
    }

    function resume() external onlyOwner ifPaused {
        paused = false;
    }
}

contract StandardToken is ERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0));
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(0));
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }
}

contract CommonToken is StandardToken, MultiOwnable {
    mapping(address => bool) public walletsNotLocked;

    event SellEvent(address indexed seller, address indexed buyer, uint256 value);
    event ChangeSellerEvent(address indexed oldSeller, address indexed newSeller);
    event Burn(address indexed burner, uint256 value);
    event Unlock();

    struct TokenConfig {
        uint256 totalSupply;
        uint256 saleLimit;
        uint256 teamTokens;
        uint256 partnersTokens;
        uint256 reservaTokens;
        uint256 advisorsTokens;
        address seller;
        address teamWallet;
        address partnersWallet;
        address advisorsWallet;
        address reservaWallet;
    }

    TokenConfig public config;

    constructor(
        address _seller,
        address _teamWallet,
        address _partnersWallet,
        address _advisorsWallet,
        address _reservaWallet
    ) MultiOwnable() public {
        config.totalSupply = 600000000 ether;
        config.saleLimit = 390000000 ether;
        config.teamTokens = 120000000 ether;
        config.partnersTokens = 30000000 ether;
        config.reservaTokens = 30000000 ether;
        config.advisorsTokens = 30000000 ether;
        config.seller = _seller;
        config.teamWallet = _teamWallet;
        config.partnersWallet = _partnersWallet;
        config.advisorsWallet = _advisorsWallet;
        config.reservaWallet = _reservaWallet;

        uint sellerTokens = config.totalSupply.sub(config.teamTokens).sub(config.partnersTokens).sub(config.advisorsTokens).sub(config.reservaTokens);
        balances[config.seller] = sellerTokens;
        emit Transfer(0x0, config.seller, sellerTokens);

        balances[config.teamWallet] = config.teamTokens;
        emit Transfer(0x0, config.teamWallet, config.teamTokens);

        balances[config.partnersWallet] = config.partnersTokens;
        emit Transfer(0x0, config.partnersWallet, config.partnersTokens);

        balances[config.reservaWallet] = config.reservaTokens;
        emit Transfer(0x0, config.reservaWallet, config.reservaTokens);

        balances[config.advisorsWallet] = config.advisorsTokens;
        emit Transfer(0x0, config.advisorsWallet, config.advisorsTokens);
    }

    modifier ifUnlocked(address from, address to) {
        require(walletsNotLocked[to]);
        require(!config.locked);
        _;
    }

    function unlock() public onlyOwner {
        require(config.locked);
        config.locked = false;
        emit Unlock();
    }

    function lockWallet(address wallet) public onlyOwner {
        walletsNotLocked[wallet] = false;
    }

    function unlockWallet(address wallet) public onlyOwner {
        walletsNotLocked[wallet] = true;
    }

    function changeSeller(address newSeller) public onlyOwner returns (bool) {
        require(newSeller != address(0));
        require(config.seller != newSeller);
        require(balances[newSeller] == 0);

        address oldSeller = config.seller;
        uint256 unsoldTokens = balances[oldSeller];
        balances[oldSeller] = 0;
        balances[newSeller] = unsoldTokens;
        emit Transfer(oldSeller, newSeller, unsoldTokens);

        config.seller = newSeller;
        emit ChangeSellerEvent(oldSeller, newSeller);
        return true;
    }

    function sellNoDecimals(address to, uint256 value) public returns (bool) {
        return sell(to, value * 1e18);
    }

    function sell(address to, uint256 value) public returns (bool) {
        require(msg.sender == config.seller, "User not authorized");
        require(to != address(0), "Not address authorized");
        require(value > 0, "Value is 0");
        require(value <= balances[config.seller]);

        balances[config.seller] = balances[config.seller].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(config.seller, to, value);

        config.totalSales++;
        config.tokensSold = config.tokensSold.add(value);
        emit SellEvent(config.seller, to, value);
        return true;
    }

    function transfer(address to, uint256 value) public ifUnlocked(msg.sender, to) returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public ifUnlocked(from, to) returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function burn(uint256 value) public returns (bool) {
        require(value > 0, "Value is zero");
        balances[msg.sender] = balances[msg.sender].sub(value);
        config.totalSupply = config.totalSupply.sub(value);
        emit Transfer(msg.sender, 0x0, value);
        emit Burn(msg.sender, value);
        return true;
    }
}

contract CommonTokensale is MultiOwnable, Pausable {
    using SafeMath for uint256;

    CommonToken public token;

    mapping(address => uint256) public buyerToSentWei;
    mapping(address => uint256) public sponsorToComisionDone;
    mapping(address => uint256) public sponsorToComision;
    mapping(address => uint256) public sponsorToComisionHold;
    mapping(address => uint256) public sponsorToComisionFromInversor;
    mapping(address => bool) public kicInversor;
    mapping(address => bool) public validateKYC;
    mapping(address => bool) public comisionInTokens;
    address[] public sponsorToComisionList;

    event ReceiveEthEvent(address indexed buyer, uint256 amountWei);
    event NewInverstEvent(address indexed child, address indexed sponsor);
    event ComisionEvent(address indexed sponsor, address indexed child, uint256 value, uint256 comision);
    event ComisionPayEvent(address indexed sponsor, uint256 value, uint256 comision);
    event ComisionInversorInTokensEvent(address indexed sponsor, bool status);
    event ChangeEndTimeEvent(address sender, uint endTime, uint date);
    event verifyKycEvent(address sender, uint date, bool status);
    event payComisionSponsorTMSY(address sponsor, uint date, uint value);
    event payComisionSponsorETH(address sponsor, uint date, uint value);
    event withdrawEvent(address sender, address to, uint value, uint date);
    event conversionToUSDEvent(uint value, uint rateUsd, uint usds);
    event newRatioEvent(uint value, uint date);
    event conversionETHToTMSYEvent(address buyer, uint value, uint tokensE18SinBono, uint tokensE18Bono);
    event createContractEvent(address token, address beneficiary, uint startTime, uint endTime);

    mapping(address => bool) public inversors;
    address[] public inversorsList;
    mapping(address => address) public inversorToSponsor;

    struct SaleConfig {
        uint256 totalWeiRefunded;
        bool isSoftCapComplete;
        uint256 rateUSDETH;
        uint256 totalUSDReceived;
        uint256 totalWeiReceived;
        uint256 totalTokensSold;
        uint256 endTime;
        uint256 startTime;
        uint256 maxCapUSD;
        uint256 minCapUSD;
        uint256 maxCapWei;
        uint256 minCapWei;
        uint256 minPaymentUSD;
        uint256 balanceComisionDone;
        uint256 balanceComisionHold;
        uint256 balanceComision;
        uint256 totalSupply;
        uint256 refundDeadlineTime;
        address beneficiary;
        bool locked;
        uint256 totalSales;
        uint256 tokensSold;
        address seller;
        uint256 unlockTeamTokensTime;
        address reservaWallet;
        address advisorsWallet;
        address partnersWallet;
        address teamWallet;
        uint256 reservaTokens;
        uint256 advisorsTokens;
        uint256 partnersTokens;
        uint256 teamTokens;
        uint256 saleLimit;
        uint8 decimals;
        string name;
        string symbol;
        bool paused;
        uint256 totalSupply;
    }

    SaleConfig public saleConfig;

    constructor(
        address _token,
        address _beneficiary,
        uint _startTime,
        uint _endTime
    ) MultiOwnable() public {
        require(_token != address(0));
        token = CommonToken(_token);
        emit createContractEvent(_token, _beneficiary, _startTime, _endTime);

        saleConfig.beneficiary = _beneficiary;
        saleConfig.startTime = now;
        saleConfig.endTime = 1544313600;
        saleConfig.minCapUSD = 400000;
        saleConfig.maxCapUSD = 4000000;
    }

    function setRatio(uint _rate) public onlyOwner returns (bool) {
        saleConfig.rateUSDETH = _rate;
        emit newRatioEvent(saleConfig.rateUSDETH, now);
        return true;
    }

    function burn(uint value) public onlyOwner returns (bool) {
        return token.burn(value);
    }

    function newInversor(address _newInversor, address _sponsor) public onlyOwner returns (bool) {
        inversors[_newInversor] = true;
        inversorsList.push(_newInversor);
        inversorToSponsor[_newInversor] = _sponsor;
        emit NewInverstEvent(_newInversor, _sponsor);
        return inversors[_newInversor];
    }

    function setComisionInvesorInTokens(address _inversor, bool _inTokens) public onlyOwner returns (bool) {
        comisionInTokens[_inversor] = _inTokens;
        emit ComisionInversorInTokensEvent(_inversor, _inTokens);
        return true;
    }

    function setComisionInTokens() public returns (bool) {
        comisionInTokens[msg.sender] = true;
        emit ComisionInversorInTokensEvent(msg.sender, true);
        return true;
    }

    function setComisionInETH() public returns (bool) {
        comisionInTokens[msg.sender] = false;
        emit ComisionInversorInTokensEvent(msg.sender, false);
        return true;
    }

    function inversorIsKyc(address inversor) public returns (bool) {
        return validateKYC[inversor];
    }

    function unVerifyKyc(address _inversor) public onlyOwner returns (bool) {
        require(!saleConfig.isSoftCapComplete);
        validateKYC[_inversor] = false;
        address sponsor = inversorToSponsor[_inversor];
        uint balanceHold = sponsorToComisionFromInversor[_inversor];
        saleConfig.balanceComision = saleConfig.balanceComision.sub(balanceHold);
        saleConfig.balanceComisionHold = saleConfig.balanceComisionHold.add(balanceHold);
        sponsorToComision[sponsor] = sponsorToComision[sponsor].sub(balanceHold);
        sponsorToComisionHold[sponsor] = sponsorToComisionHold[sponsor].add(balanceHold);
        emit verifyKycEvent(_inversor, now, false);
    }

    function verifyKyc(address _inversor) public onlyOwner returns (bool) {
        validateKYC[_inversor] = true;
        address sponsor = inversorToSponsor[_inversor];
        uint balanceHold = sponsorToComisionFromInversor[_inversor];
        saleConfig.balanceComision = saleConfig.balanceComision.add(balanceHold);
        saleConfig.balanceComisionHold = saleConfig.balanceComisionHold.sub(balanceHold);
        sponsorToComision[sponsor] = sponsorToComision[sponsor].add(balanceHold);
        sponsorToComisionHold[sponsor] = sponsorToComisionHold[sponsor].sub(balanceHold);
        emit verifyKycEvent(_inversor, now, true);
        return true;
    }

    function buyerToSentWeiOf(address buyer) public view returns (uint256) {
        return buyerToSentWei[buyer];
    }

    function balanceOfComision(address sponsor) public view returns (uint256) {
        return sponsorToComision[sponsor];
    }

    function balanceOfComisionHold(address sponsor) public view returns (uint256) {
        return sponsorToComisionHold[sponsor];
    }

    function balanceOfComisionDone(address sponsor) public view returns (uint256) {
        return sponsorToComisionDone[sponsor];
    }

    function isInversor(address inversor) public view returns (bool) {
        return inversors[inversor];
    }

    function payComisionSponsor(address _inversor) private {
        if (comisionInTokens[_inversor]) {
            uint256 val = 0;
            uint256 valueHold = sponsorToComisionHold[_inversor];
            uint256 valueReady = sponsorToComision[_inversor];
            val = valueReady.add(valueHold);
            if (val > 0) {
                require(saleConfig.balanceComision >= valueReady);
                require(saleConfig.balanceComisionHold >= valueHold);
                uint256 comisionTokens = weiToTokens(val);
                sponsorToComision[_inversor] = 0;
                sponsorToComisionHold[_inversor] = 0;
                saleConfig.balanceComision = saleConfig.balanceComision.sub(valueReady);
                saleConfig.balanceComisionDone = saleConfig.balanceComisionDone.add(val);
                saleConfig.balanceComisionHold = saleConfig.balanceComisionHold.sub(valueHold);
                saleConfig.totalSupply = saleConfig.totalSupply.sub(val);
                token.sell(_inversor, comisionTokens);
                emit payComisionSponsorTMSY(_inversor, now, val);
            }
        } else {
            uint256 value = sponsorToComision[_inversor];
            if (value > 0) {
                require(saleConfig.balanceComision >= value);
                assert(saleConfig.isSoftCapComplete);
                assert(validateKYC[_inversor]);
                sponsorToComision[_inversor] = sponsorToComision[_inversor].sub(value);
                saleConfig.balanceComision = saleConfig.balanceComision.sub(value);
                saleConfig.balanceComisionDone = saleConfig.balanceComisionDone.add(value);
                _inversor.transfer(value);
                emit payComisionSponsorETH(_inversor, now, value);
            }
        }
    }

    function payComision() public {
        address _inversor = msg.sender;
        payComisionSponsor(_inversor);
    }

    function isSoftCapCompleted() public view returns (bool) {
        return saleConfig.isSoftCapComplete;
    }

    function softCapCompleted() public {
        uint totalBalanceUSD = weiToUSD(saleConfig.totalSupply);
        if (totalBalanceUSD >= saleConfig.minCapUSD) {
            saleConfig.isSoftCapComplete = true;
        }
    }

    function balanceComisionOf(address sponsor) public view returns (uint256) {
        return sponsorToComision[sponsor];
    }

    function getNow() public returns (uint) {
        return now;
    }

    function() public payable {
        uint256 amountWei = msg.value;
        address buyer = msg.sender;
        uint valueUSD = weiToUSD(amountWei);
        require(now <= saleConfig.endTime, "End time reached");
        require(inversors[buyer] != false, "No invest");
        require(valueUSD >= saleConfig.minPaymentUSD, "Minimum payment not reached");

        emit ReceiveEthEvent(buyer, amountWei);

        uint tokensE18SinBono = weiToTokens(amountWei);
        uint tokensE18Bono = weiToTokensBono(amountWei);

        emit conversionETHToTMSYEvent(buyer, amountWei, tokensE18SinBono, tokensE18Bono);

        uint tokensE18 = tokensE18SinBono.add(tokensE18Bono);
        require(token.sell(buyer, tokensE18SinBono), "Sale failed");

        if (tokensE18Bono > 0) {
            assert(token.sell(buyer, tokensE18Bono));
        }

        uint256 amountSponsor = (amountWei * 10) / 100;
        uint256 amountBeneficiary = (amountWei * 90) / 100;

        saleConfig.totalTokensSold = saleConfig.totalTokensSold.add(tokensE18);
        saleConfig.totalWeiReceived = saleConfig.totalWeiReceived.add(amountWei);
        buyerToSentWei[buyer] = buyerToSentWei[buyer].add(amountWei);

        if (!saleConfig.isSoftCapComplete) {
            uint256 totalBalanceUSD = weiToUSD(saleConfig.totalSupply);
            if (totalBalanceUSD >= saleConfig.minCapUSD) {
                softCapCompleted();
            }
        }

        address sponsor = inversorToSponsor[buyer];
        sponsorToComisionList.push(sponsor);

        if (validateKYC[buyer]) {
            saleConfig.balanceComision = saleConfig.balanceComision.add(amountSponsor);
            sponsorToComision[sponsor] = sponsorToComision[sponsor].add(amountSponsor);
        } else {
            saleConfig.balanceComisionHold = saleConfig.balanceComisionHold.add(amountSponsor);
            sponsorToComisionHold[sponsor] = sponsorToComisionHold[sponsor].add(amountSponsor);
            sponsorToComisionFromInversor[buyer] = sponsorToComisionFromInversor[buyer].add(amountSponsor);
        }

        payComisionSponsor(sponsor);
        saleConfig.totalSupply = saleConfig.totalSupply.sub(amountBeneficiary);
    }

    function weiToUSD(uint amountWei) public view returns (uint256) {
        uint256 ethers = amountWei;
        uint256 valueUSD = saleConfig.rateUSDETH.mul(amountWei);
        emit conversionToUSDEvent(amountWei, saleConfig.rateUSDETH, valueUSD.div(1e18));
        return valueUSD.div(1e18);
    }

    function weiToTokensBono(uint amountWei) public view returns (uint256) {
        uint bono = 0;
        uint256 valueUSD = weiToUSD(amountWei);
        if (valueUSD >= uint(500 * 10**18)) bono = 10;
        if (valueUSD >= uint(1000 * 10**18)) bono = 20;
        if (valueUSD >= uint(2500 * 10**18)) bono = 30;
        if (valueUSD >= uint(5000 * 10**18)) bono = 40;
        if (valueUSD >= uint(10000 * 10**18)) bono = 50;
        uint256 bonoUsd = valueUSD.mul(bono).div(100);
        uint256 tokens = bonoUsd.mul(tokensPerUSD());
        return tokens;
    }

    function weiToTokens(uint amountWei) public view returns (uint256) {
        uint256 valueUSD = weiToUSD(amountWei);
        uint256 tokens = valueUSD.mul(tokensPerUSD());
        return tokens;
    }

    function tokensPerUSD() public pure returns (uint256) {
        return 65;
    }

    function canWithdraw() public view returns (bool);

    function withdraw(address to, uint value) public returns (uint) {
        require(canWithdraw(), "Cannot withdraw");
        require(msg.sender == saleConfig.beneficiary, "Only beneficiary can withdraw");
        require(saleConfig.totalSupply >= value, "Insufficient funds");
        require(to.call.value(value).gas(1)(), "Transfer failed");
        saleConfig.totalSupply = saleConfig.totalSupply.sub(value);
        emit withdrawEvent(msg.sender, to, value, now);
        return saleConfig.totalSupply;
    }

    function changeEndTime(uint date) public onlyOwner returns (bool) {
        saleConfig.endTime = date;
        saleConfig.refundDeadlineTime = saleConfig.endTime + 30 days;
        emit ChangeEndTimeEvent(msg.sender, saleConfig.endTime, now);
        return true;
    }
}

contract Presale is CommonTokensale {
    event RefundEthEvent(address indexed buyer, uint256 amountWei);

    constructor(
        address _token,
        address _beneficiary,
        uint _startTime,
        uint _endTime
    ) CommonTokensale(_token, _beneficiary, _startTime, _endTime) public {
        saleConfig.refundDeadlineTime = saleConfig.endTime + 3 * 30 days;
    }

    function canWithdraw() public view returns (bool) {
        return saleConfig.isSoftCapComplete;
    }

    function canRefund() public view returns (bool) {
        return !saleConfig.isSoftCapComplete && now <= saleConfig.refundDeadlineTime;
    }

    function refund() public {
        require(canRefund());
        address buyer = msg.sender;
        uint amount = buyerToSentWei[buyer];
        require(amount > 0);
        saleConfig.totalSupply = saleConfig.totalSupply.sub(amount);
        emit RefundEthEvent(buyer, amount);
        buyerToSentWei[buyer] = 0;
        saleConfig.totalWeiRefunded = saleConfig.totalWeiRefunded.add(amount);
        buyer.transfer(amount);
    }
}
```