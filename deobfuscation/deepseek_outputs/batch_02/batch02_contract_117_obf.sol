```solidity
pragma solidity ^0.4.21;

interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}

contract Honeycomb {
    string public name = "Honeycomb";
    string public symbol = "COMB";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public tokenFactor = 100000000;
    uint256 public buyPrice;
    uint256 public sellPrice;
    uint256 public minimumPayout;
    uint256 public constant initialBuyPrice = 3141592650000000000000;
    uint256 public constant initialSellPrice = 1000000000000000;
    uint256 public constant buyConstant = 10000;
    uint256 public constant sellConstant = 4;
    uint256 public constant tokenLeft = 16384;
    uint256 public constant sqrt2 = 141421356;
    uint256 public constant precision = 100000000;
    
    address public owner;
    bool public ownershipTransferAllowed = false;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor() public {
        totalSupply = 1048576 * tokenFactor;
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
        emit Transfer(0, owner, totalSupply);
        updatePrices(balanceOf[this]);
    }
    
    function calculatePrice(uint256 tokenAmount) internal view returns (uint256 price) {
        price = initialBuyPrice * (tokenAmount * buyConstant) / (initialSellPrice + totalSupply * tokenAmount / sellConstant);
    }
    
    function updatePrices(uint256 newPrice) internal {
        buyPrice = newPrice;
        sellPrice = buyPrice * sqrt2 / precision;
    }
    
    function buy() payable public returns (uint256 amount) {
        amount = msg.value * buyPrice / tokenFactor;
        require(balanceOf[this] >= amount);
        require((2 * calculatePrice(balanceOf[this] - amount)) > sellPrice);
        _transfer(this, msg.sender, amount);
        updatePrices(calculatePrice(balanceOf[this]));
        return amount;
    }
    
    function() payable public {
        buy();
    }
    
    function sell(uint256 amount) public returns (uint256 revenue) {
        revenue = amount * tokenFactor / sellPrice;
        require(revenue >= minimumPayout);
        uint256 newPrice = calculatePrice(balanceOf[this] + amount);
        require(newPrice < sellPrice);
        _transfer(msg.sender, this, amount);
        updatePrices(newPrice);
        msg.sender.transfer(revenue);
        return revenue;
    }
    
    function transfer(address _to, uint256 _value) public {
        if (_to == address(this)) {
            sell(_value);
        } else {
            _transfer(msg.sender, _to, _value);
        }
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
    
    function setOwnershipTransferAllowed(bool allowed) public onlyOwner {
        ownershipTransferAllowed = allowed;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        require(ownershipTransferAllowed);
        owner = newOwner;
        ownershipTransferAllowed = false;
    }
    
    function setMinimumPayout(uint256 amount) public onlyOwner {
        minimumPayout = amount;
    }
    
    function withdraw(uint256 amount) public onlyOwner {
        require(amount <= minimumPayout);
        owner.transfer(amount);
    }
    
    function mint(uint256 amount) public onlyOwner {
        uint256 newPrice = calculatePrice(balanceOf[this] + amount);
        _transfer(owner, this, amount);
        updatePrices(newPrice);
    }
    
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
}
```