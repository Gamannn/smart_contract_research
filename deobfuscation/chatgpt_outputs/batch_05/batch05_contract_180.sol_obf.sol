pragma solidity ^0.4.15;

contract TokenInterface {
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function transferAndCall(address to, uint256 value, bytes data) public returns (bool success);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function mul(uint256 a, uint256 b) pure internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) pure internal returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) pure internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) pure internal returns (uint256) {
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

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}

interface TokenRecipient {
    function receiveApproval(address from, uint256 value, address token, bytes extraData) public;
}

contract LikeCoinBrix is TokenInterface, Ownable {
    using SafeMath for uint256;

    string public constant name = "LikeCoin Brix";
    string public constant symbol = "LCB";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function LikeCoinBrix() public {
        totalSupply = 1000000 * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(balanceOf[msg.sender] >= value);

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(balanceOf[from] >= value);
        require(allowance[from][msg.sender] >= value);

        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

    function transferAndCall(address to, uint256 value, bytes data) public returns (bool success) {
        require(transfer(to, value));
        TokenRecipient(to).receiveApproval(msg.sender, value, this, data);
        return true;
    }
}

contract Crowdsale is Ownable {
    using SafeMath for uint256;

    address public beneficiary;
    uint256 public amountRaised;
    uint256 public deadline;
    uint256 public price;
    LikeCoinBrix public tokenReward;
    bool public crowdsaleClosed = false;

    event FundTransfer(address backer, uint256 amount, bool isContribution);

    function Crowdsale(
        address ifSuccessfulSendTo,
        uint256 durationInMinutes,
        uint256 etherCostOfEachToken,
        address addressOfTokenUsedAsReward
    ) public {
        beneficiary = ifSuccessfulSendTo;
        deadline = now + durationInMinutes * 1 minutes;
        price = etherCostOfEachToken * 1 ether;
        tokenReward = LikeCoinBrix(addressOfTokenUsedAsReward);
    }

    function () payable public {
        require(!crowdsaleClosed);
        uint256 amount = msg.value;
        amountRaised = amountRaised.add(amount);
        tokenReward.transfer(msg.sender, amount.div(price));
        FundTransfer(msg.sender, amount, true);
    }

    modifier afterDeadline() { if (now >= deadline) _; }

    function checkGoalReached() afterDeadline public {
        if (amountRaised >= 1000 ether) {
            crowdsaleClosed = true;
        }
    }

    function safeWithdrawal() afterDeadline public {
        if (beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
                FundTransfer(beneficiary, amountRaised, false);
            }
        }
    }
}