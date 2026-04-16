```solidity
pragma solidity ^0.4.24;

contract SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

contract Owned {
    address public owner;
    address public newOwner;
    address public pendingOwner;
    address public newOwnerAPI;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipAPITransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() public {
        owner = msg.sender;
        pendingOwner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyPendingOwner {
        require(msg.sender == pendingOwner);
        _;
    }
    
    modifier onlyOwnerOrPendingOwner {
        require(msg.sender == owner || msg.sender == pendingOwner);
        _;
    }
    
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    
    function proposeNewOwnerAPI(address _newOwnerAPI) public onlyOwner {
        pendingOwner = _newOwnerAPI;
    }
    
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
    
    function acceptOwnershipAPI() public onlyPendingOwner {
        emit OwnershipAPITransferred(pendingOwner, newOwnerAPI);
        pendingOwner = newOwnerAPI;
        newOwnerAPI = address(0);
    }
}

contract Pausable is Owned {
    event Pause();
    event Unpause();
    
    bool public paused = false;
    
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    
    modifier whenPaused() {
        require(paused);
        _;
    }
    
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }
    
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

contract KAASYToken is ERC20Interface, Pausable, SafeMath {
    string public symbol = "KAAS";
    string public name = "KAASY.AI Token";
    uint8 public decimals = 18;
    uint public _totalSupply;
    uint public startDate;
    uint public tradingDate;
    uint public bonusEnd20;
    uint public bonusEnd10;
    uint public bonusEnd05;
    uint public endDate;
    uint public minAmountETH;
    uint public maxAmountETH;
    uint public teamWOVestingPercentage;
    uint public teamWOVesting;
    uint public teamWithVesting;
    uint public maxSupply;
    uint public exchangeRate;
    uint public tradingStartDate;
    uint public icoEndDate;
    uint public soldSupply;
    uint public totalSold;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => uint256) contributedETH;
    mapping(address => bool) kycApproved;
    mapping(address => uint256) burnedTokens;
    
    event MintingFinished(uint indexed timestamp);
    event OwnBlockchainLaunched(uint indexed timestamp);
    event TokensBurned(address indexed burner, uint256 indexed amount, uint indexed timestamp);
    
    bool public isMintingFinished = false;
    bool public isOwnBlockchainLaunched = false;
    
    address public addrMarketing;
    address public addrLegal;
    address public addrHackathons;
    address public addrEarlySkills;
    address public addrUniversity;
    
    constructor() public {
        addrMarketing = 0x4f11859330D389F222476afd65096779Eb1aDf25;
        addrLegal = 0xe9486863859b0facB9C62C46F7e3B70C476bc838;
        addrHackathons = 0xDcdb9787ead2E0D3b12ED0cf8200Bc91F9Aaa045;
        addrEarlySkills = 0xe1e0769b37c1C66889BdFE76eaDfE878f98aa4cd;
        addrUniversity = 0x7a0De4748E5E0925Bf80989A7951E15a418e4326;
        
        soldSupply = 0;
        startDate = 1535760000;
        bonusEnd20 = 1536969600;
        bonusEnd10 = 1538179200;
        bonusEnd05 = 1539388800;
        endDate = 1542240000;
        tradingDate = 1543536000;
        minAmountETH = 1 ether / 10;
        maxAmountETH = 1 ether * 5000;
        teamWOVestingPercentage = 15;
        maxSupply = 500000000 * 10**uint(decimals);
        teamWOVesting = maxSupply * 15 / 100;
        teamWithVesting = maxSupply * 15 / 100;
        
        balances[address(this)] = teamWithVesting;
        balances[owner] = teamWOVesting * (100 - teamWOVestingPercentage) / 100;
        balances[addrUniversity] = teamWOVesting * teamWOVestingPercentage / 100;
        
        emit Transfer(address(0), address(this), teamWithVesting);
        emit Transfer(address(0), owner, balances[owner]);
        emit Transfer(address(0), addrUniversity, balances[addrUniversity]);
        
        balances[addrEarlySkills] = maxSupply * 50 / 1000;
        kycApproved[addrEarlySkills] = true;
        emit Transfer(address(0), addrEarlySkills, balances[addrEarlySkills]);
        
        balances[addrHackathons] = maxSupply * 50 / 1000;
        kycApproved[addrHackathons] = true;
        emit Transfer(address(0), addrHackathons, balances[addrHackathons]);
        
        balances[addrLegal] = maxSupply * 45 / 1000;
        kycApproved[addrLegal] = true;
        emit Transfer(address(0), addrLegal, balances[addrLegal]);
        
        balances[addrMarketing] = maxSupply * 75 / 1000;
        kycApproved[addrMarketing] = true;
        emit Transfer(address(0), addrMarketing, balances[addrMarketing]);
        
        totalSold = balances[owner] + balances[addrUniversity] + balances[addrEarlySkills] + 
                   balances[addrHackathons] + balances[addrLegal] + balances[addrMarketing];
        exchangeRate = 10000;
    }
    
    function () public payable whenNotPaused {
        if (now > endDate && !isMintingFinished) {
            finishMinting();
            msg.sender.transfer(msg.value);
            return;
        }
        
        require(now >= startDate && now <= endDate && !isMintingFinished);
        require(msg.value >= minAmountETH && msg.value <= maxAmountETH);
        require(msg.value + contributedETH[msg.sender] <= maxAmountETH);
        require(kycApproved[msg.sender] == true);
        
        uint tokens = getTokensToIssue(msg.value);
        require(safeAdd(soldSupply, tokens) <= maxSupply);
        
        soldSupply = safeAdd(soldSupply, tokens);
        totalSold = safeAdd(totalSold, tokens);
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
        contributedETH[msg.sender] = safeAdd(contributedETH[msg.sender], msg.value);
        
        emit Transfer(address(0), msg.sender, tokens);
        owner.transfer(msg.value * 15 / 100);
    }
    
    function burnMyTokens() public {
        require(isOwnBlockchainLaunched);
        uint burnerBalance = balances[msg.sender];
        burnedTokens[msg.sender] = safeAdd(burnedTokens[msg.sender], burnerBalance);
        balances[msg.sender] = 0;
        emit TokensBurned(msg.sender, burnerBalance, now);
    }
    
    function burnTokens(address burner) public onlyOwner {
        require(isOwnBlockchainLaunched);
        uint burnerBalance = balances[burner];
        burnedTokens[burner] = safeAdd(burnedTokens[burner], burnerBalance);
        balances[burner] = 0;
        emit TokensBurned(burner, burnerBalance, now);
    }
    
    function launchOwnBlockchain() public onlyOwner {
        require(!isMintingFinished);
        require(!isOwnBlockchainLaunched);
        isOwnBlockchainLaunched = true;
        tradingStartDate = now + 3600;
        emit OwnBlockchainLaunched(now);
    }
    
    function finishMintingIfTime() public returns (bool success) {
        if (now > endDate && !isMintingFinished) {
            finishMinting();
            return true;
        } else if (totalSold >= maxSupply) {
            finishMinting();
            return true;
        } else if (isMintingFinished && address(this).balance > 0) {
            owner.transfer(address(this).balance);
        }
        return false;
    }
    
    function finishMinting() internal {
        icoEndDate = now + 3600;
        isMintingFinished = true;
        emit MintingFinished(now);
        owner.transfer(address(this).balance);
    }
    
    function getTokensToIssue(uint256 ethAmount) public view returns(uint256) {
        uint256 eurAmount = exchangeEthToEur(ethAmount);
        uint256 tokens = eurAmount / 10;
        tokens = tokens * (uint256)(10) ** (uint256)(decimals);
        
        if (now < bonusEnd20) {
            tokens = eurAmount * 12;
        } else if (now < bonusEnd10) {
            tokens = eurAmount * 11;
        } else if (now < bonusEnd05) {
            tokens = eurAmount * 105 / 10;
        }
        
        if (eurAmount >= 50000) {
            tokens = tokens * 13 / 10;
        } else if (eurAmount >= 10000) {
            tokens = tokens * 12 / 10;
        }
        
        return tokens;
    }
    
    function exchangeEthToEur(uint256 ethAmount) internal view returns(uint256 eurAmount) {
        return safeDiv(safeMul(ethAmount, exchangeRate), 1 ether);
    }
    
    function getEurAmount(uint256 weiAmount) internal view returns(uint256 eurAmount) {
        return safeDiv(safeMul(safeDiv(safeMul(weiAmount, 1000000000000000000), exchangeRate), 1 ether), 1000000000000000000);
    }
    
    function releaseTeamTokens(address receiver) public returns (bool) {
        require(address(this) != address(0));
        uint monthsPassed = (now - tradingStartDate) / 3600 / 24 / 30;
        uint256 totalToRelease = maxSupply * 15 / 100 * (100 - teamWOVestingPercentage) / 100;
        uint256 releasePerMonth = (monthsPassed + 1) * totalToRelease / 24;
        uint256 alreadyReleased = totalToRelease - balances[address(this)];
        uint256 toReleaseNow = releasePerMonth - alreadyReleased;
        require(toReleaseNow > 0);
        transferFrom(address(this), receiver, toReleaseNow);
        return true;
    }
    
    function setKYCStatus(address user, bool isApproved) public onlyOwnerOrPendingOwner returns (bool) {
        kycApproved[user] = isApproved;
        return true;
    }
    
    function getKYCStatus(address user) public view returns (bool) {
        return kycApproved[user];
    }
    
    function getName() public view returns (string) {
        return name;
    }
    
    function getSymbol() public view returns (string) {
        return symbol;
    }
    
    function getDecimals() public view returns (uint8) {
        return decimals;
    }
    
    function totalSupply() public constant returns (uint) {
        return totalSold - balances[address(0)];
    }
    
    function circulatingSupply() public constant returns (uint) {
        return totalSold - balances[address(0)] - balances[address(this)];
    }
    
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }
    
    function contributedETHOf(address user) public constant returns (uint amount) {
        return contributedETH[user];
    }
    
    function burnedTokensOf(address burner) public constant returns (uint amount) {
        return burnedTokens[burner];
    }
    
    function transfer(address to, uint tokens) public whenNotPaused returns (bool success) {
        if (now > endDate && !isMintingFinished) {
            finishMintingIfTime();
        }
        require(now >= tradingStartDate || kycApproved[to] == true);
        
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint tokens) public whenNotPaused returns (bool success) {
        if (now > endDate && !isMintingFinished) {
            finishMintingIfTime();
        }
        require(now >= tradingStartDate || kycApproved[to] == true);
        
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[from] = safeSub(balances[from], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function approveAndCall(address spender, uint tokens, bytes data) public whenNotPaused returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
    
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwnerOrPendingOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
    function claimAnyERC20Token(address tokenAddress) public onlyOwnerOrPendingOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, ERC20Interface(tokenAddress).balanceOf(address(this)));
    }
    
    function setExchangeRate(uint newRate) public onlyOwnerOrPendingOwner returns (bool success) {
        exchangeRate = newRate;
        return true;
    }
    
    function getExchangeRate() public view returns (uint256) {
        return exchangeRate;
    }
    
    function setEndDate(uint256 newEndDate) public onlyOwnerOrPendingOwner returns (bool success) {
        require(!isMintingFinished);
        require(!isOwnBlockchainLaunched);
        endDate = newEndDate;
        return true;
    }
    
    function setTokenInfo(string newName, string newSymbol, address newMarketingAddress) public whenPaused onlyOwnerOrPendingOwner returns (bool success) {
        name = newName;
        symbol = newSymbol;
        addrMarketing = newMarketingAddress;
        return true;
    }
}
```