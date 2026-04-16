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
    
    function transferOwnership(address newOwner) onlyOwner public {
        pendingOwner = newOwner;
    }
    
    function claimOwnership() onlyPendingOwner public {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

contract Fomo3D is Ownable {
    using SafeMath for uint;
    
    mapping(uint => address payable) public roundIdToPlayer;
    mapping(uint => uint) public roundIdToBalance;
    
    uint public minBet = 0.1 ether;
    uint public roundStartTime = 1554076800;
    uint public roundDuration = 60;
    
    address payable public feeRecipient1;
    address payable public feeRecipient2;
    
    uint public totalJackpot;
    uint public feePercent1 = 20;
    uint public feePercent2 = 15;
    uint public jackpotPercent = 15;
    
    uint public currentRoundId;
    
    constructor(address payable _feeRecipient1, address payable _feeRecipient2) public {
        require(_feeRecipient1 != address(0));
        require(_feeRecipient2 != address(0));
        feeRecipient1 = _feeRecipient1;
        feeRecipient2 = _feeRecipient2;
    }
    
    function() external payable {
        require(gasleft() > 150000);
        placeBet(msg.sender);
    }
    
    function placeBet(address payable player) public payable {
        require(msg.value >= minBet);
        
        uint roundId = getCurrentRoundId();
        
        if (roundId > 1 && roundIdToBalance[roundId] == 0) {
            uint previousRoundBalance = roundIdToBalance[currentRoundId];
            roundIdToBalance[currentRoundId] = 0;
            
            roundIdToBalance[roundId] = roundIdToBalance[roundId].add(totalJackpot);
            totalJackpot = 0;
            
            address payable previousRoundWinner = getRoundWinner(currentRoundId);
            previousRoundWinner.transfer(previousRoundBalance);
        }
        
        currentRoundId = roundId;
        
        uint betAmount = msg.value;
        uint fee1 = betAmount.mul(feePercent1).div(100);
        uint fee2 = betAmount.mul(feePercent2).div(100);
        uint jackpotContribution = betAmount.mul(jackpotPercent).div(100);
        
        roundIdToPlayer[roundId] = player;
        roundIdToBalance[roundId] = roundIdToBalance[roundId]
            .add(betAmount)
            .sub(fee1)
            .sub(fee2)
            .sub(jackpotContribution);
        
        totalJackpot = totalJackpot.add(fee2);
        feeRecipient2.transfer(jackpotContribution);
        feeRecipient1.transfer(fee1);
    }
    
    function getRoundWinner(uint roundId) public view returns (address payable) {
        if (roundIdToPlayer[roundId] != address(0)) {
            return roundIdToPlayer[roundId];
        } else {
            return feeRecipient1;
        }
    }
    
    function setRoundDuration(uint duration) onlyOwner public {
        roundDuration = duration;
    }
    
    function setRoundStartTime(uint startTime) onlyOwner public {
        roundStartTime = startTime;
    }
    
    function setFeeRecipient1(address payable recipient) onlyOwner public {
        feeRecipient1 = recipient;
    }
    
    function setFeeRecipient2(address payable recipient) onlyOwner public {
        feeRecipient2 = recipient;
    }
    
    function setMinBet(uint amount) onlyOwner public {
        minBet = amount;
    }
    
    function setFeePercentages(uint base, uint fee1, uint fee2, uint jackpot) onlyOwner public {
        uint total = base.add(fee1).add(fee2).add(jackpot);
        require(total == 100);
        
        feePercent1 = fee1;
        feePercent2 = fee2;
        jackpotPercent = jackpot;
    }
    
    function getCurrentRoundId() public view returns (uint) {
        return now.sub(roundStartTime).div(roundDuration).add(1);
    }
    
    function getNextRoundId() public view returns (uint) {
        return getCurrentRoundId().add(1);
    }
    
    function getRoundBalance(uint roundId) public view returns (uint) {
        return roundIdToBalance[roundId];
    }
    
    function getRoundIdForTimestamp(uint timestamp) public view returns (uint) {
        return timestamp.sub(roundStartTime).div(roundDuration);
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