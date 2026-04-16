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
    uint256 constant public RATE = 7000000;
    uint256 constant public START_TIME = 1520972971;
    uint256 constant public END_TIME = 1552508971;
    mapping (address => uint256) public contributions;
    bool private paused = false;
    uint256 public totalContributions = 0;

    event LandsPurchased(address indexed purchaser, uint256 amount);
    event LandsRedeemed(address indexed redeemer, uint256 amount);

    function buyLands() payable public {
        require(now > START_TIME);
        require(now < END_TIME);
        require(!paused);
        require(msg.value >= getCurrentPrice());

        contributions[msg.sender] += 5;
        totalContributions += 5;
        LandsPurchased(msg.sender, msg.value);
    }

    function buySingleLand() payable public {
        require(now > START_TIME);
        require(now < END_TIME);
        require(!paused);
        require(msg.value >= getCurrentPrice());

        contributions[msg.sender] += 1;
        totalContributions += 1;
        LandsPurchased(msg.sender, msg.value);
    }

    function redeemLands(address redeemer) public onlyOwner returns(uint256) {
        require(!paused);
        require(contributions[redeemer] > 0);

        LandsRedeemed(redeemer, contributions[redeemer]);
        uint256 redeemedAmount = contributions[redeemer];
        contributions[redeemer] = 0;
        return redeemedAmount;
    }

    function getCurrentPrice() view public returns(uint256) {
        return (totalContributions + 1) * RATE;
    }

    function withdrawFunds() onlyOwner public {
        owner.transfer(this.balance);
    }

    function pause() onlyOwner public {
        paused = true;
    }

    function unpause() onlyOwner public {
        paused = false;
    }

    function isPaused() public view returns(bool) {
        return paused;
    }
}