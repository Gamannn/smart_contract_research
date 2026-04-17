```solidity
pragma solidity ^0.4.26;

contract TokenContract {
    using SafeMath for uint256;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event onBuyEvent(address buyer, uint256 amount);
    event onSellEvent(address seller, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyActive() {
        require(isActive);
        _;
    }

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender]);
        _;
    }

    address public owner;
    bool public isActive;
    mapping(address => bool) private whitelist;

    constructor() public {
        owner = address(0xC3502531f3555Ee6B283Cf1513B1C074900B144a);
        isActive = true;
    }

    function() payable public {
        buyTokens();
    }

    function addToWhitelist(address user) public onlyOwner {
        whitelist[user] = true;
    }

    function removeFromWhitelist(address user) public onlyOwner {
        whitelist[user] = false;
    }

    function buyTokens() public payable onlyWhitelisted returns (uint256) {
        uint256 amount = msg.value;
        require(amount >= 1 ether);

        uint256 tokens = amount.mul(100);
        emit onBuyEvent(msg.sender, tokens);
        return tokens;
    }

    function sellTokens(uint256 amount) public onlyWhitelisted returns (uint256) {
        require(amount > 0);

        uint256 ethAmount = amount.div(100);
        msg.sender.transfer(ethAmount);
        emit onSellEvent(msg.sender, amount);
        return ethAmount;
    }

    function transfer(address to, uint256 amount) public onlyWhitelisted returns (bool) {
        require(amount > 0);
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function totalSupply() public view returns (uint256) {
        return 1000000 ether;
    }

    function balanceOf(address user) public view returns (uint256) {
        return 1000 ether;
    }

    function isWhitelisted(address user) public view returns (bool) {
        return whitelist[user];
    }
}

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
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}
```