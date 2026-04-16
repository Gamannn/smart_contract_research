pragma solidity ^0.4.14;

contract TestConf {
    bytes32 public symbol;
    bytes32 public name;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => uint256) public balances;
    mapping(bytes32 => uint256) public productLimits;
    mapping(bytes32 => uint256) public productPrices;
    mapping(address => mapping(bytes32 => uint256)) productOwners;

    struct ContractState {
        uint256 currentTokenPrice;
        uint256 currentEthPrice;
        uint256 totalSupply;
        uint256 initialIssuance;
        address owner;
        address listenerAddr;
    }

    ContractState state;

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

    function safeMul(uint a, uint b) constant internal returns(uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) constant internal returns(uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) constant internal returns(uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

    function getBalance(address _addr) constant returns(uint) {
        return balances[_addr];
    }

    function getTotalSupply() constant returns(uint) {
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

    function getEthPrice() constant returns(uint256) {
        return state.currentEthPrice;
    }

    function updateEthPrice(uint256 price) {
        assert(msg.sender == state.owner);
        state.currentEthPrice = price;
    }

    function createProduct(bytes32 _name, uint128 price, uint256 limit) returns(bool) {
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

    function modifyProduct(bytes32 _name, uint256 newPrice, uint256 newLimit) {
        assert(msg.sender == state.owner);
        productPrices[_name] = newPrice;
        productLimits[_name] = newLimit;
    }

    function inventoryProduct(bytes32 _name) constant returns(uint256) {
        return productLimits[_name];
    }

    function checkProduct(bytes32 _name) constant returns(uint256) {
        return productOwners[msg.sender][_name];
    }

    function purchaseProduct(bytes32 _name, uint256 amount) {
        assert(productLimits[_name] > 0);
        uint256 totalPrice = safeMul(productPrices[_name], amount);
        assert(balances[msg.sender] >= totalPrice);
        balances[msg.sender] = safeSub(balances[msg.sender], totalPrice);
        state.totalSupply += totalPrice;
        productLimits[_name] = safeSub(productLimits[_name], amount);
        productOwners[msg.sender][_name] = safeAdd(productOwners[msg.sender][_name], amount);
    }

    function purchaseToken() payable returns (uint256 tokensSent) {
        uint256 totalTokens = msg.value / (state.currentTokenPrice * (1000000000000000000 / state.currentEthPrice)) / 1000000000000000000;
        state.totalSupply = safeSub(state.totalSupply, totalTokens);
        balances[msg.sender] = safeAdd(balances[msg.sender], totalTokens);
        return totalTokens;
    }

    function transferTo(address _to, uint256 _value) payable returns(bool) {
        assert(_to != 0 && _value > 0);
        assert(balances[msg.sender] >= _value);
        assert(safeAdd(balances[_to], _value) > balances[_to]);
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns(bool) {
        assert(allowed[_from][msg.sender] >= _value);
        assert(_value > 0);
        assert(balances[_to] + _value > balances[_to]);
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        return true;
    }

    function approve(address _spender, uint _value) returns(bool) {
        allowed[msg.sender][_spender] = _value;
        return true;
    }

    function redeem() returns(bool) {
        assert(msg.sender == state.owner);
        assert(msg.sender.send(this.balance));
        return true;
    }

    function debugBalance() returns(uint) {
        return this.balance;
    }

    function allowance(address _owner, address _spender) constant returns(uint) {
        return allowed[_owner][_spender];
    }

    function() {
        revert();
    }
}