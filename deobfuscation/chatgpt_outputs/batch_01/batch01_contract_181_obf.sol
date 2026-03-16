pragma solidity ^0.4.19;

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

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) balances;

    function transfer(address to, uint256 value) returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        Transfer(msg.sender, to, value);
        return true;
    }

    function balanceOf(address owner) constant returns (uint256 balance) {
        return balances[owner];
    }
}

contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) allowed;

    function transferFrom(address from, address to, uint256 value) returns (bool) {
        var _allowance = allowed[from][msg.sender];
        balances[to] = balances[to].add(value);
        balances[from] = balances[from].sub(value);
        allowed[from][msg.sender] = _allowance.sub(value);
        Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) returns (bool) {
        require((value == 0) || (allowed[msg.sender][spender] == 0));
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) constant returns (uint256 remaining) {
        return allowed[owner][spender];
    }
}

contract Ownable {
    address public owner;

    function Ownable() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    function mint(address to, uint256 amount) onlyOwner canMint returns (bool) {
        totalSupply = totalSupply.add(amount);
        balances[to] = balances[to].add(amount);
        Mint(to, amount);
        return true;
    }

    function finishMinting() onlyOwner returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
}

contract CIDToken is MintableToken {
    string public constant name = "CID";
    string public constant symbol = "CID";
    uint32 public constant decimals = 18;
}

contract CIDCrowdsale is Ownable {
    using SafeMath for uint;

    CIDToken public token = new CIDToken();
    mapping(address => uint) public contributions;

    uint public rate = 1000;
    uint public start = 1517468400;
    uint public end = 1519776000;
    uint public hardcap = 7000000 * (10 ** 18);
    uint public softcap = 300000 * (10 ** 18);
    address public multisig = 0x2338801bA8aEe40d679364bcA4e69d8C1B7a101C;
    address public wal1 = 0x35E0e717316E38052f6b74f144F2a7CE8318294b;
    address public wal2 = 0xa9251f22203e34049aa5D4DbfE4638009A1586F5;
    address public wal3 = 0xE9267a312B9Bc125557cff5146C8379cCEE3a33D;

    modifier saleIsOn() {
        require(now > start && now < end);
        _;
    }

    modifier isUnderHardCap() {
        require(this.balance <= hardcap);
        _;
    }

    function refund() public {
        require(this.balance < softcap && now > end && contributions[msg.sender] > 0);
        uint value = contributions[msg.sender];
        contributions[msg.sender] = 0;
        msg.sender.transfer(value);
    }

    function finishMinting() public onlyOwner {
        uint finCheckBalance = softcap.div(rate);
        if(this.balance > finCheckBalance) {
            multisig.transfer(this.balance);
            token.finishMinting();
        }
    }

    function createTokens() isUnderHardCap saleIsOn payable {
        uint tokens = rate.mul(msg.value).div(1 ether);
        uint CTS = token.totalSupply();
        uint bonusTokens = 0;

        if(CTS <= (300000 * (10 ** 18))) {
            bonusTokens = (tokens.mul(30)).div(100);
        } else if(CTS > (300000 * (10 ** 18)) && CTS <= (400000 * (10 ** 18))) {
            bonusTokens = (tokens.mul(25)).div(100);
        } else if(CTS > (400000 * (10 ** 18)) && CTS <= (500000 * (10 ** 18))) {
            bonusTokens = (tokens.mul(20)).div(100);
        } else if(CTS > (500000 * (10 ** 18)) && CTS <= (700000 * (10 ** 18))) {
            bonusTokens = (tokens.mul(15)).div(100);
        } else if(CTS > (700000 * (10 ** 18)) && CTS <= (1000000 * (10 ** 18))) {
            bonusTokens = (tokens.mul(10)).div(100);
        } else if(CTS > (1000000 * (10 ** 18))) {
            bonusTokens = 0;
        }

        tokens += bonusTokens;
        token.mint(msg.sender, tokens);
        contributions[msg.sender] = contributions[msg.sender].add(msg.value);

        uint wal1Tokens = (tokens.mul(25)).div(100);
        token.mint(wal1, wal1Tokens);

        uint wal2Tokens = (tokens.mul(10)).div(100);
        token.mint(wal2, wal2Tokens);

        uint wal3Tokens = (tokens.mul(5)).div(100);
        token.mint(wal3, wal3Tokens);
    }

    function() external payable {
        createTokens();
    }
}