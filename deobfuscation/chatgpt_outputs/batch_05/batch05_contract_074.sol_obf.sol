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

interface IExchange {
    function getExpectedRate(IERC20 srcToken, IERC20 destToken, uint srcQty) external view returns (uint expectedRate, uint slippageRate);
    function trade(IERC20 srcToken, uint srcAmount, IERC20 destToken, address destAddress, uint maxDestAmount, uint minConversionRate, address walletId) external payable returns (uint);
}

interface IBancorNetwork {
    function getReturn(IERC20 fromToken, IERC20 toToken, uint256 amount) external view returns (uint256, uint256);
}

contract Arbitrage {
    uint constant MIN_TRADING_AMOUNT = 0.0001 ether;
    IBancorNetwork public bancorNetwork;
    IExchange public kyberNetwork;
    address public kyberEtherAddress;
    address public daiTokenAddress;
    address public bntTokenAddress;

    constructor(address _bancorNetwork, address _kyberNetwork, address _kyberEtherAddress, address _daiTokenAddress, address _bntTokenAddress) public {
        bancorNetwork = IBancorNetwork(_bancorNetwork);
        kyberNetwork = IExchange(_kyberNetwork);
        kyberEtherAddress = _kyberEtherAddress;
        daiTokenAddress = _daiTokenAddress;
        bntTokenAddress = _bntTokenAddress;
    }

    function getBancorRate(IERC20 fromToken, IERC20 toToken, uint amount) public view returns (uint expectedRate, uint slippageRate) {
        return bancorNetwork.getReturn(fromToken, toToken, amount);
    }

    function getKyberRate(IERC20 fromToken, IERC20 toToken, uint amount) public view returns (uint expectedRate, uint slippageRate) {
        return kyberNetwork.getExpectedRate(fromToken, toToken, amount);
    }

    function() external payable {
        uint gasStart = gasleft();
        require(msg.value >= MIN_TRADING_AMOUNT, "Min trading amount not reached.");

        IERC20 ethToken = IERC20(kyberEtherAddress);
        IERC20 daiToken = IERC20(daiTokenAddress);
        IERC20 bntToken = IERC20(bntTokenAddress);

        (uint bancorExpectedRate, uint bancorSlippageRate) = getBancorRate(ethToken, bntToken, msg.value);
        (uint kyberExpectedRate, uint kyberSlippageRate) = getKyberRate(ethToken, daiToken, msg.value);

        uint bancorReturn = bancorExpectedRate * msg.value;
        uint kyberReturn = kyberExpectedRate + kyberSlippageRate;

        uint profit = 0;
        if (bancorReturn > kyberReturn) {
            profit = bancorReturn - kyberReturn;
            emit Trade("buy", kyberReturn, "bancor");
            emit Trade("sell", bancorReturn, "kyber");
        } else {
            profit = kyberReturn - bancorReturn;
            emit Trade("buy", bancorReturn, "kyber");
            emit Trade("sell", kyberReturn, "bancor");
        }
    }

    event Trade(string action, uint amount, string platform);

    function getIntFunc(uint256 index) internal view returns(uint256) {
        return _integer_constant[index];
    }

    function getAddrFunc(uint256 index) internal view returns(address payable) {
        return _address_constant[index];
    }

    function getStrFunc(uint256 index) internal view returns(string storage) {
        return _string_constant[index];
    }

    uint256[] public _integer_constant = [0, 100000000000000];
    address payable[] public _address_constant = [0xc0829421C1d260BD3cB3E0F06cfE2D52db2cE315, 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE];
    string[] public _string_constant = ["bancor", "buy", "sell", "Min trading amount not reached.", "kyber"];
}