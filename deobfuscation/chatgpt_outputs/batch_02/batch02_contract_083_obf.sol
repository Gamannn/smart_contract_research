```solidity
pragma solidity ^0.4.24;

contract PredictionMarket {
    address public owner;
    string public question;
    string public category;
    string public description;
    bytes32[] public possibleAnswers;
    uint256 public marketClosureTime;
    uint256 public resolutionTime;
    uint256 public totalFunds;
    uint256 public feePercentage;
    uint256 public feeAmount;
    uint256 public winningAnswer;
    uint256 public constant MAX_UINT128 = 2 ** 128;
    uint256 public constant TWO_WEEKS = 1209600;
    uint256 public constant DEFAULT_FEE_PERCENTAGE = 5;
    uint256 public constant DEFAULT_FEE_AMOUNT = 1234;

    enum States { Open, Resolved, Cancelled }
    States public state = States.Open;

    mapping(address => mapping(uint256 => uint256)) public userBets;
    mapping(uint256 => uint256) public answerBets;

    event BetPlaced(address indexed user, uint256 indexed answer, uint256 amount);

    constructor(
        string _question,
        bytes32[] _possibleAnswers,
        string _category,
        string _description,
        uint256 _marketClosureTime
    ) public payable {
        owner = msg.sender;
        question = _question;
        possibleAnswers = _possibleAnswers;
        category = _category;
        description = _description;
        marketClosureTime = now + _marketClosureTime;
        resolutionTime = now + _marketClosureTime + TWO_WEEKS;
        feePercentage = DEFAULT_FEE_PERCENTAGE;
        feeAmount = DEFAULT_FEE_AMOUNT;
        totalFunds = msg.value;
    }

    function placeBet(uint256 answerIndex) public payable {
        require(state == States.Open);
        userBets[msg.sender][answerIndex] += msg.value;
        answerBets[answerIndex] += msg.value;
        totalFunds += msg.value;
        require(totalFunds < MAX_UINT128);
        emit BetPlaced(msg.sender, answerIndex, msg.value);
    }

    function resolveMarket(uint256 winningAnswerIndex) public {
        require(now > marketClosureTime && state == States.Open);
        require(msg.sender == owner);
        winningAnswer = winningAnswerIndex;
        feeAmount = totalFunds * feePercentage / 100;
        if (answerBets[winningAnswer] == 0) {
            state = States.Cancelled;
        } else {
            state = States.Resolved;
            msg.sender.transfer(feeAmount);
        }
    }

    function claimReward() public {
        require(state == States.Resolved);
        uint256 userBet = userBets[msg.sender][winningAnswer];
        uint256 reward = userBet * (totalFunds - feeAmount) / answerBets[winningAnswer];
        userBets[msg.sender][winningAnswer] = 0;
        msg.sender.transfer(reward);
    }

    function cancelMarket() public {
        require(state != States.Resolved);
        require(msg.sender == owner || now > resolutionTime);
        state = States.Cancelled;
    }

    function refund() public {
        require(state == States.Cancelled);
        uint256 userBet = userBets[msg.sender][winningAnswer];
        userBets[msg.sender][winningAnswer] = 0;
        msg.sender.transfer(userBet);
    }
}
```