```solidity
pragma solidity ^0.4.18;

contract Ox5815776c8a71e2b0c90b5aafdbb8ddde007baa13 {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public minDeposit;
    
    address public owner;
    uint256 public minimumTarget;
    
    event Reserved(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function Ox5815776c8a71e2b0c90b5aafdbb8ddde007baa13() public {
        owner = msg.sender;
        minDeposit[owner] = minimumTarget;
    }
    
    function setMinimumTarget(uint256 _minimumTarget) public onlyOwner returns (bool) {
        minimumTarget = _minimumTarget;
        return true;
    }
    
    function setMinDeposit(uint256 _minDeposit) public returns (bool) {
        if (_minDeposit < minimumTarget || balances[msg.sender] <= 0) {
            revert();
        }
        minDeposit[msg.sender] = _minDeposit;
        return true;
    }
    
    function withdraw(uint256 _amount) public returns (bool) {
        if (_amount <= 0 || 
            balances[msg.sender] < minDeposit[msg.sender] || 
            balances[msg.sender] < _amount) {
            revert();
        }
        
        balances[msg.sender] -= _amount;
        uint256 fee = _amount * 2 / 100;
        balances[owner] += fee;
        
        msg.sender.transfer(_amount - fee);
        Withdrawn(msg.sender, _amount);
        return true;
    }
    
    function deposit() private {
        balances[msg.sender] += msg.value;
        minDeposit[msg.sender] = minimumTarget;
        Reserved(msg.sender, msg.value);
    }
    
    function () payable public {
        deposit();
    }
}
```