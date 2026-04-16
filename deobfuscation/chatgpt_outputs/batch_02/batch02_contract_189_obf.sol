```solidity
pragma solidity ^0.4.24;

contract Ownable {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }
}

interface ERC20 {
    function transfer(address to, uint256 value) external returns (bool);
}

contract TokenSale is Ownable {
    string public constant CONTRACT_NAME = "TokenSale";
    string public constant CONTRACT_VERSION = "1.0";
    string public constant TOKEN_SYMBOL = "BASS";
    uint256 private tokenPrice;
    uint256 private totalSupply;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    mapping(address => bool) private frozenAccounts;
    bool private saleActive;

    event ReceivedEth(address indexed from, uint256 value, uint256 timestamp);
    event TransferredEth(address indexed to, uint256 value);
    event TransferredERC20(address indexed to, address indexed token, uint256 value);
    event SoldToken(address indexed buyer, uint256 value, bytes32 txHash);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function () payable public {
        emit ReceivedEth(msg.sender, msg.value, now);
    }

    function transferEth(address to, uint256 value) public onlyOwner {
        require(address(this).balance >= value);
        to.transfer(value);
        emit TransferredEth(to, value);
    }

    function transferERC20(address to, address token, uint256 value) internal onlyOwner {
        ERC20 erc20 = ERC20(token);
        require(erc20.transfer(to, value));
        emit TransferredERC20(to, token, value);
    }

    function startSale(uint256 price, uint256 supply) public onlyOwner {
        tokenPrice = price * (10 ** 18);
        totalSupply = supply * tokenPrice;
        saleActive = true;
    }

    function stopSale() public onlyOwner {
        saleActive = false;
    }

    function isSaleActive() public view returns (bool) {
        return saleActive;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(saleActive);
        require(balances[msg.sender] >= value && value > 0);
        require(balances[to] + value > balances[to]);

        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowances[owner][spender];
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(!frozenAccounts[from] && !frozenAccounts[to]);
        require(saleActive);
        require(balances[from] >= value && allowances[from][msg.sender] >= value && value > 0);
        require(balances[to] + value > balances[to]);

        balances[from] -= value;
        allowances[from][msg.sender] -= value;
        balances[to] += value;
        emit Transfer(from, to, value);
        return true;
    }

    function freezeAccount(address account) public onlyOwner {
        frozenAccounts[account] = true;
    }

    function unfreezeAccount(address account) public onlyOwner {
        delete frozenAccounts[account];
    }
}
```