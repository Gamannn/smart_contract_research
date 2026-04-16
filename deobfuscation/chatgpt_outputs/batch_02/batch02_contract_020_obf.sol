pragma solidity ^0.4.24;

contract Pausable {
    event Paused();
    event Started();
    
    address public owner;
    bool public paused;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    
    modifier whenPaused() {
        require(paused);
        _;
    }
    
    constructor() public {
        owner = msg.sender;
        paused = false;
    }
    
    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
        if (paused) {
            emit Paused();
        } else {
            emit Started();
        }
    }
}

contract Token is Pausable {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public price;
    mapping(address => uint256) public maxSellAmount;
    mapping(address => uint256) public maxBuyAmount;
    mapping(address => mapping(address => uint256)) public allowance;
    
    uint256 public totalSupply;
    uint256 public totalIncome;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Income(uint256 amount);
    event PriceSet(address indexed account, uint256 price, uint256 maxSellAmount, uint256 maxBuyAmount);
    event Withdrawal(address indexed account, uint256 amount);
    event SellHolds(address indexed seller, address indexed buyer, uint256 amount, uint256 price);
    event SendHolds(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(string _name, string _symbol, uint256 _totalSupply) public {
        owner = msg.sender;
        totalSupply = _totalSupply;
        balances[owner] = totalSupply;
    }
    
    function() public payable {
        if (msg.value > 0) {
            totalIncome += msg.value / totalSupply;
            emit Income(msg.value);
        }
    }
    
    function getIncome() public view returns (uint256) {
        return (totalIncome - balances[msg.sender]) * balances[msg.sender];
    }
    
    function setPrice(uint256 _price, uint256 _maxSellAmount, uint256 _maxBuyAmount) public {
        price[msg.sender] = _price;
        maxSellAmount[msg.sender] = _maxSellAmount;
        maxBuyAmount[msg.sender] = _maxBuyAmount;
        emit PriceSet(msg.sender, _price, _maxSellAmount, _maxBuyAmount);
    }
    
    function withdraw() public whenNotPaused {
        if (balances[msg.sender] == 0) {
            return;
        }
        uint256 income = getIncome();
        balances[msg.sender] = totalIncome;
        msg.sender.transfer(income);
        emit Withdrawal(msg.sender, income);
    }
    
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(balances[msg.sender] >= _value);
        require(balances[_to] + _value > balances[_to]);
        
        uint256 senderIncome = (totalIncome - balances[msg.sender]) * _value;
        uint256 receiverIncome = (totalIncome - balances[_to]) * _value;
        
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        
        balances[_to] = totalIncome - receiverIncome / balances[_to];
        msg.sender.transfer(senderIncome);
        
        emit Transfer(msg.sender, _to, _value);
        emit Withdrawal(msg.sender, senderIncome);
        
        return true;
    }
    
    function sellHolds(address _seller) public payable whenNotPaused {
        require(price[_seller] > 0);
        
        uint256 amount = msg.value / price[_seller];
        if (amount >= balances[_seller]) {
            amount = balances[_seller];
        }
        if (amount >= maxBuyAmount[_seller]) {
            amount = maxBuyAmount[_seller];
        }
        
        require(amount > 0);
        
        maxBuyAmount[_seller] -= amount;
        transferFrom(_seller, msg.sender, amount);
        
        _seller.transfer(msg.value);
        emit SellHolds(_seller, msg.sender, amount, price[_seller]);
    }
    
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
    
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(allowance[_from][msg.sender] >= _value);
        
        allowance[_from][msg.sender] -= _value;
        transfer(_from, _to, _value);
        
        return true;
    }
    
    function allowanceOf(address _owner, address _spender) public view returns (uint256) {
        return allowance[_owner][_spender];
    }
}