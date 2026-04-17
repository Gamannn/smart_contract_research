```solidity
pragma solidity ^0.4.24;

contract MathOperations {
    function multiply(uint a, uint b) public pure returns (uint) {
        if (a == 0) {
            return 0;
        } else {
            uint result = a * b;
            require(result / a == b);
            return result;
        }
    }

    function divide(uint a, uint b) public pure returns (uint) {
        require(b > 0);
        uint result = a / b;
        require(a == b * result + a % b);
        return result;
    }
}

contract TokenInterface {
    function balanceOf(address owner) public view returns (uint);
    function transfer(address to, uint value) public returns (bool);
}

contract TokenExchange is MathOperations {
    uint public tokenPriceInWei;
    bool public exchangeActive = false;
    uint public constant exchangeRate = 100000000;
    address public owner;
    TokenInterface public tokenContract;

    event TokenTransfer(address indexed to, uint value);
    event TokenExchangeFailed(address indexed to, uint value);
    event EthFundTransfer(uint value);
    event TokenFundTransfer(uint value);

    constructor(uint initialTokenPrice, address tokenAddress) public {
        owner = msg.sender;
        tokenPriceInWei = initialTokenPrice;
        tokenContract = TokenInterface(tokenAddress);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setTokenPrice(uint newPrice) public onlyOwner returns (bool) {
        require(!exchangeActive);
        tokenPriceInWei = newPrice;
        return true;
    }

    function activateExchange() public onlyOwner returns (bool) {
        exchangeActive = true;
        return true;
    }

    function deactivateExchange() public onlyOwner returns (bool) {
        exchangeActive = false;
        return true;
    }

    function () public payable {
        require(exchangeActive);
        uint weiAmount = msg.value;
        uint tokens = divide(multiply(weiAmount, exchangeRate), tokenPriceInWei);

        if (tokens <= tokenContract.balanceOf(this)) {
            require(tokenContract.transfer(msg.sender, tokens));
            emit TokenTransfer(msg.sender, tokens);
        } else {
            emit TokenExchangeFailed(msg.sender, tokens);
            revert();
        }
    }

    function withdrawEther() public onlyOwner returns (bool) {
        require(!exchangeActive);
        if (owner.send(address(this).balance)) {
            emit EthFundTransfer(address(this).balance);
            return true;
        }
        return false;
    }

    function withdrawTokens() public onlyOwner returns (bool) {
        require(!exchangeActive);
        uint tokenBalance = tokenContract.balanceOf(this);
        if (tokenContract.transfer(owner, tokenBalance)) {
            emit TokenFundTransfer(tokenBalance);
            return true;
        }
        return false;
    }

    function destroyContract() public onlyOwner {
        require(!exchangeActive);
        selfdestruct(owner);
    }
}
```