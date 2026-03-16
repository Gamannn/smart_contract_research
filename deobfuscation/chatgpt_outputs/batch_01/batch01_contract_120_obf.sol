```solidity
pragma solidity ^0.4.18;

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
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
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
        require(newOwner != address(0));
        owner = newOwner;
    }
}

contract BasicToken is ERC20Basic, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping(address => bool) public frozenAccount;
    bool public frozenAccountICO;

    event FrozenFunds(address target, bool frozen);

    function setFrozenAccountICO(bool _frozenAccountICO) public onlyOwner {
        frozenAccountICO = _frozenAccountICO;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        if (msg.sender != owner && msg.sender != s2c.addressTeam) {
            require(!frozenAccountICO);
        }
        require(!frozenAccount[to]);
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function balanceOf(address owner) public constant returns (uint256 balance) {
        return balances[owner];
    }
}

contract StandardToken is ERC20, BasicToken {
    mapping(address => mapping(address => uint256)) allowed;

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        if (msg.sender != owner && msg.sender != s2c.addressTeam) {
            require(!frozenAccountICO);
        }
        require(!frozenAccount[from]);
        require(!frozenAccount[to]);
        require(to != address(0));
        require(value <= balances[from]);
        require(value <= allowed[from][msg.sender]);

        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require((value == 0) || (allowed[msg.sender][spender] == 0));
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public constant returns (uint256 remaining) {
        return allowed[owner][spender];
    }
}

contract MintableToken is StandardToken {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    function mint(address to, uint256 amount) onlyOwner canMint public returns (bool) {
        s2c.totalSupply = s2c.totalSupply.add(amount);
        balances[to] = balances[to].add(amount);
        emit Mint(to, amount);
        emit Transfer(address(0), to, amount);
        return true;
    }

    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}

contract MahalaCoin is Ownable, MintableToken {
    using SafeMath for uint256;

    function MahalaCoin() public {
        s2c.summTeam = 110000000 * 1 ether;
        mint(s2c.addressTeam, s2c.summTeam);
        mint(owner, 70000000 * 1 ether);
    }

    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    function getTotalSupply() public constant returns (uint256) {
        return s2c.totalSupply;
    }
}

contract Crowdsale is Ownable {
    using SafeMath for uint256;

    MahalaCoin public token;
    mapping(address => uint) public balances;
    mapping(address => uint) public balancesToken;

    event TokenProcurement(address indexed contributor, address indexed beneficiary, uint256 value, uint256 amount);

    function Crowdsale() public {
        token = createTokenContract();
        s2c.softcap = 5000 * 1 ether;
        s2c.hardcap = 20000 * 1 ether;
        s2c.minQuanValues = 100000000000000000;
        s2c.maxQuanValues = 22 * 1 ether;
        s2c.startPreSale = 1523260800;
        s2c.endPreSale = s2c.startPreSale + 40 * 1 days;
        s2c.startIco = s2c.endPreSale;
        s2c.endIco = s2c.startIco + 40 * 1 days;
        s2c.ratePreSale = 462;
        s2c.rateIco = 231;
        s2c.maxPreSale = 30000000 * 1 ether;
        s2c.maxIco = 60000000 * 1 ether;
        s2c.wallet = 0x04cFbFa64917070d7AEECd20225782240E8976dc;
    }

    function setRatePreSale(uint _ratePreSale) public onlyOwner {
        s2c.ratePreSale = _ratePreSale;
    }

    function setRateIco(uint _rateIco) public onlyOwner {
        s2c.rateIco = _rateIco;
    }

    function () external payable {
        procureTokens(msg.sender);
    }

    function createTokenContract() internal returns (MahalaCoin) {
        return new MahalaCoin();
    }

    function procureTokens(address beneficiary) public payable {
        uint256 tokens;
        uint256 weiAmount = msg.value;
        uint256 backAmount;

        require(beneficiary != address(0));
        require(weiAmount >= s2c.minQuanValues);
        require(weiAmount.add(balances[msg.sender]) <= s2c.maxQuanValues);

        address _this = this;
        require(s2c.hardcap > _this.balance);

        if (now >= s2c.startPreSale && now < s2c.endPreSale && s2c.totalPreSale < s2c.maxPreSale) {
            tokens = weiAmount.mul(s2c.ratePreSale);
            if (s2c.maxPreSale.sub(s2c.totalPreSale) <= tokens) {
                s2c.endPreSale = now;
                s2c.startIco = now;
                s2c.endIco = s2c.startIco + 40 * 1 days;
            }
            if (s2c.maxPreSale.sub(s2c.totalPreSale) < tokens) {
                tokens = s2c.maxPreSale.sub(s2c.totalPreSale);
                weiAmount = tokens.div(s2c.ratePreSale);
                backAmount = msg.value.sub(weiAmount);
            }
            s2c.totalPreSale = s2c.totalPreSale.add(tokens);
        }

        if (now >= s2c.startIco && now < s2c.endIco && s2c.totalIco < s2c.maxIco) {
            tokens = weiAmount.mul(s2c.rateIco);
            if (s2c.maxIco.sub(s2c.totalIco) < tokens) {
                tokens = s2c.maxIco.sub(s2c.totalIco);
                weiAmount = tokens.div(s2c.rateIco);
                backAmount = msg.value.sub(weiAmount);
            }
            s2c.totalIco = s2c.totalIco.add(tokens);
        }

        require(tokens > 0);
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        token.transfer(msg.sender, tokens);

        if (backAmount > 0) {
            msg.sender.transfer(backAmount);
        }

        emit TokenProcurement(msg.sender, beneficiary, weiAmount, tokens);
    }

    function refund() public {
        address _this = this;
        require(_this.balance < s2c.softcap && now > s2c.endIco);
        require(balances[msg.sender] > 0);

        uint value = balances[msg.sender];
        balances[msg.sender] = 0;
        msg.sender.transfer(value);
    }

    function transferTokenToMultisig(address _address) public onlyOwner {
        address _this = this;
        require(_this.balance < s2c.softcap && now > s2c.endIco);
        token.transfer(_address, token.balanceOf(_this));
    }

    function transferEthToMultisig() public onlyOwner {
        address _this = this;
        require(_this.balance >= s2c.softcap && now > s2c.endIco);
        s2c.wallet.transfer(_this.balance);
        token.setFrozenAccountICO(false);
    }

    function freezeAccount(address target, bool freeze) public onlyOwner {
        token.freezeAccount(target, freeze);
    }

    function mintToken(address target, uint256 mintedAmount) public onlyOwner {
        token.mint(target, mintedAmount);
    }

    struct Scalar2Vector {
        uint256 maxQuanValues;
        uint256 minQuanValues;
        address wallet;
        uint256 rateIco;
        uint256 ratePreSale;
        uint256 totalIco;
        uint256 totalPreSale;
        uint256 maxIco;
        uint256 maxPreSale;
        uint256 endIco;
        uint256 startIco;
        uint256 endPreSale;
        uint256 startPreSale;
        uint256 hardcap;
        uint256 softcap;
        uint256 totalTokens;
        uint256 summTeam;
        uint32 decimals;
        string symbol;
        string name;
        bool mintingFinished;
        bool frozenAccountICO;
        address addressTeam;
        address owner;
        uint256 totalSupply;
    }

    Scalar2Vector s2c = Scalar2Vector(
        0, 0, address(0), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 18, "MHC", "Mahala Coin", false, true, 0x04cFbFa64917070d7AEECd20225782240E8976dc, address(0), 0
    );
}
```