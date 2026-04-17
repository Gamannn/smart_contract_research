```solidity
pragma solidity ^0.5.2;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract TokenDistribution {
    using SafeMath for uint256;
    
    address public owner;
    address public tokenAddress;
    address[] public investors;
    uint256 public rate = 0;
    uint256 public totalRemaining;
    
    event Distr(address indexed to, uint256 amount);
    event DistrFinished();
    event crowdsaleFinished();
    
    bool public distributionFinished = false;
    bool public crowdsaleFinished = false;
    
    uint256 public selfdropValue = 1000000000000000;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier notFinished() {
        require(!distributionFinished);
        _;
    }
    
    modifier crowdsaleNotFinished() {
        require(!crowdsaleFinished);
        _;
    }
    
    modifier notBlacklisted() {
        require(!blacklist[msg.sender]);
        _;
    }
    
    mapping(address => bool) public blacklist;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function setTokenAddress(address _tokenAddress) public onlyOwner {
        require(_tokenAddress != address(0));
        tokenAddress = _tokenAddress;
        totalRemaining = IERC20(tokenAddress).balanceOf(address(this));
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    
    function startDistribution() public onlyOwner returns (bool) {
        distributionFinished = false;
        return true;
    }
    
    function startCrowdsale() public onlyOwner returns (bool) {
        crowdsaleFinished = false;
        return true;
    }
    
    function finishDistribution() public onlyOwner crowdsaleNotFinished returns (bool) {
        distributionFinished = true;
        emit DistrFinished();
        return true;
    }
    
    function finishCrowdsale() public notFinished returns (bool) {
        crowdsaleFinished = true;
        emit crowdsaleFinished();
        return true;
    }
    
    function distribute(address recipient, uint256 amount) private returns (bool) {
        totalRemaining = totalRemaining.sub(amount);
        IERC20(tokenAddress).transfer(recipient, amount);
        emit Distr(recipient, amount);
        
        if (totalRemaining == 0) {
            distributionFinished = true;
            crowdsaleFinished = true;
        }
        
        return true;
    }
    
    function setSelfdropValue(uint256 value) public notFinished {
        selfdropValue = value;
    }
    
    function() external payable {
        if(msg.value == 0) {
            getSelfdropTokens();
        } else {
            buyTokens();
        }
    }
    
    function getSelfdropTokens() internal crowdsaleNotFinished notBlacklisted {
        require(selfdropValue != 0);
        
        uint256 toGive = selfdropValue;
        if (toGive > totalRemaining) {
            toGive = totalRemaining;
        }
        
        require(toGive <= totalRemaining);
        require(toGive > 0);
        
        address recipient = msg.sender;
        distribute(recipient, toGive);
        
        if (toGive > 0) {
            blacklist[recipient] = true;
        }
    }
    
    function setRate(uint256 _rate) public onlyOwner {
        rate = _rate;
    }
    
    function buyTokens() public payable notFinished {
        require(msg.value >= 0.001 ether);
        require(rate > 0);
        
        uint256 value = msg.value;
        uint256 tokens = value.mul(rate);
        
        require(totalRemaining >= tokens);
        
        address recipient = msg.sender;
        uint256 toGive = tokens;
        
        distribute(recipient, toGive);
        
        if(msg.value > 0) {
            investors.push(msg.sender);
        }
    }
    
    function withdrawTokens() public onlyOwner {
        IERC20(tokenAddress).transfer(owner, IERC20(tokenAddress).balanceOf(address(this)));
    }
    
    function withdrawEther() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }
}
```