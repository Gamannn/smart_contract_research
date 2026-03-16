```solidity
pragma solidity 0.4.25;

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
    function balanceOf(address who) public view returns (uint256);
    function allowance(address owner, address spender) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract UpgradeAgent {
    function isUpgradeAgent() public pure returns (bool) {
        return true;
    }

    function upgradeFrom(address from, uint256 value) public;
}

contract CVEN is ERC20Interface {
    using SafeMath for uint256;

    UpgradeAgent public upgradeAgent;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;
    mapping(address => bool) public locked;

    event Mint(address indexed from, address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);
    event Upgrade(address indexed from, address indexed to, uint256 value);
    event UpgradeAgentSet(address agent);

    modifier onlyOwner() {
        require(msg.sender == state.owner, "Only owner is allowed");
        _;
    }

    struct State {
        bool stopped;
        bool lockstatus;
        address ethFundMain;
        address owner;
        uint256 totalUpgraded;
        uint256 mintedTokens;
        uint256 totalSupply;
        uint8 decimals;
        string name;
        string symbol;
        address oldAddress;
    }

    State public state = State(
        false,
        false,
        address(0),
        address(0),
        0,
        0,
        0,
        18,
        "CVEN",
        "Concordia Ventures Stablecoin",
        address(0)
    );

    constructor() public {
        state.owner = msg.sender;
        state.ethFundMain = 0x657Eb3CE439CA61e58FF6Cb106df2e962C5e7890;
    }

    function totalSupply() public view returns (uint256) {
        return state.totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(!state.lockstatus, "Token is locked now");
        require(to != address(0), "Receiver cannot be 0x0");
        require(balances[msg.sender] >= amount, "Balance does not have enough tokens");
        require(!locked[msg.sender], "Sender address is locked");

        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[to] = balances[to].add(amount);

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(to != address(0), "Receiver cannot be 0x0");
        require(!state.lockstatus, "Token is locked now");
        require(balances[from] >= amount, "Source balance is not enough");
        require(allowed[from][msg.sender] >= amount, "Allowance is not enough");
        require(!locked[from], "From address is locked");

        balances[from] = balances[from].sub(amount);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(amount);
        balances[to] = balances[to].add(amount);

        emit Transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        require(!state.lockstatus, "Token is locked now");
        require(spender != address(0), "Address cannot be 0x0");
        require(balances[msg.sender] >= amount, "Balance does not have enough tokens");
        require(!locked[msg.sender], "Sender address is locked");

        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

    function burn(uint256 amount) public returns (bool) {
        require(balances[msg.sender] >= amount, "Balance does not have enough tokens");
        require(!locked[msg.sender], "Sender address is locked");

        balances[msg.sender] = balances[msg.sender].sub(amount);
        state.totalSupply = state.totalSupply.sub(amount);

        emit Burn(msg.sender, amount);
        return true;
    }

    function burnFrom(address from, uint256 amount) public returns (bool) {
        require(balances[from] >= amount, "Source balance does not have enough tokens");
        require(allowed[from][msg.sender] >= amount, "Allowance is not enough");
        require(!locked[from], "Source address is locked");

        balances[from] = balances[from].sub(amount);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(amount);
        state.totalSupply = state.totalSupply.sub(amount);

        emit Burn(from, amount);
        return true;
    }

    function stopTransferToken() external onlyOwner {
        require(!state.lockstatus, "Token is locked");
        state.lockstatus = true;
    }

    function startTransferToken() external onlyOwner {
        require(state.lockstatus, "Token is transferable");
        state.lockstatus = false;
    }

    function () public payable {
        require(!state.stopped, "CrowdSale is stopping");
        mint(this, msg.sender, msg.value);
    }

    function manualMint(address to, uint256 amount) public onlyOwner {
        require(!state.stopped, "CrowdSale is stopping");
        mint(state.owner, to, amount);
    }

    function mint(address from, address to, uint256 value) internal {
        require(to != address(0), "Address cannot be 0x0");
        require(value > 0, "Value should be larger than 0");

        balances[to] = balances[to].add(value);
        state.totalSupply = state.totalSupply.add(value);
        state.mintedTokens = state.mintedTokens.add(value);

        emit Mint(from, to, value);
        emit Transfer(0, to, value);
    }

    function haltMintToken() external onlyOwner {
        require(!state.stopped, "Minting is stopping");
        state.stopped = true;
    }

    function resumeMintToken() external onlyOwner {
        require(state.stopped, "Minting is running");
        state.stopped = false;
    }

    function changeReceiveWallet(address newAddress) external onlyOwner {
        require(newAddress != address(0), "Address cannot be 0x0");
        state.ethFundMain = newAddress;
    }

    function assignOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Address cannot be 0x0");

        balances[newOwner] = balances[newOwner].add(balances[state.owner]);
        balances[state.owner] = 0;
        state.owner = newOwner;

        emit Transfer(msg.sender, newOwner, balances[newOwner]);
    }

    function forwardFunds() external onlyOwner {
        address myAddress = this;
        state.ethFundMain.transfer(myAddress.balance);
    }

    function withdrawTokens() external onlyOwner {
        uint256 value = balances[this];
        balances[state.owner] = balances[state.owner].add(value);
        balances[this] = 0;

        emit Transfer(this, state.owner, value);
    }

    function haltTokenTransferFromAddress(address investor) external onlyOwner {
        locked[investor] = true;
    }

    function resumeTokenTransferFromAddress(address investor) external onlyOwner {
        locked[investor] = false;
    }

    function setUpgradeAgent(address agent) external onlyOwner {
        require(agent != address(0), "Upgrade agent cannot be zero");
        require(state.totalUpgraded == 0, "Token are upgrading");

        upgradeAgent = UpgradeAgent(agent);
        require(upgradeAgent.isUpgradeAgent(), "The address is not upgrade agent");
        require(upgradeAgent.oldAddress() == address(this), "This is not right agent");

        emit UpgradeAgentSet(upgradeAgent);
    }

    function upgrade(uint256 value) public {
        require(value != 0, "Value cannot be zero");
        require(balances[msg.sender] >= value, "Balance is not enough");
        require(address(upgradeAgent) != address(0), "Upgrade agent is not set");

        balances[msg.sender] = balances[msg.sender].sub(value);
        state.totalSupply = state.totalSupply.sub(value);
        state.totalUpgraded = state.totalUpgraded.add(value);

        upgradeAgent.upgradeFrom(msg.sender, value);

        emit Upgrade(msg.sender, upgradeAgent, value);
        emit Transfer(msg.sender, 0, value);
    }
}
```