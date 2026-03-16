```solidity
pragma solidity ^0.4.15;

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        if (a != 0 && c / a != b) revert();
        return c;
    }
    
    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        if (b > a) revert();
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        if (c < a) revert();
        return c;
    }
}

contract Ownable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    address public owner;
    
    function Ownable() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract IRBPreRefundVault is Ownable {
    using SafeMath for uint256;
    
    enum State { Active, Refunding, Closed }
    
    State public state;
    mapping(address => uint256) public deposited;
    
    address public preCrowdsaleContractAddress;
    address public wallet;
    uint256 public totalDeposited;
    
    event Closed();
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);
    event Withdrawal(address indexed receiver, uint256 weiAmount);
    
    function IRBPreRefundVault() {
        state = State.Active;
        wallet = 0x26dB9eF39Bbfe437f5b384c3913E807e5633E7cE;
    }
    
    modifier onlyCrowdsaleContract() {
        require(msg.sender == preCrowdsaleContractAddress);
        _;
    }
    
    function setPreCrowdsaleAddress(address _preCrowdsaleAddress) external onlyOwner {
        require(_preCrowdsaleAddress != address(0));
        preCrowdsaleContractAddress = _preCrowdsaleAddress;
    }
    
    function deposit(address investor) onlyCrowdsaleContract external payable {
        require(state == State.Active);
        uint256 amount = msg.value;
        deposited[investor] = deposited[investor].add(amount);
        totalDeposited = totalDeposited.add(amount);
    }
    
    function close() onlyCrowdsaleContract external {
        require(state == State.Active);
        state = State.Closed;
        totalDeposited = 0;
        Closed();
        wallet.transfer(this.balance);
    }
    
    function enableRefunds() onlyCrowdsaleContract external {
        require(state == State.Active);
        state = State.Refunding;
        RefundsEnabled();
    }
    
    function refund(address investor) public {
        require(state == State.Refunding);
        uint256 depositedValue = deposited[investor];
        deposited[investor] = 0;
        investor.transfer(depositedValue);
        Refunded(investor, depositedValue);
    }
    
    function withdraw(uint256 amount) onlyCrowdsaleContract external returns (bool success) {
        require(state == State.Active);
        require(totalDeposited >= amount);
        totalDeposited = totalDeposited.sub(amount);
        wallet.transfer(amount);
        Withdrawal(wallet, amount);
        return true;
    }
    
    function kill() onlyOwner {
        require(state == State.Closed);
        selfdestruct(owner);
    }
}
```