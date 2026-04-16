```solidity
pragma solidity ^0.4.24;

contract TokenContract {
    address public owner;
    address public feeAddress;
    address public adminAddress;
    uint256 public maxTransaction;
    uint256 public loopCount;
    uint256 public feePercent;
    bool public receiveEth = true;
    bool public payFees = true;
    bool public isTrancheActive = true;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public lockedBalances;
    mapping(address => mapping(address => uint256)) public allowances;
    mapping(uint => uint256) public trancheSupply;
    mapping(uint => uint256) public trancheRate;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() public {
        owner = msg.sender;
        feeAddress = msg.sender;
        adminAddress = msg.sender;
        initializeTrancheSupply();
        initializeTrancheRate();
    }

    function initializeTrancheSupply() internal {
        trancheSupply[1] = 1E25;
        trancheSupply[2] = 2E25;
        trancheSupply[3] = 1E25;
        trancheSupply[4] = 1E25;
    }

    function initializeTrancheRate() internal {
        trancheRate[1] = 3.457E20;
        trancheRate[2] = 8.643E19;
        trancheRate[3] = 4.321E19;
        trancheRate[4] = 2.161E19;
    }

    function () payable public {
        require(msg.value > 0 && receiveEth);
        processTransaction(msg.value, 0);
    }

    function processTransaction(uint256 amount, uint256 tokenAmount) internal {
        uint256 trancheIndex = 0;
        loopCount++;

        if (trancheIndex <= maxTransaction && loopCount <= trancheSupply[trancheIndex]) {
            uint256 tokensAfforded = calculateTokens(amount, trancheRate[trancheIndex]);
            balances[msg.sender] = safeAdd(balances[msg.sender], tokensAfforded);
            trancheSupply[trancheIndex] = safeSub(trancheSupply[trancheIndex], tokensAfforded);
            emit Transfer(this, msg.sender, tokensAfforded);
        } else {
            uint256 fee = 0;
            if (payFees) {
                fee = safeMul(tokenAmount, feePercent) / 10000;
                balances[feeAddress] = safeAdd(balances[feeAddress], fee);
            }
            balances[msg.sender] = safeAdd(balances[msg.sender], tokenAmount);
            emit Transfer(this, msg.sender, tokenAmount);
        }
    }

    function transfer(address to, uint256 value) public {
        require(balances[msg.sender] >= value);
        balances[msg.sender] = safeSub(balances[msg.sender], value);
        balances[to] = safeAdd(balances[to], value);
        emit Transfer(msg.sender, to, value);
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(balances[from] >= value && allowances[from][msg.sender] >= value);
        balances[from] = safeSub(balances[from], value);
        allowances[from][msg.sender] = safeSub(allowances[from][msg.sender], value);
        balances[to] = safeAdd(balances[to], value);
        emit Transfer(from, to, value);
        return true;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function lockedBalanceOf(address account) public view returns (uint256) {
        return lockedBalances[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowances[owner][spender];
    }

    function setFeePercent(uint256 newFeePercent) public {
        require(msg.sender == owner && newFeePercent >= 0 && newFeePercent <= 100);
        feePercent = newFeePercent * 100;
    }

    function setAdminAddress(address newAdminAddress) public {
        require(msg.sender == owner);
        adminAddress = newAdminAddress;
    }

    function toggleReceiveEth() public {
        require(msg.sender == owner);
        receiveEth = !receiveEth;
    }

    function togglePayFees() public {
        require(msg.sender == owner);
        payFees = !payFees;
    }

    function calculateTokens(uint256 amount, uint256 rate) internal pure returns (uint256) {
        return safeMul(amount, rate) / 1 ether;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
}
```