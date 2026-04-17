```solidity
pragma solidity >=0.4.24 <0.6.0;

contract Initializable {
    bool private _initializing;
    bool private _initialized;
    
    modifier initializer() {
        require(
            _initializing || 
            _isConstructor() || 
            !_initialized, 
            "Contract instance has already been initialized"
        );
        
        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }
        
        _;
        
        if (isTopLevelCall) {
            _initializing = false;
        }
    }
    
    function _isConstructor() private view returns (bool) {
        uint256 cs;
        assembly {
            cs := extcodesize(address)
        }
        return cs == 0;
    }
    
    uint256[50] private __gap;
}

pragma solidity ^0.5.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapFactory {
    function getExchange(address token) external view returns (address exchange);
}

interface IUniswapExchange {
    function getEthToTokenInputPrice(uint256 ethSold) external view returns (uint256 tokensBought);
    function getTokenToEthInputPrice(uint256 tokensSold) external view returns (uint256 ethBought);
    function ethToTokenSwapInput(uint256 minTokens, uint256 deadline) external payable returns (uint256 tokensBought);
    function ethToTokenTransferInput(uint256 minTokens, uint256 deadline, address recipient) external payable returns (uint256 tokensBought);
    function tokenToEthSwapInput(uint256 tokensSold, uint256 minEth, uint256 deadline) external returns (uint256 ethBought);
    function tokenToEthTransferInput(uint256 tokensSold, uint256 minEth, uint256 deadline, address recipient) external returns (uint256 ethBought);
    function tokenToTokenSwapInput(uint256 tokensSold, uint256 minTokensBought, uint256 minEthBought, uint256 deadline, address tokenAddr) external returns (uint256 tokensBought);
    function tokenToTokenTransferInput(uint256 tokensSold, uint256 minTokensBought, uint256 minEthBought, uint256 deadline, address recipient, address tokenAddr) external returns (uint256 tokensBought);
    function tokenToTokenSwapOutput(uint256 tokensBought, uint256 maxTokensSold, uint256 maxEthSold, uint256 deadline, address tokenAddr) external returns (uint256 tokensSold);
    function tokenToTokenTransferOutput(uint256 tokensBought, uint256 maxTokensSold, uint256 maxEthSold, uint256 deadline, address recipient, address tokenAddr) external returns (uint256 tokensSold);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function getTokenToEthInputPrice(uint256 tokensSold) external view returns (uint256);
    function getEthToTokenInputPrice(uint256 ethSold) external view returns (uint256);
    function tokenAddress() external view returns (address);
}

interface ICErc20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function mint(uint256 mintAmount) external returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOfUnderlying(address owner) external returns (uint256);
}

interface IOneSplit {
    function getExpectedReturn(
        address fromToken,
        address toToken,
        uint256 amount,
        uint256 parts,
        uint256 featureFlags
    ) external view returns (uint256 returnAmount, uint256[] memory distribution);
    
    function swap(
        address fromToken,
        address toToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata distribution,
        uint256 featureFlags
    ) external payable;
    
    function swapWithReferral(
        address fromToken,
        address toToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata distribution,
        uint256 featureFlags
    ) external payable;
}

contract UniSwap_Zap is Initializable {
    using SafeMath for uint256;
    
    bool private stopped;
    address payable public owner;
    IUniswapFactory public uniswapFactory;
    IOneSplit public oneSplit;
    IERC20 public DAI_TOKEN_ADDRESS;
    ICErc20 public COMPOUND_TOKEN_ADDRESS;
    address public ETH_TOKEN_ADDRESS;
    address public UNISWAP_EXCHANGE_CONTRACT_ADDRESS;
    address public ONE_SPLIT_ADDRESS;
    
    event ERC20TokenHoldingsOnConversionDaiChai(uint256);
    event ERC20TokenHoldingsOnConversionEthDai(uint256);
    event LiquidityTokens(uint256);
    
    modifier stopInEmergency {
        if (!stopped) _;
    }
    
    modifier onlyInEmergency {
        if (stopped) _;
    }
    
    modifier onlyOwner() {
        require(isOwner(), "you are not authorised to call this function");
        _;
    }
    
    function initialize() initializer public {
        stopped = false;
        owner = msg.sender;
        uniswapFactory = IUniswapFactory(0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95);
        DAI_TOKEN_ADDRESS = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        COMPOUND_TOKEN_ADDRESS = ICErc20(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
        oneSplit = IOneSplit(0xD010B65120E027419586216D25bF86C2c24FCC4a);
        ONE_SPLIT_ADDRESS = address(0xD010B65120E027419586216D25bF86C2c24FCC4a);
        ETH_TOKEN_ADDRESS = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        UNISWAP_EXCHANGE_CONTRACT_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    }
    
    function set_new_UniSwapFactoryAddress(address _new_UniSwapFactoryAddress) public onlyOwner {
        uniswapFactory = IUniswapFactory(_new_UniSwapFactoryAddress);
    }
    
    function set_new_DAI_TokenContractAddress(address _new_DAI_TokenContractAddress) public onlyOwner {
        DAI_TOKEN_ADDRESS = IERC20(_new_DAI_TokenContractAddress);
    }
    
    function set_new_COMPOUND_TokenContractAddress(address _new_COMPOUND_TokenContractAddress) public onlyOwner {
        COMPOUND_TOKEN_ADDRESS = ICErc20(_new_COMPOUND_TokenContractAddress);
    }
    
    function set_new_OneSplitAddress(address _new_OneSplitAddress) public onlyOwner {
        oneSplit = IOneSplit(_new_OneSplitAddress);
        ONE_SPLIT_ADDRESS = _new_OneSplitAddress;
    }
    
    function getExpectedReturn(uint256 amount) public view returns (uint256) {
        uint256 returnAmount;
        (returnAmount, ) = oneSplit.getExpectedReturn(
            UNISWAP_EXCHANGE_CONTRACT_ADDRESS,
            ETH_TOKEN_ADDRESS,
            amount,
            1,
            0
        );
        return returnAmount;
    }
    
    function LetsInvest(address toWhomToIssue, uint256 minTokens) public payable stopInEmergency returns (uint256) {
        IERC20 cToken = IERC20(address(COMPOUND_TOKEN_ADDRESS));
        IUniswapExchange uniswapExchange = IUniswapExchange(uniswapFactory.getExchange(address(COMPOUND_TOKEN_ADDRESS)));
        
        uint256 conversionPortion = msg.value.mul(505).div(1000);
        uint256 non_conversionPortion = msg.value.sub(conversionPortion);
        
        if (minTokens == 0) {
            (minTokens, ) = oneSplit.getExpectedReturn(
                UNISWAP_EXCHANGE_CONTRACT_ADDRESS,
                ETH_TOKEN_ADDRESS,
                conversionPortion,
                1,
                0
            );
        }
        
        oneSplit.swapWithReferral.value(conversionPortion)(
            UNISWAP_EXCHANGE_CONTRACT_ADDRESS,
            ETH_TOKEN_ADDRESS,
            conversionPortion,
            minTokens,
            1,
            0
        );
        
        uint256 daiBalance = DAI_TOKEN_ADDRESS.balanceOf(address(this));
        require(daiBalance > 0, "the conversion did not happen as planned");
        
        uint256 qty2approve = daiBalance.mul(3);
        require(DAI_TOKEN_ADDRESS.approve(address(cToken), qty2approve));
        
        COMPOUND_TOKEN_ADDRESS.mint(daiBalance);
        uint256 cTokenBalance = cToken.balanceOf(address(this));
        require(cTokenBalance > 0, "the conversion did not happen as planned");
        
        emit ERC20TokenHoldingsOnConversionDaiChai(cTokenBalance);
        
        cToken.approve(address(uniswapExchange), cTokenBalance);
        uint256 liquidityTokens = addLiquidity(address(uniswapExchange), cToken, non_conversionPortion);
        
        uniswapExchange.approve(address(uniswapExchange), 0);
        uint256 liquidityTokenHoldings = uniswapExchange.balanceOf(address(this));
        emit LiquidityTokens(liquidityTokenHoldings);
        
        uniswapExchange.transfer(toWhomToIssue, liquidityTokenHoldings);
        
        cTokenBalance = cToken.balanceOf(address(this));
        cToken.transfer(toWhomToIssue, cTokenBalance);
        
        return liquidityTokenHoldings;
    }
    
    function LetsWithdraw(address payable toWhomToIssue, uint256 liquidityTokenAmount) public stopInEmergency returns (uint256) {
        IERC20 cToken = IERC20(address(COMPOUND_TOKEN_ADDRESS));
        IUniswapExchange uniswapExchange = IUniswapExchange(uniswapFactory.getExchange(address(COMPOUND_TOKEN_ADDRESS)));
        
        uint256 userBalance = uniswapExchange.balanceOf(msg.sender);
        require(userBalance >= liquidityTokenAmount, "insufficient balance");
        
        uint256 allowance = uniswapExchange.allowance(msg.sender, address(this));
        require(allowance >= liquidityTokenAmount, "insufficient allowance");
        
        uint256 initialBalance = uniswapExchange.balanceOf(address(this));
        bool transferSuccess = uniswapExchange.transferFrom(msg.sender, address(this), liquidityTokenAmount);
        uint256 finalBalance = uniswapExchange.balanceOf(address(this));
        
        require(transferSuccess, "transfer of uni failed");
        require(finalBalance > initialBalance, "insufficient uni balance");
        
        uniswapExchange.approve(address(uniswapExchange), liquidityTokenAmount);
        (uint256 ethAmount, uint256 tokenAmount) = uniswapExchange.removeLiquidity(liquidityTokenAmount, 1, uint256(-1));
        
        (uint256 minTokens, ) = oneSplit.getExpectedReturn(
            address(COMPOUND_TOKEN_ADDRESS),
            UNISWAP_EXCHANGE_CONTRACT_ADDRESS,
            tokenAmount,
            1,
            0
        );
        
        oneSplit.swapWithReferral.value(0)(
            address(COMPOUND_TOKEN_ADDRESS),
            UNISWAP_EXCHANGE_CONTRACT_ADDRESS,
            tokenAmount,
            minTokens,
            1,
            0
        );
        
        cToken.approve(ONE_SPLIT_ADDRESS, 0);
        uint256 ethReturn = ethAmount.add(minTokens);
        toWhomToIssue.transfer(ethReturn);
        
        return ethReturn;
    }
    
    function addLiquidity(address uniswapExchange, IERC20 token, uint256 value) public view returns (uint256) {
        uint256 ethReserve = address(uniswapExchange).balance;
        uint256 tokenReserve = token.balanceOf(uniswapExchange);
        uint256 tokenAmount = value.mul(tokenReserve).div(ethReserve).add(1);
        return tokenAmount;
    }
    
    function showEthReserve(address uniswapExchange) public view returns (uint256) {
        uint256 ethReserve = uniswapExchange.balance;
        return ethReserve;
    }
    
    function showTokenReserve(address uniswapExchange, IERC20 token) public view returns (uint256) {
        uint256 tokenReserve = token.balanceOf(uniswapExchange);
        return tokenReserve;
    }
    
    function showExchangeTotalSupply(address uniswapExchange) public view returns (uint256) {
        uint256 totalSupply = IUniswapExchange(uniswapExchange).totalSupply();
        return totalSupply;
    }
    
    function showPoolValue(address uniswapExchange, IERC20 token, uint256 liquidityTokenAmount) public view returns (uint256, uint256, uint256) {
        uint256 tokenReserve = token.balanceOf(uniswapExchange);
        uint256 ethReserve = uniswapExchange.balance;
        uint256 totalSupply = IUniswapExchange(uniswapExchange).totalSupply();
        
        uint256 ethValue = liquidityTokenAmount.mul(ethReserve).div(totalSupply);
        uint256 tokenValue = liquidityTokenAmount.mul(tokenReserve).div(totalSupply);
        
        uint256 tokenPrice = IUniswapExchange(uniswapExchange).getTokenToEthInputPrice(tokenValue);
        uint256 totalValue = tokenPrice.add(ethValue);
        
        return (totalValue, ethValue, tokenValue);
    }
    
    function withdrawERC20Token(IERC20 token) onlyOwner public {
        uint256 tokenBalance = token.balanceOf(address(this));
        token.transfer(owner, tokenBalance);
    }
    
    function() external payable {
        if (msg.sender != owner) {
            LetsInvest(msg.sender, 0);
        }
    }
    
    function toggleContractActive() onlyOwner public {
        stopped = !stopped;
    }
    
    function withdraw() onlyOwner public {
        owner.transfer(address(this).balance);
    }
    
    function destruct() public onlyOwner {
        selfdestruct(owner);
    }
    
    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }
    
    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    
    function _transferOwnership(address payable newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = newOwner;
    }
}
```