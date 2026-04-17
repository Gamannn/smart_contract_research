```solidity
pragma solidity ^0.5.2;

library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0);
        uint c = a / b;
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        uint c = a - b;
        return c;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a);
        return c;
    }
}

contract ERC20 {
    function totalSupply() public returns (uint);
    function balanceOf(address who) public returns (uint);
    function transfer(address to, uint value) public returns (bool);
    function transferFrom(address from, address to, uint value) public returns (bool);
    function approve(address spender, uint value) public returns (bool);
    function allowance(address owner, address spender) public returns (uint);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    uint public decimals;
    string public name;
    string public symbol;
}

contract DEX {
    using SafeMath for uint;

    address public admin;
    address public feeAccount;
    mapping(address => uint) public tokenBalance;
    mapping(address => uint) public tokenFee;
    mapping(address => uint) public tokenWithdrawFee;
    mapping(address => mapping(address => uint)) public balances;
    mapping(address => mapping(bytes32 => bool)) public orderBook;
    mapping(address => mapping(bytes32 => uint)) public orderFills;
    mapping(address => bool) public activeTokens;
    mapping(address => uint) public minDeposit;
    mapping(address => uint) public minWithdraw;

    event Order(address indexed user, uint amount, address tokenGet, uint amountGet, uint expires, uint nonce, address indexed tokenGive);
    event Cancel(address indexed user, uint amount, address tokenGet, uint amountGet, uint expires, uint nonce, address indexed tokenGive, uint8 v, bytes32 r, bytes32 s);
    event Trade(address indexed user, uint amount, address tokenGet, uint amountGet, address tokenGive, address indexed userFill);
    event Deposit(address indexed user, address token, uint amount, uint balance);
    event Withdraw(address indexed user, address token, uint amount, uint balance);
    event ActivateToken(address indexed token, string name);
    event DeactivateToken(address indexed token, string name);

    constructor(address adminAddress, address feeAccountAddress) public {
        admin = adminAddress;
        feeAccount = feeAccountAddress;
    }

    function changeAdmin(address newAdmin) public {
        require(msg.sender == admin);
        admin = newAdmin;
    }

    function changeFeeAccount(address newFeeAccount) public {
        require(msg.sender == admin);
        feeAccount = newFeeAccount;
    }

    function deposit() public payable {
        uint fee = msg.value.mul(tokenFee[address(0)]).div(1 ether);
        uint amount = msg.value.sub(fee);
        balances[address(0)][msg.sender] = balances[address(0)][msg.sender].add(amount);
        balances[address(0)][feeAccount] = balances[address(0)][feeAccount].add(fee);
        emit Deposit(msg.sender, address(0), msg.value, balances[address(0)][msg.sender]);
    }

    function withdraw(uint amount) public {
        require(balances[address(0)][msg.sender] >= amount);
        uint fee = amount.mul(tokenWithdrawFee[address(0)]).div(1 ether);
        uint withdrawAmount = amount.sub(fee);
        balances[address(0)][msg.sender] = balances[address(0)][msg.sender].sub(amount);
        balances[address(0)][feeAccount] = balances[address(0)][feeAccount].add(fee);
        msg.sender.transfer(withdrawAmount);
        emit Withdraw(msg.sender, address(0), amount, balances[address(0)][msg.sender]);
    }

    function depositToken(address token, uint amount) public {
        require(token != address(0));
        require(activeTokens[token]);
        require(ERC20(token).transferFrom(msg.sender, address(this), amount));
        uint fee = amount.mul(tokenFee[token]).div(1 ether);
        uint netAmount = amount.sub(fee);
        balances[token][msg.sender] = balances[token][msg.sender].add(netAmount);
        balances[token][feeAccount] = balances[token][feeAccount].add(fee);
        emit Deposit(msg.sender, token, amount, balances[token][msg.sender]);
    }

    function withdrawToken(address token, uint amount) public {
        require(token != address(0));
        require(balances[token][msg.sender] >= amount);
        uint fee = amount.mul(tokenWithdrawFee[token]).div(1 ether);
        uint withdrawAmount = amount.sub(fee);
        balances[token][msg.sender] = balances[token][msg.sender].sub(amount);
        balances[token][feeAccount] = balances[token][feeAccount].add(fee);
        require(ERC20(token).transfer(msg.sender, withdrawAmount));
        emit Withdraw(msg.sender, token, amount, balances[token][msg.sender]);
    }

    function balanceOf(address token, address user) view public returns (uint) {
        return balances[token][user];
    }

    function createOrder(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce) public {
        require(activeTokens[tokenGet] && activeTokens[tokenGive]);
        require(amountGet >= minDeposit[tokenGet]);
        require(amountGive >= minWithdraw[tokenGive]);
        bytes32 hash = keccak256(abi.encodePacked(address(this), tokenGet, amountGet, tokenGive, amountGive, expires, nonce));
        orderBook[msg.sender][hash] = true;
        emit Order(msg.sender, amountGet, tokenGet, amountGive, expires, nonce, tokenGive);
    }

    function cancelOrder(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 hash = keccak256(abi.encodePacked(address(this), tokenGet, amountGet, tokenGive, amountGive, expires, nonce));
        require(orderBook[user][hash] || ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), v, r, s) == user);
        orderFills[user][hash] = amountGet;
        emit Cancel(user, amountGet, tokenGet, amountGive, expires, nonce, msg.sender, v, r, s);
    }

    function activateToken(address token) public {
        require(msg.sender == admin);
        activeTokens[token] = true;
        emit ActivateToken(token, ERC20(token).name());
    }

    function deactivateToken(address token) public {
        require(msg.sender == admin);
        activeTokens[token] = false;
        emit DeactivateToken(token, ERC20(token).name());
    }

    function isActiveToken(address token) view public returns (bool) {
        if (token == address(0)) return true; // ETH is always active
        return activeTokens[token];
    }

    function setMinDeposit(address token, uint amount) public {
        require(msg.sender == admin);
        minDeposit[token] = amount;
    }

    function setMinWithdraw(address token, uint amount) public {
        require(msg.sender == admin);
        minWithdraw[token] = amount;
    }

    function setTokenFee(address token, uint fee) public {
        require(msg.sender == admin);
        tokenFee[token] = fee;
    }

    function setTokenWithdrawFee(address token, uint fee) public {
        require(msg.sender == admin);
        tokenWithdrawFee[token] = fee;
    }
}
```