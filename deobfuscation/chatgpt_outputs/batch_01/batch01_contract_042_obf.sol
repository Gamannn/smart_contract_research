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
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Pausable is Ownable {
    bool public paused = false;

    event Pause();
    event Unpause();

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
    uint256 totalSupply_;

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

    function balanceOf(address owner) public view returns (uint256) {
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
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

    function increaseApproval(address spender, uint addedValue) public returns (bool) {
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function decreaseApproval(address spender, uint subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][spender];
        if (subtractedValue > oldValue) {
            allowed[msg.sender][spender] = 0;
        } else {
            allowed[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
}

contract PausableToken is StandardToken, Pausable {
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseApproval(address spender, uint addedValue) public whenNotPaused returns (bool success) {
        return super.increaseApproval(spender, addedValue);
    }

    function decreaseApproval(address spender, uint subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseApproval(spender, subtractedValue);
    }
}

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;
    mapping (address => bool) public saleAgent;

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
    function AgroTechFarmToken() public CappedToken(5 * 10**24) {
        paused = true;
    }
}

contract AgroTechFarmCrowdsale is Ownable {
    using SafeMath for uint;

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
        token.mint(0xbc931C181fD9444bD7909d1308dEeDBc11111CCF, 500000 * (10 ** uint256(18)));
        token.mint(0x7a2735C65712381818ad0571A26a769F43A4393F, 350000 * (10 ** uint256(18)));
        token.mint(0x57D7612338352E80205Bea6FfD3A2AeD73307474, 300000 * (10 ** uint256(18)));
        token.mint(0x170c81F864c3dcEA0edb017150543e94449C1aae, 250000 * (10 ** uint256(18)));
        token.mint(0xAC32c281D155555C16043627a515670419eDB42f, 150000 * (10 ** uint256(18)));
        token.mint(0x861DCE9381D616C4F025C45995E1D7f0D6C71007, 100000 * (10 ** uint256(18)));
        token.mint(0xE03aC5F8350289714d8DD46F177D4516ef6c81A5, 100000 * (10 ** uint256(18)));
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
        uint value = balances[msg.sender];
        balances[msg.sender] = 0;
        msg.sender.transfer(value);
    }

    function createTokens() public saleIsOn payable {
        uint tokens = rate.mul(msg.value).div(1 ether);
        if(state == State.Closed){
            multisig.transfer(msg.value);
        }
        uint bonusTokens = 0;
        if(now <= start.add(10 days)) {
            bonusTokens = tokens.mul(20).div(100);
        } else if(now > start.add(10 days) && now <= start.add(25 days)) {
            bonusTokens = tokens.mul(10).div(100);
        } else if(now > start.add(25 days) && now < start.add(40 days)) {
            bonusTokens = tokens.mul(5).div(100);
        }
        tokens += bonusTokens;
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        token.mint(msg.sender, tokens);
    }

    function() external payable {
        createTokens();
    }
}