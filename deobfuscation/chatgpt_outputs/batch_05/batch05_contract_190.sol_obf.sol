```solidity
pragma solidity ^0.4.18;

interface IPriceCalculator {
    function calculateBuyPrice(uint256 totalSupply, uint256 reserveBalance, uint32 reserveRatio, uint256 depositAmount) external view returns (uint256);
    function calculateSellPrice(uint256 totalSupply, uint256 reserveBalance, uint32 reserveRatio, uint256 sellAmount) external view returns (uint256);
}

interface IToken {
    function totalSupply() external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address owner) external view returns (uint256);
    function approve(address spender, uint256 value) external;
    function allowance(address owner, address spender) external view returns (uint256);
}

interface ITokenReceiver {
    function receiveApproval(address from, uint256 value, address token, bytes data) external;
}

contract AdminControl {
    address public owner;
    mapping(address => bool) public admins;

    constructor() public {
        owner = msg.sender;
        admins[owner] = true;
    }

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender] || owner == msg.sender);
        _;
    }

    function addAdmin(address admin) onlyOwner public {
        _addAdmin(admin);
    }

    function _addAdmin(address admin) internal {
        admins[admin] = true;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }

    function revokeAdminStatus(address admin) onlyOwner public {
        admins[admin] = false;
    }
}

contract TokenExchange is AdminControl, ITokenReceiver {
    bool public tradingEnabled = false;
    IPriceCalculator public priceCalculator;
    uint32 public buyFee = 5000;
    uint32 public sellFee = 5000;
    IToken public token;

    event Buy(address indexed buyer, uint256 etherAmount, uint256 tokenAmount);
    event Sell(address indexed seller, uint256 tokenAmount, uint256 etherAmount);

    function depositTokens(uint tokenAmount) onlyOwner public {
        token.transferFrom(msg.sender, this, tokenAmount);
    }

    function enableTrading() onlyAdmin public {
        tradingEnabled = true;
    }

    function disableTrading() onlyAdmin public {
        tradingEnabled = false;
    }

    function setBuyFee(uint fee) onlyAdmin public {
        require(fee > 0 && fee <= 1000000);
        buyFee = uint32(fee);
    }

    function setSellFee(uint fee) onlyAdmin public {
        require(fee >= 0 && fee <= 1000000);
        sellFee = uint32(fee);
    }

    function setPriceCalculator(address calculator) onlyAdmin public {
        priceCalculator = IPriceCalculator(calculator);
    }

    function buyTokens(uint minTokens) public payable {
        uint tokenAmount = priceCalculator.calculateBuyPrice(
            token.totalSupply(),
            address(this).balance - msg.value,
            buyFee,
            msg.value
        );

        tokenAmount = tokenAmount - ((tokenAmount * buyFee) / 1000000);
        require(tokenAmount >= minTokens);
        require(token.balanceOf(this) >= tokenAmount);

        emit Buy(msg.sender, msg.value, tokenAmount);
        token.transfer(msg.sender, tokenAmount);
    }

    function sellTokens(uint tokenAmount, uint minEther) public {
        uint etherAmount = priceCalculator.calculateSellPrice(
            token.totalSupply(),
            address(this).balance,
            sellFee,
            tokenAmount
        );

        etherAmount = etherAmount - ((etherAmount * sellFee) / 1000000);
        require(tradingEnabled);
        require(etherAmount >= minEther);
        require(etherAmount <= address(this).balance);

        token.transferFrom(msg.sender, this, tokenAmount);
        emit Sell(msg.sender, tokenAmount, etherAmount);
        msg.sender.transfer(etherAmount);
    }

    function receiveApproval(address from, uint256 value, address tokenAddress, bytes data) external {
        _sellTokens(from, value, 0);
    }

    function _sellTokens(address seller, uint tokenAmount, uint minEther) internal {
        uint etherAmount = priceCalculator.calculateSellPrice(
            token.totalSupply(),
            address(this).balance,
            sellFee,
            tokenAmount
        );

        etherAmount = etherAmount - ((etherAmount * sellFee) / 1000000);
        require(tradingEnabled);
        require(etherAmount >= minEther);
        require(etherAmount <= address(this).balance);

        token.transferFrom(seller, this, tokenAmount);
        emit Sell(seller, tokenAmount, etherAmount);
        seller.transfer(etherAmount);
    }
}
```