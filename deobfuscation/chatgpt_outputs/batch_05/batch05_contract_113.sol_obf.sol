pragma solidity ^0.4.19;

contract TokenManager {
    using SafeMath for uint256;

    Token public tokenContract;
    address public owner;
    uint256 public tokenDecimals;
    uint256 public ethToTokenRate;
    address public feeRecipient;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    struct Config {
        uint256 tokenDecimals;
        uint256 ethToTokenRate;
        address feeRecipient;
        address owner;
    }

    Config public config;

    function TokenManager(address _tokenAddress, uint256 _ethToTokenRate) public {
        tokenContract = Token(_tokenAddress);
        ethToTokenRate = _ethToTokenRate;
        config.tokenDecimals = tokenContract.totalSupply();
        config.owner = msg.sender;
    }

    function purchaseTokens(uint256 _amount) public {
        require(tokenContract.transferFrom(msg.sender, address(this), _amount));
        uint256 tokensToReceive = calculateTokens(_amount, config.ethToTokenRate, 8);
        uint256 fee = tokensToReceive.mul(100000000).div(100000000);
        msg.sender.transfer(tokensToReceive.sub(fee));
        processPurchase(_amount);
        emit LogPurchase(msg.sender, _amount, tokensToReceive, fee);
    }

    function processPurchase(uint256 _amount) internal {
        require(tokenContract.transfer(config.feeRecipient, _amount));
    }

    function updateEthToTokenRate(uint256 _newRate) public onlyOwner {
        config.ethToTokenRate = _newRate;
    }

    function updateOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function calculateTokens(uint256 _amount, uint256 _rate, uint256 _decimals) internal pure returns (uint256) {
        uint256 tokens = _amount.mul(10 ** (_decimals + 1));
        uint256 result = (tokens / _rate + 5) / 10;
        return result;
    }

    event LogPurchase(address indexed buyer, uint256 amount, uint256 tokensReceived, uint256 fee);
}

contract Token {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address _owner) public constant returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public constant returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}