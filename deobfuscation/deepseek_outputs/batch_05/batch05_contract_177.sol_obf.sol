```solidity
pragma solidity 0.5.4;

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

contract Lottery is Ownable {
    using SafeMath for uint256;
    
    mapping(uint256 => address) public roundWinner;
    mapping(uint256 => uint256) public roundBalance;
    
    uint256 public minBet = 0.001 ether;
    uint256 public startTime = 1551700800;
    uint256 public roundDuration = 3600;
    
    address payable public devWallet;
    address payable public superJackpotWallet;
    
    constructor(address payable _devWallet, address payable _superJackpotWallet) public {
        require(_devWallet != address(0));
        require(_superJackpotWallet != address(0));
        
        devWallet = _devWallet;
        superJackpotWallet = _superJackpotWallet;
    }
    
    function() external payable {
        placeBet(msg.sender);
    }
    
    function placeBet(address player) public payable {
        require(msg.value >= minBet);
        
        uint256 currentRound = now.sub(startTime).div(roundDuration);
        uint256 betAmount = msg.value;
        
        uint256 devFee = betAmount.mul(20).div(100);
        uint256 superJackpotFee = betAmount.mul(15).div(100);
        uint256 roundJackpotFee = betAmount.mul(15).div(100);
        
        roundWinner[currentRound] = player;
        
        roundBalance[currentRound] = roundBalance[currentRound]
            .add(betAmount)
            .sub(devFee)
            .sub(superJackpotFee)
            .sub(roundJackpotFee);
            
        roundBalance[currentRound.add(1)] = roundBalance[currentRound.add(1)].add(superJackpotFee);
        
        superJackpotWallet.transfer(roundJackpotFee);
        devWallet.transfer(devFee);
    }
    
    function getRoundWinner(uint256 round) public view returns (address) {
        if (roundWinner[round] != address(0)) {
            return roundWinner[round];
        } else {
            return owner;
        }
    }
    
    function claimPrize(uint256 round) public {
        require(round < now.sub(startTime).div(roundDuration));
        require(msg.sender == getRoundWinner(round));
        
        uint256 prize = roundBalance[round];
        roundBalance[round] = 0;
        address(msg.sender).transfer(prize);
    }
    
    function setRoundDuration(uint256 duration) onlyOwner public {
        roundDuration = duration;
    }
    
    function setStartTime(uint256 time) onlyOwner public {
        startTime = time;
    }
    
    function setDevWallet(address payable wallet) onlyOwner public {
        devWallet = wallet;
    }
    
    function setSuperJackpotWallet(address payable wallet) onlyOwner public {
        superJackpotWallet = wallet;
    }
    
    function getCurrentRound() public view returns (uint256) {
        return now.sub(startTime).div(roundDuration);
    }
    
    function getRoundBalance(uint256 round) public view returns (uint256) {
        return roundBalance[round];
    }
    
    function getRoundForTimestamp(uint256 timestamp) public view returns (uint256) {
        return timestamp.sub(startTime).div(roundDuration);
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
```