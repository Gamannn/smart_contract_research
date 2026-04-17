```solidity
pragma solidity ^0.4.18;

contract ERC20Interface {
    function totalSupply() constant returns (uint256);
    function balanceOf(address tokenOwner) constant returns (uint256 balance);
    function transfer(address to, uint256 tokens) returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) returns (bool success);
    function approve(address spender, uint256 tokens) returns (bool success);
    function allowance(address tokenOwner, address spender) constant returns (uint256 remaining);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract Owned {
    address public owner;
    address public newOwner;
    
    event ownerChanged(address indexed oldOwner, address indexed newOwner);
    
    function Owned() {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function changeOwner(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }
    
    function acceptOwnership() {
        require(msg.sender == newOwner);
        ownerChanged(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract METADOLLAR is ERC20Interface, Owned {
    string public constant name = "METADOLLAR";
    string public constant symbol = "DOL";
    uint8 public constant decimals = 18;
    
    uint256 public totalSupply;
    uint256 public totalSold;
    uint256 public amountOfInvestments;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public frozenAccount;
    
    bool public preIcoIsRunning = false;
    bool public icoIsRunning = false;
    bool public icoExitIsPossible = false;
    bool public minimalGoalReached = false;
    
    uint256 public preIcoLimit;
    uint256 public icoMin;
    uint256 public icoMax;
    
    uint256 public preICOprice;
    uint256 public ICOprice;
    uint256 public currentTokenPrice;
    
    uint256 public buyCommission;
    uint256 public sellCommission;
    uint256 public sellPrice;
    
    address public supervisor;
    uint256 public countHolders;
    
    event FrozenFunds(address indexed by, address indexed target, string message);
    event BonusChanged(uint8 oldBonus, uint8 newBonus);
    event minGoalReached(uint256 amount, string message);
    event preIcoEnded(uint256 amount, string message);
    event priceUpdated(uint256 oldPrice, uint256 newPrice, string message);
    event withdrawed(address indexed to, uint256 amount, string message);
    event deposited(address indexed from, uint256 amount, string message);
    event orderToTransfer(address indexed by, address indexed from, address indexed to, uint256 amount, string message);
    event tokenCreated(address indexed by, uint256 amount, string message);
    event tokenDestroyed(address indexed by, uint256 amount, string message);
    event icoStatusUpdated(address indexed by, string message);
    
    function METADOLLAR() {
        preIcoIsRunning = true;
        icoIsRunning = false;
        icoExitIsPossible = false;
        minimalGoalReached = false;
        
        totalSupply = 100000000000000000000000000000;
        balanceOf[this] = totalSupply;
        allowance[this][supervisor] = totalSupply;
        
        currentTokenPrice = 0.001 * 1 ether;
        preICOprice = 0.001 * 1 ether;
        ICOprice = 0.00090 * 1 ether;
        sellPrice = 0.00090 * 1 ether;
        
        buyCommission = 20;
        sellCommission = 20;
        
        updatePrices();
    }
    
    function () payable {
        require(!frozenAccount[msg.sender]);
        if(msg.value > 0 && !frozenAccount[msg.sender]) {
            buyTokens();
        }
    }
    
    function totalSupply() constant returns (uint256) {
        return totalSupply;
    }
    
    function balanceOf(address tokenOwner) constant returns (uint256 balance) {
        return balanceOf[tokenOwner];
    }
    
    function allowance(address tokenOwner, address spender) constant returns (uint256 remaining) {
        return allowance[tokenOwner][spender];
    }
    
    function calculateTokens(uint256 amount) constant returns (uint256 tokens) {
        if(amount > 0) {
            tokens = amount / currentTokenPrice;
        } else {
            tokens = 0;
        }
    }
    
    function isFrozenAccount(address target) constant returns (bool frozen) {
        frozen = frozenAccount[target];
    }
    
    function buy() payable public {
        require(!frozenAccount[msg.sender]);
        require(msg.value > 0);
        
        uint256 commission = msg.value / buyCommission;
        require(address(this).send(commission));
        
        buyTokens();
    }
    
    function sell(uint256 amount) {
        require(!frozenAccount[msg.sender]);
        require(balanceOf[msg.sender] >= amount);
        require(sellPrice > 0);
        
        transferFrom(msg.sender, this, amount);
        
        uint256 revenue = amount * sellPrice;
        require(this.balance >= revenue);
        
        uint256 commission = revenue / sellCommission;
        require(address(this).send(commission));
        
        msg.sender.transfer(revenue - commission);
    }
    
    function sellAll() {
        require(!frozenAccount[msg.sender]);
        require(balanceOf[msg.sender] > 0);
        require(this.balance > 0);
        
        if(balanceOf[msg.sender] * sellPrice <= this.balance) {
            sell(balanceOf[msg.sender]);
        } else {
            sell(this.balance / sellPrice);
        }
    }
    
    function transfer(address to, uint256 tokens) returns (bool success) {
        assert(msg.sender != address(0));
        assert(to != address(0));
        require(!frozenAccount[msg.sender]);
        require(!frozenAccount[to]);
        require(balanceOf[msg.sender] >= tokens);
        require(balanceOf[msg.sender] - tokens < balanceOf[msg.sender]);
        require(balanceOf[to] + tokens > balanceOf[to]);
        require(tokens > 0);
        
        _transfer(msg.sender, to, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 tokens) returns (bool success) {
        assert(msg.sender != address(0));
        assert(from != address(0));
        assert(to != address(0));
        require(!frozenAccount[msg.sender]);
        require(!frozenAccount[from]);
        require(!frozenAccount[to]);
        require(balanceOf[from] >= tokens);
        require(allowance[from][msg.sender] >= tokens);
        require(balanceOf[from] - tokens < balanceOf[from]);
        require(balanceOf[to] + tokens > balanceOf[to]);
        require(tokens > 0);
        
        orderToTransfer(msg.sender, from, to, tokens, "Order to transfer metadollars from allowance");
        _transfer(from, to, tokens);
        allowance[from][msg.sender] -= tokens;
        return true;
    }
    
    function approve(address spender, uint256 tokens) returns (bool success) {
        require(!frozenAccount[msg.sender]);
        assert(spender != address(0));
        require(tokens >= 0);
        
        allowance[msg.sender][spender] = tokens;
        return true;
    }
    
    function checkMinGoal() internal {
        if(balanceOf[this] <= totalSupply - icoMin) {
            minimalGoalReached = true;
            minGoalReached(icoMin, "Minimal goal of ICO is reached!");
        }
    }
    
    function checkPreIcoStatus() internal {
        if(balanceOf[this] <= totalSupply - preIcoLimit) {
            preIcoIsRunning = false;
            preIcoEnded(preIcoLimit, "Token amount for preICO sold!");
        }
    }
    
    function buyTokens() internal {
        uint256 amount = msg.value;
        address sender = msg.sender;
        
        require(currentTokenPrice > 0);
        require(!frozenAccount[sender]);
        require(amount > 0);
        
        uint256 tokens = amount / currentTokenPrice;
        uint256 remainder = amount - (tokens * currentTokenPrice);
        
        require(balanceOf[this] >= tokens);
        
        amountOfInvestments = amountOfInvestments + (amount - remainder);
        
        checkMinGoal();
        _transfer(this, sender, tokens);
        
        if(!icoIsRunning) {
            checkPreIcoStatus();
        }
        
        if(remainder > 0) {
            sender.transfer(remainder);
        }
    }
    
    function _transfer(address from, address to, uint256 tokens) internal {
        assert(from != address(0));
        assert(to != address(0));
        require(tokens > 0);
        require(balanceOf[from] >= tokens);
        require(balanceOf[to] + tokens > balanceOf[to]);
        require(!frozenAccount[from]);
        require(!frozenAccount[to]);
        
        if(balanceOf[to] == 0) {
            countHolders += 1;
        }
        
        balanceOf[from] -= tokens;
        
        if(balanceOf[from] == 0) {
            countHolders -= 1;
        }
        
        balanceOf[to] += tokens;
        allowance[this][owner] = balanceOf[this];
        allowance[this][supervisor] = balanceOf[this];
        Transfer(from, to, tokens);
    }
    
    function updatePrices() internal {
        uint256 oldPrice = currentTokenPrice;
        
        if(preIcoIsRunning) {
            currentTokenPrice = preICOprice;
        } else {
            currentTokenPrice = ICOprice;
        }
        
        if(oldPrice != currentTokenPrice) {
            priceUpdated(oldPrice, currentTokenPrice, "Metadollar price updated!");
        }
    }
    
    function setPreICOprice(uint256 price) onlyOwner {
        require(price > 0);
        require(preICOprice != price);
        preICOprice = price;
        updatePrices();
    }
    
    function setICOprice(uint256 price) onlyOwner {
        require(price > 0);
        require(ICOprice != price);
        ICOprice = price;
        updatePrices();
    }
    
    function setBuyCommission(uint256 commission) onlyOwner {
        require(commission > 0);
        require(buyCommission != commission);
        buyCommission = commission;
        updatePrices();
    }
    
    function setSellCommission(uint256 commission) onlyOwner {
        require(commission > 0);
        require(sellCommission != commission);
        sellCommission = commission;
        updatePrices();
    }
    
    function setPrices(uint256 preICO, uint256 ICO) onlyOwner {
        require(preICO > 0);
        require(ICO > 0);
        preICOprice = preICO;
        ICOprice = ICO;
        updatePrices();
    }
    
    function setCommissions(uint256 buyComm, uint256 sellComm) onlyOwner {
        require(buyComm > 0);
        require(sellComm > 0);
        buyCommission = buyComm;
        sellCommission = sellComm;
        updatePrices();
    }
    
    function setSellPrice(uint256 price) onlyOwner {
        require(price >= 0);
        sellPrice = price;
    }
    
    function freezeAccount(address target, bool freeze) onlyOwner {
        require(target != owner);
        require(target != supervisor);
        frozenAccount[target] = freeze;
        
        if(freeze) {
            FrozenFunds(msg.sender, target, "Account set frozen!");
        } else {
            FrozenFunds(msg.sender, target, "Account set free for use!");
        }
    }
    
    function mintToken(uint256 amount) onlyOwner {
        require(amount > 0);
        require(balanceOf[this] <= icoMax);
        require(balanceOf[this] + amount <= totalSupply);
        
        totalSupply += amount;
        balanceOf[this] += amount;
        allowance[this][owner] = balanceOf[this];
        allowance[this][supervisor] = balanceOf[this];
        tokenCreated(msg.sender, amount, "Additional metadollars created!");
    }
    
    function burnToken(uint256 amount) onlyOwner {
        require(amount > 0);
        require(balanceOf[this] >= amount);
        require(totalSupply >= amount);
        require(balanceOf[this] - amount >= 0);
        require(totalSupply - amount >= 0);
        
        balanceOf[this] -= amount;
        totalSupply -= amount;
        allowance[this][owner] = balanceOf[this];
        allowance[this][supervisor] = balanceOf[this];
        tokenDestroyed(msg.sender, amount, "An amount of metadollars destroyed!");
    }
    
    function changeSupervisor(address _supervisor) onlyOwner {
        assert(_supervisor != address(0));
        address oldSupervisor = supervisor;
        supervisor = _supervisor;
        ownerChanged(msg.sender, oldSupervisor, _supervisor);
        allowance[this][oldSupervisor] = 0;
        allowance[this][_supervisor] = balanceOf[this];
    }
    
    function withdraw() onlyOwner {
        require(this.balance > 0);
        require(icoExitIsPossible);
        withdrawAmount(this.balance);
    }
    
    function withdrawAmount(uint256 amount) onlyOwner {
        uint256 contractbalance = this.balance;
        address sender = msg.sender;
        require(amount <= contractbalance);
        require(icoExitIsPossible);
        
        withdrawed(sender, amount, "wei withdrawed");
        sender.transfer(amount);
    }
    
    function deposit() payable onlyOwner {
        require(msg.value > 0);
        require(msg.sender.balance >= msg.value);
        
        deposited(msg.sender, msg.value, "wei deposited");
    }
    
    function setIcoExit(bool exit) onlyOwner {
        require(icoExitIsPossible != exit);
        icoExitIsPossible = exit;
    }
    
    function setIcoStatus(bool status) onlyOwner {
        require(icoIsRunning != status);
        icoIsRunning = status;
        
        if(status) {
            icoStatusUpdated(msg.sender, "Coin offering was stopped!");
        } else {
            icoStatusUpdated(msg.sender, "Coin offering is running!");
        }
    }
    
    function exitIco() {
        require(icoExitIsPossible);
        require(!frozenAccount[msg.sender]);
        require(balanceOf[msg.sender] > 0);
        require(currentTokenPrice > 1);
        
        uint256 amount = balanceOf[msg.sender];
        uint256 revenue = amount * currentTokenPrice / 2;
        require(this.balance >= revenue);
        
        _transfer(msg.sender, this, amount);
        msg.sender.transfer(revenue);
    }
    
    function getAllMyTokensForAllEtherOnContract() {
        require(icoExitIsPossible);
        require(!frozenAccount[msg.sender]);
        require(balanceOf[msg.sender] > 0);
        
        uint256 amount = balanceOf[msg.sender];
        uint256 revenue = amount * currentTokenPrice / 2;
        require(this.balance <= revenue);
        
        _transfer(msg.sender, this, amount);
        msg.sender.transfer(this.balance);
    }
}
```