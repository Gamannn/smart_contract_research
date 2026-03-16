pragma solidity 0.4.24;

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

contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address tokenOwner) public view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract BountieToken is ERC20Interface {
    using SafeMath for uint256;

    string public name = "Bountie";
    string public symbol = "BNT";
    uint8 public decimals = 18;
    uint256 public _totalSupply = 20000 ether;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    address public owner;
    address public admin;
    address public reserveWallet;
    bool public isMinting;
    bool public isPaused;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public rate;
    uint256 public cap;
    uint256 public totalMinted;

    event Mint(address indexed from, address indexed to, uint256 tokens);
    event Burn(address indexed from, uint256 tokens);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    modifier whenNotPaused() {
        require(!isPaused);
        _;
    }

    modifier whenPaused() {
        require(isPaused);
        _;
    }

    constructor() public {
        owner = msg.sender;
        admin = 0xDEe3a6b14ef8E21B9df09a059186292C9472045D;
        reserveWallet = 0xDEe3a6b14ef8E21B9df09a059186292C9472045D;
        isMinting = true;
        isPaused = false;
        startTime = 1537675200;
        endTime = 1541563200;
        rate = 6500;
        cap = 20000 ether;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint256 balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }

    function transfer(address to, uint256 tokens) public whenNotPaused returns (bool success) {
        require(to != address(0));
        require(balances[msg.sender] >= tokens);

        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint256 tokens) public whenNotPaused returns (bool success) {
        require(spender != address(0));

        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint256 tokens) public whenNotPaused returns (bool success) {
        require(to != address(0));
        require(balances[from] >= tokens);
        require(allowed[from][msg.sender] >= tokens);

        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function mint(address to, uint256 tokens) public onlyOwner whenNotPaused returns (bool success) {
        require(isMinting);
        require(to != address(0));
        require(totalMinted.add(tokens) <= cap);

        totalMinted = totalMinted.add(tokens);
        balances[to] = balances[to].add(tokens);
        emit Mint(address(0), to, tokens);
        emit Transfer(address(0), to, tokens);
        return true;
    }

    function burn(uint256 tokens) public onlyOwner whenNotPaused returns (bool success) {
        require(balances[msg.sender] >= tokens);

        balances[msg.sender] = balances[msg.sender].sub(tokens);
        _totalSupply = _totalSupply.sub(tokens);
        emit Burn(msg.sender, tokens);
        return true;
    }

    function pause() public onlyOwner whenNotPaused {
        isPaused = true;
    }

    function unpause() public onlyOwner whenPaused {
        isPaused = false;
    }

    function setAdmin(address newAdmin) public onlyOwner {
        require(newAdmin != address(0));
        admin = newAdmin;
    }

    function setReserveWallet(address newReserveWallet) public onlyOwner {
        require(newReserveWallet != address(0));
        reserveWallet = newReserveWallet;
    }

    function setRate(uint256 newRate) public onlyOwner {
        rate = newRate;
    }

    function setCap(uint256 newCap) public onlyOwner {
        cap = newCap;
    }

    function setMinting(bool minting) public onlyOwner {
        isMinting = minting;
    }
}