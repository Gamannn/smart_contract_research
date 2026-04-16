```solidity
pragma solidity ^0.8.0;

contract MathOperations {
    function multiply(uint a, uint b) internal pure returns (uint) {
        uint result = a * b;
        assert(a == 0 || result / a == b);
        return result;
    }

    function subtract(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint result = a + b;
        assert(result >= a && result >= b);
        return result;
    }

    modifier validateDataLength(uint length) {
        assert(msg.data.length >= length * 32 + 4);
        _;
    }
}

interface TokenInterface {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract LiquidityPool is MathOperations {
    bool public halted;
    address public controlWallet;

    event AddLiquidity(uint256 amount);
    event RemoveLiquidity(uint256 amount);

    modifier onlyControlWallet() {
        require(msg.sender == controlWallet, "Not authorized");
        _;
    }

    function addLiquidity() external payable onlyControlWallet {
        require(msg.value > 0, "No ether sent");
        emit AddLiquidity(msg.value);
    }

    function removeLiquidity(uint256 amount) external onlyControlWallet {
        require(amount <= address(this).balance, "Insufficient balance");
        payable(controlWallet).transfer(amount);
        emit RemoveLiquidity(amount);
    }

    function setControlWallet(address newControlWallet) external onlyControlWallet {
        require(newControlWallet != address(0), "Invalid address");
        controlWallet = newControlWallet;
    }

    function halt() external onlyControlWallet {
        halted = true;
    }

    function resume() external onlyControlWallet {
        halted = false;
    }

    function transferTokens(address tokenAddress) external onlyControlWallet {
        require(tokenAddress != address(0), "Invalid token address");
        TokenInterface token = TokenInterface(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(controlWallet, balance);
    }
}

contract TokenSwap is LiquidityPool {
    TokenInterface public tokenA;
    TokenInterface public tokenB;

    event TokenSwapped(address indexed user, uint256 amountA, uint256 amountB, uint256 rate);

    constructor(address _tokenA, address _tokenB) {
        controlWallet = msg.sender;
        tokenA = TokenInterface(_tokenA);
        tokenB = TokenInterface(_tokenB);
    }

    function swapTokens(address user, uint256 amountA, uint256 amountB, uint256 rate) private {
        require(tokenA.balanceOf(address(this)) >= amountA, "Insufficient token A balance");
        require(tokenB.balanceOf(address(this)) >= amountB, "Insufficient token B balance");

        tokenA.transfer(user, amountA);
        tokenB.transfer(user, amountB);

        emit TokenSwapped(user, amountA, amountB, rate);
    }

    function getTokenABalance() public view returns (uint256) {
        return tokenA.balanceOf(address(this));
    }

    function getTokenBBalance() public view returns (uint256) {
        return tokenB.balanceOf(address(this));
    }
}
```