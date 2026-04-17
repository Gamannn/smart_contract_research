pragma solidity ^0.4.18;

contract ERC20Interface {
    function totalSupply() constant public returns (uint);
    function balanceOf(address tokenOwner) constant public returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function allowance(address tokenOwner, address spender) constant public returns (uint remaining);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Owned {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract TokenSale is Owned {
    address public tokenAddress;
    uint256 public tokenRate;
    uint256 public minPurchase;
    uint256 public maxPurchase;
    uint256 public totalTokensSold;
    uint256 public totalEtherCollected;
    event TokensPurchased(address indexed buyer, uint256 etherAmount, uint256 tokenAmount);

    function TokenSale(
        address _tokenAddress,
        uint256 _tokenRate,
        uint256 _minPurchase,
        uint256 _maxPurchase
    ) public {
        tokenAddress = _tokenAddress;
        tokenRate = _tokenRate;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
    }

    function withdrawTokens(address to, uint256 amount) onlyOwner public {
        require(ERC20Interface(tokenAddress).transfer(to, amount));
    }

    function withdrawEther(uint256 amount) onlyOwner public {
        require(this.balance >= amount);
        owner.transfer(amount);
    }

    function setTokenRate(uint256 newRate) onlyOwner public {
        tokenRate = newRate;
    }

    function setMinPurchase(uint256 newMinPurchase) onlyOwner public {
        minPurchase = newMinPurchase;
    }

    function setMaxPurchase(uint256 newMaxPurchase) onlyOwner public {
        maxPurchase = newMaxPurchase;
    }

    function buyTokens() public payable {
        require(msg.value > 0);
        uint256 tokensToBuy = msg.value * tokenRate;
        require(tokensToBuy >= minPurchase && tokensToBuy <= maxPurchase);
        require(ERC20Interface(tokenAddress).transfer(msg.sender, tokensToBuy));
        totalTokensSold += tokensToBuy;
        totalEtherCollected += msg.value;
        TokensPurchased(msg.sender, msg.value, tokensToBuy);
    }

    function() public payable {
        buyTokens();
    }
}