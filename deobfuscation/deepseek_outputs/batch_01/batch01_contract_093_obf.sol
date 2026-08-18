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

contract TokenInterface {
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract MultiOwnable {
    mapping (address => bool) public isOwner;
    address[] public ownerHistory;

    event OwnerAddedEvent(address indexed _newOwner);
    event OwnerRemovedEvent(address indexed _oldOwner);

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

    function addOwner(address owner) onlyOwner public {
        require(owner != address(0));
        require(!isOwner[owner]);
        ownerHistory.push(owner);
        isOwner[owner] = true;
        emit OwnerAddedEvent(owner);
    }

    function removeOwner(address owner) onlyOwner public {
        require(isOwner[owner]);
        isOwner[owner] = false;
        emit OwnerRemovedEvent(owner);
    }
}

contract Pausable is MultiOwnable {
    modifier ifNotPaused {
        require(!s2c.paused);
        _;
    }

    modifier ifPaused {
        require(s2c.paused);
        _;
    }

    function pause() external onlyOwner ifNotPaused {
        s2c.paused = true;
    }

    function resume() external onlyOwner ifPaused {
        s2c.paused = false;
    }
}

contract StandardToken is TokenInterface {
    using SafeMath for uint;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract CommonToken is StandardToken, MultiOwnable {
    mapping (address => bool) public walletsNotLocked;

    event SellEvent(address indexed _seller, address indexed _buyer, uint256 _value);
    event ChangeSellerEvent(address indexed _oldSeller, address indexed _newSeller);
    event Burn(address indexed _burner, uint256 _value);
    event Unlock();

    constructor (
        address _seller,
        address _teamWallet,
        address _partnersWallet,
        address _advisorsWallet,
        address _reservaWallet
    ) MultiOwnable() public {
        s2c.totalSupply = 600000000 ether;
        s2c.saleLimit = 390000000 ether;
        s2c.teamTokens = 120000000 ether;
        s2c.partnersTokens = 30000000 ether;
        s2c.reservaTokens = 30000000 ether;
        s2c.advisorsTokens = 30000000 ether;
        s2c.seller = _seller;
        s2c.teamWallet = _teamWallet;
        s2c.partnersWallet = _partnersWallet;
        s2c.advisorsWallet = _advisorsWallet;
        s2c.reservaWallet = _reservaWallet;

        uint sellerTokens = s2c.totalSupply - s2c.teamTokens - s2c.partnersTokens - s2c.advisorsTokens - s2c.reservaTokens;
        balances[s2c.seller] = sellerTokens;
        emit Transfer(0x0, s2c.seller, sellerTokens);

        balances[s2c.teamWallet] = s2c.teamTokens;
        emit Transfer(0x0, s2c.teamWallet, s2c.teamTokens);

        balances[s2c.partnersWallet] = s2c.partnersTokens;
        emit Transfer(0x0, s2c.partnersWallet, s2c.partnersTokens);

        balances[s2c.reservaWallet] = s2c.reservaTokens;
        emit Transfer(0x0, s2c.reservaWallet, s2c.reservaTokens);

        balances[s2c.advisorsWallet] = s2c.advisorsTokens;
        emit Transfer(0x0, s2c.advisorsWallet, s2c.advisorsTokens);
    }

    modifier ifUnlocked(address _from, address _to) {
        require(walletsNotLocked[_to]);
        require(!s2c.locked);
        _;
    }

    function unlock() onlyOwner public {
        require(s2c.locked);
        s2c.locked = false;
        emit Unlock();
    }

    function walletLocked(address _wallet) onlyOwner public {
        walletsNotLocked[_wallet] = false;
    }

    function walletNotLocked(address _wallet) onlyOwner public {
        walletsNotLocked[_wallet] = true;
    }

    function changeSeller(address newSeller) onlyOwner public returns (bool) {
        require(newSeller != address(0));
        require(s2c.seller != newSeller);
        require(balances[newSeller] == 0);

        address oldSeller = s2c.seller;
        uint256 unsoldTokens = balances[oldSeller];
        balances[oldSeller] = 0;
        balances[newSeller] = unsoldTokens;
        emit Transfer(oldSeller, newSeller, unsoldTokens);
        s2c.seller = newSeller;
        emit ChangeSellerEvent(oldSeller, newSeller);
        return true;
    }

    function sellNoDecimals(address _to, uint256 _value) public returns (bool) {
        return sell(_to, _value * 1e18);
    }

    function sell(address _to, uint256 _value) public returns (bool) {
        require(msg.sender == s2c.seller, "User not authorized");
        require(_to != address(0), "Not address authorized");
        require(_value > 0, "Value is 0");
        require(_value <= balances[s2c.seller]);

        balances[s2c.seller] = balances[s2c.seller].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(s2c.seller, _to, _value);

        s2c.totalSales++;
        s2c.tokensSold = s2c.tokensSold.add(_value);
        emit SellEvent(s2c.seller, _to, _value);
        return true;
    }

    function transfer(address _to, uint256 _value) ifUnlocked(msg.sender, _to) public returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) ifUnlocked(_from, _to) public returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function burn(uint256 _value) public returns (bool) {
        require(_value > 0, "Value is zero");
        balances[msg.sender] = balances[msg.sender].sub(_value);
        s2c.totalSupply = s2c.totalSupply.sub(_value);
        emit Transfer(msg.sender, 0x0, _value);
        emit Burn(msg.sender, _value);
        return true;
    }
}

contract CommonTokensale is MultiOwnable, Pausable {
    using SafeMath for uint;

    CommonToken public token;

    mapping (address => uint256) public buyerToSentWei;
    mapping (address => uint256) public sponsorToComisionDone;
    mapping (address => uint256) public sponsorToComision;
    mapping (address => uint256) public sponsorToComisionHold;
    mapping (address => uint256) public sponsorToComisionFromInversor;
    mapping (address => bool) public kicInversor;
    mapping (address => bool) public validateKYC;
    mapping (address => bool) public comisionInTokens;
    address[] public sponsorToComisionList;

    event ReceiveEthEvent(address indexed _buyer, uint256 _amountWei);
    event NewInverstEvent(address indexed _child, address indexed _sponsor);
    event ComisionEvent(address indexed _sponsor, address indexed _child, uint256 _value, uint256 _comision);
    event ComisionPayEvent(address indexed _sponsor, uint256 _value, uint256 _comision);
    event ComisionInversorInTokensEvent(address indexed _sponsor, bool status);
    event ChangeEndTimeEvent(address _sender, uint endTime, uint _date);
    event verifyKycEvent(address _sender, uint _date, bool _status);
    event payComisionSponsorTMSY(address _sponsor, uint _date, uint _value);
    event payComisionSponsorETH(address _sponsor, uint _date, uint _value);
    event withdrawEvent(address _sender, address _to, uint _amount, uint _date);
    event conversionToUSDEvent(uint _value, uint rateUsd, uint usds);
    event newRatioEvent(uint _value, uint date);
    event conversionETHToTMSYEvent(address _buyer, uint _amount, uint tokensE18SinBono, uint tokensE18Bono);
    event createContractEvent(address _token, address _beneficiary, uint _startTime, uint _endTime);

    mapping(address => bool) public inversors;
    address[] public inversorsList;
    mapping(address => address) public inversorToSponsor;

    constructor (
        address _token,
        address _beneficiary,
        uint _startTime,
        uint _endTime
    ) MultiOwnable() public {
        require(_token != address(0));
        token = CommonToken(_token);
        emit createContractEvent(_token, _beneficiary, _startTime, _endTime);
        s2c.beneficiary = _beneficiary;
        s2c.startTime = now;
        s2c.endTime = 1544313600;
        s2c.minCapUSD = 400000;
        s2c.maxCapUSD = 4000000;
    }

    function setRatio(uint _rate) onlyOwner public returns (bool) {
        s2c.rateUSDETH = _rate;
        emit newRatioEvent(s2c.rateUSDETH, now);
        return true;
    }

    function burn(uint _value) onlyOwner public returns (bool) {
        return token.burn(_value);
    }

    function newInversor(address _newInversor, address _sponsor) onlyOwner public returns (bool) {
        inversors[_newInversor] = true;
        inversorsList.push(_newInversor);
        inversorToSponsor[_newInversor] = _sponsor;
        emit NewInverstEvent(_newInversor, _sponsor);
        return inversors[_newInversor];
    }

    function setComisionInvesorInTokens(address _inversor, bool _inTokens) onlyOwner public returns (bool) {
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

    function inversorIsKyc(address _inversor) public returns (bool) {
        return validateKYC[_inversor];
    }

    function unVerifyKyc(address _inversor) onlyOwner public returns (bool) {
        require(!s2c.isSoftCapComplete);
        validateKYC[_inversor] = false;
        address sponsor = inversorToSponsor[_inversor];
        uint balanceHold = sponsorToComisionFromInversor[_inversor];
        s2c.balanceComision = s2c.balanceComision.sub(balanceHold);
        s2c.balanceComisionHold = s2c.balanceComisionHold.add(balanceHold);
        sponsorToComision[sponsor] = sponsorToComision[sponsor].sub(balanceHold);
        sponsorToComisionHold[sponsor] = sponsorToComisionHold[sponsor].add(balanceHold);
        emit verifyKycEvent(_inversor, now, false);
    }

    function verifyKyc(address _inversor) onlyOwner public returns (bool) {
        validateKYC[_inversor] = true;
        address sponsor = inversorToSponsor[_inversor];
        uint balanceHold = sponsorToComisionFromInversor[_inversor];
        s2c.balanceComision = s2c.balanceComision.add(balanceHold);
        s2c.balanceComisionHold = s2c.balanceComisionHold.sub(balanceHold);
        sponsorToComision[sponsor] = sponsorToComision[sponsor].add(balanceHold);
        sponsorToComisionHold[sponsor] = sponsorToComisionHold[sponsor].sub(balanceHold);
        emit verifyKycEvent(_inversor, now, true);
        return true;
    }

    function buyerToSentWeiOf(address _buyer) public view returns (uint256) {
        return buyerToSentWei[_buyer];
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return token.balanceOf(_owner);
    }

    function balanceOfComision(address _sponsor) public view returns (uint256) {
        return sponsorToComision[_sponsor];
    }

    function balanceOfComisionHold(address _sponsor) public view returns (uint256) {
        return sponsorToComisionHold[_sponsor];
    }

    function balanceOfComisionDone(address _sponsor) public view returns (uint256) {
        return sponsorToComisionDone[_sponsor];
    }

    function isInversor(address _inversor) public view returns (bool) {
        return inversors[_inversor];
    }

    function payComisionSponsor(address _inversor) private {
        if(comisionInTokens[_inversor]) {
            uint256 val = 0;
            uint256 valueHold = sponsorToComisionHold[_inversor];
            uint256 valueReady = sponsorToComision[_inversor];
            val = valueReady.add(valueHold);
            if(val > 0) {
                require(s2c.balanceComision >= valueReady);
                require(s2c.balanceComisionHold >= valueHold);
                uint256 comisionTokens = weiToTokens(val);
                sponsorToComision[_inversor] = 0;
                sponsorToComisionHold[_inversor] = 0;
                s2c.balanceComision = s2c.balanceComision.sub(valueReady);
                s2c.balanceComisionDone = s2c.balanceComisionDone.add(val);
                s2c.balanceComisionHold = s2c.balanceComisionHold.sub(valueHold);
                s2c.balance = s2c.balance.sub(val);
                token.sell(_inversor, comisionTokens);
                emit payComisionSponsorTMSY(_inversor, now, val);
            }
        } else {
            uint256 amount = sponsorToComision[_inversor];
            if(amount > 0) {
                require(s2c.balanceComision >= amount);
                assert(s2c.isSoftCapComplete);
                assert(validateKYC[_inversor]);
                sponsorToComision[_inversor] = sponsorToComision[_inversor].sub(amount);
                s2c.balanceComision = s2c.balanceComision.sub(amount);
                s2c.balanceComisionDone = s2c.balanceComisionDone.add(amount);
                _inversor.transfer(amount);
                emit payComisionSponsorETH(_inversor, now, amount);
            }
        }
    }

    function payComision() public {
        address _inversor = msg.sender;
        payComisionSponsor(_inversor);
    }

    function isSoftCapCompleted() public view returns (bool) {
        return s2c.isSoftCapComplete;
    }

    function softCapCompleted() public {
        uint totalBalanceUSD = weiToUSD(s2c.balance);
        if(totalBalanceUSD >= s2c.minCapUSD) {
            s2c.isSoftCapComplete = true;
        }
    }

    function balanceComisionOf(address _sponsor) public view returns (uint256) {
        return sponsorToComision[_sponsor];
    }

    function getNow() public returns (uint) {
        return now;
    }

    function() public payable {
        uint256 _amountWei = msg.value;
        address _buyer = msg.sender;
        uint valueUSD = weiToUSD(_amountWei);
        require(now <= s2c.endTime, 'endtime');
        require(inversors[_buyer] != false, 'No invest');
        require(valueUSD >= s2c.minPaymentUSD, 'min in USD not');
        emit ReceiveEthEvent(_buyer, _amountWei);

        uint tokensE18SinBono = weiToTokens(msg.value);
        uint tokensE18Bono = weiToTokensBono(msg.value);
        emit conversionETHToTMSYEvent(_buyer, msg.value, tokensE18SinBono, tokensE18Bono);

        uint tokensE18 = tokensE18SinBono.add(tokensE18Bono);
        require(token.sell(_buyer, tokensE18SinBono), "Falla la venta");
        if(tokensE18Bono > 0) {
            assert(token.sell(_buyer, tokensE18Bono));
        }

        uint256 _amountSponsor = (_amountWei * 10) / 100;
        uint256 _amountBeneficiary = (_amountWei * 90) / 100;

        s2c.totalTokensSold = s2c.totalTokensSold.add(tokensE18);
        s2c.totalWeiReceived = s2c.totalWeiReceived.add(_amountWei);
        buyerToSentWei[_buyer] = buyerToSentWei[_buyer].add(_amountWei);

        if(!s2c.isSoftCapComplete) {
            uint256 totalBalanceUSD = weiToUSD(s2c.balance);
            if(totalBalanceUSD >= s2c.minCapUSD) {
                softCapCompleted();
            }
        }

        address sponsor = inversorToSponsor[_buyer];
        sponsorToComisionList.push(sponsor);

        if(validateKYC[_buyer]) {
            s2c.balanceComision = s2c.balanceComision.add(_amountSponsor);
            sponsorToComision[sponsor] = sponsorToComision[sponsor].add(_amountSponsor);
        } else {
            s2c.balanceComisionHold = s2c.balanceComisionHold.add(_amountSponsor);
            sponsorToComisionHold[sponsor] = sponsorToComisionHold[sponsor].add(_amountSponsor);
            sponsorToComisionFromInversor[_buyer] = sponsorToComisionFromInversor[_buyer].add(_amountSponsor);
        }

        payComisionSponsor(sponsor);
        s2c.balance = s2c.balance.add(_amountBeneficiary);
    }

    function weiToUSD(uint _amountWei) public view returns (uint256) {
        uint256 ethers = _amountWei;
        uint256 valueUSD = s2c.rateUSDETH * _amountWei;
        emit conversionToUSDEvent(_amountWei, s2c.rateUSDETH, valueUSD);
        return valueUSD / 1e18;
    }

    function weiToTokensBono(uint _amountWei) public view returns (uint256) {
        uint bono = 0;
        uint256 valueUSD = weiToUSD(_amountWei);
        if(valueUSD >= uint(500 * 10**18)) bono = 10;
        if(valueUSD >= uint(1000 * 10**18)) bono = 20;
        if(valueUSD >= uint(2500 * 10**18)) bono = 30;
        if(valueUSD >= uint(5000 * 10**18)) bono = 40;
        if(valueUSD >= uint(10000 * 10**18)) bono = 50;

        uint256 bonoUsd = valueUSD.mul(bono).div(100);
        uint256 tokens = bonoUsd.mul(tokensPerUSD());
        return tokens;
    }

    function weiToTokens(uint _amountWei) public view returns (uint256) {
        uint256 valueUSD = weiToUSD(_amountWei);
        uint256 tokens = valueUSD.mul(tokensPerUSD());
        return tokens;
    }

    function tokensPerUSD() public pure returns (uint256) {
        return 65;
    }

    function canWithdraw() public view returns (bool);

    function withdraw(address _to, uint _amount) public returns (uint) {
        require(canWithdraw(), 'No es posible retirar');
        require(msg.sender == s2c.beneficiary, 'No puede solicitar el beneficiario los fondos');
        require(s2c.balance >= _amount, 'Sin fondos');
        require(s2c.balance >= _amount, 'No hay suficientes fondos');
        require(_to.call.value(_amount).gas(1)(), 'No se que es');
        s2c.balance = s2c.balance.sub(_amount);
        emit withdrawEvent(msg.sender, _to, _amount, now);
        return s2c.balance;
    }

    function changeEndTime(uint _date) onlyOwner public returns (bool) {
        s2c.endTime = _date;
        s2c.refundDeadlineTime = s2c.endTime + 30 days;
        emit ChangeEndTimeEvent(msg.sender, s2c.endTime, now);
        return true;
    }
}

contract Presale is CommonTokensale {
    uint public refundDeadlineTime;

    event RefundEthEvent(address indexed _buyer, uint256 _amountWei);

    constructor(
        address _token,
        address _beneficiary,
        uint _startTime,
        uint _endTime
    ) CommonTokensale(
        _token,
        _beneficiary,
        _startTime,
        _endTime
    ) public {
        refundDeadlineTime = _endTime + 3 * 30 days;
    }

    function canWithdraw() public view returns (bool) {
        return s2c.isSoftCapComplete;
    }

    function canRefund() public view returns (bool) {
        return !s2c.isSoftCapComplete && now > s2c.endTime && now <= refundDeadlineTime;
    }

    function refund() public {
        require(canRefund());
        address buyer = msg.sender;
        uint amount = buyerToSentWei[buyer];
        require(amount > 0);

        uint newBal = s2c.balance - amount;
        s2c.balance = newBal;
        emit RefundEthEvent(buyer, amount);
        buyerToSentWei[buyer] = 0;
        s2c.totalWeiRefunded = s2c.totalWeiRefunded.add(amount);
        buyer.transfer(amount);
    }
}

struct scalar2Vector {
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
    uint256 balance;
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

scalar2Vector s2c = scalar2Vector(0, false, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 250, 0, 0, 0, 0, 0, address(0), true, 0, 0, address(0), now + 365 days, address(0), address(0), address(0), address(0), 0, 0, 0, 0, 0, 18, 'TMSY', 'TMSY', false, 0);
