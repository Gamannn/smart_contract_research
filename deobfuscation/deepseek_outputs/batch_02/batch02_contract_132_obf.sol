```solidity
pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface ERC20 {
    function balanceOf(address owner) public constant returns (uint256);
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BettingGame {
    using SafeMath for uint256;
    using SafeMath for uint128;
    using SafeMath for uint32;
    using SafeMath for uint8;
    
    address public owner;
    address private nextOwner;
    address public tokenContractAddress;
    address public ERC20WalletAddress;
    
    uint256 public baseTimestamp = 1534377600;
    uint256 public startBetTime = 0;
    
    event OpenBet(uint256 option);
    event BetLog(address indexed player, uint256 amount, uint256 option);
    
    mapping(address => uint256) public optionOneBet;
    mapping(address => uint256) public optionTwoBet;
    mapping(address => uint256) public optionThreeBet;
    mapping(address => uint256) public optionFourBet;
    mapping(address => uint256) public optionFiveBet;
    mapping(address => uint256) public optionSixBet;
    
    uint256 public optionOneAmount = 0;
    uint256 public optionTwoAmount = 0;
    uint256 public optionThreeAmount = 0;
    uint256 public optionFourAmount = 0;
    uint256 public optionFiveAmount = 0;
    uint256 public optionSixAmount = 0;
    
    uint256 public optionOneLimit;
    uint256 public optionTwoLimit;
    uint256 public optionThreeLimit;
    uint256 public optionFourLimit;
    uint256 public optionFiveLimit;
    uint256 public optionSixLimit;
    
    uint256 public lastBetTime;
    uint256 public finalAnswer;
    uint256 public loseTokenRate;
    
    bool public isInitialized = false;
    bool public isEtherGame = true;
    uint256 public feePool = 0;
    
    constructor() public {
        owner = msg.sender;
        isEtherGame = true;
    }
    
    function initialize(
        uint256 _startBetTime,
        uint256 _lastBetTime,
        uint256 _loseTokenRate,
        uint256 _optionOneLimit,
        uint256 _optionTwoLimit,
        uint256 _optionThreeLimit,
        uint256 _optionFourLimit,
        uint256 _optionFiveLimit,
        uint256 _optionSixLimit,
        address _tokenContractAddress,
        address _ERC20WalletAddress,
        bool _isEtherGame
    ) public {
        require(_lastBetTime > _startBetTime);
        require(_loseTokenRate > 0);
        require(_optionOneLimit > 0);
        
        startBetTime = _startBetTime;
        lastBetTime = _lastBetTime;
        loseTokenRate = _loseTokenRate;
        optionOneLimit = _optionOneLimit;
        optionTwoLimit = _optionTwoLimit;
        optionThreeLimit = _optionThreeLimit;
        optionFourLimit = _optionFourLimit;
        optionFiveLimit = _optionFiveLimit;
        optionSixLimit = _optionSixLimit;
        tokenContractAddress = _tokenContractAddress;
        ERC20WalletAddress = _ERC20WalletAddress;
        isEtherGame = _isEtherGame;
        isInitialized = true;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Cannot transfer to zero address");
        nextOwner = newOwner;
    }
    
    function acceptOwnership() external {
        require(msg.sender == nextOwner, "Only pre-approved new owner can accept");
        owner = nextOwner;
    }
    
    function() public payable {
        revert();
    }
    
    function placeBet(uint256 optionNumber) public payable {
        require(lastBetTime > now);
        require(isInitialized == true, "Game not initialized");
        require(isEtherGame == true, "This is not an Ether game");
        require(msg.value >= 0.01 ether);
        
        uint256 amount = msg.value;
        
        if(optionNumber == 1) {
            require(optionOneAmount.add(amount) <= optionOneLimit);
            optionOneBet[msg.sender] = optionOneBet[msg.sender].add(amount);
            optionOneAmount = optionOneAmount.add(amount);
        } else if(optionNumber == 2) {
            require(optionTwoAmount.add(amount) <= optionTwoLimit);
            optionTwoBet[msg.sender] = optionTwoBet[msg.sender].add(amount);
            optionTwoAmount = optionTwoAmount.add(amount);
        } else if(optionNumber == 3) {
            require(optionThreeAmount.add(amount) <= optionThreeLimit);
            optionThreeBet[msg.sender] = optionThreeBet[msg.sender].add(amount);
            optionThreeAmount = optionThreeAmount.add(amount);
        } else if(optionNumber == 4) {
            require(optionFourAmount.add(amount) <= optionFourLimit);
            optionFourBet[msg.sender] = optionFourBet[msg.sender].add(amount);
            optionFourAmount = optionFourAmount.add(amount);
        } else if(optionNumber == 5) {
            require(optionFiveAmount.add(amount) <= optionFiveLimit);
            optionFiveBet[msg.sender] = optionFiveBet[msg.sender].add(amount);
            optionFiveAmount = optionFiveAmount.add(amount);
        } else if(optionNumber == 6) {
            require(optionSixAmount.add(amount) <= optionSixLimit);
            optionSixBet[msg.sender] = optionSixBet[msg.sender].add(amount);
            optionSixAmount = optionSixAmount.add(amount);
        }
        
        feePool = feePool.add(amount.mul(20).div(1000));
        emit BetLog(msg.sender, amount, optionNumber);
    }
    
    function placeBetWithToken(uint256 optionNumber, uint256 amount) public {
        require(lastBetTime > now);
        require(isInitialized == true, "Game not initialized");
        require(isEtherGame == false, "This is not a token game");
        
        if(optionNumber == 1) {
            require(optionOneAmount.add(amount) <= optionOneLimit);
            optionOneBet[msg.sender] = optionOneBet[msg.sender].add(amount);
            optionOneAmount = optionOneAmount.add(amount);
        } else if(optionNumber == 2) {
            require(optionTwoAmount.add(amount) <= optionTwoLimit);
            optionTwoBet[msg.sender] = optionTwoBet[msg.sender].add(amount);
            optionTwoAmount = optionTwoAmount.add(amount);
        } else if(optionNumber == 3) {
            require(optionThreeAmount.add(amount) <= optionThreeLimit);
            optionThreeBet[msg.sender] = optionThreeBet[msg.sender].add(amount);
            optionThreeAmount = optionThreeAmount.add(amount);
        } else if(optionNumber == 4) {
            require(optionFourAmount.add(amount) <= optionFourLimit);
            optionFourBet[msg.sender] = optionFourBet[msg.sender].add(amount);
            optionFourAmount = optionFourAmount.add(amount);
        } else if(optionNumber == 5) {
            require(optionFiveAmount.add(amount) <= optionFiveLimit);
            optionFiveBet[msg.sender] = optionFiveBet[msg.sender].add(amount);
            optionFiveAmount = optionFiveAmount.add(amount);
        } else if(optionNumber == 6) {
            require(optionSixAmount.add(amount) <= optionSixLimit);
            optionSixBet[msg.sender] = optionSixBet[msg.sender].add(amount);
            optionSixAmount = optionSixAmount.add(amount);
        }
        
        emit BetLog(msg.sender, amount, optionNumber);
    }
    
    function setFinalAnswer(uint256 answer) public onlyOwner {
        require(now > lastBetTime);
        finalAnswer = answer;
    }
    
    function getGameInfo() public view returns(
        bool _isEtherGame,
        bool _isInitialized,
        uint256 _optionOneAmount,
        uint256 _optionTwoAmount,
        uint256 _optionThreeAmount,
        uint256 _optionFourAmount,
        uint256 _optionFiveAmount,
        uint256 _optionSixAmount,
        uint256 _loseTokenRate,
        uint256 _startBetTime,
        uint256 _lastBetTime,
        uint256 _finalAnswer,
        uint256 _feePool
    ) {
        return(
            isEtherGame,
            isInitialized,
            optionOneAmount,
            optionTwoAmount,
            optionThreeAmount,
            optionFourAmount,
            optionFiveAmount,
            optionSixAmount,
            loseTokenRate,
            startBetTime,
            lastBetTime,
            finalAnswer,
            feePool
        );
    }
    
    function getLimits() public view returns(
        uint256 _optionOneLimit,
        uint256 _optionTwoLimit,
        uint256 _optionThreeLimit,
        uint256 _optionFourLimit,
        uint256 _optionFiveLimit,
        uint256 _optionSixLimit
    ) {
        return(
            optionOneLimit,
            optionTwoLimit,
            optionThreeLimit,
            optionFourLimit,
            optionFiveLimit,
            optionSixLimit
        );
    }
    
    function getDaysSinceStart() public view returns(uint256 daysSinceStart) {
        uint256 timeSinceStart = now.sub(baseTimestamp);
        uint256 daysPassed = timeSinceStart.div(86400);
        return baseTimestamp.add(daysPassed.mul(86400));
    }
    
    function getCurrentDay() public view returns(uint256 currentDay) {
        uint256 currentTimestamp = getDaysSinceStart();
        currentDay = currentTimestamp.sub(baseTimestamp).div(86400).add(1);
        return currentDay;
    }
    
    function calculateReward() public view returns(uint256 reward) {
        uint256 totalBetAmount = optionOneAmount
            .add(optionTwoAmount)
            .add(optionThreeAmount)
            .add(optionFourAmount)
            .add(optionFiveAmount)
            .add(optionSixAmount);
        
        uint256 share = 0;
        uint256 realReward = totalBetAmount.mul(980).div(1000);
        
        if(finalAnswer == 1) {
            share = optionOneBet[msg.sender].mul(100).div(optionOneAmount);
            reward = share.mul(realReward).div(100);
        } else if(finalAnswer == 2) {
            share = optionTwoBet[msg.sender].mul(100).div(optionTwoAmount);
            reward = share.mul(realReward).div(100);
        } else if(finalAnswer == 3) {
            share = optionThreeBet[msg.sender].mul(100).div(optionThreeAmount);
            reward = share.mul(realReward).div(100);
        } else if(finalAnswer == 4) {
            share = optionFourBet[msg.sender].mul(100).div(optionFourAmount);
            reward = share.mul(realReward).div(100);
        } else if(finalAnswer == 5) {
            share = optionFiveBet[msg.sender].mul(100).div(optionFiveAmount);
            reward = share.mul(realReward).div(100);
        } else if(finalAnswer == 6) {
            share = optionSixBet[msg.sender].mul(100).div(optionSixAmount);
            reward = share.mul(realReward).div(100);
        }
        
        return reward;
    }
    
    function getRewardDetails() public view returns(
        uint256 reward,
        uint256 totalBetAmount,
        uint256 realReward,
        uint256 share
    ) {
        uint256 _reward = 0;
        uint256 _totalBetAmount = optionOneAmount
            .add(optionTwoAmount)
            .add(optionThreeAmount)
            .add(optionFourAmount)
            .add(optionFiveAmount)
            .add(optionSixAmount);
        
        uint256 _share = 0;
        uint256 _realReward = _totalBetAmount.mul(980).div(1000);
        
        if(finalAnswer == 1) {
            _share = optionOneBet[msg.sender].mul(100).div(optionOneAmount);
            _reward = _share.mul(_realReward).div(100);
        } else if(finalAnswer == 2) {
            _share = optionTwoBet[msg.sender].mul(100).div(optionTwoAmount);
            _reward = _share.mul(_realReward).div(100);
        } else if(finalAnswer == 3) {
            _share = optionThreeBet[msg.sender].mul(100).div(optionThreeAmount);
            _reward = _share.mul(_realReward).div(100);
        } else if(finalAnswer == 4) {
            _share = optionFourBet[msg.sender].mul(100).div(optionFourAmount);
            _reward = _share.mul(_realReward).div(100);
        } else if(finalAnswer == 5) {
            _share = optionFiveBet[msg.sender].mul(100).div(optionFiveAmount);
            _reward = _share.mul(_realReward).div(100);
        } else if(finalAnswer == 6) {
            _share = optionSixBet[msg.sender].mul(100).div(optionSixAmount);
            _reward = _share.mul(_realReward).div(100);
        }
        
        return (_reward, _totalBetAmount, _realReward, _share);
    }
    
    function getBetAmount(uint256 option) public view returns(uint256 betAmount) {
        if(option == 1) {
            betAmount = optionOneBet[msg.sender];
        } else if(option == 2) {
            betAmount = optionTwoBet[msg.sender];
        } else if(option == 3) {
            betAmount = optionThreeBet[msg.sender];
        } else if(option == 4) {
            betAmount = optionFourBet[msg.sender];
        } else if(option == 5) {
            betAmount = optionFiveBet[msg.sender];
        } else if(option == 6) {
            betAmount = optionSixBet[msg.sender];
        }
    }
    
    function claimReward() public {
        require(finalAnswer != 0);
        uint256 reward = calculateReward();
        
        if(reward == 0 && isEtherGame == true) {
            uint256 totalBet = optionOneBet[msg.sender]
                .add(optionTwoBet[msg.sender])
                .add(optionThreeBet[msg.sender])
                .add(optionFourBet[msg.sender])
                .add(optionFiveBet[msg.sender])
                .add(optionSixBet[msg.sender]);
            
            uint256 tokenAmount = totalBet.mul(loseTokenRate);
            ERC20(tokenContractAddress).transferFrom(ERC20WalletAddress, msg.sender, tokenAmount);
        }
        
        optionOneBet[msg.sender] = 0;
        optionTwoBet[msg.sender] = 0;
        optionThreeBet[msg.sender] = 0;
        optionFourBet[msg.sender] = 0;
        optionFiveBet[msg.sender] = 0;
        optionSixBet[msg.sender] = 0;
        
        if(isEtherGame) {
            msg.sender.transfer(reward);
        } else {
            ERC20(tokenContractAddress).transferFrom(ERC20WalletAddress, msg.sender, reward);
        }
    }
    
    function setERC20WalletAddress(address newAddress) public onlyOwner {
        ERC20WalletAddress = newAddress;
    }
    
    function withdrawFees() public onlyOwner {
        uint256 fees = feePool;
        feePool = 0;
        msg.sender.transfer(fees);
    }
}
```