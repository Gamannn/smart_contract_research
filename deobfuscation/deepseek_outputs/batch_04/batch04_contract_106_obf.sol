```solidity
pragma solidity ^0.4.15;

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;
    
    function Ownable() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}

interface Token {
    function transfer(address to, uint256 value) returns (bool);
    function balanceOf(address who) constant returns (uint256);
}

contract Crowdsale is Ownable {
    using SafeMath for uint256;
    
    Token public token;
    uint256 public constant RATE = 2200;
    
    uint256 public tokensRaised;
    bool public initialized;
    uint256 public startTime;
    uint256 public duration;
    uint256 public hardCap;
    uint256 public tokensAvailable;
    
    function initialize() onlyOwner {
        require(initialized == false);
        require(tokensAvailable > 0);
        initialized = true;
        startTime = now;
    }
    
    function isActive() constant returns (bool) {
        return (
            initialized == true &&
            now >= startTime &&
            now <= startTime.add(duration * 1 days) &&
            isGoalReached() == false
        );
    }
    
    function isGoalReached() constant returns (bool) {
        return (tokensRaised >= hardCap * 1 ether);
    }
    
    function () payable {
        buyTokens();
    }
    
    function getTokenBalance() constant returns (uint256) {
        return token.balanceOf(this);
    }
    
    function buyTokens() onlyOwner {
        uint256 tokensToBuy = msg.value.mul(RATE);
        require(isActive());
        require(tokensToBuy > 0);
        require(tokensRaised.add(tokensToBuy) <= hardCap * 1 ether);
        
        tokensRaised = tokensRaised.add(tokensToBuy);
        require(token.transfer(msg.sender, tokensToBuy));
    }
    
    function withdrawTokens() onlyOwner {
        uint256 balance = token.balanceOf(this);
        assert(balance > 0);
        require(token.transfer(owner, balance));
        selfdestruct(owner);
    }
}
```