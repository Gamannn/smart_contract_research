pragma solidity 0.5.7;

contract Ownable {
    address public owner;
    address public pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

contract InvestmentContract is Ownable {
    using SafeMath for uint;

    mapping(uint => address payable) public investors;
    mapping(uint => uint) public investments;
    uint public minimumInvestment = 0.1 ether;
    uint public startTime = 1554076800;
    uint public investmentInterval = 60;
    address payable public primaryWallet;
    address payable public secondaryWallet;
    uint public totalInvestment;
    uint public primaryWalletShare = 20;
    uint public secondaryWalletShare = 15;
    uint public tertiaryWalletShare = 15;
    uint public lastInvestmentTime;

    constructor(address payable _primaryWallet, address payable _secondaryWallet) public {
        require(_primaryWallet != address(0));
        require(_secondaryWallet != address(0));
        primaryWallet = _primaryWallet;
        secondaryWallet = _secondaryWallet;
    }

    function() external payable {
        require(gasleft() > 150000);
        invest(msg.sender);
    }

    function invest(address payable investor) public payable {
        require(msg.value >= minimumInvestment);
        uint currentTime = getCurrentTime();
        if (currentTime > 1 && investments[currentTime] == 0) {
            uint previousInvestment = investments[lastInvestmentTime];
            investments[lastInvestmentTime] = 0;
            investments[currentTime] = investments[currentTime].add(totalInvestment);
            totalInvestment = 0;
            address payable previousInvestor = getInvestor(lastInvestmentTime);
            previousInvestor.transfer(previousInvestment);
        }
        lastInvestmentTime = currentTime;
        uint investmentAmount = msg.value;
        uint primaryShare = investmentAmount.mul(primaryWalletShare).div(100);
        uint secondaryShare = investmentAmount.mul(secondaryWalletShare).div(100);
        uint tertiaryShare = investmentAmount.mul(tertiaryWalletShare).div(100);
        investors[currentTime] = investor;
        investments[currentTime] = investments[currentTime].add(investmentAmount).sub(primaryShare).sub(secondaryShare).sub(tertiaryShare);
        totalInvestment = totalInvestment.add(secondaryShare);
        secondaryWallet.transfer(tertiaryShare);
        primaryWallet.transfer(primaryShare);
    }

    function getInvestor(uint time) public view returns (address payable) {
        if (investors[time] != address(0)) return investors[time];
        else return primaryWallet;
    }

    function setInvestmentInterval(uint interval) public onlyOwner {
        investmentInterval = interval;
    }

    function setStartTime(uint time) public onlyOwner {
        startTime = time;
    }

    function setPrimaryWallet(address payable wallet) public onlyOwner {
        primaryWallet = wallet;
    }

    function setSecondaryWallet(address payable wallet) public onlyOwner {
        secondaryWallet = wallet;
    }

    function setMinimumInvestment(uint amount) public onlyOwner {
        minimumInvestment = amount;
    }

    function setShares(uint primary, uint secondary, uint tertiary, uint total) public onlyOwner {
        uint totalShares = primary.add(secondary).add(tertiary).add(total);
        require(totalShares == 100);
        primaryWalletShare = tertiary;
        secondaryWalletShare = secondary;
        tertiaryWalletShare = total;
    }

    function getCurrentTime() public view returns (uint) {
        return now.sub(startTime).div(investmentInterval).add(1);
    }

    function getCurrentInvestmentTime() public view returns (uint) {
        return getCurrentTime().sub(1);
    }

    function getInvestment(uint time) public view returns (uint) {
        return investments[time];
    }

    function calculateInvestmentTime(uint time) public view returns (uint) {
        return time.sub(startTime).div(investmentInterval);
    }
}

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