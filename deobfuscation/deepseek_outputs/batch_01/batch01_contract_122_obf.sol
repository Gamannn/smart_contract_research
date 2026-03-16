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

contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract UpgradeAgent {
    function isUpgradeAgent() public pure returns (bool) {
        return true;
    }
    function upgradeFrom(address from, uint256 value) public;
    function oldAddress() public view returns (address);
}

contract CVEN is ERC20 {
    using SafeMath for uint256;

    UpgradeAgent public upgradeAgent;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;
    mapping(address => bool) public locked;

    event Mint(address indexed from, address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);
    event Upgrade(address indexed from, address indexed agent, uint256 value);
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
        uint256 _totalsupply;
        uint8 decimals;
        string name;
        string symbol;
        address oldAddress;
    }

    State state = State(
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

    function totalSupply() public view returns (uint256 total_Supply) {
        total_Supply = state._totalsupply;
    }

    function balanceOf(address who) public view returns (uint256 balance) {
        return balances[who];
    }

    function transfer(address to, uint256 _amount) public returns (bool success) {
        require(!state.lockstatus, "Token is locked now");
        require(to != address(0), "Receiver can not be 0x0");
        require(balances[msg.sender] >= _amount, "Balance does not have enough tokens");
        require(!locked[msg.sender], "Sender address is locked");

        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[to] = balances[to].add(_amount);
        emit Transfer(msg.sender, to, _amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 _amount) public returns (bool success) {
        require(to != address(0), "Receiver can not be 0x0");
        require(!state.lockstatus, "Token is locked now");
        require(balances[from] >= _amount, "Source balance is not enough");
        require(allowed[from][msg.sender] >= _amount, "Allowance is not enough");
        require(!locked[from], "From address is locked");

        balances[from] = balances[from].sub(_amount);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(_amount);
        balances[to] = balances[to].add(_amount);
        emit Transfer(from, to, _amount);
        return true;
    }

    function approve(address spender, uint256 _amount) public returns (bool success) {
        require(!state.lockstatus, "Token is locked now");
        require(spender != address(0), "Address can not be 0x0");
        require(balances[msg.sender] >= _amount, "Balance does not have enough tokens");
        require(!locked[msg.sender], "Sender address is locked");

        allowed[msg.sender][spender] = _amount;
        emit Approval(msg.sender, spender, _amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256 remaining) {
        return allowed[owner][spender];
    }

    function burn(uint256 value) public returns (bool success) {
        require(balances[msg.sender] >= value, "Balance does not have enough tokens");
        require(!locked[msg.sender], "Sender address is locked");

        balances[msg.sender] = balances[msg.sender].sub(value);
        state._totalsupply = state._totalsupply.sub(value);
        emit Burn(msg.sender, value);
        return true;
    }

    function burnFrom(address from, uint256 value) public returns (bool success) {
        require(balances[from] >= value, "Source balance does not have enough tokens");
        require(allowed[from][msg.sender] >= value, "Allowance is not enough");
        require(!locked[from], "Source address is locked");

        balances[from] = balances[from].sub(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        state._totalsupply = state._totalsupply.sub(value);
        emit Burn(from, value);
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

    function() public payable {
        require(!state.stopped, "CrowdSale is stopping");
        mint(address(this), msg.sender, msg.value);
    }

    function manualMint(address to, uint256 value) public onlyOwner {
        require(!state.stopped, "CrowdSale is stopping");
        mint(state.owner, to, value);
    }

    function mint(address from, address to, uint256 value) internal {
        require(to != address(0), "Address can not be 0x0");
        require(value > 0, "Value should larger than 0");

        balances[to] = balances[to].add(value);
        state._totalsupply = state._totalsupply.add(value);
        state.mintedTokens = state.mintedTokens.add(value);
        emit Mint(from, to, value);
        emit Transfer(address(0), to, value);
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
        require(newAddress != address(0), "Address can not be 0x0");
        state.ethFundMain = newAddress;
    }

    function assignOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Address can not be 0x0");
        balances[newOwner] = balances[newOwner].add(balances[state.owner]);
        balances[state.owner] = 0;
        state.owner = newOwner;
        emit Transfer(msg.sender, newOwner, balances[newOwner]);
    }

    function forwardFunds() external onlyOwner {
        address myAddress = address(this);
        state.ethFundMain.transfer(myAddress.balance);
    }

    function withdrawTokens() external onlyOwner {
        uint256 value = balances[address(this)];
        balances[state.owner] = balances[state.owner].add(value);
        balances[address(this)] = 0;
        emit Transfer(address(this), state.owner, value);
    }

    function haltTokenTransferFromAddress(address investor) external onlyOwner {
        locked[investor] = true;
    }

    function resumeTokenTransferFromAddress(address investor) external onlyOwner {
        locked[investor] = false;
    }

    function setUpgradeAgent(address agent) external onlyOwner {
        require(agent != address(0), "Upgrade agent can not be zero");
        require(state.totalUpgraded == 0, "Token are upgrading");
        upgradeAgent = UpgradeAgent(agent);
        require(upgradeAgent.isUpgradeAgent(), "The address is not upgrade agent");
        require(upgradeAgent.oldAddress() == address(this), "This is not right agent");
        emit UpgradeAgentSet(upgradeAgent);
    }

    function upgrade(uint256 value) public {
        require(value != 0, "Value can not be zero");
        require(balances[msg.sender] >= value, "Balance is not enough");
        require(address(upgradeAgent) != address(0), "Upgrade agent is not set");

        balances[msg.sender] = balances[msg.sender].sub(value);
        state._totalsupply = state._totalsupply.sub(value);
        state.totalUpgraded = state.totalUpgraded.add(value);
        upgradeAgent.upgradeFrom(msg.sender, value);
        emit Upgrade(msg.sender, upgradeAgent, value);
        emit Transfer(msg.sender, address(0), value);
    }
}