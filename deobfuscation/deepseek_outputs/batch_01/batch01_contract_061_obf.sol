```solidity
pragma solidity 0.4.24;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

interface Token {
    function transfer(address to, uint tokens) external;
    function balanceOf(address tokenOwner) external returns (uint balance);
}

contract Ownable {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);
    }
}

contract PrivateSale is Ownable {
    using SafeMath for uint;
    
    mapping(address => address) public referrer;
    mapping(address => uint) public ethContributed;
    mapping(address => uint) public tokensAllocated;
    
    Token public token;
    
    uint public startTime;
    uint public endTime;
    
    uint public firstTierCap = 10000 ether;
    uint public secondTierCap = 30000 ether;
    uint public thirdTierCap = 50000 ether;
    
    uint public firstReferralBonus = 3;
    uint public secondReferralBonus = 2;
    uint public thirdReferralBonus = 1;
    
    uint public softCap = 10000 ether;
    uint public hardCap = 50000 ether;
    
    event tokensBought(address buyer, uint tokens);
    event tokensCalledBack(uint tokens);
    event privateSaleEnded(uint timestamp);
    
    constructor() public {
        startTime = now;
        endTime = now.add(112 days);
        token = Token(0x64d431354f27009965b163f7e6cdb60700ad5d12);
    }
    
    modifier saleActive() {
        require(address(this).balance <= thirdTierCap && now <= endTime);
        _;
    }
    
    function getContribution(address contributor) view public returns(uint) {
        return ethContributed[contributor];
    }
    
    function() public payable saleActive {
        require(msg.value != 0);
        
        uint totalRaised = address(this).balance;
        address buyer = msg.sender;
        uint contribution = msg.value;
        uint tokens;
        
        if(totalRaised <= firstTierCap) {
            tokens = contribution.mul(2000);
        } else if(totalRaised <= secondTierCap && totalRaised > firstTierCap) {
            tokens = contribution.mul(1500);
        } else if(totalRaised <= thirdTierCap && totalRaised > secondTierCap) {
            tokens = contribution.mul(1000);
        }
        
        ethContributed[buyer] = ethContributed[buyer].add(msg.value);
        tokensAllocated[buyer] = tokensAllocated[buyer].add(tokens);
        
        emit tokensBought(buyer, tokens);
    }
    
    function buyWithReferral(address referredBy) public payable saleActive {
        require(msg.sender != referredBy);
        require(msg.value != 0);
        
        uint totalRaised = address(this).balance;
        address buyer = msg.sender;
        uint contribution = msg.value;
        uint tokens;
        
        referrer[buyer] = referredBy;
        
        address level1 = referredBy;
        address level2 = referrer[level1];
        address level3 = referrer[level2];
        
        if(totalRaised <= firstTierCap) {
            tokens = contribution.mul(2000);
        } else if(totalRaised <= secondTierCap && totalRaised > firstTierCap) {
            tokens = contribution.mul(1500);
        } else if(totalRaised <= thirdTierCap && totalRaised > secondTierCap) {
            tokens = contribution.mul(1000);
        }
        
        ethContributed[buyer] = ethContributed[buyer].add(contribution);
        tokensAllocated[buyer] = tokensAllocated[buyer].add(tokens);
        
        uint referralBonus = tokens.div(100).mul(5);
        tokensAllocated[level1] = tokensAllocated[level1].add(referralBonus);
        
        if(level2 != address(0)) {
            uint secondLevelBonus = tokens.div(100).mul(3);
            tokensAllocated[level2] = tokensAllocated[level2].add(secondLevelBonus);
        }
        
        if(level3 != address(0)) {
            uint thirdLevelBonus = tokens.div(100).mul(1);
            tokensAllocated[level3] = tokensAllocated[level3].add(thirdLevelBonus);
        }
        
        emit tokensBought(buyer, tokens);
    }
    
    modifier saleEnded() {
        require(now > endTime);
        _;
    }
    
    modifier softCapNotReached() {
        require(now > endTime && address(this).balance < softCap);
        _;
    }
    
    function claimTokens() public {
        uint tokens = tokensAllocated[msg.sender];
        require(tokens > 0);
        
        token.transfer(msg.sender, tokens);
        tokensAllocated[msg.sender] = 0;
    }
    
    function refund() public softCapNotReached {
        uint contribution = ethContributed[msg.sender];
        require(contribution > 0);
        
        msg.sender.transfer(contribution);
        ethContributed[msg.sender] = 0;
    }
    
    modifier softCapReached() {
        require(address(this).balance >= softCap);
        _;
    }
    
    function withdrawFunds() public onlyOwner softCapReached {
        uint balance = address(this).balance;
        owner.transfer(balance);
    }
    
    function withdrawUnsoldTokens() public onlyOwner saleEnded {
        uint unsoldTokens = token.balanceOf(address(this));
        token.transfer(owner, unsoldTokens);
    }
}
```