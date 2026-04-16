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

library TokenOperations {
    function transferTokens(
        TokenInterface token,
        address to,
        uint256 value
    ) internal {
        require(token.transfer(to, value));
    }

    function transferFromTokens(
        TokenInterface token,
        address from,
        address to,
        uint256 value
    ) internal {
        require(token.transferFrom(from, to, value));
    }

    function burnTokens(
        TokenInterface token,
        address from,
        uint256 value
    ) internal {
        require(token.burn(from, value));
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

contract TokenInterface {
    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function allowance(address owner, address spender) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    function burn(address from, uint256 value) public returns (bool);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Crowdsale is Ownable {
    using SafeMath for uint256;
    using TokenOperations for TokenInterface;

    TokenInterface public token;
    address public wallet;
    uint256 public rate;
    uint256 public weiRaised;
    uint256 public cap;
    uint256 public openingTime;
    uint256 public closingTime;
    bool public isFinalized = false;
    uint256 public minInvestment;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event TokensTransfer(address indexed from, address indexed to, uint256 value, bool success);

    constructor() public {
        rate = 400;
        wallet = 0xeA9cbceD36a092C596e9c18313536D0EEFacff46;
        cap = 400000000000000000000000;
        openingTime = 1534558186;
        closingTime = 1535320800;
        minInvestment = 0.02 ether;
    }

    function hasClosed() public view returns (bool) {
        return block.timestamp > closingTime;
    }

    function changeRate(uint256 newRate) public onlyOwner {
        rate = newRate;
    }

    function closeRound() public onlyOwner {
        closingTime = block.timestamp + 1;
    }

    function setTokenAddress(TokenInterface _token) public onlyOwner {
        token = _token;
    }

    function setWalletAddress(address _wallet) public onlyOwner {
        wallet = _wallet;
    }

    function setMinInvestment(uint256 _minInvestment) public onlyOwner {
        minInvestment = _minInvestment;
    }

    function setGasAmount(uint256 _gasAmount) public onlyOwner {
        // Set gas amount for internal transactions
    }

    function setCap(uint256 _cap) public onlyOwner {
        cap = _cap;
    }

    function startNewRound(
        uint256 _rate,
        address _wallet,
        TokenInterface _token,
        uint256 _openingTime,
        uint256 _closingTime
    ) payable public onlyOwner {
        require(!isFinalized);
        rate = _rate;
        wallet = _wallet;
        token = _token;
        openingTime = _openingTime;
        closingTime = _closingTime;
    }

    function isOpen() public view returns (bool) {
        return (openingTime < block.timestamp && block.timestamp < closingTime);
    }

    function () payable external {
        buyTokens(msg.sender);
    }

    function buyTokens(address beneficiary) payable public {
        uint256 weiAmount = msg.value;
        require(beneficiary != address(0));
        require(weiAmount != 0 && weiAmount > minInvestment);
        require(weiRaised.add(weiAmount) <= cap);

        uint256 tokens = _getTokenAmount(weiAmount);
        weiRaised = weiRaised.add(weiAmount);

        token.transferTokens(beneficiary, tokens);
        emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        _forwardFunds();
    }

    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(rate);
    }

    function _forwardFunds() internal {
        bool success = wallet.call.value(msg.value).gas(25000)();
        emit TokensTransfer(msg.sender, wallet, msg.value, success);
    }
}
```