```solidity
pragma solidity ^0.4.11;

contract MatchPayToken {
    string public constant name = "MatchPay Token";
    string public constant symbol = "MPY";

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    struct TokenSale {
        bool finalized;
        uint256 ownerTokens;
        uint256 minCap;
        uint256 totalSupply;
        uint256 maxCap;
        uint256 tokenExchangeRate;
        uint256 fundingEndBlock;
        uint256 fundingStartBlock;
        address owner;
        uint256 decimals;
    }

    TokenSale public tokenSale = TokenSale(
        false,
        3 * (10**2) * (10**18),
        10 * (10**2) * (10**18),
        0,
        30 * (10**3) * (10**18),
        10,
        0,
        0,
        address(0),
        18
    );

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event MPYCreation(address indexed owner, uint256 value);
    event MPYRefund(address indexed owner, uint256 value);

    modifier isLive() {
        require(block.number >= tokenSale.fundingStartBlock && block.number <= tokenSale.fundingEndBlock);
        _;
    }

    modifier onlyOwner(address _who) {
        require(_who == tokenSale.owner);
        _;
    }

    function safeAdd(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal pure returns (uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

    function safeMult(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x * y;
        assert((x == 0) || (z / x == y));
        return z;
    }

    function MatchPayToken(uint256 _fundingStartBlock, uint256 _fundingEndBlock) public {
        tokenSale.owner = msg.sender;
        tokenSale.fundingStartBlock = _fundingStartBlock;
        tokenSale.fundingEndBlock = _fundingEndBlock;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _amount) public returns (bool success) {
        if (balances[msg.sender] >= _amount && _amount > 0 && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
        if (balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount > 0 && balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
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

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function getStats() public view returns (uint256, uint256, uint256, uint256) {
        return (tokenSale.minCap, tokenSale.maxCap, tokenSale.totalSupply, tokenSale.fundingEndBlock);
    }

    function getSupply() public view returns (uint256) {
        return tokenSale.totalSupply;
    }

    function() public isLive payable {
        if (msg.value == 0) revert();
        if (tokenSale.finalized) revert();

        uint256 tokens = safeMult(msg.value, tokenSale.tokenExchangeRate);
        uint256 newTotalSupply = safeAdd(tokenSale.totalSupply, tokens);

        if (tokenSale.maxCap < newTotalSupply) revert();

        tokenSale.totalSupply = newTotalSupply;
        balances[msg.sender] += tokens;
        MPYCreation(msg.sender, tokens);
    }

    function emergencyPay() external payable {}

    function finalize() external {
        if (msg.sender != tokenSale.owner) revert();
        if (tokenSale.totalSupply < tokenSale.minCap) revert();
        if (block.number <= tokenSale.fundingEndBlock && tokenSale.totalSupply < tokenSale.maxCap) revert();
        if (!tokenSale.owner.send(this.balance)) revert();

        balances[tokenSale.owner] += tokenSale.ownerTokens;
        tokenSale.totalSupply += tokenSale.ownerTokens;
        tokenSale.finalized = true;
    }

    function refund() external {
        if (tokenSale.finalized) revert();
        if (block.number <= tokenSale.fundingEndBlock) revert();
        if (tokenSale.totalSupply >= tokenSale.minCap) revert();
        if (msg.sender == tokenSale.owner) revert();

        uint256 mpyVal = balances[msg.sender];
        if (mpyVal == 0) revert();

        balances[msg.sender] = 0;
        tokenSale.totalSupply = safeSubtract(tokenSale.totalSupply, mpyVal);

        uint256 ethVal = mpyVal / tokenSale.tokenExchangeRate;
        MPYRefund(msg.sender, ethVal);

        if (!msg.sender.send(ethVal)) revert();
    }
}
```