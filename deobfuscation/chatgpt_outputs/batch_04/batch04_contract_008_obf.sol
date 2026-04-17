```solidity
pragma solidity ^0.5.2;

contract TokenInterface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address account) public view returns (uint256);
    function allowance(address owner, address spender) public view returns (uint256);
    function transfer(address recipient, uint256 amount) public returns (bool);
    function approve(address spender, uint256 amount) public returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool);
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

contract Crowdsale {
    using SafeMath for uint256;

    address public owner;
    address public tokenAddress;
    uint256 public rate;
    uint256 public totalRemaining;
    bool public distributionFinished;
    bool public crowdsaleFinished;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier canDistribute() {
        require(!distributionFinished);
        _;
    }

    modifier canCrowdsale() {
        require(!crowdsaleFinished);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function setTokenAddress(address _tokenAddress) public onlyOwner {
        require(_tokenAddress != address(0));
        tokenAddress = _tokenAddress;
        totalRemaining = TokenInterface(tokenAddress).balanceOf(address(this));
    }

    function startDistribution() public onlyOwner returns (bool) {
        distributionFinished = false;
        return true;
    }

    function startCrowdsale() public onlyOwner returns (bool) {
        crowdsaleFinished = false;
        return true;
    }

    function finishDistribution() public onlyOwner canDistribute returns (bool) {
        distributionFinished = true;
        emit DistributionFinished();
        return true;
    }

    function finishCrowdsale() public onlyOwner canCrowdsale returns (bool) {
        crowdsaleFinished = true;
        emit CrowdsaleFinished();
        return true;
    }

    function distributeTokens(address recipient, uint256 amount) private returns (bool) {
        totalRemaining = totalRemaining.sub(amount);
        TokenInterface(tokenAddress).transfer(recipient, amount);
        emit Distribution(recipient, amount);
        if (totalRemaining == 0) {
            distributionFinished = true;
            crowdsaleFinished = true;
        }
        return true;
    }

    function setRate(uint256 _rate) public onlyOwner {
        rate = _rate;
    }

    function () external payable {
        if (msg.value == 0) {
            distributeSelfDrop();
        } else {
            buyTokens();
        }
    }

    function distributeSelfDrop() internal canDistribute {
        require(rate != 0);
        uint256 amount = rate;
        if (amount > totalRemaining) {
            amount = totalRemaining;
        }
        require(amount <= totalRemaining);
        distributeTokens(msg.sender, amount);
    }

    function buyTokens() public payable canCrowdsale {
        require(msg.value >= 0.001 ether);
        require(rate > 0);
        uint256 tokens = msg.value.mul(rate);
        require(totalRemaining >= tokens);
        distributeTokens(msg.sender, tokens);
        if (msg.value > 0) {
            owner.transfer(msg.value);
        }
    }

    function withdrawTokens() public onlyOwner {
        TokenInterface(tokenAddress).transfer(owner, TokenInterface(tokenAddress).balanceOf(address(this)));
    }

    function withdrawEther() public onlyOwner {
        owner.transfer(address(this).balance);
    }

    event DistributionFinished();
    event CrowdsaleFinished();
    event Distribution(address indexed to, uint256 amount);
}
```