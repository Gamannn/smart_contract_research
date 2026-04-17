```solidity
pragma solidity ^0.4.15;

interface Token {
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    function transferFrom(address from, address to, uint256 value) returns (bool);
    function allowance(address owner, address spender) constant returns (uint256);
    function approve(address spender, uint256 value) returns (bool);
}

interface Exchange {
    function deposit() payable;
    function withdraw(uint amount);
    function depositToken(address token, uint amount);
    function withdrawToken(address token, uint amount);
    function balanceOf(address token, address user) constant returns (uint);
    function trade(
        address tokenGet,
        uint amountGet,
        address tokenGive,
        uint amountGive,
        uint expires,
        uint nonce
    );
    function order(
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
    );
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
        bytes32 s
    ) constant returns(uint);
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
    ) constant returns(uint);
    function amountFilled(
        address tokenGet,
        uint amountGet,
        address tokenGive,
        uint amountGive,
        uint expires,
        uint nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    );
}

contract DeltaBalances {
    address public owner;
    address public ethDeltaDepositAddress;
    Exchange public exchange;
    
    function DeltaBalances() {
        owner = msg.sender;
        ethDeltaDepositAddress = 0x8d12A197cB00D4747a1fe03395095ce2A5CC6819;
        exchange = Exchange(ethDeltaDepositAddress);
    }
    
    function() payable {}
    
    function getTokenBalance(address tokenAddress) constant returns (uint) {
        Token token = Token(tokenAddress);
        return token.balanceOf(this);
    }
    
    function transferTokenFrom(address tokenAddress, address from, address to, uint256 amount) external {
        require(msg.sender == owner);
        Token token = Token(tokenAddress);
        token.transferFrom(from, to, amount);
    }
    
    function changeOwner(address newOwner) external {
        require(msg.sender == owner);
        owner = newOwner;
    }
    
    function approveToken(address tokenAddress, address spender, uint256 amount) external {
        require(msg.sender == owner);
        Token token = Token(tokenAddress);
        token.approve(spender, amount);
    }
    
    function transferToken(address tokenAddress, address to, uint256 amount) external {
        require(msg.sender == owner);
        Token token = Token(tokenAddress);
        token.transfer(to, amount);
    }
    
    function callAddress(address target, uint value, bytes data) external returns (bytes32) {
        require(msg.sender == owner);
        require(target.call.value(value)(data));
        return 0;
    }
    
    function getExchangeBalance(address tokenAddress) constant returns (uint) {
        return exchange.balanceOf(tokenAddress, this);
    }
    
    function withdrawFromExchange(address tokenAddress, uint amount) payable external {
        require(msg.sender == owner);
        exchange.withdrawToken(tokenAddress, amount);
    }
    
    function changeExchange(address newExchangeAddress) external {
        require(msg.sender == owner);
        ethDeltaDepositAddress = newExchangeAddress;
        exchange = Exchange(newExchangeAddress);
    }
    
    function depositToExchange(address tokenAddress, uint amount) payable external {
        require(msg.sender == owner);
        exchange.depositToken(tokenAddress, amount);
    }
    
    function approveExchange(address tokenAddress, uint amount) payable external {
        require(msg.sender == owner);
        Token token = Token(tokenAddress);
        token.approve(ethDeltaDepositAddress, amount);
    }
    
    function depositEthToExchange(uint amount) payable external {
        require(msg.sender == owner);
        exchange.deposit.value(amount)();
    }
    
    function withdrawEthFromExchange(uint amount) external {
        require(msg.sender == owner);
        exchange.withdraw(amount);
    }
    
    function kill() {
        require(msg.sender == owner);
        selfdestruct(msg.sender);
    }
}
```