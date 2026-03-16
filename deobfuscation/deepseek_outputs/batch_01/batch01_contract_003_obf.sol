pragma solidity 0.5.16;

contract ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;
    
    function balanceOf(address owner) public view returns (uint) {}
    function approve(address spender, uint value) public returns (bool) {}
    function transfer(address to, uint value) public returns (bool) {}
    function allowance(address owner, address spender) public view returns (uint) {}
    function transferFrom(address from, address to, uint value) public returns (bool success) {}
}

contract RefundContract {
    event Refund(address indexed user, uint256 indexed amount, uint256 refundAmount);
    
    modifier onlyOwner() {
        require(data.owner == msg.sender);
        _;
    }
    
    modifier notInitialized() {
        require(!data.initialized, "contract is already initialized");
        _;
    }
    
    modifier isInitialized() {
        require(data.initialized, "contract is not initialized");
        _;
    }
    
    struct ContractData {
        address owner;
        address tokenAddress;
        bool initialized;
        uint256 rate;
        uint256 totalRefunded;
        uint8 decimals;
        string symbol;
        string name;
    }
    
    ContractData data = ContractData(address(0), address(0), false, 0, 0, 9, "DGD", "DigixDAO");
    
    constructor() public {
        data.owner = msg.sender;
        data.initialized = false;
    }
    
    function() external payable {}
    
    function initialize(uint256 rate, address tokenAddress) public onlyOwner() notInitialized() returns (bool success) {
        require(rate > 0, "rate cannot be zero");
        require(tokenAddress != address(0), "DGD token contract cannot be empty");
        
        data.rate = rate;
        data.tokenAddress = tokenAddress;
        data.initialized = true;
        success = true;
    }
    
    function refund() public isInitialized() returns (bool success) {
        uint256 tokenBalance = ERC20(data.tokenAddress).balanceOf(msg.sender);
        uint256 refundAmount = safeMul(tokenBalance, data.rate);
        
        require(address(this).balance >= refundAmount, "Contract does not have enough funds");
        require(ERC20(data.tokenAddress).transferFrom(msg.sender, address(0), tokenBalance), "No DGDs or DGD account not authorized");
        
        address user = msg.sender;
        (success,) = user.call.value(refundAmount)('');
        require(success, "Transfer of Ether failed");
        
        emit Refund(user, tokenBalance, refundAmount);
    }
    
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
}