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

contract ERC20Interface {
    function balanceOf(address tokenOwner) public constant returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract BettingGame {
    using SafeMath for uint256;

    address public owner;
    address private nextOwner;
    address public tokenAddress;
    bool public isInitialized = false;
    bool public isEtherGame = false;
    uint256 public startBetTime;
    uint256 public endBetTime;
    uint256 public finalAnswer;
    uint256 public loseTokenRate = 15;
    uint256 public optionOneLimit;
    uint256 public optionTwoLimit;
    uint256 public optionThreeLimit;
    uint256 public optionFourLimit;
    uint256 public optionFiveLimit;
    uint256 public optionSixLimit;
    uint256 public optionOneAmount;
    uint256 public optionTwoAmount;
    uint256 public optionThreeAmount;
    uint256 public optionFourAmount;
    uint256 public optionFiveAmount;
    uint256 public optionSixAmount;
    mapping(address => uint256) public optionOneBet;
    mapping(address => uint256) public optionTwoBet;
    mapping(address => uint256) public optionThreeBet;
    mapping(address => uint256) public optionFourBet;
    mapping(address => uint256) public optionFiveBet;
    mapping(address => uint256) public optionSixBet;

    event BetPlaced(address indexed player, uint256 amount, uint256 option);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function initializeGame(
        uint256 _startBetTime,
        uint256 _endBetTime,
        uint256 _optionOneLimit,
        uint256 _optionTwoLimit,
        uint256 _optionThreeLimit,
        uint256 _optionFourLimit,
        uint256 _optionFiveLimit,
        uint256 _optionSixLimit,
        address _tokenAddress,
        bool _isEtherGame
    ) public onlyOwner {
        require(_startBetTime < _endBetTime, "Start time must be before end time.");
        startBetTime = _startBetTime;
        endBetTime = _endBetTime;
        optionOneLimit = _optionOneLimit;
        optionTwoLimit = _optionTwoLimit;
        optionThreeLimit = _optionThreeLimit;
        optionFourLimit = _optionFourLimit;
        optionFiveLimit = _optionFiveLimit;
        optionSixLimit = _optionSixLimit;
        tokenAddress = _tokenAddress;
        isEtherGame = _isEtherGame;
        isInitialized = true;
    }

    function placeBet(uint256 option) public payable {
        require(isInitialized, "Game is not initialized.");
        require(now >= startBetTime && now <= endBetTime, "Betting is not open.");
        require(option >= 1 && option <= 6, "Invalid option.");

        uint256 amount = msg.value;
        if (isEtherGame) {
            require(amount >= 0.01 ether, "Minimum bet is 0.01 ether.");
        } else {
            ERC20Interface token = ERC20Interface(tokenAddress);
            amount = token.allowance(msg.sender, address(this));
            require(amount > 0, "No tokens approved for transfer.");
            require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed.");
        }

        if (option == 1) {
            require(optionOneAmount.add(amount) <= optionOneLimit, "Option one limit exceeded.");
            optionOneBet[msg.sender] = optionOneBet[msg.sender].add(amount);
            optionOneAmount = optionOneAmount.add(amount);
        } else if (option == 2) {
            require(optionTwoAmount.add(amount) <= optionTwoLimit, "Option two limit exceeded.");
            optionTwoBet[msg.sender] = optionTwoBet[msg.sender].add(amount);
            optionTwoAmount = optionTwoAmount.add(amount);
        } else if (option == 3) {
            require(optionThreeAmount.add(amount) <= optionThreeLimit, "Option three limit exceeded.");
            optionThreeBet[msg.sender] = optionThreeBet[msg.sender].add(amount);
            optionThreeAmount = optionThreeAmount.add(amount);
        } else if (option == 4) {
            require(optionFourAmount.add(amount) <= optionFourLimit, "Option four limit exceeded.");
            optionFourBet[msg.sender] = optionFourBet[msg.sender].add(amount);
            optionFourAmount = optionFourAmount.add(amount);
        } else if (option == 5) {
            require(optionFiveAmount.add(amount) <= optionFiveLimit, "Option five limit exceeded.");
            optionFiveBet[msg.sender] = optionFiveBet[msg.sender].add(amount);
            optionFiveAmount = optionFiveAmount.add(amount);
        } else if (option == 6) {
            require(optionSixAmount.add(amount) <= optionSixLimit, "Option six limit exceeded.");
            optionSixBet[msg.sender] = optionSixBet[msg.sender].add(amount);
            optionSixAmount = optionSixAmount.add(amount);
        }

        emit BetPlaced(msg.sender, amount, option);
    }

    function setFinalAnswer(uint256 _finalAnswer) public onlyOwner {
        require(now > endBetTime, "Betting period is not over.");
        finalAnswer = _finalAnswer;
    }

    function claimReward() public {
        require(finalAnswer > 0, "Final answer is not set.");
        uint256 reward = 0;
        if (finalAnswer == 1) {
            reward = optionOneBet[msg.sender].mul(loseTokenRate).div(100);
        } else if (finalAnswer == 2) {
            reward = optionTwoBet[msg.sender].mul(loseTokenRate).div(100);
        } else if (finalAnswer == 3) {
            reward = optionThreeBet[msg.sender].mul(loseTokenRate).div(100);
        } else if (finalAnswer == 4) {
            reward = optionFourBet[msg.sender].mul(loseTokenRate).div(100);
        } else if (finalAnswer == 5) {
            reward = optionFiveBet[msg.sender].mul(loseTokenRate).div(100);
        } else if (finalAnswer == 6) {
            reward = optionSixBet[msg.sender].mul(loseTokenRate).div(100);
        }

        if (isEtherGame) {
            msg.sender.transfer(reward);
        } else {
            ERC20Interface token = ERC20Interface(tokenAddress);
            require(token.transfer(msg.sender, reward), "Token transfer failed.");
        }

        optionOneBet[msg.sender] = 0;
        optionTwoBet[msg.sender] = 0;
        optionThreeBet[msg.sender] = 0;
        optionFourBet[msg.sender] = 0;
        optionFiveBet[msg.sender] = 0;
        optionSixBet[msg.sender] = 0;
    }

    function transferOwnership(address _nextOwner) public onlyOwner {
        require(_nextOwner != address(0), "Invalid address.");
        nextOwner = _nextOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == nextOwner, "Only the next owner can accept ownership.");
        owner = nextOwner;
        nextOwner = address(0);
    }

    function() public payable {
        revert();
    }
}
```