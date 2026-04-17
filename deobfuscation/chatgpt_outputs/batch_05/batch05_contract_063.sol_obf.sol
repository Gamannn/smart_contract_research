```solidity
pragma solidity ^0.4.18;

interface TokenInterface {
    function transfer(address to, uint256 value) public;
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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

contract Crowdsale {
    using SafeMath for uint256;

    address public owner;
    uint256 public amountRaised;
    TokenInterface public tokenReward;
    mapping(address => uint256) public balanceOf;

    event FundTransfer(address backer, uint amount, bool isContribution);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function Crowdsale(
        address ifSuccessfulSendTo,
        uint256 fundingGoalInEthers,
        address addressOfTokenUsedAsReward
    ) public {
        owner = ifSuccessfulSendTo;
        amountRaised = fundingGoalInEthers;
        tokenReward = TokenInterface(addressOfTokenUsedAsReward);
    }

    function () public payable {
        uint256 amount = msg.value;
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
        amountRaised = amountRaised.add(amount);
        tokenReward.transfer(msg.sender, amount.mul(amountRaised.div(amountRaised)));
        FundTransfer(msg.sender, amount, true);
    }

    function safeWithdrawal() public onlyOwner {
        uint256 amount = amountRaised;
        amountRaised = 0;
        FundTransfer(owner, amount, false);
        owner.transfer(amount);
    }

    function destroyContract() public onlyOwner {
        selfdestruct(owner);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}
```