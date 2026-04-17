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
    bool public isFinalized = false;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public cap;
    uint256 public weiRaised;

    function Crowdsale(address _tokenAddress, uint256 _startTime, uint256 _endTime, uint256 _cap) {
        require(_tokenAddress != address(0));
        require(_startTime >= now);
        require(_endTime >= _startTime);
        require(_cap > 0);

        token = Token(_tokenAddress);
        startTime = _startTime;
        endTime = _endTime;
        cap = _cap;
    }

    function () payable {
        buyTokens();
    }

    function buyTokens() public payable {
        require(validPurchase());

        uint256 weiAmount = msg.value;
        uint256 tokens = weiAmount.mul(RATE);

        weiRaised = weiRaised.add(weiAmount);

        token.transfer(msg.sender, tokens);
        owner.transfer(msg.value);
    }

    function validPurchase() internal constant returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        bool withinCap = weiRaised.add(msg.value) <= cap;

        return withinPeriod && nonZeroPurchase && withinCap;
    }

    function hasEnded() public constant returns (bool) {
        return now > endTime || weiRaised >= cap;
    }

    function finalize() onlyOwner {
        require(!isFinalized);
        require(hasEnded());

        uint256 remainingTokens = token.balanceOf(this);
        if (remainingTokens > 0) {
            token.transfer(owner, remainingTokens);
        }

        isFinalized = true;
    }
}