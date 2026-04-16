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
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
}

contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }
    
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

contract PreICO is Ownable, SafeMath {
    ERC20 public token;
    ERC20 public euroToken;
    
    using SafeMath for uint256;
    
    address public manager = msg.sender;
    address public wallet;
    
    mapping(address => uint256) public investedEther;
    
    uint256 public startTime = 1543700145;
    uint256 public endTime = 1547510400;
    uint256 public weiRaised;
    
    uint256 public euroPrice;
    uint256 public buyPrice;
    uint256 public hardCap = 10000000 * 1e18;
    uint256 public soldTokens;
    uint256 public bounty;
    
    modifier onlyManagerOrOwner() {
        require(msg.sender == manager || msg.sender == owner);
        _;
    }
    
    constructor() public {
        token = ERC20(0xc7f8ae21f634f8eba94a14de0a5e84ca37ea3240);
        euroToken = ERC20(0xb3c662ebd2c2a530fcf536063bc3e7816c85a5be);
        euroPrice = 21127;
        buyPrice = (1e18 / euroPrice).safeMul(10);
    }
    
    function setStartTime(uint256 newStartTime) public onlyManagerOrOwner {
        startTime = newStartTime;
    }
    
    function setEndTime(uint256 newEndTime) public onlyManagerOrOwner {
        endTime = newEndTime;
    }
    
    function setManager(address newManager) public onlyManagerOrOwner {
        manager = newManager;
    }
    
    function setEuroPrice(uint256 newEuroPrice) public onlyManagerOrOwner {
        euroPrice = newEuroPrice;
        buyPrice = (1e18 / euroPrice).safeMul(10);
    }
    
    function isActive() public view returns(bool) {
        return now >= startTime && now <= endTime;
    }
    
    function () public payable {
        require(euroToken.transferFrom(msg.sender, address(this), msg.value));
        require(isActive());
        require(msg.value >= buyPrice.safeMul(100));
        
        buyTokens(msg.sender, msg.value);
        require(soldTokens <= hardCap);
        
        investedEther[msg.sender] = investedEther[msg.sender].safeAdd(msg.value);
    }
    
    function buyTokens(address investor, uint256 euroAmount) internal {
        uint256 tokens = euroAmount.safeMul(1e18).safeDiv(buyPrice);
        token.transfer(investor, tokens);
        soldTokens = soldTokens.safeAdd(tokens);
        bounty = tokens.safeDiv(250);
        weiRaised = weiRaised.safeAdd(euroAmount);
    }
    
    function transferTokens(address to, uint256 amount) public onlyManagerOrOwner {
        token.transfer(to, amount);
    }
    
    function withdrawEther(address to, uint256 amount) public onlyManagerOrOwner {
        to.transfer(amount);
    }
}