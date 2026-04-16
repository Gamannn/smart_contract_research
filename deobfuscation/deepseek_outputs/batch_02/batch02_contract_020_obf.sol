pragma solidity ^0.4.24;

contract Ownable {
    event PAUSED();
    event STARTED();
    
    address public owner;
    bool public paused;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier whenPaused() {
        require(paused);
        _;
    }
    
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
    
    function setPaused(bool _paused) onlyOwner public {
        paused = _paused;
        if (paused) {
            emit PAUSED();
        } else {
            emit STARTED();
        }
    }
}

contract Token is Ownable {
    mapping (address => uint) public balanceOf;
    mapping (address => uint256) public lastDividendPoint;
    mapping (address => uint256) public sellPrice;
    mapping (address => uint256) public sellLimit;
    mapping (address => mapping(address => uint256)) public allowance;
    
    uint256 public profitPerShare;
    uint256 public totalSupply;
    
    string public name;
    string public symbol;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event INCOME(uint256 amount);
    event PRICE_SET(address holder, uint balance, uint256 price, uint256 limit);
    event WITHDRAWAL(address holder, uint256 amount);
    event SELL_HOLDS(address seller, address buyer, uint amount, uint256 price);
    event SEND_HOLDS(address from, address to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(string _name, string _symbol, uint256 _totalSupply) public {
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
        totalSupply = _totalSupply;
        balanceOf[owner] = totalSupply;
        paused = false;
    }
    
    function receiveDividends() public payable {
        if (msg.value > 0) {
            profitPerShare += (msg.value / totalSupply);
            assert(profitPerShare * totalSupply > 0);
            emit INCOME(msg.value);
        }
    }
    
    function() public payable {
        receiveDividends();
    }
    
    function dividendsOwing(address _address) public view returns (uint256) {
        return (profitPerShare - lastDividendPoint[_address]) * balanceOf[_address];
    }
    
    function setPrice(uint256 price, uint256 limit) public {
        sellPrice[msg.sender] = price;
        sellLimit[msg.sender] = limit;
        emit PRICE_SET(msg.sender, balanceOf[msg.sender], price, limit);
    }
    
    function withdraw() public whenNotPaused {
        if (balanceOf[msg.sender] == 0) {
            return;
        }
        uint256 amount = dividendsOwing(msg.sender);
        lastDividendPoint[msg.sender] = profitPerShare;
        msg.sender.transfer(amount);
        emit WITHDRAWAL(msg.sender, amount);
    }
    
    function _transfer(address from, address to, uint256 amount) internal {
        require(balanceOf[from] >= amount);
        require(balanceOf[to] + amount > balanceOf[to]);
        
        uint256 fromDividends = (profitPerShare - lastDividendPoint[from]) * amount;
        uint256 toDividends = (profitPerShare - lastDividendPoint[to]) * balanceOf[to];
        
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        
        lastDividendPoint[to] = profitPerShare - toDividends / balanceOf[to];
        
        from.transfer(fromDividends);
        emit Transfer(from, to, amount);
        emit WITHDRAWAL(from, fromDividends);
    }
    
    function buyFrom(address seller) public payable whenNotPaused {
        require(sellPrice[seller] > 0);
        uint256 amount = msg.value / sellPrice[seller];
        
        if (amount >= balanceOf[seller]) {
            amount = balanceOf[seller];
        }
        if (amount >= sellLimit[seller]) {
            amount = sellLimit[seller];
        }
        require(amount > 0);
        
        sellLimit[seller] -= amount;
        _transfer(seller, msg.sender, amount);
        seller.transfer(msg.value);
        emit SELL_HOLDS(seller, msg.sender, amount, sellPrice[seller]);
    }
    
    function balanceOf(address _address) public view returns (uint256) {
        return balanceOf[_address];
    }
    
    function transfer(address to, uint amount) public whenNotPaused returns(bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) public whenNotPaused returns (bool) {
        require(allowance[from][msg.sender] >= amount);
        allowance[from][msg.sender] -= amount;
        _transfer(from, to, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowance[_owner][_spender];
    }
}