pragma solidity ^0.4.23;

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

contract Token {
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function transfer(address to, uint256 value) public returns (bool);
}

contract Exchange {
    using SafeMath for uint256;

    address public owner;
    address public tradedToken;
    uint256 public ethBalance;
    uint256 public tradedTokenBalance;
    uint256 public commissionRatio;
    bool public tradingDeactivated;
    bool public ethIsSeeded;
    bool public tradedTokenIsSeeded;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier tradingActive() {
        require(!tradingDeactivated);
        _;
    }

    constructor(address _tradedToken, uint256 _ethSeedAmount, uint256 _tradedTokenSeedAmount) public {
        owner = msg.sender;
        tradedToken = _tradedToken;
        ethBalance = _ethSeedAmount;
        tradedTokenBalance = _tradedTokenSeedAmount;
        commissionRatio = 0;
        tradingDeactivated = false;
        ethIsSeeded = false;
        tradedTokenIsSeeded = false;
    }

    function transferTokensThroughProxy(address from, address to, uint256 amount) private {
        tradedTokenBalance = tradedTokenBalance.add(amount);
        require(Token(tradedToken).transferFrom(from, to, amount));
    }

    function transferTokensFromContract(address to, uint256 amount) private {
        tradedTokenBalance = tradedTokenBalance.sub(amount);
        require(Token(tradedToken).transfer(to, amount));
    }

    function depositETHToContract() private {
        ethBalance = ethBalance.add(msg.value);
    }

    function withdrawETH(address to, uint256 amount) private {
        ethBalance = ethBalance.sub(amount);
        to.transfer(amount);
    }

    function withdrawTokens(address to, uint256 amount) private {
        tradedTokenBalance = tradedTokenBalance.sub(amount);
        require(Token(tradedToken).transfer(to, amount));
    }

    function setEthSeeded() private {
        ethIsSeeded = true;
    }

    function setTradedTokenSeeded() private {
        tradedTokenIsSeeded = true;
    }

    function seedETH() public payable onlyOwner {
        require(!ethIsSeeded);
        require(msg.value == ethBalance);
        setEthSeeded();
    }

    function seedTradedToken(uint256 amount) public onlyOwner {
        require(!tradedTokenIsSeeded);
        require(Token(tradedToken).transferFrom(msg.sender, this, amount));
        setTradedTokenSeeded();
    }

    function activateTrading() public onlyOwner {
        require(ethIsSeeded && tradedTokenIsSeeded);
        tradingDeactivated = false;
    }

    function deactivateTrading() public onlyOwner {
        tradingDeactivated = true;
    }

    function buyTokens(uint256 amount) public payable tradingActive {
        require(msg.value == amount);
        uint256 tokensToTransfer = calculateTokensToTransfer(amount);
        transferTokensFromContract(msg.sender, tokensToTransfer);
        depositETHToContract();
    }

    function sellTokens(uint256 amount) public tradingActive {
        uint256 ethToTransfer = calculateEthToTransfer(amount);
        transferTokensThroughProxy(msg.sender, this, amount);
        withdrawETH(msg.sender, ethToTransfer);
    }

    function calculateTokensToTransfer(uint256 ethAmount) public view returns (uint256) {
        uint256 totalEthBalance = ethBalance.add(ethAmount);
        return (2 * tradedTokenBalance * ethAmount) / totalEthBalance;
    }

    function calculateEthToTransfer(uint256 tokenAmount) public view returns (uint256) {
        uint256 totalTokenBalance = tradedTokenBalance.add(tokenAmount);
        return (tokenAmount * ethBalance * (totalTokenBalance + tradedTokenBalance)) / (2 * totalTokenBalance * tradedTokenBalance);
    }

    function calculateAmountMinusCommission(uint256 amount) private view returns (uint256) {
        return (amount * (1 ether - commissionRatio)) / 1 ether;
    }

    function() public payable {
        buyTokens(msg.value);
    }
}