pragma solidity >=0.4.24 <0.6.0;

contract Initializable {
    bool private initialized;
    bool private initializing;

    modifier initializer() {
        require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");
        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }
        _;
        if (isTopLevelCall) {
            initializing = false;
        }
    }

    function isConstructor() private view returns (bool) {
        uint256 cs;
        assembly {
            cs := extcodesize(address)
        }
        return cs == 0;
    }

    uint256[50] private ______gap;
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

pragma solidity ^0.5.0;

interface IUniswapFactory {
    function getExchange(address token) external view returns (address exchange);
}

interface IUniswapExchange {
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256 tokens_bought);
    function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline) external returns (uint256 eth_bought);
    function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256 tokens_bought);
    function getTokenToEthInputPrice(uint256 tokens_sold) external view returns (uint256 eth_bought);
}

contract MyContract is Initializable {
    using SafeMath for uint256;

    bool private paused;
    address payable public owner;
    IUniswapFactory public uniswapFactory;
    IERC20 public daiToken;
    IERC20 public chaiToken;
    address public daiAddress;
    address public ethAddress;
    address public chaiAddress;

    event ERC20TokenHoldingsOnConversionDaiChai(uint256);
    event ERC20TokenHoldingsOnConversionEthDai(uint256);
    event LiquidityTokens(uint256);

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function initialize() initializer public {
        paused = false;
        owner = msg.sender;
        uniswapFactory = IUniswapFactory(0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95);
        daiToken = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        chaiToken = IERC20(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
        daiAddress = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        ethAddress = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
        chaiAddress = address(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
    }

    function setNewChaiTokenAddress(address newChaiTokenAddress) public onlyOwner {
        chaiToken = IERC20(newChaiTokenAddress);
    }

    function setNewUniswapFactoryAddress(address newUniswapFactoryAddress) public onlyOwner {
        uniswapFactory = IUniswapFactory(newUniswapFactoryAddress);
    }

    function getEthToDaiPrice(uint256 ethAmount) public view returns (uint256) {
        IUniswapExchange exchange = IUniswapExchange(uniswapFactory.getExchange(daiAddress));
        return exchange.getEthToTokenInputPrice(ethAmount);
    }

    function convertEthToDai(address recipient, uint256 minDai) public payable whenNotPaused returns (uint256) {
        IUniswapExchange exchange = IUniswapExchange(uniswapFactory.getExchange(daiAddress));
        uint256 daiBought = exchange.ethToTokenSwapInput.value(msg.value)(minDai, now + 300);
        require(daiBought >= minDai, "Conversion did not yield enough DAI");
        require(daiToken.transfer(recipient, daiBought), "DAI transfer failed");
        emit ERC20TokenHoldingsOnConversionEthDai(daiBought);
        return daiBought;
    }

    function convertDaiToEth(address payable recipient, uint256 daiAmount) public whenNotPaused returns (uint256) {
        IUniswapExchange exchange = IUniswapExchange(uniswapFactory.getExchange(daiAddress));
        require(daiToken.transferFrom(msg.sender, address(this), daiAmount), "DAI transfer failed");
        require(daiToken.approve(address(exchange), daiAmount), "DAI approve failed");
        uint256 ethBought = exchange.tokenToEthSwapInput(daiAmount, 1, now + 300);
        recipient.transfer(ethBought);
        emit ERC20TokenHoldingsOnConversionDaiChai(ethBought);
        return ethBought;
    }

    function pause() public onlyOwner {
        paused = true;
    }

    function unpause() public onlyOwner {
        paused = false;
    }

    function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }

    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = newOwner;
    }

    function() external payable {
        if (msg.sender != owner) {
            convertEthToDai(msg.sender, 0);
        }
    }
}