```solidity
pragma solidity ^0.4.26;

contract TokenInterface {
    function getTokenAddress() external view returns (address);
    function getExchangeAddress() external view returns (address);
    function trade(uint256 srcAmount, uint256 destAmount, uint256 maxDestAmount) external payable returns (uint256);
    function tradeWithHint(uint256 srcAmount, uint256 destAmount, uint256 maxDestAmount, uint256 minConversionRate) external returns (uint256, uint256);
    function getExpectedRate(uint256 srcAmount) external view returns (uint256 expectedRate);
    function getRate(uint256 expectedRate) external view returns (uint256 rate);
    function getBalance(uint256 balance) external view returns (uint256);
    function getBalanceOf(uint256 balance) external view returns (uint256);
    function swap(uint256 srcAmount, uint256 destAmount) external payable returns (uint256);
    function swapWithHint(uint256 srcAmount, uint256 destAmount, address hint) external payable returns (uint256);
    function swapToken(uint256 srcAmount, uint256 destAmount) external payable returns (uint256);
    function swapTokenWithHint(uint256 srcAmount, uint256 destAmount, address hint) external payable returns (uint256);
    function convert(uint256 srcAmount, uint256 destAmount, uint256 maxDestAmount) external returns (uint256);
    function convertWithHint(uint256 srcAmount, uint256 destAmount, uint256 maxDestAmount, address hint) external returns (uint256);
    function convertToken(uint256 srcAmount, uint256 destAmount, uint256 maxDestAmount) external returns (uint256);
    function convertTokenWithHint(uint256 srcAmount, uint256 destAmount, uint256 maxDestAmount, address hint) external returns (uint256);
    function execute(uint256 srcAmount, uint256 destAmount, uint256 maxDestAmount, uint256 minConversionRate, address destAddress) external returns (uint256);
    function executeWithHint(uint256 srcAmount, uint256 destAmount, uint256 maxDestAmount, uint256 minConversionRate, address hint, address destAddress) external returns (uint256);
    function executeToken(uint256 srcAmount, uint256 destAmount, uint256 maxDestAmount, uint256 minConversionRate, address destAddress) external returns (uint256);
    function executeTokenWithHint(uint256 srcAmount, uint256 destAmount, uint256 maxDestAmount, uint256 minConversionRate, address hint, address destAddress) external returns (uint256);
    bytes32 public tokenSymbol;
    bytes32 public exchangeSymbol;
    uint256 public tokenDecimals;
    function approve(address spender, address token, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function getExchangeRate(address token) external;
}

interface ExchangeInterface {
    function totalSupply() public view returns (uint);
    function balanceOf(address owner) public view returns (uint);
    function approve(address spender, uint amount) public returns (bool);
    function transfer(address to, uint amount) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint);
    function decimals() public view returns (uint);
    event Approval(address indexed owner, address indexed spender, uint amount);
}

interface KyberNetworkInterface {
    function getExpectedRate() public view returns (uint);
    function getBalance(address owner) public view returns (uint);
    function getAllowance(address spender, uint amount) public returns (bool);
    function approve(address spender, uint amount) public returns (bool);
    function transfer(address to, uint amount) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint);
    function decimals() public view returns (uint);
    event Approval(address indexed owner, address indexed spender, uint amount);
}

interface UniswapExchangeInterface {
    function getExchangeRate(string srcToken, string destToken, string tradeType, uint256 amount) external view returns (uint256);
    function getBalance(address owner) external view returns (uint256);
    function getAddress(string symbol) external view returns (address);
    function getSymbol(string symbol) external view returns (bytes32);
    function getTokenAddress(string symbol) external view returns (address);
}

contract TokenSwap {
    ExchangeInterface constant internal ETH_TOKEN_ADDRESS = ExchangeInterface(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
    KyberNetworkInterface public kyberNetwork = KyberNetworkInterface(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);
    UniswapExchangeInterface uniswapExchange = UniswapExchangeInterface(0x8316b0826);
    address public daiAddress = 0x89d24a6b4ccb1b6faa2625fe562bd;
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function swapTokens(address srcToken, address destToken, uint256 srcAmount) external returns (bool) {
        address exchangeAddress = destToken;
        TokenInterface tokenInterface = TokenInterface(exchangeAddress);
        ExchangeInterface srcTokenInterface = ExchangeInterface(srcToken);
        uint256 expectedRate = getExpectedRate(kyberNetwork, srcTokenInterface, srcAmount, msg.sender);
        tokenInterface.swap(expectedRate, 1, block.timestamp);
        return true;
    }

    function getExpectedRate(KyberNetworkInterface kyberNetwork, ExchangeInterface srcTokenInterface, uint256 srcAmount, address sender) internal returns (uint256) {
        uint256 minConversionRate = 1;
        srcTokenInterface.approve(this, srcAmount);
        srcTokenInterface.transfer(kyberNetwork, 0);
        srcTokenInterface.transfer(address(kyberNetwork), srcAmount);
        uint256 expectedRate = kyberNetwork.getExpectedRate(ETH_TOKEN_ADDRESS, srcAmount, ETH_TOKEN_ADDRESS, this, 8000000000000000000000000000000000000000000000000000000000000000, 0, 0x0000000000000000000000000000);
        return expectedRate;
    }

    function () external payable {}

    function withdraw() external {
        msg.sender.transfer(address(this).balance);
        ExchangeInterface token = ExchangeInterface(daiAddress);
        uint256 balance = token.balanceOf(this);
        token.transfer(msg.sender, balance);
    }

    function getExchangeRate() constant returns (uint256) {
        uint256 rate = uniswapExchange.getExchangeRate("ETH", "SAI", "BUY-KYBER-EXCHANGE", 1000000000000000000);
        return rate;
    }

    function getExchangeRateWithHint() constant returns (uint256) {
        uint256 rate = uniswapExchange.getExchangeRate("ETH", "SAI", "BUY-KYBER-EXCHANGE", 1000000000000000000);
        return rate;
    }
}
```