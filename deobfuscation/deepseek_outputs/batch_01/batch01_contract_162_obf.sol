```solidity
pragma solidity 0.5.11;

interface IFundReceiver {
    function fund(address customer, uint8 plan) external payable;
}

interface IInvestmentManager {
    function invest(address customer, address target, uint256 amount, uint8 plan) external returns (bool);
}

interface IInvestable {
    function invest() external payable;
}

contract InvestmentPlatform is IInvestmentManager, IFundReceiver {
    mapping(address => uint256) public balances;
    mapping(address => bool) private approvedTargets;
    
    address public owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function fund(address customer, uint8 plan) external payable {
        balances[customer] += msg.value;
        emit CustomerFunded(msg.sender, customer, plan, now);
    }
    
    function invest(address customer, address target, uint256 amount, uint8 plan) external returns (bool) {
        require(approvedTargets[target]);
        
        if (balances[customer] < amount) {
            return false;
        }
        
        balances[customer] -= amount;
        IInvestable(target).invest.value(amount)();
        
        emit Invest(customer, target, amount, plan, now);
        return true;
    }
    
    function withdraw(uint256 amount) public {
        uint256 withdrawAmount = amount;
        
        if (amount == 0) {
            withdrawAmount = balances[msg.sender];
        }
        
        require(withdrawAmount > 0);
        require(withdrawAmount <= balances[msg.sender]);
        
        balances[msg.sender] -= withdrawAmount;
        msg.sender.transfer(amount);
        
        emit Withdraw(msg.sender, amount, now);
    }
    
    function enableInvestTarget(address target) public {
        require(msg.sender == owner);
        approvedTargets[target] = true;
        emit InvestTargetEnabled(target, now);
    }
    
    function disableInvestTarget(address target) public {
        require(msg.sender == owner);
        approvedTargets[target] = true;
        emit InvestTargetDisabled(target, now);
    }
    
    event CustomerFunded(
        address indexed funder,
        address indexed customer,
        uint8 indexed plan,
        uint256 timestamp
    );
    
    event Invest(
        address indexed customer,
        address indexed target,
        uint256 amount,
        uint8 plan,
        uint256 timestamp
    );
    
    event Withdraw(
        address indexed customer,
        uint256 amount,
        uint256 timestamp
    );
    
    event InvestTargetEnabled(
        address indexed target,
        uint256 timestamp
    );
    
    event InvestTargetDisabled(
        address indexed target,
        uint256 timestamp
    );
}
```