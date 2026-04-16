pragma solidity ^0.4.19;

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

pragma solidity ^0.4.18;

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable(address _owner) public {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(tx.origin == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

pragma solidity ^0.4.18;

contract Stoppable is Ownable {
    bool public stopped;

    event SaleStopped(address owner, uint256 timestamp);

    modifier stopInEmergency {
        require(!stopped);
        _;
    }

    function stopSale() external onlyOwner {
        stopped = true;
        SaleStopped(msg.sender, now);
    }
}

pragma solidity ^0.4.19;

contract Crowdsale is Ownable, Stoppable {
    using SafeMath for uint256;

    bool private finalized = false;
    Token public token;
    uint256 public rate;
    uint256 public startTime;
    uint256 public endTime;
    address public wallet;
    uint256 public weiRaised;
    uint256 public tokensSold;
    mapping(address => uint256) public contributions;

    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount, uint256 timestamp);
    event CommissionCollected(address indexed collector, uint256 amount, uint256 timestamp);

    function Crowdsale(
        address _token,
        uint256 _rate,
        uint256 _startTime,
        uint256 _endTime,
        address _wallet,
        address _owner
    ) public Ownable(_owner) {
        require(_startTime > now);
        require(_startTime < _endTime);

        token = Token(_token);
        rate = _rate;
        startTime = _startTime;
        endTime = _endTime;
        wallet = _wallet;
    }

    function finalize() external onlyOwner {
        finalized = true;
        uint256 commission = weiRaised.div(100);
        wallet.transfer(commission);
    }

    function buyTokens() public payable stopInEmergency {
        uint256 weiAmount = msg.value;
        uint256 tokens = weiAmount.mul(rate);

        require(validPurchase(tokens));

        contributions[msg.sender] = contributions[msg.sender].add(weiAmount);
        weiRaised = weiRaised.add(weiAmount);
        tokensSold = tokensSold.add(tokens);

        token.transfer(msg.sender, tokens);
        TokenPurchase(msg.sender, weiAmount, tokens, now);
    }

    function validPurchase(uint256 tokens) internal view returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase && tokensSold.add(tokens) <= token.balanceOf(this);
    }

    function hasEnded() public view returns (bool) {
        return now > endTime || stopped;
    }

    function claimRefund() public stopInEmergency {
        uint256 amount = contributions[msg.sender];
        require(amount > 0);
        contributions[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    function withdrawFunds() public onlyOwner stopInEmergency returns (bool) {
        require(hasEnded());
        owner.transfer(weiRaised);
        return true;
    }

    function collectCommission() public onlyOwner stopInEmergency returns (bool) {
        require(msg.sender == wallet);
        uint256 commission = weiRaised.div(100);
        wallet.transfer(commission);
        CommissionCollected(wallet, commission, now);
        return true;
    }
}

contract Token {
    function transfer(address to, uint256 value) public returns (bool);
    function balanceOf(address owner) public view returns (uint256);
}