```solidity
pragma solidity ^0.4.18;

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

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract ERC20Basic {
    function transfer(address to, uint256 value) public returns (bool);
    function balanceOf(address who) public view returns (uint256);
}

contract TokenVesting {
    using SafeMath for uint256;

    ERC20Basic public token;
    address public beneficiary;
    uint256 public start;
    uint256 public duration;
    uint256 public released;

    function TokenVesting(address _beneficiary, uint256 _start, uint256 _duration) public {
        require(_beneficiary != address(0));
        beneficiary = _beneficiary;
        start = _start;
        duration = _duration;
    }

    function release() public {
        uint256 unreleased = releasableAmount();
        require(unreleased > 0);
        released = released.add(unreleased);
        token.transfer(beneficiary, unreleased);
    }

    function releasableAmount() public view returns (uint256) {
        return vestedAmount().sub(released);
    }

    function vestedAmount() public view returns (uint256) {
        uint256 currentBalance = token.balanceOf(this);
        uint256 totalBalance = currentBalance.add(released);

        if (now < start) {
            return 0;
        } else if (now >= start.add(duration)) {
            return totalBalance;
        } else {
            return totalBalance.mul(now.sub(start)).div(duration);
        }
    }
}

contract Crowdsale is Ownable {
    using SafeMath for uint256;

    ERC20Basic public token;
    uint256 public rate;
    uint256 public weiRaised;

    function Crowdsale(uint256 _rate, address _wallet, ERC20Basic _token) public {
        require(_rate > 0);
        require(_wallet != address(0));
        require(_token != address(0));

        rate = _rate;
        wallet = _wallet;
        token = _token;
    }

    function () external payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(msg.value != 0);

        uint256 weiAmount = msg.value;
        uint256 tokens = weiAmount.mul(rate);

        weiRaised = weiRaised.add(weiAmount);

        token.transfer(beneficiary, tokens);
        forwardFunds();
    }

    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}
```