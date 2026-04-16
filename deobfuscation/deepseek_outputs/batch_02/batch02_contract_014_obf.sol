```solidity
pragma solidity ^0.4.18;

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

contract PreSale is Ownable {
    uint256 constant public INCREASE_RATE = 700000000000000;
    uint256 constant public START_TIME = 1520972971;
    uint256 constant public END_TIME = 1552508971;
    
    mapping(address => uint256) public landsPurchased;
    uint256 public landsSold;
    bool public paused;
    
    event landsPurchased(address indexed buyer, uint256 value);
    event landsRedeemed(address indexed buyer, uint256 amount);
    
    function PreSale() public {
        paused = false;
    }
    
    function buyLand5() payable public {
        require(now > START_TIME);
        require(now < END_TIME);
        require(paused == false);
        require(msg.value >= getCurrentPrice());
        
        landsPurchased[msg.sender] = landsPurchased[msg.sender] + 5;
        landsSold = landsSold + 5;
        
        landsPurchased(msg.sender, msg.value);
    }
    
    function buyLand1() payable public {
        require(now > START_TIME);
        require(now < END_TIME);
        require(paused == false);
        require(msg.value >= getCurrentPrice());
        
        landsPurchased[msg.sender] = landsPurchased[msg.sender] + 1;
        landsSold = landsSold + 1;
        
        landsPurchased(msg.sender, msg.value);
    }
    
    function redeemLand(address target) public onlyOwner returns(uint256) {
        require(paused == false);
        require(landsPurchased[target] > 0);
        
        landsRedeemed(target, landsPurchased[target]);
        uint256 amount = landsPurchased[target];
        landsPurchased[target] = 0;
        
        return amount;
    }
    
    function getCurrentPrice() view public returns(uint256) {
        return (landsSold + 1) * INCREASE_RATE;
    }
    
    function getNextPrice() view public returns(uint256) {
        return (landsSold) * INCREASE_RATE;
    }
    
    function withdraw() onlyOwner public {
        owner.transfer(this.balance);
    }
    
    function pause() onlyOwner public {
        paused = true;
    }
    
    function unpause() onlyOwner public {
        paused = false;
    }
    
    function isPaused() onlyOwner public view returns(bool) {
        return paused;
    }
}
```