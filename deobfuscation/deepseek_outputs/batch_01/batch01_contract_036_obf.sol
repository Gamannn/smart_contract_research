```solidity
pragma solidity ^0.4.23;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    
    function power(uint256 base, uint256 exponent) internal pure returns (uint256) {
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
    function deposit() external payable returns(bool);
}

contract RetroBlockToken2 is IExternalContract {
    using SafeMath for uint256;
    
    mapping(address => uint256) private claimedDividends;
    IExternalContract public externalContract;
    mapping(address => uint256) private pendingDividends;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event AddProfit(address indexed investor, uint256 amount, uint256 profit);
    event Withdraw(address indexed user, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == contractData.owner, "only owner");
        _;
    }
    
    modifier noContract() {
        address user = msg.sender;
        uint256 size;
        assembly {
            size := extcodesize(user)
        }
        require(size == 0, "sorry humans only");
        _;
    }
    
    constructor(address _externalContract) public {
        contractData.owner = msg.sender;
        contractData.marketingWallet = 0x28Dd611d5d2cAA117239bD3f3A548DcE5Fa873b0;
        contractData.devWallet = 0x119ea7f823588D2Db81d86cEFe4F3BE25e4C34DC;
        externalContract = IExternalContract(_externalContract);
        balances[this] = 700;
    }
    
    function() public payable {
        require(msg.value > 0, "Amount must be provided");
        contractData.totalProfit = msg.value.div(contractData.totalSupply).add(contractData.totalProfit);
        emit AddProfit(msg.sender, msg.value, contractData.totalProfit);
    }
    
    function deposit() external payable returns(bool) {
        if(msg.value > 0) {
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
    
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
    
    function approve(address spender, uint256 value) public returns (bool) {
        require(value > 0 && allowances[msg.sender][spender] == 0);
        allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(value <= allowances[from][msg.sender]);
        allowances[from][msg.sender] -= value;
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
        require(from != to);
        require(value > 0 && value <= balances[from]);
        
        uint256 toBalance = balances[to].add(value);
        assert(toBalance >= balances[to]);
        
        uint256 fromBalance = balances[from].sub(value);
        
        balances[to] = toBalance;
        balances[from] = fromBalance;
        
        uint256 profitShare = value.mul(contractData.totalProfit);
        pendingDividends[from] = pendingDividends[from].add(profitShare);
        claimedDividends[to] = claimedDividends[to].add(profitShare);
        
        emit Transfer(from, to, value);
        return true;
    }
    
    function buy(uint256 tokenAmount) external noContract payable {
        require(tokenAmount > 0);
        uint256 cost = tokenAmount.mul(contractData.tokenPrice);
        require(msg.value == cost);
        require(balances[this] >= tokenAmount);
        require((contractData.totalSupply - contractData.soldTokens) >= tokenAmount, "Sold out");
        
        _transfer(this, msg.sender, tokenAmount);
        
        contractData.marketingWallet.transfer(cost.mul(60).div(100));
        contractData.devWallet.transfer(cost.mul(20).div(100));
        externalContract.depend.value(cost.mul(20).div(100))();
        
        contractData.soldTokens += tokenAmount;
    }
    
    function withdraw() external {
        uint256 amount = getDividends(msg.sender);
        require(amount > 0, "No cash available");
        emit Withdraw(msg.sender, amount);
        claimedDividends[msg.sender] = claimedDividends[msg.sender].add(amount);
        msg.sender.transfer(amount);
    }
    
    function withdrawContract() public onlyOwner {
        uint256 amount = getDividends(this);
        emit Withdraw(msg.sender, amount);
        claimedDividends[this] = claimedDividends[this].add(amount);
        contractData.owner.transfer(amount);
    }
    
    function getDividends(address user) public view returns(uint256) {
        return contractData.totalProfit
            .mul(balances[user])
            .add(pendingDividends[user])
            .sub(claimedDividends[user]);
    }
    
    function setDevWallet(address wallet) public onlyOwner {
        contractData.devWallet = wallet;
    }
    
    function setExternalContract(address _externalContract) public onlyOwner {
        externalContract = IExternalContract(_externalContract);
    }
    
    function setMarketingWallet(address wallet) public onlyOwner {
        contractData.marketingWallet = wallet;
    }
    
    struct ContractData {
        address devWallet;
        uint256 totalProfit;
        address marketingWallet;
        address owner;
        string contractName;
        string tokenName;
        uint256 tokenPrice;
        uint256 soldTokens;
        uint256 totalSupply;
        uint8 decimals;
    }
    
    ContractData private contractData = ContractData(
        address(0),
        0,
        address(0),
        address(0),
        "RetroBlockToken2",
        "Retro Block Token 2",
        1 ether,
        0,
        700,
        0
    );
}
```