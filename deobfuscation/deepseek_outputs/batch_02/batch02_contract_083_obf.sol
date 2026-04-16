```solidity
pragma solidity ^0.4.24;

contract PredictionMarket {
    address public owner;
    string public question;
    bytes32[] public possibleAnswers;
    string public description;
    string public category;
    
    uint256 public marketClosureTime;
    uint256 public cancellationDeadline;
    uint256 public feePercentage = 5;
    uint256 public correctAnswer;
    uint256 public totalPool;
    uint256 public feeAmount;
    
    enum States { Open, Resolved, Cancelled }
    States public state = States.Open;
    
    mapping(address => mapping(uint256 => uint256)) public bets;
    mapping(uint256 => uint256) public answerTotalBets;
    
    event BetPlaced(address indexed better, uint256 indexed answer, uint256 amount);
    
    constructor(
        string _question,
        bytes32[] _possibleAnswers,
        string _description,
        string _category,
        uint256 _marketDuration
    ) public payable {
        owner = msg.sender;
        question = _question;
        possibleAnswers = _possibleAnswers;
        marketClosureTime = now + _marketDuration;
        cancellationDeadline = now + _marketDuration + 1209600;
        description = _description;
        category = _category;
        totalPool = msg.value;
    }
    
    function placeBet(uint256 answer) public payable {
        require(state == States.Open);
        bets[msg.sender][answer] += msg.value;
        answerTotalBets[answer] += msg.value;
        totalPool += msg.value;
        require(totalPool < 2 ** 128);
        emit BetPlaced(msg.sender, answer, msg.value);
    }
    
    function resolveMarket(uint256 winningAnswer) public {
        require(now > marketClosureTime && state == States.Open);
        require(msg.sender == owner);
        
        correctAnswer = winningAnswer;
        
        if (answerTotalBets[winningAnswer] == 0) {
            state = States.Cancelled;
        } else {
            state = States.Resolved;
            feeAmount = totalPool * feePercentage / 100;
            owner.transfer(feeAmount);
        }
    }
    
    function claimWinnings() public {
        require(state == States.Resolved);
        uint256 winnings = bets[msg.sender][correctAnswer] * (totalPool - feeAmount) / answerTotalBets[correctAnswer];
        msg.sender.transfer(winnings);
    }
    
    function cancelMarket() public {
        require(state != States.Resolved);
        require(msg.sender == owner || now > cancellationDeadline);
        state = States.Cancelled;
    }
    
    function refundBet(uint256 answer) public {
        require(state == States.Cancelled);
        uint256 refundAmount = bets[msg.sender][answer];
        bets[msg.sender][answer] = 0;
        msg.sender.transfer(refundAmount);
    }
}
```