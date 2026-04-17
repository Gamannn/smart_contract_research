pragma solidity ^0.4.10;

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
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }
}

contract ERC20Interface {
    uint256 public totalSupply;
    function transfer(address to, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function balanceOf(address owner) public view returns (uint256 balance);
    function approve(address spender, uint256 value) public returns (bool success);
    function allowance(address owner, address spender) public view returns (uint256 remaining);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20Interface, SafeMath {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    function transfer(address to, uint256 value) public returns (bool success) {
        if (balances[msg.sender] >= value && value > 0) {
            balances[msg.sender] = safeSub(balances[msg.sender], value);
            balances[to] = safeAdd(balances[to], value);
            Transfer(msg.sender, to, value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        if (balances[from] >= value && allowed[from][msg.sender] >= value && value > 0) {
            balances[to] = safeAdd(balances[to], value);
            balances[from] = safeSub(balances[from], value);
            allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], value);
            Transfer(from, to, value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address owner) public view returns (uint256 balance) {
        return balances[owner];
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256 remaining) {
        return allowed[owner][spender];
    }
}

contract MNDToken is StandardToken {
    string public constant name = "MNDToken";
    string public constant symbol = "MND";
    uint256 public constant decimals = 18;
    uint256 public constant tokenCreationCap = 6000000 * 10**decimals;
    uint256 public constant tokenCreationMin = 5000000 * 10**decimals;
    address public owner;
    address public wallet;
    uint256 public oneTokenInWei;
    uint256 public totalSupply;

    event CreateMND(address indexed to, uint256 value);

    function MNDToken() public {
        owner = msg.sender;
        wallet = 0x0077DA9DF6507655CDb3aB9277A347EDe759F93F;
        oneTokenInWei = 70175438596491;
    }

    function () payable public {
        createTokens();
    }

    function createTokens() internal {
        if (msg.value <= 0) revert();
        uint256 tokens = safeDiv(safeMul(msg.value, 10**decimals), oneTokenInWei);
        uint256 checkedSupply = safeAdd(totalSupply, tokens);

        if (tokenCreationCap < checkedSupply) revert();

        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
        totalSupply = checkedSupply;
        CreateMND(msg.sender, tokens);
    }

    function setPhaseToPreICO2() external onlyOwner returns (bool) {
        // Set phase to PreICO2
        return true;
    }

    function setPhaseToICO() external onlyOwner returns (bool) {
        // Set phase to ICO
        return true;
    }

    function setTokenPrice(uint256 price1, uint256 price2, uint256 price3) external onlyOwner returns (bool) {
        oneTokenInWei = price1;
        // Set other prices
        return true;
    }

    function withdraw() external onlyOwner returns (bool) {
        wallet.transfer(this.balance);
        return true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}