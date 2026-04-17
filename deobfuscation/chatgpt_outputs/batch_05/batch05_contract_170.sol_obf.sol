pragma solidity 0.4.18;

contract SafeMath {
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(a >= b);
        return a - b;
    }

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
}

contract ERC20Interface {
    uint256 public totalSupply;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is ERC20Interface, SafeMath {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] = safeSub(balances[msg.sender], _value);
            balances[_to] = safeAdd(balances[_to], _value);
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] = safeAdd(balances[_to], _value);
            balances[_from] = safeSub(balances[_from], _value);
            allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract GLXCoin is StandardToken, Ownable {
    string public constant name = "GLXCoin";
    string public constant symbol = "GLXC";
    uint8 public constant decimals = 18;
    uint256 public constant tokenCreationCap = 1000000 * 10**uint256(decimals);

    uint256 public fundingStartBlock;
    uint256 public fundingEndBlock;
    bool public isFinalized = false;
    address public ethFundDeposit;
    uint256 public tokenExchangeRate = 1000;

    event CreateGLX(address indexed _to, uint256 _value);
    event Mint(address indexed _to, uint256 _value);

    function GLXCoin() public {
        ethFundDeposit = msg.sender;
        fundingStartBlock = block.number;
        fundingEndBlock = fundingStartBlock + 100000;
    }

    function createTokens() internal {
        if (isFinalized) revert();
        if (block.number > fundingEndBlock) revert();
        if (msg.value < 1 ether) revert();

        uint256 tokens = safeMul(msg.value, tokenExchangeRate);
        uint256 checkedSupply = safeAdd(totalSupply, tokens);

        if (tokenCreationCap < checkedSupply) revert();

        totalSupply = checkedSupply;
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
        CreateGLX(msg.sender, tokens);
    }

    function () public payable {
        createTokens();
    }

    function finalize() external onlyOwner {
        if (!ethFundDeposit.send(this.balance)) revert();
        isFinalized = true;
    }

    function changeFundingEndBlock(uint256 _newFundingEndBlock) external onlyOwner {
        require(_newFundingEndBlock > fundingStartBlock);
        fundingEndBlock = _newFundingEndBlock;
    }
}