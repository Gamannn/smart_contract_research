```solidity
pragma solidity ^0.4.24;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IKyberNetworkProxy {
    function getExpectedRate(IERC20 src, IERC20 dest, uint srcQty) external view returns (uint expectedRate, uint slippageRate);
    function trade(IERC20 src, uint srcAmount, IERC20 dest, address destAddress, uint maxDestAmount, uint minConversionRate, address walletId) external payable returns (uint);
}

interface IBancorNetwork {
    function getReturnByPath(IERC20[] calldata path, uint256 amount) external view returns (uint256, uint256);
}

interface IBancorConverter {
    function getReturn(IERC20 fromToken, IERC20 toToken, uint256 amount) external view returns (uint256, uint256);
}

contract Arbitrage is IKyberNetworkProxy {
    uint constant public MIN_TRADING_AMOUNT = 0.0001 ether;
    
    IBancorConverter public bancorConverter;
    address public daiTokenAddress;
    address public bntTokenAddress;
    address public kyberNetworkProxyAddress;
    address public kyberEtherAddress;
    
    constructor() public {
        bancorConverter = IBancorConverter(0x188ccabc5c1ec9d3ccacbd155e3f6e19f36115c6);
        daiTokenAddress = 0xc0829421C1d260BD3cB3E0F06cfE2D52db2cE315;
        bntTokenAddress = 0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C;
        kyberNetworkProxyAddress = 0x818E6FECD516Ecc3849DAf6845e3EC868087B755;
        kyberEtherAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }
    
    function getExpectedRate(IERC20 src, IERC20 dest, uint srcQty) external view returns (uint expectedRate, uint slippageRate) {
        return IKyberNetworkProxy(kyberNetworkProxyAddress).getExpectedRate(src, dest, srcQty);
    }
    
    function getReturnByPath(IERC20[] calldata path, uint256 amount) external view returns (uint256, uint256) {
        return IBancorNetwork(kyberNetworkProxyAddress).getReturnByPath(path, amount);
    }
    
    function trade(IERC20 src, uint srcAmount, IERC20 dest, address destAddress, uint maxDestAmount, uint minConversionRate, address walletId) external payable returns (uint) {
        return IKyberNetworkProxy(kyberNetworkProxyAddress).trade(src, srcAmount, dest, destAddress, maxDestAmount, minConversionRate, walletId);
    }
    
    function getReturn(IERC20 fromToken, IERC20 toToken, uint256 amount) public view returns (uint256, uint256) {
        return bancorConverter.getReturn(fromToken, toToken, amount);
    }
    
    function() external payable {
        uint gasStart = gasleft();
        
        require(msg.value >= MIN_TRADING_AMOUNT, "Min trading amount not reached.");
        
        IERC20 daiToken = IERC20(daiTokenAddress);
        IERC20 bntToken = IERC20(bntTokenAddress);
        
        (uint kyberRate, ) = getExpectedRate(
            IERC20(kyberEtherAddress),
            daiToken,
            msg.value
        );
        
        (uint bancorRate, ) = getReturn(
            IERC20(bntTokenAddress),
            IERC20(daiTokenAddress),
            msg.value
        );
        
        uint kyberResult = kyberRate * msg.value;
        uint bancorResult = bancorRate + msg.value;
        uint profit = 0;
        
        if (kyberResult > bancorResult) {
            profit = kyberResult - bancorResult;
            emit Trade("buy", bancorResult, "bancor");
            emit Trade("sell", kyberResult, "kyber");
        } else {
            profit = bancorResult - kyberResult;
            emit Trade("buy", kyberResult, "kyber");
            emit Trade("sell", bancorResult, "bancor");
        }
    }
    
    event Trade(string action, uint256 amount, string exchange);
}
```