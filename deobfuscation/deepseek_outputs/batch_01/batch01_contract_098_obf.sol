```solidity
pragma solidity ^0.4.17;

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC20 {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Noxon is ERC20 {
    using SafeMath for uint256;
    
    string public constant name = "NOXON";
    string public constant symbol = "NOXON";
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    modifier onlyOwner() {
        require(msg.sender == state.owner);
        _;
    }
    
    function changeOwner(address newOwner) public onlyOwner {
        state.pendingOwner = newOwner;
    }
    
    function acceptOwnership() public {
        if (msg.sender == state.pendingOwner) {
            state.owner = state.pendingOwner;
            state.pendingOwner = address(0);
        }
    }
    
    function changeManager(address _newManager) public onlyOwner {
        state.newManager = _newManager;
    }
    
    function acceptManagership() public {
        if (msg.sender == state.newManager) {
            state.manager = state.newManager;
            state.newManager = address(0);
        }
    }
    
    function Noxon() public {
        require(state.totalSupply == 0);
        state.owner = msg.sender;
        state.manager = state.owner;
    }
    
    function NoxonInit() public payable onlyOwner returns (bool) {
        require(state.totalSupply == 0);
        require(state.initialized == 0);
        require(msg.value > 0);
        
        Transfer(0, msg.sender, 1);
        balances[state.owner] = 1;
        state.totalSupply = balances[state.owner];
        state._burnPrice = msg.value;
        state._emissionPrice = state._burnPrice.mul(2);
        state.initialized = block.timestamp;
        return true;
    }
    
    function lockEmission() public onlyOwner {
        state.emissionlocked = true;
    }
    
    function unlockEmission() public onlyOwner {
        state.emissionlocked = false;
    }
    
    function totalSupply() public constant returns (uint256) {
        return state.totalSupply;
    }
    
    function burnPrice() public constant returns (uint256) {
        return state._burnPrice;
    }
    
    function emissionPrice() public constant returns (uint256) {
        return state._emissionPrice;
    }
    
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        if (_to == address(this)) {
            return burnTokens(_amount);
        } else {
            if (balances[msg.sender] >= _amount && 
                _amount > 0 && 
                balances[_to] + _amount > balances[_to]) {
                balances[msg.sender] = balances[msg.sender].sub(_amount);
                balances[_to] = balances[_to].add(_amount);
                Transfer(msg.sender, _to, _amount);
                return true;
            } else {
                return false;
            }
        }
    }
    
    function burnTokens(uint256 _amount) private returns (bool success) {
        state._burnPrice = getBurnPrice();
        uint256 _burnPriceTmp = state._burnPrice;
        
        if (balances[msg.sender] >= _amount && _amount > 0) {
            balances[msg.sender] = balances[msg.sender].sub(_amount);
            state.totalSupply = state.totalSupply.sub(_amount);
            assert(state.totalSupply >= 1);
            
            msg.sender.transfer(_amount.mul(state._burnPrice));
            state._burnPrice = getBurnPrice();
            assert(state._burnPrice >= _burnPriceTmp);
            
            TokenBurned(msg.sender, _amount.mul(state._burnPrice), state._burnPrice, _amount);
            return true;
        } else {
            return false;
        }
    }
    
    event TokenBought(address indexed buyer, uint256 ethers, uint _emissionedPrice, uint amountOfTokens);
    event TokenBurned(address indexed buyer, uint256 ethers, uint _burnedPrice, uint amountOfTokens);
    
    function () public payable {
        uint256 _burnPriceTmp = state._burnPrice;
        require(state.emissionlocked == false);
        require(state._burnPrice > 0 && state._emissionPrice > state._burnPrice);
        require(msg.value > 0);
        
        uint256 amount = msg.value / state._emissionPrice;
        require(balances[msg.sender] + amount > balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].add(amount);
        state.totalSupply = state.totalSupply.add(amount);
        
        uint256 mg = msg.value / 2;
        state.manager.transfer(mg);
        
        TokenBought(msg.sender, msg.value, state._emissionPrice, amount);
        
        state._burnPrice = getBurnPrice();
        state._emissionPrice = state._burnPrice.mul(2);
        assert(state._burnPrice >= _burnPriceTmp);
    }
    
    function getBurnPrice() public returns (uint) {
        return this.balance / state.totalSupply;
    }
    
    event EtherReserved(uint etherReserved);
    
    function addToReserve() public payable returns (bool) {
        uint256 _burnPriceTmp = state._burnPrice;
        if (msg.value > 0) {
            state._burnPrice = getBurnPrice();
            state._emissionPrice = state._burnPrice.mul(2);
            EtherReserved(msg.value);
            assert(state._burnPrice >= _burnPriceTmp);
            return true;
        } else {
            return false;
        }
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
        if (balances[_from] >= _amount && 
            allowed[_from][msg.sender] >= _amount && 
            _amount > 0 && 
            balances[_to] + _amount > balances[_to] && 
            _to != address(this)) {
            balances[_from] = balances[_from].sub(_amount);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
            balances[_to] = balances[_to].add(_amount);
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
    
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function transferAnyERC20Token(address tokenAddress, uint amount) public onlyOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(state.owner, amount);
    }
    
    function burnAll() external returns (bool) {
        return burnTokens(balances[msg.sender]);
    }
    
    struct State {
        address newManager;
        address pendingOwner;
        address manager;
        address owner;
        bool emissionlocked;
        uint256 initialized;
        uint256 _emissionPrice;
        uint256 _burnPrice;
        uint256 totalSupply;
        uint8 _unused;
    }
    
    State state = State(address(0), address(0), address(0), address(0), false, 0, 0, 0, 0, 0);
}
```