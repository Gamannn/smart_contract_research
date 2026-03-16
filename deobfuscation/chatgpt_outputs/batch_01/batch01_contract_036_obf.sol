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
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
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

interface IExternalContract {
    function externalFunction() external payable returns (bool);
}

contract RetroBlockToken is IExternalContract {
    using SafeMath for uint256;

    mapping(address => uint256) private balances;
    IExternalContract public externalContract;
    mapping(address => uint256) private rewards;
    mapping(address => uint256) private allowances;
    mapping(address => mapping(address => uint256)) private allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event AddProfit(address indexed from, uint256 value, uint256 profit);
    event Withdraw(address indexed to, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == contractData.owner, "only owner");
        _;
    }

    modifier onlyHumans() {
        address sender = msg.sender;
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(sender)
        }
        require(codeSize == 0, "sorry humans only");
        _;
    }

    constructor(address externalContractAddress) public {
        contractData.owner = msg.sender;
        contractData.secondaryAddress1 = 0x28Dd611d5d2cAA117239bD3f3A548DcE5Fa873b0;
        contractData.secondaryAddress2 = 0x119ea7f823588D2Db81d86cEFe4F3BE25e4C34DC;
        externalContract = IExternalContract(externalContractAddress);
        balances[this] = 700;
    }

    function() public payable {
        require(msg.value > 0, "Amount must be provided");
        contractData.totalProfit = msg.value.div(contractData.totalSupply).add(contractData.totalProfit);
        emit AddProfit(msg.sender, msg.value, contractData.totalProfit);
    }

    function externalFunction() external payable returns (bool) {
        if (msg.value > 0) {
            contractData.totalProfit = msg.value.div(contractData.totalSupply).add(contractData.totalProfit);
            emit AddProfit(msg.sender, msg.value, contractData.totalProfit);
            return true;
        } else {
            return false;
        }
    }

    function totalSupply() external view returns (uint256) {
        return contractData.totalSupply;
    }

    function balanceOf(address owner) external view returns (uint256) {
        return balances[owner];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(value > 0 && allowed[msg.sender][spender] == 0);
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(value <= allowed[from][msg.sender]);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        return _transfer(from, to, value);
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return allowed[owner][spender];
    }

    function transfer(address to, uint256 value) external returns (bool) {
        return _transfer(msg.sender, to, value);
    }

    function _transfer(address from, address to, uint256 value) internal returns (bool) {
        require(to != address(0), "Receiver address cannot be null");
        require(from != to);
        require(value > 0 && value <= balances[from]);

        uint256 newBalanceTo = balances[to].add(value);
        assert(newBalanceTo >= balances[to]);

        uint256 newBalanceFrom = balances[from].sub(value);
        balances[to] = newBalanceTo;
        balances[from] = newBalanceFrom;

        uint256 reward = value.mul(contractData.totalProfit);
        rewards[from] = rewards[from].add(reward);
        rewards[to] = rewards[to].add(reward);

        emit Transfer(from, to, value);
        return true;
    }

    function purchase(uint256 amount) external onlyHumans payable {
        require(amount > 0);
        uint256 cost = amount.mul(contractData.pricePerToken);
        require(msg.value == cost);
        require(balances[this] >= amount);
        require((contractData.totalSupply - contractData.soldTokens) >= amount, "Sold out");

        _transfer(this, msg.sender, amount);

        contractData.secondaryAddress1.transfer(cost.mul(60).div(100));
        contractData.secondaryAddress2.transfer(cost.mul(20).div(100));
        externalContract.externalFunction.value(cost.mul(20).div(100))();

        contractData.soldTokens += amount;
    }

    function withdraw() external {
        uint256 cash = calculateCash(msg.sender);
        require(cash > 0, "No cash available");
        emit Withdraw(msg.sender, cash);
        rewards[msg.sender] = rewards[msg.sender].sub(cash);
        msg.sender.transfer(cash);
    }

    function withdrawAll() public onlyOwner {
        uint256 cash = calculateCash(this);
        emit Withdraw(msg.sender, cash);
        rewards[this] = rewards[this].sub(cash);
        contractData.owner.transfer(cash);
    }

    function calculateCash(address owner) public view returns (uint256) {
        return contractData.totalProfit.mul(balances[owner]).add(rewards[owner]).sub(rewards[owner]);
    }

    function setSecondaryAddress1(address newAddress) public onlyOwner {
        contractData.secondaryAddress1 = newAddress;
    }

    function setExternalContract(address newAddress) public onlyOwner {
        externalContract = IExternalContract(newAddress);
    }

    function setSecondaryAddress2(address newAddress) public onlyOwner {
        contractData.secondaryAddress2 = newAddress;
    }

    struct ContractData {
        address secondaryAddress1;
        uint256 totalProfit;
        address secondaryAddress2;
        address owner;
        string contractName;
        string tokenName;
        uint256 pricePerToken;
        uint256 soldTokens;
        uint256 totalSupply;
        uint8 decimals;
    }

    ContractData contractData = ContractData(
        address(0),
        0,
        address(0),
        address(0),
        "RetroBlockToken",
        "Retro Block Token 2",
        1 ether,
        0,
        700,
        0
    );
}
```