pragma solidity ^0.5.8;

contract Ownable {
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    address payable public owner;
    address payable public pendingOwner;
    
    function transferOwnership(address payable newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }
    
    function claimOwnership() public {
        if (msg.sender == pendingOwner) {
            owner = pendingOwner;
        }
    }
}

contract StakingContract is Ownable {
    uint8 public feePercentage;
    uint32 public stakerCount;
    string public website;
    
    mapping (address => uint256) public stakes;
    
    event Staked(address indexed staker, uint256 amount);
    event Transfered(address indexed from, address indexed to, uint256 amount);
    
    function getStake(address staker) view public returns (uint256) {
        return stakes[staker];
    }
    
    function transfer(address to, uint256 amount) public returns (bool) {
        require(to != address(0) && amount > 100 && amount <= stakes[msg.sender]);
        
        stakes[msg.sender] -= amount;
        uint256 fee = calculateFee(amount);
        amount -= fee;
        
        if (stakes[to] == 0) {
            stakerCount++;
        }
        
        stakes[to] += amount;
        emit Transfered(msg.sender, to, amount);
        return true;
    }
    
    function withdraw(uint256 amount) public returns (bool) {
        require(amount > 100 && amount <= stakes[msg.sender]);
        
        stakes[msg.sender] -= amount;
        
        if (msg.sender == owner) {
            owner.transfer(amount);
        } else {
            uint256 fee = calculateFee(amount);
            msg.sender.transfer(amount - fee);
        }
        return true;
    }
    
    function calculateFee(uint256 amount) internal returns (uint256) {
        if (msg.sender == owner) {
            return 0;
        }
        
        uint256 fee = amount * feePercentage / 100;
        owner.transfer(fee);
        return fee;
    }
}

contract EtherBox is StakingContract {
    constructor() public {
        feePercentage = 1;
        stakerCount = 0;
        website = 'www.etherbox.io';
        owner = msg.sender;
    }
    
    function stake() payable external {
        require(msg.value >= 100);
        
        if (stakes[msg.sender] == 0) {
            stakerCount++;
        }
        
        uint256 fee = calculateFee(msg.value);
        stakes[msg.sender] += msg.value - fee;
        emit Staked(msg.sender, msg.value);
    }
}