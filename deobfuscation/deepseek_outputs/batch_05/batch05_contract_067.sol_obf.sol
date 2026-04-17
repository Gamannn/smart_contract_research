pragma solidity ^0.4.26;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IKyberNetwork {
    function getExpectedRate(IERC20 src, IERC20 dest, uint srcQty) external view returns (uint expectedRate, uint slippageRate);
    function trade(IERC20 src, uint srcAmount, IERC20 dest, address destAddress, uint maxDestAmount, uint minConversionRate, address walletId, bytes calldata hint) external payable returns (uint);
    function swapTokenToToken(IERC20 token, uint srcAmount, IERC20 destToken, uint minConversionRate) external returns (uint);
    function swapEtherToToken(IERC20 token, uint minConversionRate) external payable returns (uint);
}

interface IExchangeHelper {
    function getExchangeRate(string calldata src, string calldata dest, string calldata exchange, uint srcAmount) external view returns (uint);
    function getTokenAddress(string calldata symbol) external view returns (address);
    function getTokenSymbol(address token) external view returns (string memory);
    function getTokenDecimals(string calldata symbol) external view returns (uint);
}

contract DeobfuscatedContract {
    IERC20 constant internal ETH_TOKEN = IERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
    IKyberNetwork public kyberNetwork = IKyberNetwork(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);
    IExchangeHelper exchangeHelper = IExchangeHelper(0x8316b0826);
    
    address public daiAddress = 0x89d24a6b4ccb1b6faa2625fe562bd;
    address public owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function swapEtherToToken(IERC20 token, uint minRate) internal returns (uint) {
        uint amountBought = kyberNetwork.swapEtherToToken.value(msg.value)(token, minRate);
        require(token.transfer(msg.sender, amountBought));
        return amountBought;
    }
    
    function swapTokenToEther(IKyberNetwork kyber, IERC20 token, uint srcAmount, address recipient) internal returns (uint) {
        uint minRate = 1;
        token.transferFrom(msg.sender, address(this), srcAmount);
        token.approve(address(kyber), 0);
        token.approve(address(kyber), srcAmount);
        uint amountBought = kyber.trade(
            token,
            srcAmount,
            ETH_TOKEN,
            address(this),
            8000000000000000000000000000000000000000000000000000000000000000,
            0,
            0x0000000000000000000000000000,
            ""
        );
        return amountBought;
    }
    
    function executeTrade(address tokenAddress, address exchangeAddress, uint amount) public payable returns (bool) {
        address exchange = exchangeAddress;
        IERC20 token = IERC20(tokenAddress);
        uint etherAmount = swapTokenToEther(kyberNetwork, token, amount, msg.sender);
        (bool success, ) = exchange.call.value(etherAmount)(abi.encodeWithSignature("swap(uint256,uint256)", 1, block.timestamp));
        return success;
    }
    
    function() external payable {}
    
    function withdraw() public onlyOwner {
        msg.sender.transfer(address(this).balance);
        IERC20 token = IERC20(daiAddress);
        uint balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }
    
    function getBuyRate() public view returns (uint256) {
        uint256 rate = exchangeHelper.getExchangeRate("ETH", "SAI", "BUY-KYBER-EXCHANGE", 1000000000000000000);
        return rate;
    }
    
    function getSellRate() public view returns (uint256) {
        uint256 rate = exchangeHelper.getExchangeRate("ETH", "SAI", "SELL-UNISWAP-EXCHANGE", 1000000000000000000);
        return rate;
    }
}