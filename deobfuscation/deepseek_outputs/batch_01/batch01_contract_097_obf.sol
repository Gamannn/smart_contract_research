pragma solidity ^0.4.11;

contract MPY {
    string public constant name = "MatchPay Token";
    string public constant symbol = "MPY";
    uint8 public constant decimals = 18;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event MPYCreation(address indexed owner, uint256 amount);
    event MPYRefund(address indexed owner, uint256 amount);

    struct ContractState {
        bool finalized;
        uint256 ownerTokens;
        uint256 minCap;
        uint256 totalSupply;
        uint256 maxCap;
        uint256 rate;
        uint256 fundingEndBlock;
        uint256 fundingStartBlock;
        address owner;
    }

    ContractState public state = ContractState({
        finalized: false,
        ownerTokens: 300 * (10 ** uint256(decimals)),
        minCap: 100 * (10 ** uint256(decimals)),
        totalSupply: 0,
        maxCap: 30000 * (10 ** uint256(decimals)),
        rate: 10,
        fundingEndBlock: 0,
        fundingStartBlock: 0,
        owner: address(0)
    });

    modifier is_live() {
        require(block.number >= state.fundingStartBlock && block.number <= state.fundingEndBlock);
        _;
    }

    modifier only_owner(address _who) {
        require(_who == state.owner);
        _;
    }

    function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

    function safeSubtract(uint256 a, uint256 b) internal returns (uint256) {
        assert(a >= b);
        uint256 c = a - b;
        return c;
    }

    function safeMult(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function MPY(uint256 _fundingStartBlock, uint256 _fundingEndBlock) {
        state.owner = msg.sender;
        state.fundingStartBlock = _fundingStartBlock;
        state.fundingEndBlock = _fundingEndBlock;
    }

    function balanceOf(address _owner) constant returns (uint256) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _amount) returns (bool success) {
        if (balances[msg.sender] >= _amount &&
            _amount > 0 &&
            balances[_to] + _amount > balances[_to])
        {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _amount) returns (bool success) {
        if (balances[_from] >= _amount &&
            allowed[_from][msg.sender] >= _amount &&
            _amount > 0 &&
            balances[_to] + _amount > balances[_to])
        {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint256 _amount) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256) {
        return allowed[_owner][_spender];
    }

    function getStats() constant returns (uint256, uint256, uint256, uint256) {
        return (state.minCap, state.maxCap, state.totalSupply, state.fundingEndBlock);
    }

    function getSupply() constant returns (uint256) {
        return state.totalSupply;
    }

    function() is_live() payable {
        if (msg.value == 0) revert();
        if (state.finalized) revert();

        uint256 tokens = safeMult(msg.value, state.rate);
        uint256 newTotalSupply = safeAdd(state.totalSupply, tokens);

        if (state.maxCap < newTotalSupply) revert();

        state.totalSupply = newTotalSupply;
        balances[msg.sender] += tokens;
        MPYCreation(msg.sender, tokens);
    }

    function emergencyPay() external payable {}

    function finalize() external {
        if (msg.sender != state.owner) revert();
        if (state.totalSupply < state.minCap) revert();
        if (block.number <= state.fundingEndBlock && state.totalSupply < state.maxCap) revert();
        if (!state.owner.send(this.balance)) revert();

        balances[state.owner] += state.ownerTokens;
        state.totalSupply += state.ownerTokens;
        state.finalized = true;
    }

    function refund() external {
        if (state.finalized) revert();
        if (block.number <= state.fundingEndBlock) revert();
        if (state.totalSupply >= state.minCap) revert();
        if (msg.sender == state.owner) revert();

        uint256 mpyVal = balances[msg.sender];
        if (mpyVal == 0) revert();

        balances[msg.sender] = 0;
        state.totalSupply = safeSubtract(state.totalSupply, mpyVal);

        uint256 ethVal = mpyVal / state.rate;
        MPYRefund(msg.sender, ethVal);

        if (!msg.sender.send(ethVal)) revert();
    }
}