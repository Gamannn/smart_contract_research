```solidity
pragma solidity ^0.4.18;

contract TokenInterface {
    function totalSupply() constant returns (uint256);
    function balanceOf(address owner) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    function transferFrom(address from, address to, uint256 value) returns (bool);
    function approve(address spender, uint256 value) returns (bool);
    function allowance(address owner, address spender) constant returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
    address public owner;
    address constant internal supervisor = 0x2d6808bC989CbEB46cc6dd75a6C90deA50e3e504;
    event OwnerChanged(address indexed previousOwner, address indexed newOwner);

    function Ownable() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        require(newOwner != address(0));
        OwnerChanged(owner, newOwner);
        owner = newOwner;
    }
}

contract MetaDollar is TokenInterface, Ownable {
    string public constant name = "METADOLLAR";
    string public constant symbol = "DOL";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => bool) frozenAccounts;
    event FrozenFunds(address target, bool frozen);
    event BonusChanged(uint8 previousBonus, uint8 newBonus);
    event MinGoalReached(uint256 amountRaised, string message);
    event PreIcoEnded(uint256 amountRaised, string message);
    event PriceUpdated(uint256 oldPrice, uint256 newPrice, string message);
    event Withdrawn(address indexed to, uint256 amount, string message);
    event Deposited(address indexed from, uint256 amount, string message);
    event OrderToTransfer(address indexed from, address indexed to, uint256 value, string message);
    event TokenCreated(address indexed to, uint256 value, string message);
    event TokenDestroyed(address indexed from, uint256 value, string message);
    event IcoStatusUpdated(address indexed by, string message);

    function MetaDollar() {
        totalSupply = 100000000000000000000000000000;
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address owner) constant returns (uint256) {
        return balances[owner];
    }

    function transfer(address to, uint256 value) returns (bool) {
        require(to != address(0));
        require(value <= balances[msg.sender]);
        require(!frozenAccounts[msg.sender]);
        require(!frozenAccounts[to]);

        balances[msg.sender] -= value;
        balances[to] += value;
        Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) returns (bool) {
        require(to != address(0));
        require(value <= balances[from]);
        require(value <= allowed[from][msg.sender]);
        require(!frozenAccounts[from]);
        require(!frozenAccounts[to]);

        balances[from] -= value;
        balances[to] += value;
        allowed[from][msg.sender] -= value;
        Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) returns (bool) {
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) constant returns (uint256) {
        return allowed[owner][spender];
    }

    function freezeAccount(address target, bool freeze) onlyOwner {
        frozenAccounts[target] = freeze;
        FrozenFunds(target, freeze);
    }

    function mintToken(address target, uint256 mintedAmount) onlyOwner {
        balances[target] += mintedAmount;
        totalSupply += mintedAmount;
        TokenCreated(target, mintedAmount, "Additional metadollars created!");
    }

    function burnToken(uint256 burnAmount) onlyOwner {
        require(balances[msg.sender] >= burnAmount);
        balances[msg.sender] -= burnAmount;
        totalSupply -= burnAmount;
        TokenDestroyed(msg.sender, burnAmount, "An amount of metadollars destroyed!");
    }

    function withdrawEther(uint256 amount) onlyOwner {
        require(this.balance >= amount);
        owner.transfer(amount);
        Withdrawn(owner, amount, "wei withdrawn");
    }

    function depositEther() payable {
        require(msg.value > 0);
        Deposited(msg.sender, msg.value, "wei deposited");
    }
}
```