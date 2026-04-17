```solidity
pragma solidity >=0.4.26;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IKyberNetwork {
    function getExpectedRate(IERC20 src, IERC20 dest, uint256 srcQty) external view returns (uint256 expectedRate, uint256 slippageRate);
    function tradeWithHint(
        IERC20 src,
        uint256 srcAmount,
        IERC20 dest,
        address destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address walletId,
        bytes calldata hint
    ) external payable returns (uint256);
    function swapTokenToToken(IERC20 src, uint256 srcAmount, IERC20 dest, uint256 minConversionRate) external returns (uint256);
    function swapEtherToToken(IERC20 token, uint256 minConversionRate) external payable returns (uint256);
    function maxGasPrice() external view returns (uint256);
    function enabled() external view returns (bool);
    function info(bytes32 id) external view returns (uint256);
}

interface IUniswapExchange {
    function getEthToTokenInputPrice(uint256 ethSold) external view returns (uint256 tokensBought);
    function getEthToTokenOutputPrice(uint256 tokensBought) external view returns (uint256 ethSold);
    function getTokenToEthInputPrice(uint256 tokensSold) external view returns (uint256 ethBought);
    function getTokenToEthOutputPrice(uint256 ethBought) external view returns (uint256 tokensSold);
    function ethToTokenSwapInput(uint256 minTokens, uint256 deadline) external payable returns (uint256 tokensBought);
    function ethToTokenTransferInput(uint256 minTokens, uint256 deadline, address recipient) external payable returns (uint256 tokensBought);
    function ethToTokenSwapOutput(uint256 tokensBought, uint256 deadline) external payable returns (uint256 ethSold);
    function ethToTokenTransferOutput(uint256 tokensBought, uint256 deadline, address recipient) external payable returns (uint256 ethSold);
    function tokenToEthSwapInput(uint256 tokensSold, uint256 minEth, uint256 deadline) external returns (uint256 ethBought);
    function tokenToEthTransferInput(uint256 tokensSold, uint256 minEth, uint256 deadline, address recipient) external returns (uint256 ethBought);
    function tokenToEthSwapOutput(uint256 ethBought, uint256 maxTokens, uint256 deadline) external returns (uint256 tokensSold);
    function tokenToEthTransferOutput(uint256 ethBought, uint256 maxTokens, uint256 deadline, address recipient) external returns (uint256 tokensSold);
    function tokenToTokenSwapInput(uint256 tokensSold, uint256 minTokensBought, uint256 minEthBought, uint256 deadline, address tokenAddr) external returns (uint256 tokensBought);
    function tokenToTokenTransferInput(uint256 tokensSold, uint256 minTokensBought, uint256 minEthBought, uint256 deadline, address recipient, address tokenAddr) external returns (uint256 tokensBought);
    function tokenToTokenSwapOutput(uint256 tokensBought, uint256 maxTokensSold, uint256 maxEthSold, uint256 deadline, address tokenAddr) external returns (uint256 tokensSold);
    function tokenToTokenTransferOutput(uint256 tokensBought, uint256 maxTokensSold, uint256 maxEthSold, uint256 deadline, address recipient, address tokenAddr) external returns (uint256 tokensSold);
    function tokenToExchangeSwapInput(uint256 tokensSold, uint256 minTokensBought, uint256 minEthBought, uint256 deadline, address exchangeAddr) external returns (uint256 tokensBought);
    function tokenToExchangeTransferInput(uint256 tokensSold, uint256 minTokensBought, uint256 minEthBought, uint256 deadline, address recipient, address exchangeAddr) external returns (uint256 tokensBought);
    function tokenToExchangeSwapOutput(uint256 tokensBought, uint256 maxTokensSold, uint256 maxEthSold, uint256 deadline, address exchangeAddr) external returns (uint256 tokensSold);
    function tokenToExchangeTransferOutput(uint256 tokensBought, uint256 maxTokensSold, uint256 maxEthSold, uint256 deadline, address recipient, address exchangeAddr) external returns (uint256 tokensSold);
    function factoryAddress() external view returns (address);
    function tokenAddress() external view returns (address);
    function tokenToTokenInputPrice(uint256 tokensSold, uint256 minTokensBought, uint256 minEthBought, uint256 deadline, address tokenAddr) external view returns (uint256);
    function tokenToTokenOutputPrice(uint256 tokensBought, uint256 maxTokensSold, uint256 maxEthSold, uint256 deadline, address tokenAddr) external view returns (uint256);
    function tokenToExchangeInputPrice(uint256 tokensSold, uint256 minTokensBought, uint256 minEthBought, uint256 deadline, address exchangeAddr) external view returns (uint256);
    function tokenToExchangeOutputPrice(uint256 tokensBought, uint256 maxTokensSold, uint256 maxEthSold, uint256 deadline, address exchangeAddr) external view returns (uint256);
}

interface IUniswapFactory {
    function getExchange(address token) external view returns (address exchange);
    function getToken(address exchange) external view returns (address token);
    function getTokenWithId(uint256 tokenId) external view returns (address token);
    function initializeFactory(address template) external;
}

contract TradingContract {
    IERC20 constant internal ETH_TOKEN_ADDRESS = IERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
    IKyberNetwork public kyberNetwork = IKyberNetwork(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);
    IUniswapFactory public uniswapFactory = IUniswapFactory(0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95);
    
    address public owner;
    address public batTokenAddress = 0x0D8775F648430679A709E98d2b0Cb6250d2887EF;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function executeTrade(
        address tokenAddress,
        address exchangeAddress,
        uint256 amount
    ) public onlyOwner returns (bool) {
        IERC20 token = IERC20(tokenAddress);
        IUniswapExchange exchange = IUniswapExchange(exchangeAddress);
        
        uint256 receivedAmount = _swapViaKyber(kyberNetwork, token, amount, msg.sender);
        exchange.ethToTokenSwapInput(receivedAmount, 1, block.timestamp);
        
        return true;
    }
    
    function _swapViaKyber(
        IKyberNetwork kyber,
        IERC20 srcToken,
        uint256 srcAmount,
        address recipient
    ) internal returns (uint256) {
        uint256 minRate = 1;
        
        srcToken.transferFrom(msg.sender, address(this), srcAmount);
        srcToken.approve(address(kyber), 0);
        srcToken.approve(address(kyber), srcAmount);
        
        uint256 destAmount = kyber.tradeWithHint(
            srcToken,
            srcAmount,
            ETH_TOKEN_ADDRESS,
            address(this),
            8000000000000000000000000000000000000000000000000000000000000000,
            0,
            0x0000000000000000000000000000000000000004,
            ""
        );
        
        return destAmount;
    }
    
    function withdraw() public onlyOwner {
        msg.sender.transfer(address(this).balance);
        
        IERC20 token = IERC20(batTokenAddress);
        uint256 tokenBalance = token.balanceOf(address(this));
        token.transfer(msg.sender, tokenBalance);
    }
    
    function getKyberRate() public view returns (uint256) {
        uint256 rate = uniswapFactory.getExchange(batTokenAddress) != address(0) ? 
            uniswapFactory.getExchange(batTokenAddress).balance : 0;
        return rate;
    }
    
    function getUniswapRate() public view returns (uint256) {
        uint256 rate = uniswapFactory.getExchange(batTokenAddress) != address(0) ? 
            uniswapFactory.getExchange(batTokenAddress).balance : 0;
        return rate;
    }
    
    function() external payable {}
}
```