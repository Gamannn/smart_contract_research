pragma solidity ^0.4.16;

contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() onlyOwner whenNotPaused public returns (bool) {
        paused = true;
        emit Pause();
        return true;
    }

    function unpause() onlyOwner whenPaused public returns (bool) {
        paused = false;
        emit Unpause();
        return true;
    }
}

interface TokenRecipient {
    function receiveApproval(address from, uint256 value, address token, bytes extraData) external;
}

contract ERC20Token is Pausable {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);

    constructor(
        uint256 initialSupply,
        uint256 maxSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply;
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
        decimals = 18;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != 0x0);
        require(balanceOf[from] >= value);
        require(balanceOf[to] + value > balanceOf[to]);

        uint256 previousBalances = balanceOf[from] + balanceOf[to];
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
        assert(balanceOf[from] + balanceOf[to] == previousBalances);
    }

    function transfer(address to, uint256 value) whenNotPaused public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) whenNotPaused public returns (bool) {
        require(value <= allowance[from][msg.sender]);
        allowance[from][msg.sender] -= value;
        _transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) whenNotPaused public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function approveAndCall(address spender, uint256 value, bytes extraData) public returns (bool) {
        TokenRecipient spenderContract = TokenRecipient(spender);
        if (approve(spender, value)) {
            spenderContract.receiveApproval(msg.sender, value, this, extraData);
            return true;
        }
    }

    function burn(uint256 value) public returns (bool) {
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;
        totalSupply -= value;
        emit Burn(msg.sender, value);
        return true;
    }

    function burnFrom(address from, uint256 value) public returns (bool) {
        require(balanceOf[from] >= value);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;
        allowance[from][msg.sender] -= value;
        totalSupply -= value;
        emit Burn(from, value);
        return true;
    }
}

contract AdvancedToken is ERC20Token {
    mapping(address => bool) public frozenAccount;

    event FrozenFunds(address target, bool frozen);

    constructor(
        uint256 initialSupply,
        uint256 maxSupply,
        string tokenName,
        string tokenSymbol
    ) ERC20Token(initialSupply, maxSupply, tokenName, tokenSymbol) public {}

    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        require(totalSupply + mintedAmount <= maxSupply);
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }

    function freezeAccount(address target) onlyOwner public {
        frozenAccount[target] = true;
        emit FrozenFunds(target, true);
    }

    function unfreezeAccount(address target) onlyOwner public {
        frozenAccount[target] = false;
        emit FrozenFunds(target, false);
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != 0x0);
        require(balanceOf[from] >= value);
        require(balanceOf[to] + value >= balanceOf[to]);
        require(!frozenAccount[from]);
        require(!frozenAccount[to]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    function () payable public {}
}