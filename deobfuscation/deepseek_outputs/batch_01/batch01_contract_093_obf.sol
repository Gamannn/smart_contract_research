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

contract ERC20Interface {
    function balanceOf(address tokenOwner) public view returns (uint256 balance);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);
    
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed owner, address indexed spender, uint256 tokens);
}

contract MultiOwnable {
    mapping(address => bool) public isOwner;
    address[] public ownerHistory;
    
    event OwnerAddedEvent(address indexed _newOwner);
    event OwnerRemovedEvent(address indexed _oldOwner);
    
    constructor() public {
        address creator = msg.sender;
        ownerHistory.push(creator);
        isOwner[creator] = true;
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
    modifier ifNotPaused() {
        require(!s2c.paused);
        _;
    }
    
    modifier ifPaused() {
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

contract ERC20Token is ERC20Interface {
    using SafeMath for uint256;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    function balanceOf(address tokenOwner) public view returns (uint256 balance) {
        return balances[tokenOwner];
    }
    
    function transfer(address to, uint256 tokens) public returns (bool) {
        require(to != address(0));
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 tokens) public returns (bool) {
        require(to != address(0));
        
        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    
    function approve(address spender, uint256 tokens) public returns (bool) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }
}

contract CommonToken is ERC20Token, MultiOwnable {
    mapping(address => bool) public walletsNotLocked;
    
    event SellEvent(address indexed _seller, address indexed _buyer, uint256 tokens);
    event ChangeSellerEvent(address indexed _oldSeller, address indexed _newSeller);
    event Burn(address indexed _burner, uint256 tokens);
    event Unlock();
    
    constructor(
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
        
        uint256 sellerTokens = s2c.totalSupply
            .sub(s2c.teamTokens)
            .sub(s2c.partnersTokens)
            .sub(s2c.advisorsTokens)
            .sub(s2c.reservaTokens);
        
        balances[s2c.seller] = sellerTokens;
        emit Transfer(address(0), s2c.seller, sellerTokens);
        
        balances[s2c.teamWallet] = s2c.teamTokens;
        emit Transfer(address(0), s2c.teamWallet, s2c.teamTokens);
        
        balances[s2c.partnersWallet] = s2c.partnersTokens;
        emit Transfer(address(0), s2c.partnersWallet, s2c.partnersTokens);
        
        balances[s2c.reservaWallet] = s2c.reservaTokens;
        emit Transfer(address(0), s2c.reservaWallet, s2c.reservaTokens);
        
        balances[s2c.advisorsWallet] = s2c.advisorsTokens;
        emit Transfer(address(0), s2c.advisorsWallet, s2c.advisorsTokens);
    }
    
    modifier ifUnlocked(address from, address to) {
        require(walletsNotLocked[to]);
        require(!s2c.locked);
        _;
    }
    
    function unlock() public onlyOwner {
        require(s2c.locked);
        s2c.locked = false;
        emit Unlock();
    }
    
    function walletLocked(address _wallet) public onlyOwner {
        walletsNotLocked[_wallet] = false;
    }
    
    function walletNotLocked(address _wallet) public onlyOwner {
        walletsNotLocked[_wallet] = true;
    }
    
    function changeSeller(address newSeller) public onlyOwner returns (bool) {
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
    
    function sellNoDecimals(address to, uint256 tokens) public returns (bool) {
        return sell(to, tokens * 1e18);
    }
    
    function sell(address to, uint256 tokens) public returns (bool) {
        require(msg.sender == s2c.seller, "User not authorized");
        require(to != address(0), "Not address authorized");
        require(tokens > 0, "Value is 0");
        require(tokens <= balances[s2c.seller]);
        
        balances[s2c.seller] = balances[s2c.seller].sub(tokens);
        balances[to] = balances[to].add(tokens);
        
        emit Transfer(s2c.seller, to, tokens);
        
        s2c.totalSales++;
        s2c.tokensSold = s2c.tokensSold.add(tokens);
        
        emit SellEvent(s2c.seller, to, tokens);
        return true;
    }
    
    function transfer(address to, uint256 tokens) ifUnlocked(msg.sender, to) public returns (bool) {
        return super.transfer(to, tokens);
    }
    
    function transferFrom(address from, address to, uint256 tokens) ifUnlocked(from, to) public returns (bool) {
        return super.transferFrom(from, to, tokens);
    }
    
    function burn(uint256 tokens) public returns (bool) {
        require(tokens > 0, "Value is zero");
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        s2c.totalSupply = s2c.totalSupply.sub(tokens);
        
        emit Transfer(msg.sender, address(0), tokens);
        emit Burn(msg.sender, tokens);
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
    
    event ReceiveEthEvent(address indexed _buyer, uint256 _amountWei);
    event NewInverstEvent(address indexed _child, address indexed _sponsor);
    event ComisionEvent(address indexed _sponsor, address indexed _child, uint256 tokens, uint256 _comision);
    event ComisionPayEvent(address indexed _sponsor, uint256 tokens, uint256 _comision);
    event ComisionInversorInTokensEvent(address indexed _sponsor, bool status);
    event ChangeEndTimeEvent(address _sender, uint256 endTime, uint256 _date);
    event verifyKycEvent(address _sender, uint256 _date, bool _status);
    event payComisionSponsorTMSY(address _sponsor, uint256 _date, uint256 tokens);
    event payComisionSponsorETH(address _sponsor, uint256 _date, uint256 tokens);
    event withdrawEvent(address _sender, address to, uint256 amount, uint256 _date);
    event conversionToUSDEvent(uint256 tokens, uint256 rateUsd, uint256 usds);
    event newRatioEvent(uint256 tokens, uint256 date);
    event conversionETHToTMSYEvent(address _buyer, uint256 amount, uint256 tokensE18SinBono, uint256 tokensE18Bono);
    event createContractEvent(address _token, address _beneficiary, uint256 _startTime, uint256 _endTime);
    
    mapping(address => bool) public inversors;
    address[] public inversorsList;
    mapping(address => address) public inversorToSponsor;
    
    constructor(
        address _token,
        address _beneficiary,
        uint256 _startTime,
        uint256 _endTime
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
    
    function setRatio(uint256 _rate) public onlyOwner returns (bool) {
        s2c.rateUSDETH = _rate;
        emit newRatioEvent(s2c.rateUSDETH, now);
        return true;
    }
    
    function burn(uint256 tokens) public onlyOwner returns (bool) {
        return token.burn(tokens);
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
    
    function inversorIsKyc(address investor) public returns (bool) {
        return validateKYC[investor];
    }
    
    function unVerifyKyc(address _inversor) public onlyOwner returns (bool) {
        require(!s2c.isSoftCapComplete);
        
        validateKYC[_inversor] = false;
        address sponsor = inversorToSponsor[_inversor];
        uint256 balanceHold = sponsorToComisionFromInversor[_inversor];
        
        s2c.balanceComision = s2c.balanceComision.sub(balanceHold);
        s2c.balanceComisionHold = s2c.balanceComisionHold.add(balanceHold);
        
        sponsorToComision[sponsor] = sponsorToComision[sponsor].sub(balanceHold);
        sponsorToComisionHold[sponsor] = sponsorToComisionHold[sponsor].add(balanceHold);
        
        emit verifyKycEvent(_inversor, now, false);
        return true;
    }
    
    function verifyKyc(address _inversor) public onlyOwner returns (bool) {
        validateKYC[_inversor] = true;
        address sponsor = inversorToSponsor[_inversor];
        uint256 balanceHold = sponsorToComisionFromInversor[_inversor];
        
        s2c.balanceComision = s2c.balanceComision.add(balanceHold);
        s2c.balanceComisionHold = s2c.balanceComisionHold.sub(balanceHold);
        
        sponsorToComision[sponsor] = sponsorToComision[sponsor].add(balanceHold);
        sponsorToComisionHold[sponsor] = sponsorToComisionHold[sponsor].sub(balanceHold);
        
        emit verifyKycEvent(_inversor, now, true);
        return true;
    }
    
    function buyerToSentWeiOf(address investor) public view returns (uint256) {
        return buyerToSentWei[investor];
    }
    
    function balanceOf(address investor) public view returns (uint256) {
        return token.balanceOf(investor);
    }
    
    function balanceOfComision(address investor) public view returns (uint256) {
        return sponsorToComision[investor];
    }
    
    function balanceOfComisionHold(address investor) public view returns (uint256) {
        return sponsorToComisionHold[investor];
    }
    
    function balanceOfComisionDone(address investor) public view returns (uint256) {
        return sponsorToComisionDone[investor];
    }
    
    function isInversor(address investor) public view returns (bool) {
        return inversors[investor];
    }
    
    function payComisionSponsor(address _inversor) private {
        if (comisionInTokens[_inversor]) {
            uint256 val = 0;
            uint256 valueHold = sponsorToComisionHold[_inversor];
            uint256 valueReady = sponsorToComision[_inversor];
            val = valueReady.add(valueHold);
            
            if (val > 0) {
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
            if (amount > 0) {
                require(s2c.balanceComision >= amount);
                assert(s2c.isSoftCapComplete);
                assert(validateKYC[_inversor]);
                
                sponsorToComision[_inversor] = sponsorToComision[_inversor].sub(amount);
                s2c.balanceComision = s2c.balanceComision.sub(amount);
                s2c.balanceComisionDone = s2c.balanceComisionDone.add(amount);
                
                _inversor.transfer(amount);
                emit payComisionSponsorETH(_in