pragma solidity ^0.4.18;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC20Basic {
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) balances;

    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        Transfer(msg.sender, to, value);
        return true;
    }

    function balanceOf(address owner) public constant returns (uint256) {
        return balances[owner];
    }
}

contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) internal allowed;

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balances[from]);
        require(value <= allowed[from][msg.sender]);
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public constant returns (uint256) {
        return allowed[owner][spender];
    }

    function increaseApproval(address spender, uint addedValue) public returns (bool) {
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);
        Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function decreaseApproval(address spender, uint subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][spender];
        if (subtractedValue > oldValue) {
            allowed[msg.sender][spender] = 0;
        } else {
            allowed[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
}

contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }

    function transferOwnership(address newOwner) internal onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract PausableToken is StandardToken {
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        uint allowanceAmount = allowed[from][msg.sender];
        require(balances[from] >= value);
        require(allowanceAmount >= value);
        require(balances[to].add(value) >= balances[to]);
        balances[to] = balances[to].add(value);
        balances[from] = balances[from].sub(value);
        if (allowanceAmount < config.maxApprovalAmount) {
            allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        }
        Transfer(from, to, value);
        return true;
    }
}

contract EtherToken is PausableToken, Ownable {
    using SafeMath for uint256;
    string constant public name = "Ether Token";
    string constant public symbol = "WXETH";
    event Issuance(uint256 amount);
    event Destruction(uint256 amount);

    function EtherToken() public {
        config.isActive = true;
        config.issuer = msg.sender;
    }

    function setPaused(bool paused) public onlyOwner {
        config.isActive = !paused;
    }

    function emergencyWithdraw() public onlyOwner {
        require(!config.isActive);
        require(config.totalSupply > 0);
        require(config.issuer != 0x0);
        uint256 amount = config.totalSupply;
        config.totalSupply = config.totalSupply.sub(config.totalSupply);
        Transfer(config.issuer, this, config.totalSupply);
        Destruction(config.totalSupply);
        config.issuer.transfer(amount);
    }

    function () public payable {
        require(config.isActive);
        deposit(msg.sender);
    }

    function deposit(address beneficiary) public payable {
        require(config.isActive);
        require(beneficiary != 0x0);
        require(msg.value != 0);
        balances[beneficiary] = balances[beneficiary].add(msg.value);
        config.totalSupply = config.totalSupply.add(msg.value);
        Issuance(msg.value);
        Transfer(this, beneficiary, msg.value);
    }

    function withdraw(uint256 amount) public {
        require(config.isActive);
        withdrawTo(msg.sender, amount);
    }

    function withdrawTo(address to, uint amount) public {
        require(config.isActive);
        require(to != 0x0);
        require(amount != 0);
        require(amount <= balances[to]);
        require(this != to);
        balances[to] = balances[to].sub(amount);
        config.totalSupply = config.totalSupply.sub(amount);
        Transfer(msg.sender, this, amount);
        Destruction(amount);
        to.transfer(amount);
    }

    struct Config {
        address issuer;
        bool isActive;
        uint256 decimals;
        uint256 maxApprovalAmount;
        address owner;
        uint256 totalSupply;
    }
    Config config = Config(address(0), false, 18, 2**256 - 1, address(0), 0);
}