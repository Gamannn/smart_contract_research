```solidity
pragma solidity ^0.4.18;

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

library SafeMath32 {
    function add(uint32 a, uint32 b) internal pure returns (uint32) {
        uint32 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract BalanceHolder {
    mapping(address => uint256) public balanceOf;
    
    event LogWithdraw(
        address indexed user,
        uint256 amount
    );
    
    function withdraw() public {
        uint256 amount = balanceOf[msg.sender];
        balanceOf[msg.sender] = 0;
        msg.sender.transfer(amount);
        emit LogWithdraw(msg.sender, amount);
    }
}

contract Owned {
    address public owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract Realitio is BalanceHolder, Owned {
    using SafeMath for uint256;
    using SafeMath32 for uint32;
    
    address constant NULL_ADDRESS = address(0);
    uint32 constant UNANSWERED = 0;
    
    event LogNewTemplate(
        uint256 indexed template_id,
        address indexed user,
        string question_text
    );
    
    event LogNewQuestion(
        bytes32 indexed question_id,
        address indexed user,
        uint256 template_id,
        string question,
        bytes32 indexed content_hash,
        address arbitrator,
        uint32 timeout,
        uint32 opening_ts,
        uint256 nonce,
        uint256 created
    );
    
    event LogFundAnswerBounty(
        bytes32 indexed question_id,
        uint256 bounty_added,
        uint256 bounty,
        address indexed user
    );
    
    event LogNewAnswer(
        bytes32 answer,
        bytes32 indexed question_id,
        bytes32 history_hash,
        address indexed user,
        uint256 bond,
        uint256 ts,
        bool is_commitment
    );
    
    event LogAnswerReveal(
        bytes32 indexed question_id,
        address indexed user,
        bytes32 indexed answer_hash,
        bytes32 answer,
        uint256 nonce,
        uint256 bond
    );
    
    event LogNotifyOfArbitrationRequest(
        bytes32 indexed question_id,
        address indexed user
    );
    
    event LogFinalize(
        bytes32 indexed question_id,
        bytes32 indexed answer
    );
    
    event LogClaim(
        bytes32 indexed question_id,
        address indexed user,
        uint256 amount
    );
    
    struct Question {
        bytes32 content_hash;
        address arbitrator;
        uint32 opening_ts;
        uint32 timeout;
        uint32 finalize_ts;
        bool is_pending_arbitration;
        uint256 bounty;
        bytes32 best_answer;
        bytes32 history_hash;
        uint256 bond;
    }
    
    struct Commitment {
        uint32 commit_ts;
        bool is_revealed;
        bytes32 revealed_answer;
    }
    
    struct Claim {
        address payee;
        uint256 last_bond;
        uint256 queued_funds;
    }
    
    uint256 public template_count = 0;
    mapping(uint256 => uint256) public template_question_counts;
    mapping(uint256 => bytes32) public template_hashes;
    mapping(bytes32 => Question) public questions;
    mapping(bytes32 => Claim) public question_claims;
    mapping(bytes32 => Commitment) public commitments;
    mapping(address => uint256) public arbitrator_question_fees;
    
    modifier onlyArbitrator(bytes32 question_id) {
        require(msg.sender == questions[question_id].arbitrator, "msg.sender must be arbitrator");
        _;
    }
    
    modifier anyValue() {
        _;
    }
    
    modifier questionMustNotExist(bytes32 question_id) {
        require(questions[question_id].timeout == 0, "question must not exist");
        _;
    }
    
    modifier questionMustExist(bytes32 question_id) {
        require(questions[question_id].timeout > 0, "question must exist");
        require(!questions[question_id].is_pending_arbitration, "question must not be pending arbitration");
        uint32 finalize_ts = questions[question_id].finalize_ts;
        require(finalize_ts > UNANSWERED, "finalization deadline must not have passed");
        uint32 opening_ts = questions[question_id].opening_ts;
        require(opening_ts == 0 || opening_ts <= uint32(now), "opening date must have passed");
        _;
    }
    
    modifier pendingArbitration(bytes32 question_id) {
        require(questions[question_id].is_pending_arbitration, "question must be pending arbitration");
        _;
    }
    
    modifier notPendingArbitration(bytes32 question_id) {
        require(questions[question_id].timeout > 0, "question must exist");
        uint32 finalize_ts = questions[question_id].finalize_ts;
        require(finalize_ts == UNANSWERED || finalize_ts > uint32(now), "finalization deadline must not have passed");
        uint32 opening_ts = questions[question_id].opening_ts;
        require(opening_ts == UNANSWERED || opening_ts <= uint32(now), "opening date must have passed");
        _;
    }
    
    modifier mustBeFinalized(bytes32 question_id) {
        require(isFinalized(question_id), "question must be finalized");
        _;
    }
    
    modifier bondMustBeZero() {
        require(msg.value > 0, "bond must be positive");
        _;
    }
    
    modifier bondMustDouble(bytes32 question_id) {
        require(msg.value > 0, "bond must be positive");
        require(msg.value >= (questions[question_id].bond.mul(2)), "bond must be double at least previous bond");
        _;
    }
    
    modifier bondMustBeAtLeast(bytes32 question_id, uint256 min_bond) {
        if (min_bond > 0) {
            require(questions[question_id].bond <= min_bond, "bond must be at least min_bond");
        }
        _;
    }
    
    constructor() public {
        createTemplate('{"title": "%s", "type": "bool", "category": "%s", "lang": "%s"}');
        createTemplate('{"title": "%s", "type": "uint", "decimals": 18, "category": "%s", "lang": "%s"}');
        createTemplate('{"title": "%s", "type": "single-select", "outcomes": [%s], "category": "%s", "lang": "%s"}');
        createTemplate('{"title": "%s", "type": "multiple-select", "outcomes": [%s], "category": "%s", "lang": "%s"}');
        createTemplate('{"title": "%s", "type": "datetime", "category": "%s", "lang": "%s"}');
    }
    
    function setQuestionFee(uint256 fee) anyValue() external {
        arbitrator_question_fees[msg.sender] = fee;
        emit LogSetQuestionFee(msg.sender, fee);
    }
    
    function createTemplate(string question_text) anyValue() public returns (uint256) {
        uint256 template_id = template_count;
        template_question_counts[template_id] = block.number;
        template_hashes[template_id] = keccak256(abi.encodePacked(question_text));
        emit LogNewTemplate(template_id, msg.sender, question_text);
        template_count = template_id.add(1);
        return template_id;
    }
    
    function createQuestionAndTemplate(
        string question_text,
        string question,
        address arbitrator,
        uint32 timeout,
        uint32 opening_ts,
        uint256 nonce
    ) public payable returns (bytes32) {
        uint256 template_id = createTemplate(question_text);
        return createQuestion(template_id, question, arbitrator, timeout, opening_ts, nonce);
    }
    
    function createQuestion(
        uint256 template_id,
        string question,
        address arbitrator,
        uint32 timeout,
        uint32 opening_ts,
        uint256 nonce
    ) public payable returns (bytes32) {
        require(template_question_counts[template_id] > 0, "template must exist");
        bytes32 content_hash = keccak256(abi.encodePacked(template_id, opening_ts, question));
        bytes32 question_id = keccak256(abi.encodePacked(content_hash, arbitrator, timeout, msg.sender, nonce));
        initializeQuestion(question_id, content_hash, arbitrator, timeout, opening_ts);
        emit LogNewQuestion(question_id, msg.sender, template_id, question, content_hash, arbitrator, timeout, opening_ts, nonce, now);
        return question_id;
    }
    
    function initializeQuestion(
        bytes32 question_id,
        bytes32 content_hash,
        address arbitrator,
        uint32 timeout,
        uint32 opening_ts
    ) questionMustNotExist(question_id) internal {
        require(timeout > 0, "timeout must be positive");
        require(timeout < 365 days, "timeout must be less than 365 days");
        require(arbitrator != NULL_ADDRESS, "arbitrator must be set");
        
        uint256 bounty = msg.value;
        
        if (msg.sender != arbitrator) {
            uint256 question_fee = arbitrator_question_fees[arbitrator];
            require(bounty >= question_fee, "ETH provided must cover question fee");
            bounty = bounty.sub(question_fee);
            balanceOf[arbitrator] = balanceOf[arbitrator].add(question_fee);
        }
        
        questions[question_id].content_hash = content_hash;
        questions[question_id].arbitrator = arbitrator;
        questions[question_id].opening_ts = opening_ts;
        questions[question_id].timeout = timeout;
        questions[question_id].bounty = bounty;
    }
    
    function fundAnswerBounty(bytes32 question_id) questionMustExist(question_id) external payable {
        questions[question_id].bounty = questions[question_id].bounty.add(msg.value);
        emit LogFundAnswerBounty(question_id, msg.value, questions[question_id].bounty, msg.sender);
    }
    
    function submitAnswer(bytes32 question_id, bytes32 answer, uint256 max_previous) 
        questionMustExist(question_id)
        bondMustDouble(question_id)
        bondMustBeAtLeast(question_id, max_previous)
        external payable 
    {
        _addAnswerToHistory(question_id, answer, msg.sender, msg.value, false);
        _updateCurrentAnswer(question_id, answer, questions[question_id].timeout);
    }
    
    function submitAnswerCommitment(bytes32 question_id, bytes32 answer_hash, uint256 max_previous, address _answerer) 
        questionMustExist(question_id)
        bondMustDouble(question_id)
        bondMustBeAtLeast(question_id, max_previous)
        external payable 
    {
        bytes32 commitment_id = keccak256(abi.encodePacked(question_id, answer_hash, msg.value));
        address answerer = (_answerer == NULL_ADDRESS) ? msg.sender : _answerer;
        require(commitments[commitment_id].commit_ts == 0, "commitment must not already exist");
        
        uint32 commit_timeout = questions[question_id].timeout / 8;
        commitments[commitment_id].commit_ts = uint32(now).add(commit_timeout);
        
        _addAnswerToHistory(question_id, commitment_id, answerer, msg.value, true);
    }
    
    function submitAnswerReveal(bytes32 question_id, bytes32 answer, uint256 nonce, uint256 bond) 
        notPendingArbitration(question_id) 
        external 
    {
        bytes32 answer_hash = keccak256(abi.encodePacked(answer, nonce));
        bytes32 commitment_id = keccak256(abi.encodePacked(question_id, answer_hash, bond));
        
        require(!commitments[commitment_id].is_revealed, "commitment must not have been revealed yet");
        require(commitments[commitment_id].commit_ts > uint32(now), "reveal deadline must not have passed");
        
        commitments[commitment_id].revealed_answer = answer;
        commitments[commitment_id].is_revealed = true;
        
        if (bond == questions[question_id].bond) {
            _updateCurrentAnswer(question_id, answer, questions[question_id].timeout);
        }
        
        emit LogAnswerReveal(question_id, msg.sender, answer_hash, answer, nonce, bond);
    }
    
    function _addAnswerToHistory(
        bytes32 question_id,
        bytes32 answer,
        address answerer,
        uint256 bond,
        bool is_commitment
    ) internal {
        bytes32 new_history_hash = keccak256(abi.encodePacked(
            questions[question_id].history_hash,
            answer,
            bond,
            answerer,
            is_commitment
        ));
        
        if (bond > 0) {
            questions[question_id].bond = bond;
        }
        
        questions[question_id].history_hash = new_history_hash;
        emit LogNewAnswer(answer, question_id, new_history_hash, answerer, bond, now, is_commitment);
    }
    
    function _updateCurrentAnswer(bytes32 question_id, bytes32 answer, uint32 timeout) internal {
        questions[question_id].best_answer = answer;
        questions[question_id].finalize_ts = uint32(now).add(timeout);
    }
    
    function notifyOfArbitrationRequest(
        bytes32 question_id,
        address requester,
        uint256 max_previous
    ) 
        onlyArbitrator(question_id)
        questionMustExist(question_id)
        bondMustBeAtLeast(question_id, max_previous)
        external 
    {
        require(questions[question_id].bond > 0, "Question must already have an answer when arbitration is requested");
        questions[question_id].is_pending_arbitration = true;
        emit LogNotifyOfArbitrationRequest(question_id, requester);
    }
    
    function acceptAnswer(
        bytes32 question_id,
        bytes32 answer,
        address answerer
    ) 
        onlyArbitrator(question_id)
        pendingArbitration(question_id)
        bondMustBeZero()
        external 
    {
        require(answerer != NULL_ADDRESS, "answerer must be provided");
        emit LogFinalize(question_id, answer);
        questions[question_id].is_pending_arbitration = false;
        _addAnswerToHistory(question_id, answer, answerer, 0, false);
        _updateCurrentAnswer(question_id, answer, 0);
    }
    
    function isFinalized(bytes32 question_id) view public returns (bool) {
        uint32 finalize_ts = questions[question_id].finalize_ts;
        return (
            !questions[question_id].is_pending_arbitration &&
            (finalize_ts > UNANSWERED) &&
            (finalize_ts <= uint32(now))
        );
    }
    
    function getBestAnswer(bytes32 question_id) external view returns (bytes32) {
        return questions[question_id].best_answer;
    }
    
    function getHistoryHash(bytes32 question_id) external view returns (bytes32) {
        return questions[question_id].history_hash;
    }
    
    function getBond(bytes32 question_id) external view returns (uint256) {
        return questions[question_id].bond;
    }
    
    function claimWinnings(
        bytes32 question_id,
        bytes32[] history_hashes,
        address[] addrs,
        uint256[] bonds,
        bytes32[] answers
    ) mustBeFinalized(question_id) public {
        require(history_hashes.length > 0, "at least one history hash entry must be provided");
        
        address payee = question_claims[question_id].payee;
        uint256 last_bond = question_claims[question_id].last_bond;
        uint256 queued_funds = question_claims[question_id].queued_funds;
        
        bytes32 last_history_hash = questions[question_id].best_answer;
        
        uint256 i;
        for (i = 0; i < history_hashes.length; i++) {
            bool is_commitment = _verifyHistoryInput(
                last_history_hash,
                history_hashes[i],
                answers[i],
                bonds[i],
                addrs[i]
            );
            
            queued_funds = queued_funds.add(last_bond);
            (queued_funds, payee) = _processHistoryItem(
                question_id,
                questions[question_id].best_answer,
                queued_funds,
                payee,
                addrs[i],
                bonds[i],
                answers[i],
                is_commitment
            );
            
            last_bond = bonds[i];
            last_history_hash = history_hashes[i];
        }
        
        if (last_history_hash != questions[question_id].history_hash) {
            if (payee != NULL_ADDRESS) {
                _payClaimReward(question_id, payee, queued_funds);
                queued_funds = 0;
            }
            question_claims[question_id].payee = payee;
            question_claims[question_id].last_bond = last_bond;
            question_claims[question_id].queued_funds = queued_funds;
        } else {
            _payClaimReward(question_id, payee, queued_funds.add(last_bond));
            delete question_claims[question_id];
        }
        
        questions[question_id].history_hash = last_history_hash;
    }
    
    function _payClaimReward(bytes32 question_id, address payee, uint256 amount) internal {
        balanceOf[payee] = balance