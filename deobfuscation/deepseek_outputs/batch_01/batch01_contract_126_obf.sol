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
    function balanceOf(address tokenOwner) public view returns (uint256);
    function allowance(address tokenOwner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool);
    function approve(address spender, uint256 tokens) public returns (bool);
    function transfer(address to, uint256 tokens) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed owner, address indexed spender, uint256 tokens);
}

contract BountieToken is ERC20Interface {
    using SafeMath for uint256;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;

    event Mint(address indexed from, address indexed to, uint256 tokens);
    event Burn(address indexed from, uint256 tokens);

    modifier onlyOwner() {
        require(msg.sender == config.owner);
        _;
    }

    modifier beforeDeadline() {
        require(now < config.deadline);
        _;
    }

    modifier duringCrowdsale() {
        require(now >= config.startTime && now < config.deadline);
        _;
    }

    modifier afterDeadline() {
        require(now >= config.deadline);
        _;
    }

    struct Config {
        bool crowdsalePaused;
        bool transfersPaused;
        uint256 deadline;
        uint256 stage4End;
        uint256 stage3End;
        uint256 stage2End;
        uint256 stage1End;
        address teamWallet;
        address ethFundDeposit;
        address owner;
        uint256 totalEthReceived;
        uint256 totalTokensMinted;
        uint256 totalSupply;
        uint256 hardCap;
        uint256 baseRate;
        uint8 decimals;
        string symbol;
        string name;
    }

    Config private config = Config(
        false,
        true,
        1541563200,
        1540612800,
        1539662400,
        1538712000,
        1537675200,
        0xDEe3a6b14ef8E21B9df09a059186292C9472045D,
        0xDEe3a6b14ef8E21B9df09a059186292C9472045D,
        address(0),
        0,
        0,
        0,
        20000 ether,
        6500,
        18,
        "Bountie",
        "Bountie Token"
    );

    constructor() public {
        config.owner = msg.sender;
    }

    function totalSupply() public view returns (uint256) {
        return config.totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }

    function transferFrom(address from, address to, uint256 tokens) public afterDeadline returns (bool) {
        require(to != address(0));
        require(!config.transfersPaused);
        require(balances[from] >= tokens && allowed[from][msg.sender] >= tokens && tokens >= 0);

        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function approve(address spender, uint256 tokens) public afterDeadline returns (bool) {
        require(!config.transfersPaused);
        require(spender != address(0));
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint256) {
        require(tokenOwner != address(0) && spender != address(0));
        return allowed[tokenOwner][spender];
    }

    function transfer(address to, uint256 tokens) public afterDeadline returns (bool) {
        require(!config.transfersPaused);
        require(to != address(0));
        require(balances[msg.sender] >= tokens && tokens >= 0);

        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function burn(uint256 amount) public onlyOwner returns (bool) {
        uint256 tokens = amount * 10 ** 18;
        require(balances[msg.sender] >= tokens);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        config.totalSupply = config.totalSupply.sub(tokens);
        emit Burn(msg.sender, tokens);
        return true;
    }

    function pauseTransfers() external onlyOwner afterDeadline {
        require(!config.transfersPaused);
        config.transfersPaused = true;
    }

    function unpauseTransfers() external onlyOwner afterDeadline {
        require(config.transfersPaused);
        config.transfersPaused = false;
    }

    function allocateTokens(address recipient, uint256 amount) external onlyOwner beforeDeadline {
        uint256 tokens = amount * 10 ** 18;
        uint256 currentRate = getCurrentRate();
        uint256 ethAmount = tokens.div(currentRate);
        config.totalEthReceived = config.totalEthReceived.add(ethAmount);
        require(config.totalEthReceived <= config.hardCap);
        mintTokens(config.owner, recipient, tokens);
    }

    function () public payable duringCrowdsale {
        require(msg.value != 0 && msg.sender != address(0));
        require(!config.crowdsalePaused && msg.sender != config.owner);
        uint256 currentRate = getCurrentRate();
        uint256 tokens = msg.value.mul(currentRate);
        config.totalEthReceived = config.totalEthReceived.add(msg.value);
        require(config.totalEthReceived <= config.hardCap);
        mintTokens(address(this), msg.sender, tokens);
    }

    function mintTokens(address from, address recipient, uint256 tokens) private {
        require(tokens > 0);
        config.totalTokensMinted = config.totalTokensMinted.add(tokens);
        uint256 teamTokens = tokens * 4 / 65;
        uint256 ownerTokens = tokens * 31 / 65;
        balances[config.teamWallet] = balances[config.teamWallet].add(teamTokens);
        balances[config.owner] = balances[config.owner].add(ownerTokens);
        config.totalSupply = config.totalSupply.add(tokens * 100 / 65);
        balances[recipient] = balances[recipient].add(tokens);
        emit Mint(from, recipient, tokens);
        emit Transfer(address(0), recipient, tokens);
        emit Mint(from, config.teamWallet, teamTokens);
        emit Transfer(address(0), config.teamWallet, teamTokens);
        emit Mint(from, config.owner, ownerTokens);
        emit Transfer(address(0), config.owner, ownerTokens);
    }

    function getCurrentRate() private view returns (uint256) {
        uint256 rate = config.baseRate;
        if (now < config.stage1End) {
            require(config.totalEthReceived < 10000 ether);
            rate = config.baseRate * 6 / 5;
        } else if (now < config.stage2End) {
            require(config.totalEthReceived < 11739 ether);
            rate = config.baseRate * 23 / 20;
        } else if (now < config.stage3End) {
            require(config.totalEthReceived < 13557 ether);
            rate = config.baseRate * 11 / 10;
        } else if (now < config.stage4End) {
            require(config.totalEthReceived < 15462 ether);
            rate = config.baseRate * 21 / 20;
        } else {
            require(config.totalEthReceived < config.hardCap);
            rate = config.baseRate;
        }
        return rate;
    }

    function pauseCrowdsale() external onlyOwner duringCrowdsale {
        require(!config.crowdsalePaused);
        config.crowdsalePaused = true;
    }

    function unpauseCrowdsale() external onlyOwner duringCrowdsale {
        require(config.crowdsalePaused);
        config.crowdsalePaused = false;
    }

    function setEthFundDeposit(address newDeposit) external onlyOwner {
        require(newDeposit != address(0));
        config.ethFundDeposit = newDeposit;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        balances[newOwner] = balances[newOwner].add(balances[config.owner]);
        balances[config.owner] = 0;
        config.owner = newOwner;
        emit Transfer(msg.sender, newOwner, balances[newOwner]);
    }

    function withdrawEth() external onlyOwner {
        address thisContract = address(this);
        config.ethFundDeposit.transfer(thisContract.balance);
    }

    function changeTeamWallet(address newTeamWallet) public onlyOwner returns(bool) {
        require(newTeamWallet != address(0) && config.teamWallet != newTeamWallet);
        uint256 teamBalance = balances[config.teamWallet];
        address oldTeamWallet = config.teamWallet;
        balances[newTeamWallet] = balances[newTeamWallet].add(teamBalance);
        balances[config.teamWallet] = 0;
        config.teamWallet = newTeamWallet;
        emit Transfer(oldTeamWallet, newTeamWallet, teamBalance);
        return true;
    }
}