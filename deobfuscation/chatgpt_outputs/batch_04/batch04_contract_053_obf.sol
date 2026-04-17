pragma solidity ^0.4.15;

contract ExchangeContract {
    function deposit() payable;
    function withdraw(uint amount);
    function transferTo(address to, uint amount);
    function transferFrom(address from, uint amount);
    function balanceOf(address owner, address token) constant returns (uint);
    function trade(address maker, uint makerAmount, address taker, uint takerAmount, uint makerFee, uint takerFee);
    function cancelOrder(address maker, uint makerAmount, address taker, uint takerAmount, uint makerFee, uint takerFee, address feeRecipient, uint8 v, bytes32 r, bytes32 s, uint amount);
    function privateTrade(address maker, uint makerAmount, address taker, uint takerAmount, address feeRecipient, uint amount) private;
    function getOrderHash(address maker, uint makerAmount, address taker, uint takerAmount, uint makerFee, uint takerFee, address feeRecipient, uint8 v, bytes32 r, bytes32 s) constant returns(uint);
    function getTradeHash(address maker, uint makerAmount, address taker, uint takerAmount, uint makerFee, uint takerFee, address feeRecipient, uint8 v, bytes32 r, bytes32 s) constant returns(uint);
    function getCancelHash(address maker, uint makerAmount, address taker, uint takerAmount, uint makerFee, uint takerFee, uint8 v, bytes32 r, bytes32 s);
}

contract TokenContract {
    function totalSupply() constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    function balanceOf(address owner, address token) constant returns (uint256);
    function allowance(address owner) constant returns (uint256);
    function approve(address spender, uint256 value) returns (bool);
    function transferFrom(address from, address to, uint256 value) returns (bool);
}

contract TradingPlatform {
    address public owner;
    address public ethDeltaDepositAddress;
    ExchangeContract public exchangeContract;

    function TradingPlatform() {
        owner = msg.sender;
        ethDeltaDepositAddress = 0x8d12A197cB00D4747a1fe03395095ce2A5CC6819;
        exchangeContract = ExchangeContract(0xfc0bfd4ff4b97a1054fceeacbf12602dc4575c10);
    }

    function() payable {}

    function getBalance(address tokenAddress) constant returns (uint) {
        TokenContract token = TokenContract(tokenAddress);
        return token.balanceOf(this);
    }

    function transferTokens(address tokenAddress, address from, address to, uint256 amount) external {
        require(msg.sender == owner);
        TokenContract token = TokenContract(tokenAddress);
        token.transferFrom(from, to, amount);
    }

    function updateOwner(address newOwner) external {
        require(msg.sender == owner);
        owner = newOwner;
    }

    function withdrawEther(uint amount) external {
        require(msg.sender == owner);
        owner.transfer(amount);
    }

    function executeTrade(address tokenAddress, uint amount, bytes data) external returns (bytes32) {
        require(msg.sender == owner);
        require(tokenAddress.call.value(amount)(data));
        return 0;
    }

    function getExchangeBalance(address tokenAddress) constant returns (uint) {
        return exchangeContract.balanceOf(tokenAddress, this);
    }

    function depositToExchange(address tokenAddress, uint amount) payable external {
        require(msg.sender == owner);
        exchangeContract.deposit.value(amount)();
    }

    function withdrawFromExchange(uint amount) external {
        require(msg.sender == owner);
        exchangeContract.withdraw(amount);
    }

    function kill() {
        require(msg.sender == owner);
        selfdestruct(msg.sender);
    }
}