```solidity
pragma solidity ^0.8.0;

library MathLibrary {
    function safeMultiply(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 result = a * b;
        assert(result / a == b);
        return result;
    }

    function safeDivide(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 result = a / b;
        return result;
    }

    function safeSubtract(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 result = a + b;
        assert(result >= a);
        return result;
    }
}

library MathLibrary32 {
    function safeAdd(uint32 a, uint32 b) internal pure returns (uint32) {
        uint32 result = a + b;
        assert(result >= a);
        return result;
    }
}

contract BalanceHolder {
    mapping(address => uint256) public balances;
    event LogWithdraw(address indexed user, uint256 amount);

    function withdraw() public {
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit LogWithdraw(msg.sender, amount);
    }
}

contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract QuestionManager is BalanceHolder, Ownable {
    using MathLibrary for uint256;
    using MathLibrary32 for uint32;

    address constant NULL_ADDRESS = address(0);
    uint32 constant UNANSWERED = 0;

    event LogNewTemplate(uint256 indexed templateId, address indexed creator, string content);
    event LogNewQuestion(
        bytes32 indexed questionId,
        address indexed creator,
        uint256 templateId,
        string content,
        bytes32 indexed questionHash,
        address arbitrator,
        uint32 openingTs,
        uint32 timeout,
        uint256 minBond,
        uint256 bounty
    );
    event LogFundAnswerBounty(
        bytes32 indexed questionId,
        uint256 amount,
        uint256 totalBounty,
        address indexed funder
    );
    event LogNewAnswer(
        bytes32 answerHash,
        bytes32 indexed questionId,
        bytes32 answerCommitmentId,
        address indexed answerer,
        uint256 bond,
        uint256 timestamp,
        bool isCommitment
    );
    event LogAnswerReveal(
        bytes32 indexed questionId,
        address indexed answerer,
        bytes32 indexed answerCommitmentId,
        bytes32 answerHash,
        uint256 bond,
        uint256 timestamp
    );
    event LogNotifyOfArbitrationRequest(bytes32 indexed questionId, address indexed requester);
    event LogFinalize(bytes32 indexed questionId, bytes32 indexed answerHash);
    event LogClaim(bytes32 indexed questionId, address indexed claimant, uint256 amount);

    struct Question {
        bytes32 questionHash;
        address arbitrator;
        uint32 openingTs;
        uint32 timeout;
        uint32 finalizeTs;
        bool isPendingArbitration;
        uint256 bounty;
        bytes32 bestAnswer;
        bytes32 lastAnswer;
        uint256 bond;
    }

    struct Commitment {
        uint32 revealDeadline;
        bool isRevealed;
        bytes32 answerHash;
    }

    struct Claim {
        address claimant;
        uint256 lastBond;
        uint256 accumulatedBounty;
    }

    uint256 public templateCount = 0;
    mapping(uint256 => uint256) public templateCreationBlock;
    mapping(uint256 => bytes32) public templateHashes;
    mapping(bytes32 => Question) public questions;
    mapping(bytes32 => Claim) public questionClaims;
    mapping(bytes32 => Commitment) public commitments;
    mapping(address => uint256) public questionFees;

    modifier onlyArbitrator(bytes32 questionId) {
        require(msg.sender == questions[questionId].arbitrator, "Caller is not the arbitrator");
        _;
    }

    modifier questionMustExist(bytes32 questionId) {
        require(questions[questionId].timeout > 0, "Question must exist");
        _;
    }

    modifier questionMustNotBePendingArbitration(bytes32 questionId) {
        require(!questions[questionId].isPendingArbitration, "Question must not be pending arbitration");
        _;
    }

    modifier questionMustBePendingArbitration(bytes32 questionId) {
        require(questions[questionId].isPendingArbitration, "Question must be pending arbitration");
        _;
    }

    modifier questionMustBeFinalized(bytes32 questionId) {
        require(isFinalized(questionId), "Question must be finalized");
        _;
    }

    modifier bondMustBeZero() {
        require(msg.value == 0, "Bond must be zero");
        _;
    }

    modifier bondMustBeDoublePrevious(bytes32 questionId) {
        require(
            msg.value >= questions[questionId].bond.safeMultiply(2),
            "Bond must be double at least previous bond"
        );
        _;
    }

    modifier bondMustNotExceedBounty(bytes32 questionId, uint256 bond) {
        require(
            questions[questionId].bond <= bond,
            "Bond must not exceed bounty"
        );
        _;
    }

    constructor() {
        createTemplate('{"title": "%s", "type": "bool", "category": "%s", "lang": "%s"}');
        createTemplate('{"title": "%s", "type": "uint", "decimals": 18, "category": "%s", "lang": "%s"}');
        createTemplate('{"title": "%s", "type": "single-select", "outcomes": [%s], "category": "%s", "lang": "%s"}');
        createTemplate('{"title": "%s", "type": "multiple-select", "outcomes": [%s], "category": "%s", "lang": "%s"}');
        createTemplate('{"title": "%s", "type": "datetime", "category": "%s", "lang": "%s"}');
    }

    function createTemplate(string memory content) public returns (uint256) {
        uint256 templateId = templateCount;
        templateCreationBlock[templateId] = block.number;
        templateHashes[templateId] = keccak256(abi.encodePacked(content));
        emit LogNewTemplate(templateId, msg.sender, content);
        templateCount = templateId.safeAdd(1);
        return templateId;
    }

    function createQuestion(
        string memory content,
        string memory questionContent,
        address arbitrator,
        uint32 timeout,
        uint32 openingTs,
        uint256 minBond
    ) public payable returns (bytes32) {
        uint256 templateId = createTemplate(content);
        return createQuestionWithTemplate(
            templateId,
            questionContent,
            arbitrator,
            timeout,
            openingTs,
            minBond
        );
    }

    function createQuestionWithTemplate(
        uint256 templateId,
        string memory questionContent,
        address arbitrator,
        uint32 timeout,
        uint32 openingTs,
        uint256 minBond
    ) public payable returns (bytes32) {
        require(templateCreationBlock[templateId] > 0, "Template must exist");
        bytes32 questionHash = keccak256(
            abi.encodePacked(templateId, openingTs, questionContent)
        );
        bytes32 questionId = keccak256(
            abi.encodePacked(questionHash, arbitrator, timeout, msg.sender, minBond)
        );
        initializeQuestion(
            questionId,
            questionHash,
            arbitrator,
            timeout,
            openingTs
        );
        emit LogNewQuestion(
            questionId,
            msg.sender,
            templateId,
            questionContent,
            questionHash,
            arbitrator,
            timeout,
            openingTs,
            minBond,
            now
        );
        return questionId;
    }

    function initializeQuestion(
        bytes32 questionId,
        bytes32 questionHash,
        address arbitrator,
        uint32 timeout,
        uint32 openingTs
    ) internal {
        require(timeout > 0, "Timeout must be positive");
        require(timeout < 365 days, "Timeout must be less than 365 days");
        require(arbitrator != NULL_ADDRESS, "Arbitrator must be set");
        uint256 bounty = msg.value;
        if (msg.sender != arbitrator) {
            uint256 fee = questionFees[arbitrator];
            require(bounty >= fee, "ETH provided must cover question fee");
            bounty = bounty.safeSubtract(fee);
            balances[arbitrator] = balances[arbitrator].safeAdd(fee);
        }
        questions[questionId].questionHash = questionHash;
        questions[questionId].arbitrator = arbitrator;
        questions[questionId].openingTs = openingTs;
        questions[questionId].timeout = timeout;
        questions[questionId].bounty = bounty;
    }

    function fundAnswerBounty(bytes32 questionId) external payable questionMustExist(questionId) {
        questions[questionId].bounty = questions[questionId].bounty.safeAdd(msg.value);
        emit LogFundAnswerBounty(questionId, msg.value, questions[questionId].bounty, msg.sender);
    }

    function submitAnswer(
        bytes32 questionId,
        bytes32 answerHash,
        uint256 bond
    ) external payable questionMustExist(questionId) bondMustBeDoublePrevious(questionId) bondMustNotExceedBounty(questionId, bond) {
        recordAnswer(questionId, answerHash, msg.sender, msg.value, false);
        finalizeAnswer(questionId, answerHash, questions[questionId].timeout);
    }

    function submitAnswerCommitment(
        bytes32 questionId,
        bytes32 answerCommitmentId,
        uint256 bond,
        address answerer
    ) external payable questionMustExist(questionId) bondMustBeDoublePrevious(questionId) bondMustNotExceedBounty(questionId, bond) {
        bytes32 commitmentId = keccak256(
            abi.encodePacked(questionId, answerCommitmentId, msg.value)
        );
        address finalAnswerer = (answerer == NULL_ADDRESS) ? msg.sender : answerer;
        require(
            commitments[commitmentId].revealDeadline == UNANSWERED,
            "Commitment must not already exist"
        );
        uint32 revealDeadline = questions[questionId].timeout / 8;
        commitments[commitmentId].revealDeadline = uint32(now).safeAdd(revealDeadline);
        recordAnswer(questionId, commitmentId, finalAnswerer, msg.value, true);
    }

    function revealAnswer(
        bytes32 questionId,
        bytes32 answerHash,
        uint256 bond,
        uint256 answer
    ) external questionMustBeFinalized(questionId) {
        bytes32 answerCommitmentId = keccak256(
            abi.encodePacked(answerHash, bond)
        );
        bytes32 commitmentId = keccak256(
            abi.encodePacked(questionId, answerCommitmentId, answer)
        );
        require(
            !commitments[commitmentId].isRevealed,
            "Commitment must not have been revealed yet"
        );
        require(
            commitments[commitmentId].revealDeadline > uint32(now),
            "Reveal deadline must not have passed"
        );
        commitments[commitmentId].answerHash = answerHash;
        commitments[commitmentId].isRevealed = true;
        if (answer == questions[questionId].bond) {
            finalizeAnswer(questionId, answerHash, questions[questionId].timeout);
        }
        emit LogAnswerReveal(questionId, msg.sender, answerCommitmentId, answerHash, bond, now);
    }

    function recordAnswer(
        bytes32 questionId,
        bytes32 answerHash,
        address answerer,
        uint256 bond,
        bool isCommitment
    ) internal {
        bytes32 answerCommitmentId = keccak256(
            abi.encodePacked(
                questions[questionId].lastAnswer,
                answerHash,
                bond,
                answerer,
                isCommitment
            )
        );
        if (bond > 0) {
            questions[questionId].bond = bond;
        }
        questions[questionId].lastAnswer = answerCommitmentId;
        emit LogNewAnswer(answerCommitmentId, questionId, answerCommitmentId, answerer, bond, now, isCommitment);
    }

    function finalizeAnswer(
        bytes32 questionId,
        bytes32 answerHash,
        uint32 timeout
    ) internal {
        questions[questionId].bestAnswer = answerHash;
        questions[questionId].finalizeTs = uint32(now).safeAdd(timeout);
    }

    function requestArbitration(
        bytes32 questionId,
        address requester,
        uint256 bond
    ) external onlyArbitrator(questionId) questionMustExist(questionId) bondMustNotExceedBounty(questionId, bond) {
        require(
            questions[questionId].bond > 0,
            "Question must already have a bond when arbitration is requested"
        );
        questions[questionId].isPendingArbitration = true;
        emit LogNotifyOfArbitrationRequest(questionId, requester);
    }

    function finalizeArbitration(
        bytes32 questionId,
        bytes32 answerHash,
        address finalAnswerer
    ) external onlyArbitrator(questionId) questionMustBePendingArbitration(questionId) {
        require(finalAnswerer != NULL_ADDRESS, "Final answerer must be provided");
        emit LogFinalize(questionId, answerHash);
        questions[questionId].isPendingArbitration = false;
        recordAnswer(questionId, answerHash, finalAnswerer, 0, false);
        finalizeAnswer(questionId, answerHash, 0);
    }

    function isFinalized(bytes32 questionId) public view returns (bool) {
        uint32 finalizeTs = questions[questionId].finalizeTs;
        return (
            !questions[questionId].isPendingArbitration &&
            (finalizeTs > UNANSWERED) &&
            (finalizeTs <= uint32(now))
        );
    }

    function getBestAnswer(bytes32 questionId) external view returns (bytes32) {
        return questions[questionId].bestAnswer;
    }

    function getLastAnswer(bytes32 questionId) external view returns (bytes32) {
        return questions[questionId].lastAnswer;
    }

    function verifyAnswer(
        bytes32 questionId,
        bytes32 questionHash,
        address arbitrator,
        uint32 timeout,
        uint256 bond
    ) external view returns (bytes32) {
        require(
            questionHash == questions[questionId].questionHash,
            "Question hash must match"
        );
        require(
            arbitrator == questions[questionId].arbitrator,
            "Arbitrator must match"
        );
        require(
            timeout <= questions[questionId].timeout,
            "Timeout must be long enough"
        );
        require(
            bond <= questions[questionId].bond,
            "Bond must be high enough"
        );
        return questions[questionId].bestAnswer;
    }

    function claimReward(
        bytes32 questionId,
        bytes32[] memory answerHashes,
        address[] memory answerers,
        uint256[] memory bonds,
        bytes32[] memory answerCommitmentIds
    ) public {
        require(answerHashes.length > 0, "At least one answer hash entry must be provided");
        address claimant = questionClaims[questionId].claimant;
        uint256 lastBond = questionClaims[questionId].lastBond;
        uint256 accumulatedBounty = questionClaims[questionId].accumulatedBounty;
        bytes32 lastAnswer = questions[questionId].bestAnswer;
        uint256 index;
        for (index = 0; index < answerHashes.length; index++) {
            bool isCommitment = verifyAnswer(
                lastAnswer,
                answerHashes[index],
                answerCommitmentIds[index],
                bonds[index],
                answerers[index]
            );
            accumulatedBounty = accumulatedBounty.safeAdd(lastBond);
            (accumulatedBounty, claimant) = processAnswer(
                questionId,
                questions[questionId].bestAnswer,
                accumulatedBounty,
                claimant,
                answerers[index],
                bonds[index],
                answerCommitmentIds[index],
                isCommitment
            );
            lastBond = bonds[index];
            lastAnswer = answerHashes[index];
        }
        if (lastAnswer != questions[questionId].bestAnswer) {
            if (claimant != NULL_ADDRESS) {
                distributeReward(questionId, claimant, accumulatedBounty);
                accumulatedBounty = 0;
            }
            questionClaims[questionId].claimant = claimant;
            questionClaims[questionId].lastBond = lastBond;
            questionClaims[questionId].accumulatedBounty = accumulatedBounty;
        } else {
            distributeReward(
                questionId,
                claimant,
                accumulatedBounty.safeAdd(lastBond)
            );
            delete questionClaims[questionId];
        }
        questions[questionId].lastAnswer = lastAnswer;
    }

    function distributeReward(
        bytes32 questionId,
        address claimant,
        uint256 amount
    ) internal {
        balances[claimant] = balances[claimant].safeAdd(amount);
        emit LogClaim(questionId, claimant, amount);
    }

    function verifyAnswer(
        bytes32 lastAnswer,
        bytes32 answerHash,
        bytes32 answerCommitmentId,
        uint256 bond,
        address answerer
    ) internal pure returns (bool) {
        if (
            lastAnswer ==
            keccak256(
                abi.encodePacked(answerCommitmentId, bond, answerer, true)
            )
        ) {
            return true;
        }
        if (
            lastAnswer ==
            keccak256(
                abi.encodePacked(answerHash, answerCommitmentId, bond, answerer, false)
            )
        ) {
            return false;
        }
        revert("Answer input provided did not match the expected hash");
    }

    function processAnswer(
        bytes32 questionId,
        bytes32 bestAnswer,
        uint256 accumulatedBounty,
        address claimant,
        address answerer,
        uint256 bond,
        bytes32 answerCommitmentId,
        bool isCommitment
    ) internal returns (uint256, address) {
        if (isCommitment) {
            bytes32 commitmentId = answerCommitmentId;
            if (!commitments[commitmentId].isRevealed) {
                delete commitments[commitmentId];
                return (accumulatedBounty, claimant);
            } else {
                answerCommitmentId = commitments[commitmentId].answerHash;
                delete commitments[commitmentId];
            }
        }
        if (answerCommitmentId == bestAnswer) {
            if (claimant == NULL_ADDRESS) {
                claimant = answerer;
                accumulatedBounty = accumulatedBounty.safeAdd(
                    questions[questionId].bounty
                );
                questions[questionId].bounty = 0;
            } else if (answerer != claimant) {
                uint256 reward = (accumulatedBounty >= bond)
                    ? bond
                    : accumulatedBounty;
                distributeReward(
                    questionId,
                    claimant,
                    accumulatedBounty.safeSubtract(reward)
                );
                claimant = answerer;
                accumulatedBounty = reward;
            }
        }
        return (accumulatedBounty, claimant);
    }

    function withdrawFees(
        bytes32[] memory questionIds,
        uint256[] memory amounts,
        bytes32[] memory answerHashes,
        address[] memory answerers,
        uint256[] memory bonds,
        bytes32[] memory answerCommitmentIds
    ) public {
        uint256 index;
        uint256 answerIndex;
        for (index = 0; index < questionIds.length; index++) {
            bytes32 questionId = questionIds[index];
            uint256 amount = amounts[index];
            bytes32[] memory answerHashesArray = new bytes32[](amount);
            address[] memory answerersArray = new address[](amount);
            uint256[] memory bondsArray = new uint256[](amount);
            bytes32[] memory answerCommitmentIdsArray = new bytes32[](amount);
            uint256 answerCount;
            for (answerCount = 0; answerCount < amount; answerCount++) {
                answerHashesArray[answerCount] = answerHashes[answerIndex];
                answerersArray[answerCount] = answerers[answerIndex];
                bondsArray[answerCount] = bonds[answerIndex];
                answerCommitmentIdsArray[answerCount] = answerCommitmentIds[answerIndex];
                answerIndex++;
            }
            claimReward(
                questionId,
                answerHashesArray,
                answerersArray,
                bondsArray,
                answerCommitmentIdsArray
            );
        }
        withdraw();
    }

    function getQuestionHash(bytes32 questionId) public view returns (bytes32) {
        return questions[questionId].questionHash;
    }

    function getArbitrator(bytes32 questionId) public view returns (address) {
        return questions[questionId].arbitrator;
    }

    function getOpeningTs(bytes32 questionId) public view returns (uint32) {
        return questions[questionId].openingTs;
    }

    function getTimeout(bytes32 questionId) public view returns (uint32) {
        return questions[questionId].timeout;
    }

    function getFinalizeTs(bytes32 questionId) public view returns (uint32) {
        return questions[questionId].finalizeTs;
    }

    function isPendingArbitration(bytes32 questionId) public view returns (bool) {
        return questions[questionId].isPendingArbitration;
    }

    function getBounty(bytes32 questionId) public view returns (uint256) {
        return questions[questionId].bounty;
    }

    function getBestAnswer(bytes32 questionId) public view returns (bytes32) {
        return questions[questionId].bestAnswer;
    }

    function getLastAnswer(bytes32 questionId) public view returns (bytes32) {
        return questions[questionId].lastAnswer;
    }

    function getBond(bytes32 questionId) public view returns (uint256) {
        return questions[questionId].bond;
    }
}

contract ArbitrationManager is Ownable {
    QuestionManager public questionManager;
    mapping(bytes32 => uint256) public disputeFees;
    uint256 public defaultDisputeFee;
    mapping(bytes32 => uint256) customDisputeFees;
    string public metadata;

    event LogRequestArbitration(
        bytes32 indexed questionId,
        uint256 amount,
        address requester,
        uint256 remainingFee
    );
    event LogSetQuestionManager(address questionManager);
    event LogSetQuestionFee(uint256 fee);
    event LogSetDisputeFee(uint256 fee);
    event LogSetCustomDisputeFee(bytes32 indexed questionId, uint256 fee);

    constructor() {
        owner = msg.sender;
    }

    function getQuestionManager() external view returns (QuestionManager) {
        return questionManager;
    }

    function setQuestionManager(address manager) public onlyOwner {
        questionManager = QuestionManager(manager);
        emit LogSetQuestionManager(manager);
    }

    function setDisputeFee(uint256 fee) public onlyOwner {
        defaultDisputeFee = fee;
        emit LogSetDisputeFee(fee);
    }

    function setCustomDisputeFee(bytes32 questionId, uint256 fee) public onlyOwner {
        customDisputeFees[questionId] = fee;
        emit LogSetCustomDisputeFee(questionId, fee);
    }

    function getDisputeFee(bytes32 questionId) public view returns (uint256) {
        return (customDisputeFees[questionId] > 0) ? customDisputeFees[questionId] : defaultDisputeFee;
    }

    function setQuestionFee(uint256 fee) public onlyOwner {
        questionManager.setQuestionFee(fee);
        emit LogSetQuestionFee(fee);
    }

    function finalizeArbitration(
        bytes32 questionId,
        bytes32 answerHash,
        address finalAnswerer
    ) public onlyOwner {
        delete disputeFees[questionId];
        questionManager.finalizeArbitration(questionId, answerHash, finalAnswerer);
    }

    function requestArbitration(
        bytes32 questionId,
        uint256 bond
    ) external payable returns (bool) {
        uint256 fee = getDisputeFee(questionId);
        require(fee > 0, "Arbitrator must have set a non-zero fee for the question");
        disputeFees[questionId] += msg.value;
        uint256 totalFee = disputeFees[questionId];
        if (totalFee >= fee) {
            questionManager.requestArbitration(questionId, msg.sender, bond);
            emit LogRequestArbitration(questionId, msg.value, msg.sender, 0);
            return true;
        } else {
            require(
                !questionManager.isFinalized(questionId),
                "Question must not have been finalized"
            );
            emit LogRequestArbitration(questionId, msg.value, msg.sender, fee - totalFee);
            return false;
        }
    }

    function withdrawFees(address recipient) public onlyOwner {
        payable(recipient).transfer(address(this).balance);
    }

    function withdrawAccumulatedFees() public onlyOwner {
        questionManager.withdraw();
    }

    function setMetadata(string memory newMetadata) public onlyOwner {
        metadata = newMetadata;
    }
}
```