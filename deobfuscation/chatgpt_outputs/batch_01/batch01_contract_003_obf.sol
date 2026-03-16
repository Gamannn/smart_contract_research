pragma solidity 0.5.16;

contract TokenContract {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;

    function balanceOf(address owner) public view returns (uint) {}
    function approve(address spender, uint value) public returns (bool) {}
    function transfer(address to, uint value) public returns (bool) {}
    function allowance(address owner, address spender) public view returns (uint) {}
    function transferFrom(address from, address to, uint value) public returns (bool) {}
}

contract RefundContract {
    event Refund(address indexed user, uint256 indexed tokenAmount, uint256 etherAmount);

    modifier onlyOwner() {
        require(contractData.owner == msg.sender);
        _;
    }

    modifier notInitialized() {
        require(!contractData.initialized, "contract is already initialized");
        _;
    }

    modifier isInitialized() {
        require(contractData.initialized, "contract is not initialized");
        _;
    }

    constructor() public {
        contractData.owner = msg.sender;
        contractData.initialized = false;
    }

    function () external payable {}

    function initialize(uint256 rate, address tokenContract) public onlyOwner notInitialized returns (bool success) {
        require(rate > 0, "rate cannot be zero");
        require(tokenContract != address(0), "Token contract cannot be empty");

        contractData.rate = rate;
        contractData.tokenContract = tokenContract;
        contractData.initialized = true;
        success = true;
    }

    function refund() public isInitialized returns (bool success) {
        uint256 tokenBalance = TokenContract(contractData.tokenContract).balanceOf(msg.sender);
        uint256 etherAmount = calculateEtherAmount(tokenBalance, contractData.rate);

        require(address(this).balance >= etherAmount, "Contract does not have enough funds");
        require(TokenContract(contractData.tokenContract).transferFrom(msg.sender, address(0), tokenBalance), "No tokens or account not authorized");

        address payable user = msg.sender;
        (success,) = user.call.value(etherAmount)("");
        require(success, "Transfer of Ether failed");

        emit Refund(user, tokenBalance, etherAmount);
    }

    function calculateEtherAmount(uint256 tokenAmount, uint256 rate) internal pure returns (uint256) {
        if (tokenAmount == 0) {
            return 0;
        }
        uint256 etherAmount = tokenAmount * rate;
        require(etherAmount / tokenAmount == rate, "SafeMath: multiplication overflow");
        return etherAmount;
    }

    struct ContractData {
        address owner;
        address tokenContract;
        bool initialized;
        uint256 rate;
        uint256 someOtherValue;
        uint8 someFlag;
        string tokenSymbol;
        string tokenName;
    }

    ContractData contractData = ContractData(address(0), address(0), false, 0, 0, 9, "DGD", "DigixDAO");
}