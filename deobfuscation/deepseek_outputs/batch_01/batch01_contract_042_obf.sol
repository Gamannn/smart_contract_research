pragma solidity ^0.4.23;

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
        return a / b;
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
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        OwnershipTransferred(owner, newOwner);
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

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 public totalSupply_;

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
}

contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) internal allowed;

    function transferFrom(address _from, address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balances[_from]);
        require(value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(value);
        emit Transfer(_from, to, value);
        return true;
    }

    function approve(address _spender, uint256 value) public returns (bool) {
        allowed[msg.sender][_spender] = value;
        emit Approval(msg.sender, _spender, value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

contract PausableToken is StandardToken, Pausable {
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address _from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, to, value);
    }

    function approve(address _spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(_spender, value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    mapping (address => bool) public saleAgent;

    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    modifier onlySaleAgent() {
        require(saleAgent[msg.sender]);
        _;
    }

    function setSaleAgent(address addr, bool state) onlyOwner canMint public {
        saleAgent[addr] = state;
    }

    function mint(address to, uint256 amount) onlySaleAgent canMint public returns (bool) {
        totalSupply_ = totalSupply_.add(amount);
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

contract CappedToken is MintableToken {
    uint256 public cap;

    function CappedToken(uint256 _cap) public {
        require(_cap > 0);
        cap = _cap;
    }

    function mint(address to, uint256 amount) onlySaleAgent canMint public returns (bool) {
        require(totalSupply_.add(amount) <= cap);
        return super.mint(to, amount);
    }
}

contract AgroTechFarmToken is PausableToken, CappedToken {
    string public constant name = "AgroTechFarm";
    string public constant symbol = "ATF";
    uint8 public constant decimals = 18;
    uint256 public constant TOKEN_CAP = 5 * 10**24;

    function AgroTechFarmToken() public CappedToken(TOKEN_CAP) {
        paused = true;
    }
}

contract AgroTechFarmCrowdsale is Ownable {
    using SafeMath for uint256;

    AgroTechFarmToken public token;

    enum State { Active, Refunding, Closed }
    State public state = State.Active;

    mapping (address => uint256) public balances;

    event RefundsClosed();
    event RefundsEnabled();

    address public multisig;
    uint256 public rate;
    uint256 public softcap;
    uint256 public start;
    uint256 public end;

    bool public tokenSpread = false;

    uint256 public constant SUPPLY_FOR_SALE = 3250000 * (10 ** 18);
    uint256 public constant SUPPLY_FOR_RESERVE = 500000 * (10 ** 18);
    uint256 public constant SUPPLY_FOR_MARKETING = 350000 * (10 ** 18);
    uint256 public constant SUPPLY_FOR_TEAM = 300000 * (10 ** 18);
    uint256 public constant SUPPLY_FOR_REFERAL = 250000 * (10 ** 18);
    uint256 public constant SUPPLY_FOR_ADVISORS = 150000 * (10 ** 18);
    uint256 public constant SUPPLY_FOR_PARTNERSHIPS = 100000 * (10 ** 18);
    uint256 public constant SUPPLY_FOR_BOUNTY = 100000 * (10 ** 18);

    address public constant holderReserveTokens = 0xbc931C181fD9444bD7909d1308dEeDBc11111CCF;
    address public constant holderMarketingTokens = 0x7a2735C65712381818ad0571A26a769F43A4393F;
    address public constant holderTeamTokens = 0x57D7612338352E80205Bea6FfD3A2AeD73307474;
    address public constant holderReferalTokens = 0x170c81F864c3dcEA0edb017150543e94449C1aae;
    address public constant holderAdvisorsTokens = 0xAC32c281D155555C16043627a515670419eDB42f;
    address public constant holderPartnershipsTokens = 0x861DCE9381D616C4F025C45995E1D7f0D6C71007;
    address public constant holderBountyTokens = 0xE03aC5F8350289714d8DD46F177D4516ef6c81A5;

    function AgroTechFarmCrowdsale(address _multisig, AgroTechFarmToken _token) public {
        require(_multisig != address(0));
        require(_token != address(0));

        multisig = _multisig;
        token = _token;
        rate = 83333333333000000000;
        softcap = 1600000000000000000000;
        start = 1527811200;
        end = 1533081600;
    }

    modifier saleIsOn() {
        require(now > start && now < end);
        _;
    }

    function spreadTokens() external onlyOwner {
        require(!tokenSpread);

        token.mint(holderReserveTokens, SUPPLY_FOR_RESERVE);
        token.mint(holderMarketingTokens, SUPPLY_FOR_MARKETING);
        token.mint(holderTeamTokens, SUPPLY_FOR_TEAM);
        token.mint(holderReferalTokens, SUPPLY_FOR_REFERAL);
        token.mint(holderAdvisorsTokens, SUPPLY_FOR_ADVISORS);
        token.mint(holderPartnershipsTokens, SUPPLY_FOR_PARTNERSHIPS);
        token.mint(holderBountyTokens, SUPPLY_FOR_BOUNTY);

        tokenSpread = true;
    }

    function closeRefunds() onlyOwner public {
        require(state == State.Active && address(this).balance >= softcap);
        state = State.Closed;
        emit RefundsClosed();
        multisig.transfer(address(this).balance);
    }

    function enableRefunds() onlyOwner public {
        require(address(this).balance < softcap && state == State.Active && now > end);
        state = State.Refunding;
        emit RefundsEnabled();
    }

    function refund() public {
        require(state == State.Refunding);
        uint256 value = balances[msg.sender];
        balances[msg.sender] = 0;
        msg.sender.transfer(value);
    }

    function createTokens() public saleIsOn payable {
        uint256 tokens = rate.mul(msg.value).div(1 ether);

        if (state == State.Closed) {
            multisig.transfer(msg.value);
        }

        uint256 bonusTokens = 0;
        if (now <= start.add(10 days)) {
            bonusTokens = tokens.mul(20).div(100);
        } else if (now > start.add(10 days) && now <= start.add(25 days)) {
            bonusTokens = tokens.mul(10).div(100);
        } else if (now > start.add(25 days) && now < start.add(40 days)) {
            bonusTokens = tokens.mul(5).div(100);
        }

        tokens = tokens.add(bonusTokens);
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        token.mint(msg.sender, tokens);
    }

    function() external payable {
        createTokens();
    }
}