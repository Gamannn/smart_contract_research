```solidity
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

interface IToken {
    function deposit() external payable returns (bool);
}

contract RetroBlockToken is IToken {
    using SafeMath for uint256;

    mapping(address => uint256) private balances;
    mapping(address => uint256) private rewards;
    mapping(address => uint256) private profits;
    mapping(address => mapping(address => uint256)) private allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event AddProfit(address indexed from, uint256 value, uint256 totalProfit);
    event Withdraw(address indexed to, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == tokenData.owner, "only owner");
        _;
    }

    modifier onlyHumans() {
        address sender = msg.sender;
        uint256 codeSize;
        assembly { codeSize := extcodesize(sender) }
        require(codeSize == 0, "sorry humans only");
        _;
    }

    struct TokenData {
        address profitAddress;
        uint256 profitRate;
        address feeAddress;
        address owner;
        string symbol;
        string name;
        uint256 tokenPrice;
        uint256 soldTokens;
        uint256 totalSupply;
        uint8 decimals;
    }

    TokenData private tokenData = TokenData(
        address(0),
        0,
        address(0),
        address(0),
        "RBT",
        "Retro Block Token",
        1 ether,
        0,
        300,
        0
    );

    constructor() public {
        tokenData.owner = msg.sender;
        tokenData.feeAddress = 0x28Dd611d5d2cAA117239bD3f3A548DcE5Fa873b0;
        tokenData.profitAddress = 0x119ea7f823588D2Db81d86cEFe4F3BE25e4C34DC;
        profits[this] = 300;
    }

    function() public payable {
        if (msg.value > 0) {
            tokenData.profitRate = msg.value.div(tokenData.totalSupply).add(tokenData.profitRate);
            emit AddProfit(msg.sender, msg.value, tokenData.profitRate);
        }
    }

    function deposit() external payable returns (bool) {
        if (msg.value > 0) {
            tokenData.profitRate = msg.value.div(tokenData.totalSupply).add(tokenData.profitRate);
            emit AddProfit(msg.sender, msg.value, tokenData.profitRate);
            return true;
        } else {
            return false;
        }
    }

    function totalSupply() external view returns (uint256) {
        return tokenData.totalSupply;
    }

    function balanceOf(address owner) external view returns (uint256) {
        return profits[owner];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(value > 0 && allowances[msg.sender][spender] == 0);
        allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(value <= allowances[from][msg.sender]);
        allowances[from][msg.sender] = allowances[from][msg.sender].sub(value);
        return _transfer(from, to, value);
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return allowances[owner][spender];
    }

    function transfer(address to, uint256 value) external returns (bool) {
        return _transfer(msg.sender, to, value);
    }

    function _transfer(address from, address to, uint256 value) internal returns (bool) {
        require(to != address(0), "Receiver address cannot be null");
        require(value > 0 && value <= profits[from]);

        uint256 newBalance = profits[to].add(value);
        assert(newBalance >= profits[to]);

        uint256 newSenderBalance = profits[from].sub(value);
        profits[from] = newSenderBalance;
        profits[to] = newBalance;

        uint256 reward = value.mul(tokenData.profitRate);
        rewards[from] = rewards[from].add(reward);
        balances[to] = balances[to].add(reward);

        emit Transfer(from, to, value);
        return true;
    }

    function buyTokens(uint256 amount) external onlyHumans payable {
        require(amount > 0);
        uint256 cost = amount.mul(tokenData.tokenPrice);
        require(msg.value == cost);
        require(profits[this] >= amount);
        require((tokenData.totalSupply - tokenData.soldTokens) >= amount, "Sold out");

        tokenData.feeAddress.transfer(cost.mul(80).div(100));
        _transfer(this, msg.sender, amount);
        tokenData.profitAddress.transfer(cost.mul(20).div(100));
        tokenData.soldTokens = tokenData.soldTokens.add(amount);
    }

    function withdraw() external {
        uint256 availableCash = calculateCash(msg.sender);
        require(availableCash > 0, "No cash available");
        emit Withdraw(msg.sender, availableCash);
        balances[msg.sender] = balances[msg.sender].add(availableCash);
        msg.sender.transfer(availableCash);
    }

    function calculateCash(address owner) public view returns (uint256) {
        return tokenData.profitRate.mul(profits[owner]).add(rewards[owner]).sub(balances[owner]);
    }

    function setProfitAddress(address newAddress) public onlyOwner {
        tokenData.profitAddress = newAddress;
    }

    function setFeeAddress(address newAddress) public onlyOwner {
        tokenData.feeAddress = newAddress;
    }
}
```