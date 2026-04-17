```solidity
pragma solidity >=0.4.26;

contract ExchangeInterface {
    function getExchangeRate() external view returns (address);
    function getTokenAddress() external view returns (address);
    function trade(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount
    ) external payable returns (uint256);
    function getExpectedRate(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice
    ) external returns (uint256, uint256);
    function getBalance(address token) external view returns (uint256);
    function getAllowance(address token) external view returns (uint256);
    function deposit(uint256 amount) external payable returns (uint256);
    function withdraw(uint256 amount) external payable returns (uint256);
    function transfer(
        uint256 amount,
        uint256 minConversionRate,
        address destAddress
    ) external payable returns (uint256);
    function approve(
        uint256 amount,
        uint256 minConversionRate,
        address destAddress
    ) external payable returns (uint256);
    function swap(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount
    ) external returns (uint256);
    function swapWithHint(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFee(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGas(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDest(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHint(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFee(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGas(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDest(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHint(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFee(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGas(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDest(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHint(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFee(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGas(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDest(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHint(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFee(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGas(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDest(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHint(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFee(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGas(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDest(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHint(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFee(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGas(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDest(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHint(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFee(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGas(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDest(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHint(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFee(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGas(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDest(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHint(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFee(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGas(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDest(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHint(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFee(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGas(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDest(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHint(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFee(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGas(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDest(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHint(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFee(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGas(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDest(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHint(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFee(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGas(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDest(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHint(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFee(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGas(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDest(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHint(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFee(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGas(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDest(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHint(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFee(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGas(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDest(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHint(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFee(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGas(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDest(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHint(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFee(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGas(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDest(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHint(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFee(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGas(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDest(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHint(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFee(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGas(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDest(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHint(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFee(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGas(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDest(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHint(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFee(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGas(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDest(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHint(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFee(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGas(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDest(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHint(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFee(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDest(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHint(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGas(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDest(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHint(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDest(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHint(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFee(
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 maxDestAmount,
        uint256 maxGasPrice,
        address destAddress
    ) external returns (uint256);
    function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFeeAndGasAndDestAndHintAndFee