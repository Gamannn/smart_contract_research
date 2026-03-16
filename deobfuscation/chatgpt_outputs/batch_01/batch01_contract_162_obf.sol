pragma solidity 0.5.11;

interface ICustomerFunding {
    function fundCustomer(address customer, uint8 category) external payable;
}

interface IInvestment {
    function invest(address customer, address target, uint256 amount, uint8 category) external returns (bool);
}

interface IInvestmentTarget {
    function receiveInvestment() external payable;
}

contract InvestmentPlatform is IInvestment, ICustomerFunding {
    mapping(address => uint256) public customerBalances;
    mapping(address => bool) private approvedTargets;
    address private owner;

    constructor() public {
        owner = msg.sender;
    }

    function fundCustomer(address customer, uint8 category) external payable {
        customerBalances[customer] += msg.value;
        emit OnCustomerFunded(msg.sender, customer, category, now);
    }

    function invest(address customer, address target, uint256 amount, uint8 category) external returns (bool) {
        require(approvedTargets[target], "Target not approved");
        if (customerBalances[customer] < amount) return false;
        customerBalances[customer] -= amount;
        IInvestmentTarget(target).receiveInvestment.value(amount)();
        emit OnInvest(customer, target, amount, category, now);
        return true;
    }

    function withdraw(uint256 amount) public {
        uint256 withdrawalAmount = amount;
        if (amount == 0) withdrawalAmount = customerBalances[msg.sender];
        require(withdrawalAmount > 0, "Insufficient balance");
        require(withdrawalAmount <= customerBalances[msg.sender], "Withdrawal amount exceeds balance");
        customerBalances[msg.sender] -= withdrawalAmount;
        msg.sender.transfer(withdrawalAmount);
        emit OnWithdraw(msg.sender, withdrawalAmount, now);
    }

    function enableInvestmentTarget(address target) public {
        require(msg.sender == owner, "Only owner can enable targets");
        approvedTargets[target] = true;
        emit OnInvestTargetEnabled(target, now);
    }

    function disableInvestmentTarget(address target) public {
        require(msg.sender == owner, "Only owner can disable targets");
        approvedTargets[target] = false;
        emit OnInvestTargetDisabled(target, now);
    }

    event OnCustomerFunded(
        address indexed funder,
        address indexed customer,
        uint8 indexed category,
        uint256 timestamp
    );

    event OnInvest(
        address indexed customer,
        address indexed target,
        uint256 amount,
        uint8 category,
        uint256 timestamp
    );

    event OnWithdraw(
        address indexed customer,
        uint256 amount,
        uint256 timestamp
    );

    event OnInvestTargetEnabled(
        address indexed target,
        uint256 timestamp
    );

    event OnInvestTargetDisabled(
        address indexed target,
        uint256 timestamp
    );
}