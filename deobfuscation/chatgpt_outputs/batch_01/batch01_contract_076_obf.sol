pragma solidity ^0.4.18;

interface Token {
    function transfer(address receiver, uint amount) external;
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

contract Presale is Ownable {
    using SafeMath for uint256;

    Token public tokenReward;
    mapping(address => uint256) public balanceOf;
    uint256 public fundingGoal;
    uint256 public amountRaised;
    uint256 public deadline;
    uint256 public price;
    uint256 public bonus;
    uint256 public usdPrice;
    bool public fundingGoalReached = false;
    bool public crowdsaleClosed = false;
    address public beneficiary;

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

    function Presale(
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint durationInMinutes,
        uint tokensPerDollar,
        uint bonusInPercent,
        address addressOfTokenUsedAsReward
    ) public {
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers.mul(1 ether);
        deadline = now.add(durationInMinutes.mul(1 minutes));
        price = 10**18;
        price = price.div(tokensPerDollar).div(usdPrice);
        bonus = bonusInPercent;
        tokenReward = Token(addressOfTokenUsedAsReward);
    }

    function changeBonus(uint _bonus) public onlyOwner {
        bonus = _bonus;
    }

    function setUSDPrice(uint _usd) public onlyOwner {
        usdPrice = _usd;
    }

    function finishCrowdsale() public onlyOwner {
        deadline = now;
        crowdsaleClosed = true;
    }

    function () public payable {
        require(beneficiary != address(0));
        require(!crowdsaleClosed);
        require(msg.value != 0);

        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;

        uint tokensToSend = amount.div(price).mul(10**18);
        uint tokenToSendWithBonus = tokensToSend.add(tokensToSend.mul(bonus).div(100));

        tokenReward.transfer(msg.sender, tokenToSendWithBonus);
        FundTransfer(msg.sender, amount, true);
    }

    modifier afterDeadline() {
        if (now >= deadline) _;
    }

    function checkGoalReached() public afterDeadline {
        if (amountRaised >= fundingGoal) {
            fundingGoalReached = true;
            GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }

    function safeWithdrawal() public afterDeadline {
        if (!fundingGoalReached) {
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                if (msg.sender.send(amount)) {
                    FundTransfer(msg.sender, amount, false);
                } else {
                    balanceOf[msg.sender] = amount;
                }
            }
        }

        if (fundingGoalReached && beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
                FundTransfer(beneficiary, amountRaised, false);
            } else {
                fundingGoalReached = false;
            }
        }
    }
}

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