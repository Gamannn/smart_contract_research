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

interface ERC20 {
    function totalSupply() external returns (uint);
    function balanceOf(address who) external returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
    function allowance(address owner, address spender) external returns (uint);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    function name() external returns (string memory);
    function symbol() external returns (string memory);
}

contract DEX {
    using SafeMath for uint;
    
    address public admin;
    address public feeAccount;
    
    mapping(address => uint) public tokenFeeWithdraw;
    mapping(address => uint) public tokenFeeDeposit;
    mapping(address => uint) public tokenFeeTrade;
    mapping(address => mapping(address => uint)) public tokens;
    mapping(address => mapping(bytes32 => bool)) public orders;
    mapping(address => mapping(bytes32 => uint)) public orderFills;
    mapping(address => bool) public activeTokens;
    mapping(address => uint) public tokenMinAmount;
    mapping(address => uint) public tokenMaxAmount;
    
    event Order(
        address tokenGet,
        uint amountGet,
        address tokenGive,
        uint amountGive,
        uint expires,
        uint nonce,
        address user
    );
    
    event Cancel(
        address tokenGet,
        uint amountGet,
        address tokenGive,
        uint amountGive,
        uint expires,
        uint nonce,
        address user,
        uint8 v,
        bytes32 r,
        bytes32 s
    );
    
    event Trade(
        address tokenGet,
        uint amountGet,
        address tokenGive,
        uint amountGive,
        address get,
        address give
    );
    
    event Deposit(
        address token,
        address user,
        uint amount,
        uint balance
    );
    
    event Withdraw(
        address token,
        address user,
        uint amount,
        uint balance
    );
    
    event ActivateToken(
        address admin,
        string symbol
    );
    
    event DeactivateToken(
        address admin,
        string symbol
    );
    
    constructor(address _admin, address _feeAccount) public {
        admin = _admin;
        feeAccount = _feeAccount;
    }
    
    function changeAdmin(address _admin) public {
        require(msg.sender == admin);
        admin = _admin;
    }
    
    function changeFeeAccount(address _feeAccount) public {
        require(msg.sender == admin);
        feeAccount = _feeAccount;
    }
    
    function deposit() public payable {
        uint fee = msg.value.mul(tokenFeeDeposit[address(0)]) / (1 ether);
        uint amount = msg.value.sub(fee);
        
        tokens[address(0)][msg.sender] = tokens[address(0)][msg.sender].add(amount);
        tokens[address(0)][feeAccount] = tokens[address(0)][feeAccount].add(fee);
        
        emit Deposit(address(0), msg.sender, msg.value, tokens[address(0)][msg.sender]);
    }
    
    function withdraw(uint amount) public {
        require(tokens[address(0)][msg.sender] >= amount);
        
        uint fee = amount.mul(tokenFeeWithdraw[address(0)]) / (1 ether);
        uint withdrawAmount = amount.sub(fee);
        
        tokens[address(0)][msg.sender] = tokens[address(0)][msg.sender].sub(amount);
        tokens[address(0)][feeAccount] = tokens[address(0)][feeAccount].add(fee);
        
        msg.sender.transfer(withdrawAmount);
        
        emit Withdraw(address(0), msg.sender, amount, tokens[address(0)][msg.sender]);
    }
    
    function depositToken(address token, uint amount) public {
        require(token != address(0));
        require(isActive(token));
        require(ERC20(token).transferFrom(msg.sender, address(this), amount));
        
        uint fee = amount.mul(tokenFeeDeposit[token]) / (1 ether);
        uint depositAmount = amount.sub(fee);
        
        tokens[token][msg.sender] = tokens[token][msg.sender].add(depositAmount);
        tokens[token][feeAccount] = tokens[token][feeAccount].add(fee);
        
        emit Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
    }
    
    function withdrawToken(address token, uint amount) public {
        require(token != address(0));
        require(tokens[token][msg.sender] >= amount);
        
        uint fee = amount.mul(tokenFeeWithdraw[token]) / (1 ether);
        uint withdrawAmount = amount.sub(fee);
        
        tokens[token][msg.sender] = tokens[token][msg.sender].sub(amount);
        tokens[token][feeAccount] = tokens[token][feeAccount].add(fee);
        
        require(ERC20(token).transfer(msg.sender, withdrawAmount));
        
        emit Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
    }
    
    function balanceOf(address token, address user) public view returns (uint) {
        return tokens[token][user];
    }
    
    function order(
        address tokenGet,
        uint amountGet,
        address tokenGive,
        uint amountGive,
        uint expires,
        uint nonce
    ) public {
        require(isActive(tokenGet) && isActive(tokenGive));
        require(amountGet >= tokenMinAmount[tokenGet]);
        require(amountGive >= tokenMinAmount[tokenGive]);
        
        bytes32 hash = sha256(abi.encodePacked(
            address(this),
            tokenGet,
            amountGet,
            tokenGive,
            amountGive,
            expires,
            nonce
        ));
        
        orders[msg.sender][hash] = true;
        
        emit Order(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender);
    }
    
    function trade(
        address tokenGet,
        uint amountGet,
        address tokenGive,
        uint amountGive,
        uint expires,
        uint nonce,
        address user,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint amount
    ) public {
        require(isActive(tokenGet) && isActive(tokenGive));
        
        bytes32 hash = sha256(abi.encodePacked(
            address(this),
            tokenGet,
            amountGet,
            tokenGive,
            amountGive,
            expires,
            nonce
        ));
        
        require(
            (orders[user][hash] || ecrecover(
                keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),
                v, r, s
            ) == user) &&
            block.number <= expires &&
            orderFills[user][hash].add(amount) <= amountGet
        );
        
        tradeBalances(tokenGet, amountGet, tokenGive, amountGive, user, amount);
        orderFills[user][hash] = orderFills[user][hash].add(amount);
        
        emit Trade(
            tokenGet,
            amount,
            tokenGive,
            amountGive.mul(amount).div(amountGet),
            user,
            msg.sender
        );
    }
    
    function tradeBalances(
        address tokenGet,
        uint amountGet,
        address tokenGive,
        uint amountGive,
        address user,
        uint amount
    ) private {
        uint feeMake = amount.mul(tokenFeeTrade[tokenGet]) / (1 ether);
        uint feeTake = amount.mul(tokenFeeTrade[tokenGet]) / (1 ether);
        
        tokens[tokenGet][msg.sender] = tokens[tokenGet][msg.sender].sub(amount.add(feeTake));
        tokens[tokenGet][user] = tokens[tokenGet][user].add(amount.sub(feeMake));
        tokens[tokenGet][feeAccount] = tokens[tokenGet][feeAccount].add(feeMake.add(feeTake));
        
        tokens[tokenGive][user] = tokens[tokenGive][user].sub(
            amountGive.mul(amount).div(amountGet)
        );
        tokens[tokenGive][msg.sender] = tokens[tokenGive][msg.sender].add(
            amountGive.mul(amount).div(amountGet)
        );
    }
    
    function testTrade(
        address tokenGet,
        uint amountGet,
        address tokenGive,
        uint amountGive,
        uint expires,
        uint nonce,
        address user,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint amount,
        address sender
    ) public view returns(bool) {
        if (!isActive(tokenGet) || !isActive(tokenGive)) return false;
        
        if (!(
            tokens[tokenGet][sender] >= amount &&
            availableVolume(
                tokenGet,
                amountGet,
                tokenGive,
                amountGive,
                expires,
                nonce,
                user,
                v, r, s
            ) >= amount
        )) return false;
        
        return true;
    }
    
    function availableVolume(
        address tokenGet,
        uint amountGet,
        address tokenGive,
        uint amountGive,
        uint expires,
        uint nonce,
        address user,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns(uint) {
        bytes32 hash = sha256(abi.encodePacked(
            address(this),
            tokenGet,
            amountGet,
            tokenGive,
            amountGive,
            expires,
            nonce
        ));
        
        if (!(
            (orders[user][hash] || ecrecover(
                keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),
                v, r, s
            ) == user) &&
            block.number <= expires
        )) return 0;
        
        return calculateVolume(amountGet, tokenGive, amountGive, user, hash);
    }
    
    function calculateVolume(
        uint amountGet,
        address tokenGive,
        uint amountGive,
        address user,
        bytes32 hash
    ) private view returns(uint) {
        uint available1 = amountGet.sub(orderFills[user][hash]);
        uint available2 = tokens[tokenGive][user].mul(amountGet).div(amountGive);
        
        if (available1 < available2) return available1;
        return available2;
    }
    
    function amountFilled(
        address tokenGet,
        uint amountGet,
        address tokenGive,
        uint amountGive,
        uint expires,
        uint nonce,
        address user
    ) public view returns(uint) {
        bytes32 hash = sha256(abi.encodePacked(
            address(this),
            tokenGet,
            amountGet,
            tokenGive,
            amountGive,
            expires,
            nonce
        ));
        
        return orderFills[user][hash];
    }
    
    function cancelOrder(
        address tokenGet,
        uint amountGet,
        address tokenGive,
        uint amountGive,
        uint expires,
        uint nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        bytes32 hash = sha256(abi.encodePacked(
            address(this),
            tokenGet,
            amountGet,
            tokenGive,
            amountGive,
            expires,
            nonce
        ));
        
        require(
            orders[msg.sender][hash] ||
            ecrecover(
                keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),
                v, r, s
            ) == msg.sender
        );
        
        orderFills[msg.sender][hash] = amountGet;
        
        emit Cancel(
            tokenGet,
            amountGet,
            tokenGive,
            amountGive,
            expires,
            nonce,
            msg.sender,
            v, r, s
        );
    }
    
    function activateToken(address token) public {
        require(msg.sender == admin);
        activeTokens[token] = true;
        emit ActivateToken(token, ERC20(token).symbol());
    }
    
    function deactivateToken(address token) public {
        require(msg.sender == admin);
        activeTokens[token] = false;
        emit DeactivateToken(token, ERC20(token).symbol());
    }
    
    function isActive(address token) public view returns(bool) {
        if (token == address(0)) return true; // ETH is always active
        return activeTokens[token];
    }
    
    function setTokenMinAmount(address token, uint amount) public {
        require(msg.sender == admin);
        tokenMinAmount[token] = amount;
    }
    
    function setTokenMaxAmount(address token, uint amount) public {
        require(msg.sender == admin);
        tokenMaxAmount[token] = amount;
    }
    
    function setTokenFeeTrade(address token, uint fee) public {
        require(msg.sender == admin);
        tokenFeeTrade[token] = fee;
    }
    
    function setTokenFeeWithdraw(address token, uint fee) public {
        require(msg.sender == admin);
        tokenFeeWithdraw[token] = fee;
    }
    
    function setTokenFeeDeposit(address token, uint fee) public {
        require(msg.sender == admin);
        tokenFeeDeposit[token] = fee;
    }
}
```