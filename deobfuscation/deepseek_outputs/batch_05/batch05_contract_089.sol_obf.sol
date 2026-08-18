pragma solidity ^0.4.24;

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

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract Realitio is BalanceHolder, Owned {
    using SafeMath for uint256;
    using SafeMath32 for uint32;

    address constant NULL_ADDRESS = address(0);
    bytes32 constant NULL_HASH = bytes32(0);
    uint32 constant NULL_TIMESTAMP = 0;

    event LogNewTemplate(
        uint256 indexed template_id,
        address indexed user,
        string question_text
    );

    event LogNewQuestion(
        bytes32 indexed question_id,
        address indexed user,
        uint256 template_id,
        string question_text,
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
        uint32 reveal_ts;
        bool is_revealed;
        bytes32 revealed_answer;
    }

    struct Claim {
        address owner;
        uint256 bond;
        uint256 value;
    }

    uint256 template_id = 0;
    mapping(uint256 => uint256) public template_created;
    mapping(uint256 => bytes32) public template_content_hash;
    mapping(bytes32 => Question) public questions;
    mapping(bytes32 => Claim) public question_claims;
    mapping(bytes32 => Commitment) public commitments;
    mapping(address => uint256) public arbitrator_question_fees;

    modifier onlyArbitrator(bytes32 question_id) {
        require(msg.sender == questions[question_id].arbitrator, "msg.sender must be arbitrator");
        _;
    }

    modifier noArbitration(bytes32 question_id) {
        require(questions[question_id].timeout > 0, "question must not exist");
        require(!questions[question_id].is_pending_arbitration, "question must not be pending arbitration");
        uint32 finalize_ts = questions[question_id].finalize_ts;
        require(finalize_ts > uint32(now), "finalization deadline must not have passed");
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
        require(finalize_ts == NULL_TIMESTAMP || finalize_ts > uint32(now), "finalization dealine must not have passed");
        uint32 opening_ts = questions[question_id].opening_ts;
        require(opening_ts == NULL_TIMESTAMP || opening_ts <= uint32(now), "opening date must have passed");
        _;
    }

    modifier isFinalized(bytes32 question_id) {
        require(question_is_finalized(question_id), "question must be finalized");
        _;
    }

    modifier bondMustBeZero() {
        require(msg.value == 0, "bond must be zero");
        _;
    }

    modifier bondMustBePositive(bytes32 question_id) {
        require(msg.value > 0, "bond must be positive");
        require(msg.value >= (questions[question_id].bond.mul(2)), "bond must be double at least previous bond");
        _;
    }

    modifier bondMustBeAtLeast(bytes32 question_id, uint256 bond) {
        require(questions[question_id].bond <= bond, "bond must be at least");
        _;
    }

    constructor() public {
        createTemplate('{"title": "%s", "type": "bool", "category": "%s", "lang": "%s"}');
        createTemplate('{"title": "%s", "type": "uint", "decimals": 18, "category": "%s", "lang": "%s"}');
        createTemplate('{"title": "%s", "type": "single-select", "outcomes": [%s], "category": "%s", "lang": "%s"}');
        createTemplate('{"title": "%s", "type": "multiple-select", "outcomes": [%s], "category": "%s", "lang": "%s"}');
        createTemplate('{"title": "%s", "type": "datetime", "category": "%s", "lang": "%s"}');
    }

    function setQuestionFee(uint256 fee) external {
        arbitrator_question_fees[msg.sender] = fee;
        emit LogSetQuestionFee(msg.sender, fee);
    }

    function createTemplate(string content) public returns (uint256) {
        uint256 id = template_id;
        template_created[id] = block.number;
        template_content_hash[id] = keccak256(abi.encodePacked(content));
        emit LogNewTemplate(id, msg.sender, content);
        template_id = id.add(1);
        return id;
    }

    function createQuestion(
        string content,
        string question_text,
        address arbitrator,
        uint32 timeout,
        uint32 opening_ts,
        uint256 nonce
    ) public payable returns (bytes32) {
        uint256 template_id = createTemplate(content);
        return createQuestionInternal(template_id, question_text, arbitrator, timeout, opening_ts, nonce);
    }

    function createQuestionInternal(
        uint256 template_id,
        string question_text,
        address arbitrator,
        uint32 timeout,
        uint32 opening_ts,
        uint256 nonce
    ) public payable returns (bytes32) {
        require(template_created[template_id] > 0, "template must exist");
        bytes32 content_hash = keccak256(abi.encodePacked(template_id, opening_ts, question_text));
        bytes32 question_id = keccak256(abi.encodePacked(content_hash, arbitrator, timeout, msg.sender, nonce));
        createQuestionInternal(question_id, content_hash, arbitrator, timeout, opening_ts);
        emit LogNewQuestion(question_id, msg.sender, template_id, question_text, content_hash, arbitrator, timeout, opening_ts, nonce, now);
        return question_id;
    }

    function createQuestionInternal(bytes32 question_id, bytes32 content_hash, address arbitrator, uint32 timeout, uint32 opening_ts) internal {
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

    function fundAnswerBounty(bytes32 question_id) external payable {
        require(questions[question_id].timeout > 0, "question must exist");
        require(!questions[question_id].is_pending_arbitration, "question must not be pending arbitration");
        uint32 finalize_ts = questions[question_id].finalize_ts;
        require(finalize_ts > uint32(now), "finalization deadline must not have passed");
        uint32 opening_ts = questions[question_id].opening_ts;
        require(opening_ts == 0 || opening_ts <= uint32(now), "opening date must have passed");
        questions[question_id].bounty = questions[question_id].bounty.add(msg.value);
        emit LogFundAnswerBounty(question_id, msg.value, questions[question_id].bounty, msg.sender);
    }

    function submitAnswer(bytes32 question_id, bytes32 answer, uint256 bond) external payable {
        require(questions[question_id].timeout > 0, "question must exist");
        require(!questions[question_id].is_pending_arbitration, "question must not be pending arbitration");
        uint32 finalize_ts = questions[question_id].finalize_ts;
        require(finalize_ts > uint32(now), "finalization deadline must not have passed");
        uint32 opening_ts = questions[question_id].opening_ts;
        require(opening_ts == 0 || opening_ts <= uint32(now), "opening date must have passed");
        require(msg.value > 0, "bond must be positive");
        require(msg.value >= (questions[question_id].bond.mul(2)), "bond must be double at least previous bond");
        require(questions[question_id].bond <= bond, "bond must be at least");
        submitAnswerInternal(question_id, answer, msg.sender, msg.value, false);
        setBestAnswer(question_id, answer, questions[question_id].timeout);
    }

    function submitAnswerCommitment(bytes32 question_id, bytes32 answer_hash, uint256 bond, address arbitrator) external payable {
        require(questions[question_id].timeout > 0, "question must exist");
        require(!questions[question_id].is_pending_arbitration, "question must not be pending arbitration");
        uint32 finalize_ts = questions[question_id].finalize_ts;
        require(finalize_ts > uint32(now), "finalization deadline must not have passed");
        uint32 opening_ts = questions[question_id].opening_ts;
        require(opening_ts == 0 || opening_ts <= uint32(now), "opening date must have passed");
        require(msg.value > 0, "bond must be positive");
        require(msg.value >= (questions[question_id].bond.mul(2)), "bond must be double at least previous bond");
        require(questions[question_id].bond <= bond, "bond must be at least");
        bytes32 commitment_id = keccak256(abi.encodePacked(question_id, answer_hash, msg.value));
        address user = (arbitrator == NULL_ADDRESS) ? msg.sender : arbitrator;
        require(commitments[commitment_id].reveal_ts == 0, "commitment must not already exist");
        uint32 reveal_ts = questions[question_id].timeout / 2;
        commitments[commitment_id].reveal_ts = uint32(now).add(reveal_ts);
        submitAnswerInternal(question_id, commitment_id, user, msg.value, true);
    }

    function submitAnswerReveal(bytes32 question_id, bytes32 answer, uint256 nonce, uint256 bond) external {
        require(questions[question_id].timeout > 0, "question must exist");
        require(!questions[question_id].is_pending_arbitration, "question must not be pending arbitration");
        uint32 finalize_ts = questions[question_id].finalize_ts;
        require(finalize_ts > uint32(now), "finalization deadline must not have passed");
        uint32 opening_ts = questions[question_id].opening_ts;
        require(opening_ts == 0 || opening_ts <= uint32(now), "opening date must have passed");
        require(msg.value > 0, "bond must be positive");
        require(msg.value >= (questions[question_id].bond.mul(2)), "bond must be double at least previous bond");
        require(questions[question_id].bond <= bond, "bond must be at least");
        bytes32 answer_hash = keccak256(abi.encodePacked(answer, nonce));
        bytes32 commitment_id = keccak256(abi.encodePacked(question_id, answer_hash, bond));
        require(!commitments[commitment_id].is_revealed, "commitment must not have been revealed yet");
        require(commitments[commitment_id].reveal_ts > uint32(now), "reveal deadline must not have passed");
        commitments[commitment_id].revealed_answer = answer;
        commitments[commitment_id].is_revealed = true;
        if (bond == questions[question_id].bond) {
            setBestAnswer(question_id, answer, questions[question_id].timeout);
        }
        emit LogAnswerReveal(question_id, msg.sender, answer_hash, answer, nonce, bond);
    }

    function submitAnswerInternal(bytes32 question_id, bytes32 answer, address user, uint256 bond, bool is_commitment) internal {
        bytes32 history_hash = keccak256(abi.encodePacked(questions[question_id].history_hash, answer, bond, user, is_commitment));
        if (bond > 0) {
            questions[question_id].bond = bond;
        }
        questions[question_id].history_hash = history_hash;
        emit LogNewAnswer(answer, question_id, history_hash, user, bond, now, is_commitment);
    }

    function setBestAnswer(bytes32 question_id, bytes32 answer, uint32 timeout) internal {
        questions[question_id].best_answer = answer;
        questions[question_id].finalize_ts = uint32(now).add(timeout);
    }

    function notifyOfArbitrationRequest(bytes32 question_id, address user, uint256 bond) external {
        require(msg.sender == questions[question_id].arbitrator, "msg.sender must be arbitrator");
        require(questions[question_id].timeout > 0, "question must exist");
        require(!questions[question_id].is_pending_arbitration, "question must not be pending arbitration");
        uint32 finalize_ts = questions[question_id].finalize_ts;
        require(finalize_ts > uint32(now), "finalization deadline must not have passed");
        uint32 opening_ts = questions[question_id].opening_ts;
        require(opening_ts == 0 || opening_ts <= uint32(now), "opening date must have passed");
        require(msg.value > 0, "bond must be positive");
        require(msg.value >= (questions[question_id].bond.mul(2)), "bond must be double at least previous bond");
        require(questions[question_id].bond <= bond, "bond must be at least");
        require(questions[question_id].bond > 0, "Question must already have an answer when arbitration is requested");
        questions[question_id].is_pending_arbitration = true;
        emit LogNotifyOfArbitrationRequest(question_id, user);
    }

    function finalize(bytes32 question_id, bytes32 answer, address user) external {
        require(msg.sender == questions[question_id].arbitrator, "msg.sender must be arbitrator");
        require(questions[question_id].is_pending_arbitration, "question must be pending arbitration");
        require(user != NULL_ADDRESS, "user must be provided");
        emit LogFinalize(question_id, answer);
        questions[question_id].is_pending_arbitration = false;
        submitAnswerInternal(question_id, answer, user, 0, false);
        setBestAnswer(question_id, answer, 0);
    }

    function question_is_finalized(bytes32 question_id) view public returns (bool) {
        uint32 finalize_ts = questions[question_id].finalize_ts;
        return ( !questions[question_id].is_pending_arbitration && (finalize_ts > NULL_TIMESTAMP) && (finalize_ts <= uint32(now)) );
    }

    function getBestAnswer(bytes32 question_id) external view returns (bytes32) {
        return questions[question_id].best_answer;
    }

    function getBestAnswer2(bytes32 question_id) external view returns (bytes32) {
        return questions[question_id].best_answer;
    }

    function getBestAnswer3(
        bytes32 question_id,
        bytes32 content_hash,
        address arbitrator,
        uint32 timeout,
        uint256 bond
    ) external view returns (bytes32) {
        require(content_hash == questions[question_id].content_hash, "content hash must match");
        require(arbitrator == questions[question_id].arbitrator, "arbitrator must match");
        require(timeout <= questions[question_id].timeout, "timeout must be long enough");
        require(bond <= questions[question_id].bond, "bond must be high enough");
        return questions[question_id].best_answer;
    }

    function claimWinnings(
        bytes32 question_id,
        bytes32[] history_hashes,
        address[] addrs,
        uint256[] bonds,
        bytes32[] answers
    ) public {
        require(history_hashes.length > 0, "at least one history hash entry must be provided");
        address owner = question_claims[question_id].owner;
        uint256 bond = question_claims[question_id].bond;
        uint256 value = question_claims[question_id].value;
        bytes32 previous_answer = questions[question_id].best_answer;
        uint256 i;
        for (i = 0; i < history_hashes.length; i++) {
            bool is_commitment = isHistoryInputValid(previous_answer, history_hashes[i], answers[i], bonds[i], addrs[i]);
            value = value.add(bond);
            (value, owner) = updateClaim(question_id, previous_answer, value, owner, addrs[i], bonds[i], answers[i], is_commitment);
            bond = bonds[i];
            previous_answer = history_hashes[i];
        }
        if (previous_answer != NULL_HASH) {
            if (owner != NULL_ADDRESS) {
                claim(question_id, owner, value);
                value = 0;
            }
            question_claims[question_id].owner = owner;
            question_claims[question_id].bond = bond;
            question_claims[question_id].value = value;
        } else {
            claim(question_id, owner, value.add(bond));
            delete question_claims[question_id];
        }
        questions[question_id].history_hash = previous_answer;
    }

    function claim(bytes32 question_id, address owner, uint256 amount) internal {
        balanceOf[owner] = balanceOf[owner].add(amount);
        emit LogClaim(question_id, owner, amount);
    }

    function isHistoryInputValid(
        bytes32 previous_answer,
        bytes32 history_hash,
        bytes32 answer,
        uint256 bond,
        address user
    ) internal pure returns (bool) {
        if (previous_answer == keccak256(abi.encodePacked(NULL_HASH, answer, bond, user, true)) ) {
            return true;
        }
        if (previous_answer == keccak256(abi.encodePacked(history_hash, answer, bond, user, false)) ) {
            return false;
        }
        revert("History input provided did not match the expected hash");
    }

    function updateClaim(
        bytes32 question_id,
        bytes32 best_answer,
        uint256 value,
        address owner,
        address user,
        uint256 bond,
        bytes32 answer,
        bool is_commitment
    ) internal returns (uint256, address) {
        if (is_commitment) {
            bytes32 commitment_id = answer;
            if (!commitments[commitment_id].is_revealed) {
                delete commitments[commitment_id];
                return (value, owner);
            } else {
                answer = commitments[commitment_id].revealed_answer;
                delete commitments[commitment_id];
            }
        }
        if (answer == best_answer) {
            if (owner == NULL_ADDRESS) {
                owner = user;
                value = value.add(questions[question_id].bounty);
                questions[question_id].bounty = 0;
            } else if (user != owner) {
                uint256 reward = (value >= bond) ? bond : value;
                claim(question_id, owner, value.sub(reward));
                owner = user;
                value = reward;
            }
        }
        return (value, owner);
    }

    function claimMultiple(
        bytes32[] question_ids,
        uint256[] lengths,
        bytes32[] history_hashes,
        address[] addrs,
        uint256[] bonds,
        bytes32[] answers
    ) public {
        uint256 i;
        uint256 j;
        for (i = 0; i < question_ids.length; i++) {
            bytes32 question_id = question_ids[i];
            uint256 length = lengths[i];
            bytes32[] memory history_hashes_i = new bytes32[](length);
            address[] memory addrs_i = new address[](length);
            uint256[] memory bonds_i = new uint256[](length);
            bytes32[] memory answers_i = new bytes32[](length);
            uint256 k;
            for (k = 0; k < length; k++) {
                history_hashes_i[k] = history_hashes[j];
                addrs_i[k] = addrs[j];
                bonds_i[k] = bonds[j];
                answers_i[k] = answers[j];
                j++;
            }
            claimWinnings(question_id, history_hashes_i, addrs_i, bonds_i, answers_i);
        }
        withdraw();
    }

    function getContentHash(bytes32 question_id) public view returns(bytes32) {
        return questions[question_id].content_hash;
    }

    function getArbitrator(bytes32 question_id) public view returns(address) {
        return questions[question_id].arbitrator;
    }

    function getOpeningTs(bytes32 question_id) public view returns(uint32) {
        return questions[question_id].opening_ts;
    }

    function getTimeout(bytes32 question_id) public view returns(uint32) {
        return questions[question_id].timeout;
    }

    function getFinalizeTs(bytes32 question_id) public view returns(uint32) {
        return questions[question_id].finalize_ts;
    }

    function isPendingArbitration(bytes32 question_id) public view returns(bool) {
        return questions[question_id].is_pending_arbitration;
    }

    function getBounty(bytes32 question_id) public view returns(uint256) {
        return questions[question_id].bounty;
    }

    function getBestAnswer4(bytes32 question_id) public view returns(bytes32) {
        return questions[question_id].best_answer;
    }

    function getHistoryHash(bytes32 question_id) public view returns(bytes32) {
        return questions[question_id].history_hash;
    }

    function getBond(bytes32 question_id) public view returns(uint256) {
        return questions[question_id].bond;
    }
}

contract RealitioArbitrator is Owned {
    Realitio public realitio;
    mapping(bytes32 => uint256) public dispute_fees;
    uint256 dispute_fee;
    mapping(bytes32 => uint256) custom_dispute_fees;
    string public metadata;
    event LogRequestArbitration(
        bytes32 indexed question_id,
        uint256 amount,
        address user,
        uint256 fee
    );
    event LogSetRealitio(
        address realitio
    );
    event LogSetQuestionFee(
        uint256 question_fee
    );
    event LogSetDisputeFee(
        uint256 dispute_fee
    );
    event LogSetCustomDisputeFee(
        bytes32 indexed question_id,
        uint256 dispute_fee
    );

    constructor() public {
        owner = msg.sender;
    }

    function getRealitio() external view returns(Realitio) {
        return realitio;
    }

    function setRealitio(address realitio_address) onlyOwner public {
        realitio = Realitio(realitio_address);
        emit LogSetRealitio(realitio_address);
    }

    function setDisputeFee(uint256 fee) onlyOwner public {
        dispute_fee = fee;
        emit LogSetDisputeFee(fee);
    }

    function setCustomDisputeFee(bytes32 question_id, uint256 fee) onlyOwner public {
        custom_dispute_fees[question_id] = fee;
        emit LogSetCustomDisputeFee(question_id, fee);
    }

    function getDisputeFee(bytes32 question_id) public view returns (uint256) {
        return (custom_dispute_fees[question_id] > 0) ? custom_dispute_fees[question_id] : dispute_fee;
    }

    function setQuestionFee(uint256 fee) onlyOwner public {
        realitio.setQuestionFee(fee);
        emit LogSetQuestionFee(fee);
    }

    function finalize(bytes32 question_id, bytes32 answer, address user) onlyOwner public {
        delete dispute_fees[question_id];
        realitio.finalize(question_id, answer, user);
    }

    function requestArbitration(bytes32 question_id, uint256 bond) external payable returns (bool) {
        uint256 fee = getDisputeFee(question_id);
        require(fee > 0, "The arbitrator must have set non-zero dispute fee for the question");
        dispute_fees[question_id] += msg.value;
        uint256 total = dispute_fees[question_id];
        if (total >= fee) {
            realitio.notifyOfArbitrationRequest(question_id, msg.sender, bond);
            emit LogRequestArbitration(question_id, msg.value, msg.sender, 0);
            return true;
        } else {
            require(!realitio.question_is_finalized(question_id), "The question must not have been finalized");
            emit LogRequestArbitration(question_id, msg.value, msg.sender, fee - total);
            return false;
        }
    }

    function withdraw(address user) onlyOwner public {
        user.transfer(address(this).balance);
    }

    function withdrawFees() onlyOwner public {
        realitio.withdraw();
    }

    function setMetadata(string metadata) onlyOwner public {
        this.metadata = metadata;
    }
}
