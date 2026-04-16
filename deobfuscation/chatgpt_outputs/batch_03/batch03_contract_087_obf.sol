pragma solidity ^0.4.18;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract TimedCrowdsale {
    using SafeMath for uint256;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public rate;
    address public wallet;

    function TimedCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
        require(_startTime >= now);
        require(_endTime >= _startTime);
        require(_rate > 0);
        require(_wallet != 0x0);

        startTime = _startTime;
        endTime = _endTime;
        rate = _rate;
        wallet = _wallet;
    }

    function validPurchase() internal constant returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

    function hasEnded() public constant returns (bool) {
        return now > endTime;
    }
}

contract CappedCrowdsale is TimedCrowdsale {
    using SafeMath for uint256;

    uint256 public cap;

    function CappedCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, uint256 _cap) public
        TimedCrowdsale(_startTime, _endTime, _rate, _wallet)
    {
        require(_cap > 0);
        cap = _cap;
    }

    function validPurchase() internal constant returns (bool) {
        bool withinCap = msg.value.add(weiRaised) <= cap;
        return super.validPurchase() && withinCap;
    }

    function hasEnded() public constant returns (bool) {
        bool capReached = weiRaised >= cap;
        return super.hasEnded() || capReached;
    }
}

contract Token {
    function transfer(address to, uint256 value) public returns (bool);
}

contract TokenSale is CappedCrowdsale, Ownable {
    using SafeMath for uint256;

    Token public token;
    uint256 public weiRaised;
    uint256 public minContribution;

    function TokenSale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, uint256 _cap, uint256 _minContribution, address _tokenAddress) public
        CappedCrowdsale(_startTime, _endTime, _rate, _wallet, _cap)
    {
        require(_minContribution > 0);
        require(_tokenAddress != 0x0);

        minContribution = _minContribution;
        token = Token(_tokenAddress);
    }

    function () payable public {
        buyTokens(msg.sender);
    }

    function buyTokens(address beneficiary) public payable {
        require(beneficiary != 0x0);
        require(validPurchase());
        require(msg.value >= minContribution);

        uint256 weiAmount = msg.value;
        uint256 tokens = weiAmount.mul(rate);

        weiRaised = weiRaised.add(weiAmount);

        token.transfer(beneficiary, tokens);
        forwardFunds();
    }

    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    function updateWallet(address _wallet) onlyOwner public {
        wallet = _wallet;
    }

    function finalize() onlyOwner public {
        selfdestruct(wallet);
    }
}