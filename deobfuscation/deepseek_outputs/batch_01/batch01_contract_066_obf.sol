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

    function pow(uint256 base, uint256 exponent) internal pure returns (uint256) {
        if (base == 0) return 0;
        else if (exponent == 0) return 1;
        else {
            uint256 result = base;
            for (uint256 i = 1; i < exponent; i++) {
                result = mul(result, base);
            }
            return result;
        }
    }
}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
}

contract RetroBlockToken is IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _credits;
    mapping(address => uint256) private _withdrawn;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event AddProfit(address indexed investor, uint256 investment, uint256 totalProfit);
    event Withdraw(address indexed investor, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == config.owner, "only owner");
        _;
    }

    modifier noContract() {
        address investor = msg.sender;
        uint256 size;
        assembly {
            size := extcodesize(investor)
        }
        require(size == 0, "sorry humans only");
        _;
    }

    struct Config {
        address teamWallet;
        uint256 totalProfit;
        address marketingWallet;
        address owner;
        string contractName;
        string tokenName;
        uint256 tokenPrice;
        uint256 tokensSold;
        uint256 totalSupply;
        uint8 decimals;
    }

    Config private config = Config(
        address(0),
        0,
        address(0),
        address(0),
        "RetroBlockToken",
        "Retro Block Token 1",
        1 ether,
        0,
        300,
        0
    );

    constructor() public {
        config.owner = msg.sender;
        config.marketingWallet = 0x28Dd6115d2cAA117239bD3f3A548DcE5Fa873b0;
        config.teamWallet = 0x119ea7f823588D2Db81d86cEFe4F3BE25e4C34DC;
        _balances[this] = 300;
    }

    function() public payable {
        if (msg.value > 0) {
            config.totalProfit = msg.value.div(config.totalSupply).add(config.totalProfit);
            emit AddProfit(msg.sender, msg.value, config.totalProfit);
        }
    }

    function invest() external payable returns (bool) {
        if (msg.value > 0) {
            config.totalProfit = msg.value.div(config.totalSupply).add(config.totalProfit);
            emit AddProfit(msg.sender, msg.value, config.totalProfit);
            return true;
        } else {
            return false;
        }
    }

    function totalSupply() external view returns (uint256) {
        return config.totalSupply;
    }

    function balanceOf(address owner) external view returns (uint256) {
        return _balances[owner];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(value > 0 && _allowances[msg.sender][spender] == 0);
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(value <= _allowances[from][msg.sender]);
        _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(value);
        return _transfer(from, to, value);
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function transfer(address to, uint256 value) external returns (bool) {
        return _transfer(msg.sender, to, value);
    }

    function _transfer(address from, address to, uint256 value) internal returns (bool) {
        require(to != address(0), "Receiver address cannot be null");
        require(value > 0 && value <= _balances[from]);

        uint256 toBalance = _balances[to].add(value);
        assert(toBalance >= _balances[to]);

        uint256 fromBalance = _balances[from].sub(value);
        _balances[from] = fromBalance;
        _balances[to] = toBalance;

        uint256 profitShare = value.mul(config.totalProfit);
        _credits[from] = _credits[from].add(profitShare);
        _withdrawn[to] = _withdrawn[to].add(profitShare);

        emit Transfer(from, to, value);
        return true;
    }

    function buy(uint256 amount) external noContract payable {
        require(amount > 0);
        uint256 cost = amount.mul(config.tokenPrice);
        require(msg.value == cost);
        require(_balances[this] >= amount);
        require((config.totalSupply - config.tokensSold) >= amount, "Sold out");

        config.marketingWallet.transfer(cost.mul(80).div(100));
        _transfer(this, msg.sender, amount);
        config.teamWallet.transfer(cost.mul(20).div(100));
        config.tokensSold = config.tokensSold.add(amount);
    }

    function withdraw() external {
        uint256 amount = pendingProfit(msg.sender);
        require(amount > 0, "No cash available");
        emit Withdraw(msg.sender, amount);
        _withdrawn[msg.sender] = _withdrawn[msg.sender].add(amount);
        msg.sender.transfer(amount);
    }

    function pendingProfit(address investor) public view returns (uint256) {
        return config.totalProfit.mul(_balances[investor]).add(_credits[investor]).sub(_withdrawn[investor]);
    }

    function setTeamWallet(address wallet) public onlyOwner {
        config.teamWallet = wallet;
    }

    function setMarketingWallet(address wallet) public onlyOwner {
        config.marketingWallet = wallet;
    }
}