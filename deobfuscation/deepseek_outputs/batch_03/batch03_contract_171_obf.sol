pragma solidity ^0.4.14;

contract TestConf {
    bytes32 public symbol;
    bytes32 public name;
    
    mapping(address => mapping(address => uint256)) public allowed;
    mapping(address => uint256) public balances;
    mapping(bytes32 => uint256) public productLimits;
    mapping(bytes32 => uint256) public productPrices;
    mapping(address => mapping(bytes32 => uint256)) public productOwners;
    
    struct State {
        uint256 currentTokenPrice;
        uint256 currentEthPrice;
        uint256 totalSupply;
        uint256 initialIssuance;
        address owner;
        address listenerAddr;
    }
    
    State public state;
    
    function TestConf() {
        name = "TestConf";
        state.totalSupply = 1000000;
        state.initialIssuance = state.totalSupply;
        state.owner = 0x443B9375536521127DBfABff21f770e4e684475d;
        state.currentEthPrice = 20000;
        state.currentTokenPrice = 100;
        symbol = "TEST1";
        balances[state.owner] = 100;
    }
    
    function safeMul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function safeSub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function safeAdd(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
    
    function balanceOf(address _addr) constant returns (uint256 bal) {
        return balances[_addr];
    }
    
    function totalSupply() constant returns (uint256) {
        return state.totalSupply;
    }
    
    function setTokenPrice(uint128 _amount) {
        assert(msg.sender == state.owner);
        state.currentTokenPrice = _amount;
    }
    
    function setEthPrice(uint128 _amount) {
        assert(msg.sender == state.owner);
        state.currentEthPrice = _amount;
    }
    
    function seeEthPrice() constant returns (uint256) {
        return state.currentEthPrice;
    }
    
    function __getEthPrice(uint256 price) {
        assert(msg.sender == state.owner);
        state.currentEthPrice = price;
    }
    
    function createProduct(bytes32 _name, uint128 price, uint256 limit) returns (bool success) {
        assert((msg.sender == state.owner) || (limit > 0));
        productPrices[_name] = price;
        productLimits[_name] = limit;
        return true;
    }
    
    function nullifyProduct(bytes32 _name) {
        assert(msg.sender == state.owner);
        productLimits[_name] = 0;
    }
    
    function modifyProductPrice(bytes32 _name, uint256 newPrice) {
        assert(msg.sender == state.owner);
        productPrices[_name] = newPrice;
    }
    
    function modifyProductLimit(bytes32 _name, uint256 newLimit) {
        assert(msg.sender == state.owner);
        productLimits[_name] = newLimit;
    }
    
    function modifyProductPriceAndLimit(bytes32 _name, uint256 newPrice, uint256 newLimit) {
        assert(msg.sender == state.owner);
        productPrices[_name] = newPrice;
        productLimits[_name] = newLimit;
    }
    
    function inventoryProduct(bytes32 _name) constant returns (uint256 productAmnt) {
        return productLimits[_name];
    }
    
    function checkProduct(bytes32 _name) constant returns (uint256 productAmnt) {
        return productOwners[msg.sender][_name];
    }
    
    function purchaseProduct(bytes32 _name, uint256 amnt) {
        require(productLimits[_name] > 0);
        require(safeSub(productLimits[_name], amnt) >= 0);
        uint256 totalPrice = safeMul(productPrices[_name], amnt);
        require(balances[msg.sender] >= totalPrice);
        
        balances[msg.sender] = safeSub(balances[msg.sender], totalPrice);
        state.totalSupply = safeAdd(state.totalSupply, totalPrice);
        productLimits[_name] = safeSub(productLimits[_name], amnt);
        productOwners[msg.sender][_name] = safeAdd(productOwners[msg.sender][_name], amnt);
    }
    
    function purchaseToken() payable returns (uint256 tokensSent) {
        uint256 totalTokens = msg.value / (state.currentTokenPrice * (1000000000000000000 / state.currentEthPrice)) / 1000000000000000000;
        state.totalSupply = safeSub(state.totalSupply, totalTokens);
        balances[msg.sender] = safeAdd(balances[msg.sender], totalTokens);
        return totalTokens;
    }
    
    function transferTo(address _to, uint256 _value) payable returns (bool success) {
        require(_to != address(0));
        require(_value > 0);
        require(balances[msg.sender] >= _value);
        require(safeAdd(balances[_to], _value) > balances[_to]);
        
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require(allowed[_from][msg.sender] >= _value);
        require(_value > 0);
        require(safeAdd(balances[_to], _value) > balances[_to]);
        
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        return true;
    }
    
    function __redeem() returns (bool success) {
        assert(msg.sender == state.owner);
        assert(msg.sender.send(this.balance));
        return true;
    }
    
    function __DEBUG_BAL() returns (uint256 bal) {
        return this.balance;
    }
    
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function() {
        revert();
    }
}