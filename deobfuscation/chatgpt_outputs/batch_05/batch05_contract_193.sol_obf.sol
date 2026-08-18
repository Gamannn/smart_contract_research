pragma solidity >=0.4.26;

contract ExchangeContract {
    function getSourceToken() external view returns (address sourceToken);
    function getDestinationToken() external view returns (address destinationToken);
    function executeTrade(uint256 sourceAmount, uint256 minDestinationAmount, uint256 maxDestinationAmount) external payable returns (uint256);
    function getExpectedRate(uint256 sourceAmount, uint256 minDestinationAmount, uint256 maxDestinationAmount, uint256 maxDestinationAmount) external returns (uint256, uint256);
    function getBalance(uint256 token) external view returns (uint256 balance);
    function getTokenAmount(uint256 balance) external view returns (uint256 tokenAmount);
    function getRate(uint256 tokenAmount) external view returns (uint256 rate);
    function getTokenRate(uint256 rate) external view returns (uint256 tokenAmount);
    function trade(uint256 sourceAmount, uint256 minDestinationAmount) external payable returns (uint256 balance);
    function tradeWithHint(uint256 sourceAmount, uint256 minDestinationAmount, address hint) external payable returns (uint256 balance);
    function swap(uint256 balance, uint256 minDestinationAmount) external payable returns (uint256 tokenAmount);
    function swapWithHint(uint256 balance, uint256 minDestinationAmount, address hint) external payable returns (uint256 tokenAmount);
    function getExpectedRateWithHint(uint256 tokenAmount, uint256 minDestinationAmount, uint256 maxDestinationAmount) external returns (uint256 rate);
    function getExpectedRateWithHintAndAddress(uint256 tokenAmount, uint256 minDestinationAmount, uint256 maxDestinationAmount, address hint) external returns (uint256 rate);
    function getExpectedRateWithHintAndAddressAndAmount(uint256 tokenAmount, uint256 minDestinationAmount, uint256 maxDestinationAmount, uint256 maxDestinationAmount, address hint) external returns (uint256 balance);
    function getExpectedRateWithHintAndAddressAndAmountAndAddress(uint256 tokenAmount, uint256 minDestinationAmount, uint256 maxDestinationAmount, uint256 maxDestinationAmount, address hint, address hintAddress) external returns (uint256 balance);
    function getExpectedRateWithHintAndAddressAndAmountAndAddressAndAmount(uint256 balance, uint256 minDestinationAmount, uint256 maxDestinationAmount, uint256 maxDestinationAmount, address hint, address hintAddress) external returns (uint256 rate);
    function getExpectedRateWithHintAndAddressAndAmountAndAddressAndAmountAndAddress(uint256 balance, uint256 minDestinationAmount, uint256 maxDestinationAmount, uint256 maxDestinationAmount, address hint, address hintAddress) external returns (uint256 rate);
    bytes32 public sourceTokenHash;
    bytes32 public destinationTokenHash;
    uint256 public tradeAmount;
    function executeTradeWithHint(address sourceToken, address destinationToken, uint256 tradeAmount) external returns (bool);
    function executeTradeWithHintAndAddress(address destinationToken, uint256 tradeAmount) external returns (bool);
    function getTradeAmount(address sourceToken, address destinationToken) external view returns (uint256);
    function getTradeAmount(address sourceToken) external view returns (uint256);
    function getTradeAmount() external view returns (uint256);
    function executeTradeWithHintAndAddressAndAmount(address hint) external;
}

interface TokenInterface {
    function getTradeAmount() external view returns (uint256 tradeAmount);
    function getTradeAmount(address sourceToken) external view returns (uint256 tradeAmount);
    function executeTradeWithHint(address destinationToken, uint256 tradeAmount) external returns (bool success);
    function executeTradeWithHintAndAddress(address sourceToken, address destinationToken, uint256 tradeAmount) external returns (bool success);
    function executeTradeWithHintAndAddressAndAmount(address destinationToken, uint256 tradeAmount) external returns (bool success);
    function getTradeAmount(address sourceToken, address destinationToken) external view returns (uint256 tradeAmount);
    function getTradeAmount() external view returns (uint256 tradeAmount);
    event Approval(address indexed sourceToken, address indexed destinationToken, uint256 tradeAmount);
}

interface KyberNetworkInterface {
    function getExpectedRate() external view returns (uint256);
    function getExpectedRate(address sourceToken) external view returns (uint256);
    function getExpectedRate(address sourceToken, TokenInterface destinationToken) external view returns (uint256);
    function isEnabled() external view returns (bool);
    function getExpectedRateWithHint(bytes32 hint) external view returns (uint256);
    function getExpectedRateWithHintAndAddress(TokenInterface sourceToken, TokenInterface destinationToken, uint256 tradeAmount) external view returns (uint256, uint256);
    function getExpectedRateWithHintAndAddressAndAmount(TokenInterface sourceToken, uint256 tradeAmount, TokenInterface destinationToken, address hint, uint256 minDestinationAmount, uint256 maxDestinationAmount, address hintAddress, bytes hintData) external payable returns (uint256);
    function executeTradeWithHintAndAddressAndAmount(TokenInterface sourceToken, uint256 tradeAmount) external payable returns (uint256);
    function executeTradeWithHintAndAddressAndAmountAndAddress(TokenInterface sourceToken, uint256 tradeAmount, uint256 minDestinationAmount) external returns (uint256);
}

interface ExchangeRateInterface {
    function getExchangeRate(string memory sourceToken, string memory destinationToken, string memory exchange, uint256 tradeAmount) external view returns (uint256);
    function getExchangeRate(address sourceToken) external view returns (uint256);
    function getExchangeRate(string memory exchange) external view returns (address);
    function getExchangeRate(string memory exchange) external view returns (bytes32);
    function getExchangeRate(string memory exchange) external view returns (address);
}

contract Exchange {
    TokenInterface constant internal ETH_TOKEN_ADDRESS = TokenInterface(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
    KyberNetworkInterface public kyberNetwork = KyberNetworkInterface(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);
    ExchangeRateInterface exchangeRateInterface = ExchangeRateInterface(0x8316b0826);
    address public owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function executeTradeWithHintAndAddressAndAmountAndAddressAndAmountAndAddressAndAmount(address sourceToken, address destinationToken, uint256 tradeAmount) public returns (bool) {
        address hintAddress = destinationToken;
        ExchangeContract exchangeContract = ExchangeContract(hintAddress);
        TokenInterface sourceTokenInterface = TokenInterface(sourceToken);
        uint256 tradeAmount = executeTradeWithHintAndAddressAndAmount(kyberNetwork, sourceTokenInterface, tradeAmount, msg.sender);
        exchangeContract.trade(tradeAmount, 1, block.timestamp);
        return true;
    }
    
    function executeTradeWithHintAndAddressAndAmount(KyberNetworkInterface kyberNetwork, TokenInterface sourceToken, uint256 tradeAmount, address hint) internal returns (uint256) {
        uint256 minDestinationAmount = 1;
        sourceToken.executeTradeWithHintAndAddress(msg.sender, address(this), tradeAmount);
        sourceToken.executeTradeWithHintAndAddressAndAmount(kyberNetwork, 0);
        sourceToken.executeTradeWithHintAndAddressAndAmount(address(kyberNetwork), tradeAmount);
        uint256 rate = kyberNetwork.getExpectedRateWithHintAndAddressAndAmount(TokenInterface(0x0D8775F648430679A709E98d2b0Cb6250d2887EF), tradeAmount, TokenInterface(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee), address(this), 8000000000000000000000000000000000000000000000000000000000000000, 0, address(0));
        return rate;
    }
    
    function executeTradeWithHintAndAddressAndAmountAndAddressAndAmountAndAddressAndAmountAndAddress(address sourceToken, address destinationToken, uint256 tradeAmount) public returns (bool) {
        address hintAddress = destinationToken;
        ExchangeContract exchangeContract = ExchangeContract(hintAddress);
        TokenInterface sourceTokenInterface = TokenInterface(sourceToken);
        uint256 tradeAmount = executeTradeWithHintAndAddressAndAmount(kyberNetwork, sourceTokenInterface, tradeAmount, msg.sender);
        exchangeContract.trade(tradeAmount, 1, block.timestamp);
        return true;
    }
    
    function() external payable {}
    
    function withdraw() public {
        msg.sender.transfer(address(this).balance);
        TokenInterface token = TokenInterface(0x0D8775F648430679A709E98d2b0Cb6250d2887EF);
        uint256 currentTokenBalance = exchangeRateInterface.getExchangeRate(address(this));
        exchangeRateInterface.executeTradeWithHint(msg.sender, currentTokenBalance);
    }
    
    function getExchangeRate() public view returns (uint256) {
        uint256 rate = exchangeRateInterface.getExchangeRate("ETH", "BAT", "EXCHANGE", 1000000000000000000);
        return rate;
    }
    
    function getExchangeRate() public view returns (uint256) {
        uint256 rate = exchangeRateInterface.getExchangeRate("EXCHANGE", 1000000000000000000);
        return rate;
    }
    
    function getIntFunc(uint256 index) internal view returns (uint256) {
        return _integer_constant[index];
    }
    
    function getBoolFunc(uint256 index) internal view returns (bool) {
        return _bool_constant[index];
    }
    
    function getStrFunc(uint256 index) internal view returns (string storage) {
        return _string_constant[index];
    }
    
    function getAddrFunc(uint256 index) internal view returns (address payable) {
        return _address_constant[index];
    }
    
    uint256[] public _integer_constant = [7483, 8000, 1000000000000000000, 1, 1364, 0];
    bool[] public _bool_constant = [true];
    string[] public _string_constant = ["SELL-UNISWAP-EXCHANGE", "BAT", "BUY-KYBER-EXCHANGE", "ETH", "PERM"];
    address payable[] public _address_constant = [0x0000000000000000000000000000000000000004, 0x818E6FECD516Ecc3849DAf6845e3EC868087B755, 0x0D8775F648430679A709E98d2b0Cb6250d2887EF];
}
