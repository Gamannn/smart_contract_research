```solidity
pragma solidity ^0.4.18;

interface Token {
    function balanceOf(address owner) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function approve(address spender, uint256 value) public returns (bool);
}

interface FeeCalculator {
    function getFee(address user) public constant returns (uint);
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

contract Exchange {
    using SafeMath for uint256;

    mapping(address => mapping(address => uint256)) public balances;
    mapping(address => bool) public tokenWhitelist;
    mapping(address => bool) public userWhitelist;
    mapping(address => mapping(bytes32 => bool)) public orderConfirmed;
    mapping(address => mapping(bytes32 => uint256)) public orderFills;

    event Order(
        address tokenGive,
        uint256 amountGive,
        address tokenGet,
        uint256 amountGet,
        uint256 expires,
        uint256 nonce,
        address user
    );

    event Cancel(
        address tokenGive,
        uint256 amountGive,
        address tokenGet,
        uint256 amountGet,
        uint256 expires,
        uint256 nonce,
        address user,
        uint8 v,
        bytes32 r,
        bytes32 s
    );

    event Trade(
        address tokenGive,
        uint256 amountGive,
        address tokenGet,
        uint256 amountGet,
        address get,
        address give
    );

    event Deposit(
        address token,
        address user,
        uint256 amount,
        uint256 balance
    );

    event Withdraw(
        address token,
        address user,
        uint256 amount,
        uint256 balance
    );

    struct ExchangeConfig {
        uint256 feeRebate;
        uint256 feeTake;
        uint256 feeMake;
        address feeCalculator;
        address feeAccount;
        address admin;
    }

    ExchangeConfig config = ExchangeConfig(0, 0, 0, address(0), address(0), address(0));

    function Exchange(
        address admin,
        address feeAccount,
        address feeCalculator,
        uint256 feeMake,
        uint256 feeTake,
        uint256 feeRebate
    ) public {
        require(admin != 0x0);
        config.admin = admin;
        config.feeAccount = feeAccount;
        config.feeCalculator = feeCalculator;
        config.feeMake = feeMake;
        config.feeTake = feeTake;
        config.feeRebate = feeRebate;
        tokenWhitelist[0x0] = true;
    }

    modifier onlyAdmin() {
        require(msg.sender == config.admin);
        _;
    }

    function() public payable {
        revert();
    }

    function changeAdmin(address admin) public onlyAdmin {
        require(admin != 0x0 && config.admin != admin);
        config.admin = admin;
    }

    function changeFeeCalculator(address feeCalculator) public onlyAdmin {
        config.feeCalculator = feeCalculator;
    }

    function changeFeeAccount(address feeAccount) public onlyAdmin {
        require(feeAccount != 0x0);
        config.feeAccount = feeAccount;
    }

    function changeFeeMake(uint256 feeMake) public onlyAdmin {
        config.feeMake = feeMake;
    }

    function changeFeeTake(uint256 feeTake) public onlyAdmin {
        require(feeTake >= config.feeRebate);
        config.feeTake = feeTake;
    }

    function changeFeeRebate(uint256 feeRebate) public onlyAdmin {
        require(feeRebate <= config.feeTake);
        config.feeRebate = feeRebate;
    }

    function addToken(address token) public onlyAdmin {
        require(token != 0x0 && !tokenWhitelist[token]);
        tokenWhitelist[token] = true;
    }

    function removeToken(address token) public onlyAdmin {
        require(token != 0x0 && tokenWhitelist[token]);
        tokenWhitelist[token] = false;
    }

    function addUser(address user) public onlyAdmin {
        require(user != 0x0 && !userWhitelist[user]);
        userWhitelist[user] = true;
    }

    function removeUser(address user) public onlyAdmin {
        require(user != 0x0 && userWhitelist[user]);
        userWhitelist[user] = false;
    }

    function depositEther() public payable {
        require(userWhitelist[msg.sender]);
        balances[0x0][msg.sender] = balances[0x0][msg.sender].add(msg.value);
        Deposit(0x0, msg.sender, msg.value, balances[0x0][msg.sender]);
    }

    function withdrawEther(uint256 amount) public {
        require(balances[0x0][msg.sender] >= amount);
        balances[0x0][msg.sender] = balances[0x0][msg.sender].sub(amount);
        msg.sender.transfer(amount);
        Withdraw(0x0, msg.sender, amount, balances[0x0][msg.sender]);
    }

    function depositToken(address token, uint256 amount) public {
        require(token != 0x0 && tokenWhitelist[token]);
        require(userWhitelist[msg.sender]);
        balances[token][msg.sender] = balances[token][msg.sender].add(amount);
        require(Token(token).transferFrom(msg.sender, address(this), amount));
        Deposit(token, msg.sender, amount, balances[token][msg.sender]);
    }

    function withdrawToken(address token, uint256 amount) public {
        require(token != 0x0);
        require(balances[token][msg.sender] >= amount);
        balances[token][msg.sender] = balances[token][msg.sender].sub(amount);
        require(Token(token).transfer(msg.sender, amount));
        Withdraw(token, msg.sender, amount, balances[token][msg.sender]);
    }

    function balanceOf(address token, address user) public constant returns (uint256) {
        return balances[token][user];
    }

    function order(
        address tokenGive,
        uint256 amountGive,
        address tokenGet,
        uint256 amountGet,
        uint256 expires,
        uint256 nonce
    ) public {
        require(userWhitelist[msg.sender]);
        require(tokenWhitelist[tokenGive] && tokenWhitelist[tokenGet]);
        bytes32 hash = keccak256(address(this), tokenGive, amountGive, tokenGet, amountGet, expires, nonce);
        orderConfirmed[msg.sender][hash] = true;
        Order(tokenGive, amountGive, tokenGet, amountGet, expires, nonce, msg.sender);
    }

    function cancelOrder(
        address tokenGive,
        uint256 amountGive,
        address tokenGet,
        uint256 amountGet,
        uint256 expires,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        bytes32 hash = keccak256(address(this), tokenGive, amountGive, tokenGet, amountGet, expires, nonce);
        require(validateOrder(hash, msg.sender, v, r, s));
        orderFills[msg.sender][hash] = amountGive;
        Cancel(tokenGive, amountGive, tokenGet, amountGet, expires, nonce, msg.sender, v, r, s);
    }

    function trade(
        address tokenGive,
        uint256 amountGive,
        address tokenGet,
        uint256 amountGet,
        uint256 expires,
        uint256 nonce,
        address user,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 amount
    ) public {
        require(userWhitelist[msg.sender]);
        require(tokenWhitelist[tokenGive] && tokenWhitelist[tokenGet]);
        require(block.number <= expires);
        bytes32 hash = keccak256(address(this), tokenGive, amountGive, tokenGet, amountGet, expires, nonce);
        require(validateOrder(hash, user, v, r, s));
        require(orderFills[user][hash].add(amount) <= amountGive);
        orderFills[user][hash] = orderFills[user][hash].add(amount);
        tradeBalances(tokenGive, amountGive, tokenGet, amountGet, user, amount);
        Trade(
            tokenGive,
            amount,
            tokenGet,
            amountGet.mul(amount).div(amountGive),
            user,
            msg.sender
        );
    }

    function testTrade(
        address tokenGive,
        uint256 amountGive,
        address tokenGet,
        uint256 amountGet,
        uint256 expires,
        uint256 nonce,
        address user,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 amount,
        address sender
    ) public constant returns(bool) {
        require(userWhitelist[user] && userWhitelist[sender]);
        require(tokenWhitelist[tokenGive] && tokenWhitelist[tokenGet]);
        require(balances[tokenGive][sender] >= amount);
        return availableVolume(
            tokenGive,
            amountGive,
            tokenGet,
            amountGet,
            expires,
            nonce,
            user,
            v,
            r,
            s
        ) >= amount;
    }

    function availableVolume(
        address tokenGive,
        uint256 amountGive,
        address tokenGet,
        uint256 amountGet,
        uint256 expires,
        uint256 nonce,
        address user,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public constant returns (uint256) {
        require(userWhitelist[user]);
        require(tokenWhitelist[tokenGive] && tokenWhitelist[tokenGet]);
        bytes32 hash = keccak256(address(this), tokenGive, amountGive, tokenGet, amountGet, expires, nonce);
        if (!(validateOrder(hash, user, v, r, s) && block.number <= expires)) {
            return 0;
        }
        if (amountGive.sub(orderFills[user][hash]) < balances[tokenGet][user].mul(amountGive).div(amountGet)) {
            return amountGive.sub(orderFills[user][hash]);
        }
        return balances[tokenGet][user].mul(amountGive).div(amountGet);
    }

    function amountFilled(
        address tokenGive,
        uint256 amountGive,
        address tokenGet,
        uint256 amountGet,
        uint256 expires,
        uint256 nonce,
        address user
    ) public constant returns (uint256) {
        require(userWhitelist[user]);
        require(tokenWhitelist[tokenGive] && tokenWhitelist[tokenGet]);
        return orderFills[user][keccak256(address(this), tokenGive, amountGive, tokenGet, amountGet, expires, nonce)];
    }

    function tradeBalances(
        address tokenGive,
        uint256 amountGive,
        address tokenGet,
        uint256 amountGet,
        address user,
        uint256 amount
    ) private {
        uint256 feeMakeXfer = amount.mul(config.feeMake).div(1 ether);
        uint256 feeTakeXfer = amount.mul(config.feeTake).div(1 ether);
        uint256 feeRebateXfer = 0;
        
        if (config.feeCalculator != 0x0) {
            uint256 feeClass = FeeCalculator(config.feeCalculator).getFee(user);
            if (feeClass == 1) {
                feeRebateXfer = amount.mul(config.feeRebate).div(1 ether);
            } else if (feeClass == 2) {
                feeRebateXfer = feeTakeXfer;
            }
        }

        balances[tokenGive][msg.sender] = balances[tokenGive][msg.sender].sub(amount.add(feeTakeXfer));
        balances[tokenGive][user] = balances[tokenGive][user].add(amount.add(feeRebateXfer).sub(feeMakeXfer));
        balances[tokenGive][config.feeAccount] = balances[tokenGive][config.feeAccount].add(feeMakeXfer.add(feeTakeXfer).sub(feeRebateXfer));
        
        balances[tokenGet][user] = balances[tokenGet][user].sub(amountGet.mul(amount).div(amountGive));
        balances[tokenGet][msg.sender] = balances[tokenGet][msg.sender].add(amountGet.mul(amount).div(amountGive));
    }

    function validateOrder(
        bytes32 hash,
        address user,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private constant returns (bool) {
        return (
            orderConfirmed[user][hash] ||
            ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == user
        );
    }
}
```