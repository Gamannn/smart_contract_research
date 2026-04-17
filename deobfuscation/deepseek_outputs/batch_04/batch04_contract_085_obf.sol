```solidity
pragma solidity ^0.4.23;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
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
    
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

interface ERC20 {
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function transfer(address to, uint256 value) public returns (bool success);
}

contract Exchange {
    using SafeMath for uint256;
    
    address public admin;
    address public tradedToken;
    
    uint256 public tradedTokenBalance;
    uint256 public ethBalance;
    
    uint256 public commissionRatio;
    uint256 public tokenSeedAmount;
    uint256 public ethSeedAmount;
    
    bool public tradingDeactivated;
    bool public tokenSeeded;
    bool public ethSeeded;
    
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
    
    modifier tradingActive() {
        require(tradingDeactivated == false);
        _;
    }
    
    constructor(address _tradedToken, uint256 _tokenSeedAmount, uint256 _ethSeedAmount, uint256 _commissionRatio) public {
        admin = tx.origin;
        tradedToken = _tradedToken;
        tokenSeedAmount = _tokenSeedAmount;
        ethSeedAmount = _ethSeedAmount;
        commissionRatio = _commissionRatio;
    }
    
    function transferTokensThroughProxy(address from, address to, uint256 amount) private {
        tradedTokenBalance = tradedTokenBalance.add(amount);
        require(ERC20(tradedToken).transferFrom(from, to, amount));
    }
    
    function transferTokensFromContract(address to, uint256 amount) private {
        tradedTokenBalance = tradedTokenBalance.sub(amount);
        require(ERC20(tradedToken).transfer(to, amount));
    }
    
    function transferETHToContract() private {
        ethBalance = ethBalance.add(msg.value);
    }
    
    function transferETH(address to, uint256 amount) private {
        ethBalance = ethBalance.sub(amount);
        to.transfer(amount);
    }
    
    function depositToken(uint256 amount) private {
        transferTokensThroughProxy(msg.sender, this, amount);
    }
    
    function completeBuyExchange() private {
        transferETHToContract();
    }
    
    function withdrawETH(uint256 amount) public onlyAdmin {
        transferETH(admin, amount);
    }
    
    function withdrawToken(uint256 amount) public onlyAdmin {
        transferTokensFromContract(admin, amount);
    }
    
    function deactivateTrading() private {
        tradingDeactivated = true;
    }
    
    function setTokenSeeded() private {
        tokenSeeded = true;
    }
    
    function seedToken() public onlyAdmin {
        require(!tokenSeeded);
        deactivateTrading();
        depositToken(tokenSeedAmount);
        setTokenSeeded();
    }
    
    function seedETH() public payable onlyAdmin {
        require(!ethSeeded);
        require(msg.value == ethSeedAmount);
        completeBuyExchange();
        ethSeeded = true;
    }
    
    function sellToken(uint256 amount) public tradingActive {
        require(isSeeded());
        depositToken(amount);
    }
    
    function buyToken() public payable tradingActive {
        require(isSeeded());
        completeBuyExchange();
    }
    
    function isSeeded() private view returns(bool) {
        return (tokenSeeded && ethSeeded);
    }
    
    function activateTrading() public onlyAdmin {
        require(!tradingDeactivated);
        tradingDeactivated = false;
    }
    
    function reactivateTrading() public onlyAdmin {
        require(tradingDeactivated);
        tradingDeactivated = false;
    }
    
    function getBuyPrice(uint256 amount) public view returns(uint256) {
        uint256 ethReserve = ethBalance;
        uint256 tokenReserve = tradedTokenBalance;
        uint256 tokenReservePlusAmount = tokenReserve.add(amount);
        return (2 * ethReserve * amount) / (tokenReservePlusAmount * tokenReservePlusAmount);
    }
    
    function getSellPrice(uint256 amount) public view returns(uint256) {
        uint256 ethReserve = ethBalance;
        uint256 tokenReserve = tradedTokenBalance;
        uint256 ethReservePlusAmount = ethReserve.add(amount);
        return (amount * tokenReserve * (ethReservePlusAmount + ethReserve)) / (2 * ethReservePlusAmount * ethReserve);
    }
    
    function amountMinusCommission(uint256 amount) private view returns(uint256) {
        return (amount * (1 ether - commissionRatio)) / (1 ether);
    }
    
    function executeSell(uint256 tokenAmount) private {
        uint256 ethAmount = getSellPrice(tokenAmount);
        uint256 commission = amountMinusCommission(ethAmount);
        uint256 netAmount = ethAmount - commission;
        
        depositToken(tokenAmount);
        transferETH(msg.sender, commission);
        transferETH(admin, netAmount);
    }
    
    function executeBuy() private {
        uint256 ethAmount = msg.value;
        uint256 tokenAmount = getBuyPrice(ethAmount);
        uint256 commission = amountMinusCommission(tokenAmount);
        uint256 netAmount = tokenAmount - commission;
        
        completeBuyExchange();
        transferTokensFromContract(msg.sender, commission);
        transferTokensFromContract(admin, netAmount);
    }
    
    function sell(uint256 tokenAmount) public tradingActive {
        require(isSeeded());
        executeSell(tokenAmount);
    }
    
    function buy() private tradingActive {
        require(isSeeded());
        executeBuy();
    }
    
    function() public payable {
        buy();
    }
}
```