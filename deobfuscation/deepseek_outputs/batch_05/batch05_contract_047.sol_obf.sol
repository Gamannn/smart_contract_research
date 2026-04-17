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
    uint256 public constant RATE = 3000;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public weiRaised;
    uint256 public cap;
    uint256 public goal;
    uint256 public initialTokens;
    bool public isFinalized = false;
    bool public isInitialized = false;

    function Crowdsale() {
        startTime = 1504357200;
        endTime = startTime.add(30 days);
        cap = 2000 ether;
        goal = 1000 ether;
        initialTokens = 6000000 * 10**18;
    }

    function initialize() onlyOwner {
        require(isInitialized == false);
        require(token.balanceOf(this) == initialTokens);
        isInitialized = true;
    }

    function isActive() constant returns (bool) {
        return (
            isInitialized == true &&
            now >= startTime &&
            now <= endTime &&
            weiRaised < cap
        );
    }

    function goalReached() constant returns (bool) {
        return (weiRaised >= goal);
    }

    function () payable {
        buyTokens();
    }

    function tokenBalance() constant returns (uint256) {
        return token.balanceOf(this);
    }

    function buyTokens() payable {
        require(isActive());
        require(msg.value > 0);

        uint256 weiAmount = msg.value;
        uint256 tokens = weiAmount.mul(RATE);

        weiRaised = weiRaised.add(weiAmount);
        require(token.transfer(msg.sender, tokens));
    }

    function finalize() onlyOwner {
        require(!isFinalized);
        require(now > endTime || weiRaised >= cap);

        uint256 balance = token.balanceOf(this);
        assert(balance > 0);
        token.transfer(owner, balance);

        owner.transfer(this.balance);
        isFinalized = true;
    }
}