pragma solidity ^0.4.18;

interface token {
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

contract I2Presale is Ownable {
    using SafeMath for uint256;
    
    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    
    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    
    struct CrowdsaleData {
        bool crowdsaleClosed;
        bool fundingGoalReached;
        uint256 bonus;
        uint256 usd;
        uint256 price;
        uint256 deadline;
        uint256 amountRaised;
        uint256 fundingGoal;
        address beneficiary;
    }
    
    CrowdsaleData public crowdsale;
    
    function I2Presale(
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint durationInMinutes,
        uint tokensPerDollar,
        uint bonusInPercent,
        address addressOfTokenUsedAsReward
    ) public {
        crowdsale.beneficiary = ifSuccessfulSendTo;
        crowdsale.fundingGoal = fundingGoalInEthers.mul(1 ether);
        crowdsale.deadline = now.add(durationInMinutes.mul(1 minutes));
        crowdsale.price = 10**18;
        crowdsale.usd = 1000;
        crowdsale.price = crowdsale.price.div(tokensPerDollar).div(crowdsale.usd);
        crowdsale.bonus = bonusInPercent;
        tokenReward = token(addressOfTokenUsedAsReward);
    }
    
    function changeBonus(uint _bonus) public onlyOwner {
        crowdsale.bonus = _bonus;
    }
    
    function setUSDPrice(uint _usd) public onlyOwner {
        crowdsale.usd = _usd;
    }
    
    function finshCrowdsale() public onlyOwner {
        crowdsale.deadline = now;
        crowdsale.crowdsaleClosed = true;
    }
    
    function () public payable {
        require(crowdsale.beneficiary != address(0));
        require(!crowdsale.crowdsaleClosed);
        require(msg.value != 0);
        
        uint amount = msg.value;
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
        crowdsale.amountRaised = crowdsale.amountRaised.add(amount);
        
        uint tokensToSend = amount.div(crowdsale.price).mul(10**18);
        uint tokenToSendWithBonus = tokensToSend.add(tokensToSend.mul(crowdsale.bonus).div(100));
        
        tokenReward.transfer(msg.sender, tokenToSendWithBonus);
        FundTransfer(msg.sender, amount, true);
    }
    
    modifier afterDeadline() {
        if (now >= crowdsale.deadline) _;
    }
    
    function checkGoalReached() public afterDeadline {
        if (crowdsale.amountRaised >= crowdsale.fundingGoal) {
            crowdsale.fundingGoalReached = true;
            GoalReached(crowdsale.beneficiary, crowdsale.amountRaised);
        }
        crowdsale.crowdsaleClosed = true;
    }
    
    function safeWithdrawal() public afterDeadline {
        if (!crowdsale.fundingGoalReached) {
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
        
        if (crowdsale.fundingGoalReached && crowdsale.beneficiary == msg.sender) {
            if (crowdsale.beneficiary.send(crowdsale.amountRaised)) {
                FundTransfer(crowdsale.beneficiary, crowdsale.amountRaised, false);
            } else {
                crowdsale.fundingGoalReached = false;
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