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
    function balanceOf(address owner) constant returns (uint256);
}

contract Crowdsale is Ownable {
    using SafeMath for uint256;

    Token public token;
    uint256 public constant RATE = 3000;
    uint256 public constant START = 1504357200;
    uint256 public constant DURATION = 30 days;
    uint256 public constant GOAL = 6000000 * 10**18;
    uint256 public constant CAP = 2000 * 1 ether;
    uint256 public raisedAmount;
    bool public isFinalized = false;

    function Crowdsale(address _tokenAddress) {
        token = Token(_tokenAddress);
    }

    function isActive() constant returns (bool) {
        return (now >= START && now <= START.add(DURATION) && !isFinalized);
    }

    function hasEnded() constant returns (bool) {
        return (raisedAmount >= CAP);
    }

    function () payable {
        buyTokens();
    }

    function buyTokens() internal {
        require(isActive());
        uint256 tokens = msg.value.mul(RATE);
        raisedAmount = raisedAmount.add(msg.value);
        token.transfer(msg.sender, tokens);
    }

    function finalize() onlyOwner {
        require(!isFinalized);
        require(hasEnded());

        uint256 remainingTokens = token.balanceOf(this);
        assert(remainingTokens > 0);
        token.transfer(owner, remainingTokens);
        selfdestruct(owner);
    }
}