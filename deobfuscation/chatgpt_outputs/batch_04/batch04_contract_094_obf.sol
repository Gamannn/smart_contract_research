pragma solidity ^0.5.8;

contract OwnerContract {
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    address payable owner;
    address payable newOwner;

    function setNewOwner(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function confirmNewOwner() public {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}

contract StakingContract is OwnerContract {
    uint8 public feePercentage;
    uint32 public totalStakers;
    string public website;
    mapping(address => uint256) public stakes;

    event Staked(address indexed staker, uint256 amount);
    event Transferred(address indexed from, address indexed to, uint256 amount);

    function getStake(address staker) view public returns (uint256) {
        return stakes[staker];
    }

    function transferStake(address to, uint256 amount) public returns (bool) {
        require(to != address(0) && amount > 100 && amount <= stakes[msg.sender]);
        stakes[msg.sender] -= amount;
        amount -= calculateFee(amount);
        if (stakes[to] == 0) totalStakers++;
        stakes[to] += amount;
        emit Transferred(msg.sender, to, amount);
        return true;
    }

    function withdrawStake(uint256 amount) public returns (bool) {
        require(amount > 100 && amount <= stakes[msg.sender]);
        stakes[msg.sender] -= amount;
        if (msg.sender == owner) {
            owner.transfer(amount);
        } else {
            msg.sender.transfer(amount - calculateFee(amount));
        }
        return true;
    }

    function calculateFee(uint256 amount) internal returns (uint256) {
        if (msg.sender == owner) return 0;
        uint256 fee = amount * feePercentage / 100;
        owner.transfer(fee);
        return fee;
    }
}

contract EtherBox is StakingContract {
    constructor() public {
        feePercentage = 1;
        totalStakers = 0;
        website = 'www.etherbox.io';
        owner = msg.sender;
    }

    function() payable external {
        require(msg.value >= 100);
        if (stakes[msg.sender] == 0) totalStakers++;
        stakes[msg.sender] += msg.value - calculateFee(msg.value);
        emit Staked(msg.sender, msg.value);
    }
}