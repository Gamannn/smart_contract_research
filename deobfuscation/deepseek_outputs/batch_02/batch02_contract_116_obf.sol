```solidity
pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

library SafeERC20 {
    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }
    
    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value));
    }
    
    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        require(token.approve(spender, value));
    }
}

contract Ownable {
    address public owner;
    
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function allowance(address owner, address spender) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Crowdsale is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    
    ERC20 public token;
    address public wallet;
    MintableToken public mintableToken;
    
    uint256 public tokensRaised;
    uint256 public rate;
    uint256 public openingTime;
    uint256 public closingTime;
    uint256 public cap;
    uint256 public minInvestmentValue;
    uint256 public gasAmount;
    bool public checks;
    
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event TokensTransfer(address indexed from, address indexed to, uint256 value, bool success);
    
    constructor() public {
        rate = 400;
        wallet = 0xeA9cbceD36a092C596e9c18313536D0EEFacff46;
        cap = 400000000000000000000000;
        openingTime = 1534558186;
        closingTime = 1535320800;
        minInvestmentValue = 0.02 ether;
        checks = true;
        gasAmount = 25000;
    }
    
    function hasClosed() public view returns (bool) {
        return tokensRaised >= cap || ((!checks && true));
    }
    
    function changeRate(uint256 newRate) public onlyOwner {
        rate = newRate;
    }
    
    function closeCurrentRound() public onlyOwner {
        closingTime = block.timestamp + 1;
    }
    
    function setTokenAddress(ERC20 tokenAddress) public onlyOwner {
        token = tokenAddress;
    }
    
    function setWalletAddress(address newWallet) public onlyOwner {
        wallet = newWallet;
    }
    
    function changeMinInvestmentValue(uint256 newMinInvestment) public onlyOwner {
        minInvestmentValue = newMinInvestment;
    }
    
    function setChecks(bool _checks) public onlyOwner {
        checks = _checks;
    }
    
    function setGasAmount(uint256 _gasAmount) public onlyOwner {
        gasAmount = _gasAmount;
    }
    
    function setCap(uint256 newCap) public onlyOwner {
        cap = newCap;
    }
    
    function startNewRound(
        uint256 newRate,
        address newWallet,
        ERC20 tokenAddress,
        uint256 newCap,
        uint256 newOpeningTime,
        uint256 newClosingTime
    ) payable public onlyOwner {
        require(!isOpen());
        rate = newRate;
        wallet = newWallet;
        token = tokenAddress;
        cap = newCap;
        openingTime = newOpeningTime;
        closingTime = newClosingTime;
    }
    
    function hasClosedTime() public view returns (bool) {
        return block.timestamp > closingTime;
    }
    
    function isOpen() public view returns (bool) {
        return (openingTime < block.timestamp && block.timestamp < closingTime);
    }
    
    function() payable external {
        buyTokens(msg.sender);
    }
    
    function buyTokens(address beneficiary) payable public {
        uint256 weiAmount = msg.value;
        if (checks) {
            _preValidatePurchase(beneficiary, weiAmount);
        }
        uint256 tokens = _getTokenAmount(weiAmount);
        tokensRaised = tokensRaised.add(tokens);
        mintableToken.mint(beneficiary, tokens);
        emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
        _forwardFunds();
    }
    
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0));
        require(weiAmount != 0 && weiAmount > minInvestmentValue);
        require(tokensRaised.add(_getTokenAmount(weiAmount)) <= cap);
    }
    
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        mintableToken.mint(beneficiary, tokenAmount);
    }
    
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }
    
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(rate);
    }
    
    function _forwardFunds() internal {
        bool success = wallet.call.value(msg.value).gas(gasAmount)();
        emit TokensTransfer(msg.sender, wallet, msg.value, success);
    }
}

contract MintableToken {
    function mint(address to, uint256 amount) public returns (bool);
}
```