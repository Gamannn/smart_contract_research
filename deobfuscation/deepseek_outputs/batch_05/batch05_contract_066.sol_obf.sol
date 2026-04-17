```solidity
pragma solidity ^0.4.25;

contract Ownable {
    address public owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract ERC20 {
    function transfer(address to, uint256 value) public returns (bool);
    function balanceOf(address who) public view returns (uint256);
}

contract PreICO is Ownable {
    ERC20 public token;
    ERC20 public whitelist;
    
    address public admin = msg.sender;
    address public treasury;
    
    mapping(address => uint256) public invested;
    
    uint256 public startTime = 1543700145;
    uint256 public endTime = 1547510400;
    uint256 public weiRaised;
    
    uint256 public euroPrice;
    uint256 public tokenPrice;
    uint256 public hardCap = 10000000 * 1e18;
    uint256 public bountyPool;
    uint256 public soldTokens;
    
    modifier onlyAdmin() {
        require(msg.sender == admin || msg.sender == owner);
        _;
    }
    
    constructor() public {
        token = ERC20(0x4257c4a305085bf7b75c5885f75152fb63adf958);
        whitelist = ERC20(0x603e90eed7de8a6d3f5d392ab1c07a1c6e42f95a);
        treasury = 0xd048afdd7f3fd420709aeafff9f27722e96ee924;
        euroPrice = 1000000000000000000;
        tokenPrice = (1e18 / euroPrice) * 10;
    }
    
    function setStartTime(uint256 newStartTime) public onlyAdmin {
        startTime = newStartTime;
    }
    
    function setEndTime(uint256 newEndTime) public onlyAdmin {
        endTime = newEndTime;
    }
    
    function setAdmin(address newAdmin) public onlyAdmin {
        admin = newAdmin;
    }
    
    function setEuroPrice(uint256 newEuroPrice) public onlyAdmin {
        euroPrice = newEuroPrice;
        tokenPrice = (1e18 / euroPrice) * 10;
    }
    
    function isActive() public view returns(bool) {
        return now >= startTime && now <= endTime;
    }
    
    function () public payable {
        require(whitelist.balanceOf(msg.sender) > 0);
        require(isActive());
        require(msg.value >= tokenPrice * 100);
        
        buyTokens(msg.sender, msg.value);
        require(soldTokens <= hardCap);
        
        invested[msg.sender] += msg.value;
    }
    
    function buyTokens(address investor, uint256 weiAmount) internal {
        uint256 tokens = weiAmount * 1e18 / tokenPrice;
        token.transfer(investor, tokens);
        soldTokens += tokens;
        
        uint256 bounty = tokens * 250 / 10000;
        bountyPool += bounty;
        weiRaised += weiAmount;
    }
    
    function transferEthFromContract(address to, uint256 amount) public onlyAdmin {
        to.transfer(amount);
    }
}
```