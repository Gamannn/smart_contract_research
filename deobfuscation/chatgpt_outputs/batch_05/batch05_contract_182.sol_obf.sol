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
        uint256 c = a / b;
        return c;
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

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface ERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract TokenSale is Ownable {
    using SafeMath for uint256;

    uint256 public buyPrice;
    uint256 public sellPrice;
    address public tokenAddress;

    event SellTransaction(uint256 amountInWei, uint256 tokensSold);
    event BuyTransaction(uint256 amountInWei, uint256 tokensBought);

    function setBuyPrice(uint256 newBuyPrice) public onlyOwner {
        buyPrice = newBuyPrice;
    }

    function setSellPrice(uint256 newSellPrice) public onlyOwner {
        sellPrice = newSellPrice;
    }

    function buyTokens() payable public {
        ERC20 token = ERC20(tokenAddress);
        uint256 tokensToBuy = msg.value.mul(buyPrice).div(100);
        require(token.balanceOf(address(this)) >= tokensToBuy);
        token.transfer(msg.sender, tokensToBuy);
        emit BuyTransaction(msg.value, tokensToBuy);
    }

    function sellTokens(uint256 tokensToSell) public {
        address seller = msg.sender;
        ERC20 token = ERC20(tokenAddress);
        uint256 transactionPrice = tokensToSell.div(sellPrice).mul(100);
        require(address(this).balance >= transactionPrice);
        require(token.transferFrom(seller, address(this), tokensToSell));
        seller.transfer(transactionPrice);
        emit SellTransaction(transactionPrice, tokensToSell);
    }

    function withdraw(uint256 amount) public onlyOwner {
        msg.sender.transfer(amount);
    }

    function withdrawTokens(uint256 amount) public onlyOwner {
        ERC20 token = ERC20(tokenAddress);
        token.transfer(msg.sender, amount);
    }

    function destroyContract() public onlyOwner {
        ERC20 token = ERC20(tokenAddress);
        uint256 tokenBalance = token.balanceOf(address(this));
        token.transfer(msg.sender, tokenBalance);
        msg.sender.transfer(address(this).balance);
        selfdestruct(owner);
    }

    function changeTokenAddress(address newTokenAddress) public onlyOwner {
        tokenAddress = newTokenAddress;
    }
}