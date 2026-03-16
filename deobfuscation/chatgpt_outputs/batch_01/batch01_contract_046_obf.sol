```solidity
pragma solidity ^0.4.18;

contract Token {
    function balanceOf(address owner) public constant returns(uint);
}

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
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20Detailed is ERC20 {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Exchange {
    using SafeMath for uint256;

    mapping (address => mapping (address => uint256)) public balances;
    mapping (address => bool) public tokenWhitelist;
    mapping (address => bool) public userWhitelist;
    mapping (address => mapping (bytes32 => bool)) public orderFills;
    mapping (address => mapping (bytes32 => uint256)) public orderAmounts;

    event Order(address indexed tokenGet, uint256 amountGet, address indexed tokenGive, uint256 amountGive, uint256 expires, uint256 nonce, address indexed user);
    event Cancel(address indexed tokenGet, uint256 amountGet, address indexed tokenGive, uint256 amountGive, uint256 expires, uint256 nonce, address indexed user, uint8 v, bytes32 r, bytes32 s);
    event Trade(address indexed tokenGet, uint256 amountGet, address indexed tokenGive, uint256 amountGive, address indexed get, address give);
    event Deposit(address indexed token, address indexed user, uint256 amount, uint256 balance);
    event Withdraw(address indexed token, address indexed user, uint256 amount, uint256 balance);

    struct Config {
        uint256 feeRebate;
        uint256 feeTake;
        uint256 feeMake;
        address feeAccount;
        address admin;
        address owner;
    }

    Config public config;

    function Exchange(
        address feeAccount,
        address admin,
        address owner,
        uint256 feeMake,
        uint256 feeTake,
        uint256 feeRebate
    ) public {
        require(feeAccount != 0x0);
        config.feeAccount = feeAccount;
        config.admin = admin;
        config.owner = owner;
        config.feeMake = feeMake;
        config.feeTake = feeTake;
        config.feeRebate = feeRebate;
        tokenWhitelist[0x0] = true;
    }

    modifier onlyOwner() {
        require(msg.sender == config.owner);
        _;
    }

    function() public payable {
        revert();
    }

    function changeOwner(address newOwner) public onlyOwner {
        require(newOwner != 0x0 && config.owner != newOwner);
        config.owner = newOwner;
    }

    function changeAdmin(address newAdmin) public onlyOwner {
        config.admin = newAdmin;
    }

    function changeFeeAccount(address newFeeAccount) public onlyOwner {
        require(newFeeAccount != 0x0);
        config.feeAccount = newFeeAccount;
    }

    function changeFeeMake(uint256 newFeeMake) public onlyOwner {
        config.feeMake = newFeeMake;
    }

    function changeFeeTake(uint256 newFeeTake) public onlyOwner {
        require(newFeeTake >= config.feeRebate);
        config.feeTake = newFeeTake;
    }

    function changeFeeRebate(uint256 newFeeRebate) public onlyOwner {
        require(newFeeRebate <= config.feeTake);
        config.feeRebate = newFeeRebate;
    }

    function addTokenToWhitelist(address token) public onlyOwner {
        require(token != 0x0 && !tokenWhitelist[token]);
        tokenWhitelist[token] = true;
    }

    function removeTokenFromWhitelist(address token) public onlyOwner {
        require(token != 0x0 && tokenWhitelist[token]);
        tokenWhitelist[token] = false;
    }

    function addUserToWhitelist(address user) public onlyOwner {
        require(user != 0x0 && !userWhitelist[user]);
        userWhitelist[user] = true;
    }

    function removeUserFromWhitelist(address user) public onlyOwner {
        require(user != 0x0 && userWhitelist[user]);
        userWhitelist[user] = false;
    }

    function deposit() public payable {
        require(userWhitelist[msg.sender]);
        balances[0x0][msg.sender] = balances[0x0][msg.sender].add(msg.value);
        Deposit(0x0, msg.sender, msg.value, balances[0x0][msg.sender]);
    }

    function withdraw(uint256 amount) public {
        require(balances[0x0][msg.sender] >= amount);
        balances[0x0][msg.sender] = balances[0x0][msg.sender].sub(amount);
        msg.sender.transfer(amount);
        Withdraw(0x0, msg.sender, amount, balances[0x0][msg.sender]);
    }

    function depositToken(address token, uint256 amount) public {
        require(token != 0x0 && tokenWhitelist[token]);
        require(userWhitelist[msg.sender]);
        balances[token][msg.sender] = balances[token][msg.sender].add(amount);
        require(ERC20Detailed(token).transferFrom(msg.sender, address(this), amount));
        Deposit(token, msg.sender, amount, balances[token][msg.sender]);
    }

    function withdrawToken(address token, uint256 amount) public {
        require(token != 0x0);
        require(balances[token][msg.sender] >= amount);
        balances[token][msg.sender] = balances[token][msg.sender].sub(amount);
        require(ERC20Detailed(token).transfer(msg.sender, amount));
        Withdraw(token, msg.sender, amount, balances[token][msg.sender]);
    }

    function balanceOf(address token, address user) public constant returns (uint256) {
        return balances[token][user];
    }

    function order(
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        uint256 expires,
        uint256 nonce
    ) public {
        require(userWhitelist[msg.sender]);
        require(tokenWhitelist[tokenGet] && tokenWhitelist[tokenGive]);
        bytes32 hash = keccak256(address(this), tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        orderFills[msg.sender][hash] = true;
        Order(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender);
    }

    function cancelOrder(
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        uint256 expires,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        bytes32 hash = keccak256(address(this), tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        require(validateOrder(hash, msg.sender, v, r, s));
        orderAmounts[msg.sender][hash] = amountGet;
        Cancel(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender, v, r, s);
    }

    function trade(
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        uint256 expires,
        uint256 nonce,
        address user,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 amount
    ) public {
        require(userWhitelist[msg.sender]);
        require(tokenWhitelist[tokenGet] && tokenWhitelist[tokenGive]);
        require(block.number <= expires);
        bytes32 hash = keccak256(address(this), tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        require(validateOrder(hash, user, v, r, s));
        require(orderAmounts[user][hash].add(amount) <= amountGet);
        orderAmounts[user][hash] = orderAmounts[user][hash].add(amount);
        executeTrade(tokenGet, amountGet, tokenGive, amountGive, user, amount);
        Trade(tokenGet, amount, tokenGive, amountGive.mul(amount).div(amountGet), user, msg.sender);
    }

    function availableVolume(
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        uint256 expires,
        uint256 nonce,
        address user,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public constant returns (uint256) {
        require(userWhitelist[user]);
        require(tokenWhitelist[tokenGet] && tokenWhitelist[tokenGive]);
        bytes32 hash = keccak256(address(this), tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        if (!(validateOrder(hash, user, v, r, s) && block.number <= expires)) {
            return 0;
        }
        if (amountGet.sub(orderAmounts[user][hash]) < balances[tokenGive][user].mul(amountGet).div(amountGive)) {
            return amountGet.sub(orderAmounts[user][hash]);
        }
        return balances[tokenGive][user].mul(amountGet).div(amountGive);
    }

    function amountFilled(
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        uint256 expires,
        uint256 nonce,
        address user
    ) public constant returns (uint256) {
        require(userWhitelist[user]);
        require(tokenWhitelist[tokenGet] && tokenWhitelist[tokenGive]);
        return orderAmounts[user][keccak256(address(this), tokenGet, amountGet, tokenGive, amountGive, expires, nonce)];
    }

    function executeTrade(
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        address user,
        uint256 amount
    ) private {
        uint256 feeRebate = amount.mul(config.feeRebate).div(1 ether);
        uint256 feeTake = amount.mul(config.feeTake).div(1 ether);
        uint256 feeMake = 0;
        if (config.admin != 0x0) {
            uint256 userType = Token(config.admin).balanceOf(user);
            if (userType == 1) {
                feeMake = amount.mul(config.feeRebate).div(1 ether);
            } else if (userType == 2) {
                feeMake = feeTake;
            }
        }
        balances[tokenGet][msg.sender] = balances[tokenGet][msg.sender].sub(amount.add(feeTake));
        balances[tokenGet][user] = balances[tokenGet][user].add(amount.sub(feeRebate));
        balances[tokenGet][config.feeAccount] = balances[tokenGet][config.feeAccount].add(feeRebate.add(feeTake).sub(feeMake));
        balances[tokenGive][user] = balances[tokenGive][user].sub(amountGive.mul(amount).div(amountGet));
        balances[tokenGive][msg.sender] = balances[tokenGive][msg.sender].add(amountGive.mul(amount).div(amountGet));
    }

    function validateOrder(
        bytes32 hash,
        address user,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private constant returns (bool) {
        return (
            orderFills[user][hash] ||
            ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == user
        );
    }
}
```