```solidity
pragma solidity ^0.4.18;

contract ERC20 {
    function transfer(address to, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
}

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
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function min(uint a, uint b) internal pure returns (uint) {
        if (a >= b) return b;
        return a;
    }

    function max(uint a, uint b) internal pure returns (uint) {
        if (a >= b) return a;
        return b;
    }
}

contract DSAuthority {
    function canCall(address src, address dst, bytes4 sig) public view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority(address indexed authority);
    event LogSetOwner(address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority public authority;
    address public owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_) public auth {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_) public auth {
        authority = authority_;
        emit LogSetAuthority(authority);
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, this, sig);
        }
    }
}

contract Exchange is DSAuth {
    using SafeMath for uint;

    ERC20 public daiToken;
    mapping(address => uint) public dai;
    mapping(address => uint) public eth;
    mapping(address => uint) public totalEth;
    mapping(address => uint) public totalDai;
    mapping(bytes32 => mapping(address => uint)) public callsOwned;
    mapping(bytes32 => mapping(address => uint)) public putsOwned;
    mapping(bytes32 => mapping(address => uint)) public callsSold;
    mapping(bytes32 => mapping(address => uint)) public putsSold;
    mapping(bytes32 => uint) public callsAssigned;
    mapping(bytes32 => uint) public putsAssigned;
    mapping(bytes32 => uint) public callsExercised;
    mapping(bytes32 => uint) public putsExercised;
    mapping(address => mapping(bytes32 => bool)) public cancelled;
    mapping(address => mapping(bytes32 => uint)) public filled;
    mapping(address => uint) public feeRebates;
    mapping(bytes32 => bool) public claimedFeeRebate;

    struct FeeSchedule {
        string precisionError;
        uint256 feesWithdrawn;
        uint256 feesCollected;
        uint256 settlementFee;
        uint256 exerciseFee;
        uint256 contractFee;
        uint256 flatFee;
    }

    FeeSchedule public feeSchedule;

    constructor(address daiAddress) public {
        require(daiAddress != 0x0);
        daiToken = ERC20(daiAddress);
        feeSchedule = FeeSchedule("Precision", 0, 0, 20 ether, 20 ether, 1 ether, 7 ether);
    }

    function() public payable {
        revert();
    }

    event Deposit(address indexed user, uint amount);
    event Withdraw(address indexed user, uint amount, address to);
    event DepositDai(address indexed user, uint amount);
    event WithdrawDai(address indexed user, uint amount, address to);

    function deposit() public payable {
        _addEth(msg.value, msg.sender);
        emit Deposit(msg.sender, msg.value);
    }

    function depositDai(uint amount) public {
        require(daiToken.transferFrom(msg.sender, this, amount));
        _addDai(amount, msg.sender);
        emit DepositDai(msg.sender, amount);
    }

    function withdraw(uint amount, address to) public {
        require(to != 0x0);
        _subEth(amount, msg.sender);
        to.transfer(amount);
        emit Withdraw(msg.sender, amount, to);
    }

    function withdrawDai(uint amount, address to) public {
        require(to != 0x0);
        _subDai(amount, msg.sender);
        daiToken.transfer(to, amount);
        emit WithdrawDai(msg.sender, amount, to);
    }

    function depositDaiFor(uint amount, address user) public {
        require(user != 0x0);
        require(daiToken.transferFrom(msg.sender, this, amount));
        _addDai(amount, user);
        emit DepositDai(user, amount);
    }

    function _addEth(uint amount, address user) private {
        eth[user] = eth[user].add(amount);
        totalEth[user] = totalEth[user].add(amount);
    }

    function _subEth(uint amount, address user) private {
        eth[user] = eth[user].sub(amount);
        totalEth[user] = totalEth[user].sub(amount);
    }

    function _addDai(uint amount, address user) private {
        dai[user] = dai[user].add(amount);
        totalDai[user] = totalDai[user].add(amount);
    }

    function _subDai(uint amount, address user) private {
        dai[user] = dai[user].sub(amount);
        totalDai[user] = totalDai[user].sub(amount);
    }

    function setFeeSchedule(uint _flatFee, uint _contractFee, uint _exerciseFee, uint _settlementFee) public auth {
        feeSchedule.flatFee = _flatFee;
        feeSchedule.contractFee = _contractFee;
        feeSchedule.exerciseFee = _exerciseFee;
        feeSchedule.settlementFee = _settlementFee;
        require(feeSchedule.contractFee < 5 ether);
        require(feeSchedule.flatFee < 6.95 ether);
        require(feeSchedule.exerciseFee < 20 ether);
        require(feeSchedule.settlementFee < 20 ether);
    }

    function withdrawFees(address to) public auth {
        require(to != 0x0);
        uint amount = feeSchedule.feesCollected.sub(feeSchedule.feesWithdrawn);
        feeSchedule.feesWithdrawn = feeSchedule.feesCollected;
        require(daiToken.transfer(to, amount));
    }

    modifier hasFee(uint amount) {
        _;
        _collectFee(msg.sender, calculateFee(amount));
    }

    enum Action {
        BuyCallToOpen,
        BuyCallToClose,
        SellCallToOpen,
        SellCallToClose,
        BuyPutToOpen,
        BuyPutToClose,
        SellPutToOpen,
        SellPutToClose
    }

    event CancelOrder(address indexed user, bytes32 hash);

    function cancelOrder(bytes32 hash) public {
        cancelled[msg.sender][hash] = true;
        emit CancelOrder(msg.sender, hash);
    }

    function callBtoWithSto(
        uint amount,
        uint expiration,
        bytes32 nonce,
        uint price,
        uint size,
        uint strike,
        uint validUntil,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public hasFee(amount) {
        bytes32 hash = keccak256(Action.SellCallToOpen, expiration, nonce, price, size, strike, validUntil, this);
        address maker = _getMaker(hash, v, r, s);
        _validateOrder(amount, expiration, hash, maker, price, validUntil, size, strike);
        _buyCallToOpen(amount, expiration, price, strike, msg.sender);
        _sellCallToOpen(amount, expiration, price, strike, maker);
    }

    function callBtoWithStc(
        uint amount,
        uint expiration,
        bytes32 nonce,
        uint price,
        uint size,
        uint strike,
        uint validUntil,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public hasFee(amount) {
        bytes32 hash = keccak256(Action.SellCallToClose, expiration, nonce, price, size, strike, validUntil, this);
        address maker = _getMaker(hash, v, r, s);
        _validateOrder(amount, expiration, hash, maker, price, validUntil, size, strike);
        _buyCallToOpen(amount, expiration, price, strike, msg.sender);
        _sellCallToClose(amount, expiration, price, strike, maker);
    }

    function callBtcWithSto(
        uint amount,
        uint expiration,
        bytes32 nonce,
        uint price,
        uint size,
        uint strike,
        uint validUntil,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public hasFee(amount) {
        bytes32 hash = keccak256(Action.SellCallToOpen, expiration, nonce, price, size, strike, validUntil, this);
        address maker = _getMaker(hash, v, r, s);
        _validateOrder(amount, expiration, hash, maker, price, validUntil, size, strike);
        _buyCallToClose(amount, expiration, price, strike, msg.sender);
        _sellCallToOpen(amount, expiration, price, strike, maker);
    }

    function callBtcWithStc(
        uint amount,
        uint expiration,
        bytes32 nonce,
        uint price,
        uint size,
        uint strike,
        uint validUntil,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public hasFee(amount) {
        bytes32 hash = keccak256(Action.SellCallToClose, expiration, nonce, price, size, strike, validUntil, this);
        address maker = _getMaker(hash, v, r, s);
        _validateOrder(amount, expiration, hash, maker, price, validUntil, size, strike);
        _buyCallToClose(amount, expiration, price, strike, msg.sender);
        _sellCallToClose(amount, expiration, price, strike, maker);
    }

    function callStoWithBto(
        uint amount,
        uint expiration,
        bytes32 nonce,
        uint price,
        uint size,
        uint strike,
        uint validUntil,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public hasFee(amount) {
        bytes32 hash = keccak256(Action.BuyCallToOpen, expiration, nonce, price, size, strike, validUntil, this);
        address maker = _getMaker(hash, v, r, s);
        _validateOrder(amount, expiration, hash, maker, price, validUntil, size, strike);
        _sellCallToOpen(amount, expiration, price, strike, msg.sender);
        _buyCallToOpen(amount, expiration, price, strike, maker);
    }

    function callStoWithBtc(
        uint amount,
        uint expiration,
        bytes32 nonce,
        uint price,
        uint size,
        uint strike,
        uint validUntil,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public hasFee(amount) {
        bytes32 hash = keccak256(Action.BuyCallToClose, expiration, nonce, price, size, strike, validUntil, this);
        address maker = _getMaker(hash, v, r, s);
        _validateOrder(amount, expiration, hash, maker, price, validUntil, size, strike);
        _sellCallToOpen(amount, expiration, price, strike, msg.sender);
        _buyCallToClose(amount, expiration, price, strike, maker);
    }

    function callStcWithBto(
        uint amount,
        uint expiration,
        bytes32 nonce,
        uint price,
        uint size,
        uint strike,
        uint validUntil,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public hasFee(amount) {
        bytes32 hash = keccak256(Action.BuyCallToOpen, expiration, nonce, price, size, strike, validUntil, this);
        address maker = _getMaker(hash, v, r, s);
        _validateOrder(amount, expiration, hash, maker, price, validUntil, size, strike);
        _sellCallToClose(amount, expiration, price, strike, msg.sender);
        _buyCallToOpen(amount, expiration, price, strike, maker);
    }

    function callStcWithBtc(
        uint amount,
        uint expiration,
        bytes32 nonce,
        uint price,
        uint size,
        uint strike,
        uint validUntil,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public hasFee(amount) {
        bytes32 hash = keccak256(Action.BuyCallToClose, expiration, nonce, price, size, strike, validUntil, this);
        address maker = _getMaker(hash, v, r, s);
        _validateOrder(amount, expiration, hash, maker, price, validUntil, size, strike);
        _sellCallToClose(amount, expiration, price, strike, msg.sender);
        _buyCallToClose(amount, expiration, price, strike, maker);
    }

    event BuyCallToOpen(address indexed user, uint amount, uint expiration, uint price, uint strike);
    event SellCallToOpen(address indexed user, uint amount, uint expiration, uint price, uint strike);
    event BuyCallToClose(address indexed user, uint amount, uint expiration, uint price, uint strike);
    event SellCallToClose(address indexed user, uint amount, uint expiration, uint price, uint strike);

    function _buyCallToOpen(uint amount, uint expiration, uint price, uint strike, address buyer) private {
        bytes32 series = keccak256(expiration, strike);
        uint premium = amount.mul(price).div(1 ether);
        _subDai(premium, buyer);
        callsOwned[series][buyer] = callsOwned[series][buyer].add(amount);
        emit BuyCallToOpen(buyer, amount, expiration, price, strike);
    }

    function _buyCallToClose(uint amount, uint expiration, uint price, uint strike, address buyer) private {
        bytes32 series = keccak256(expiration, strike);
        uint premium = amount.mul(price).div(1 ether);
        _subDai(premium, buyer);
        eth[buyer] = eth[buyer].add(amount);
        callsSold[series][buyer] = callsSold[series][buyer].sub(amount);
        emit BuyCallToClose(buyer, amount, expiration, price, strike);
    }

    function _sellCallToOpen(uint amount, uint expiration, uint price, uint strike, address seller) private {
        bytes32 series = keccak256(expiration, strike);
        uint premium = amount.mul(price).div(1 ether);
        _addDai(premium, seller);
        eth[seller] = eth[seller].sub(amount);
        callsSold[series][seller] = callsSold[series][seller].add(amount);
        emit SellCallToOpen(seller, amount, expiration, price, strike);
    }

    function _sellCallToClose(uint amount, uint expiration, uint price, uint strike, address seller) private {
        bytes32 series = keccak256(expiration, strike);
        uint premium = amount.mul(price).div(1 ether);
        _addDai(premium, seller);
        callsOwned[series][seller] = callsOwned[series][seller].sub(amount);
        emit SellCallToClose(seller, amount, expiration, price, strike);
    }

    event ExerciseCall(address indexed user, uint amount, uint expiration, uint strike);

    function exerciseCall(uint amount, uint expiration, uint strike) public {
        require(now < expiration, "Expired");
        require(amount % 1 finney == 0, feeSchedule.precisionError);
        uint cost = amount.mul(strike).div(1 ether);
        bytes32 series = keccak256(expiration, strike);
        require(callsOwned[series][msg.sender] > 0);
        callsOwned[series][msg.sender] = callsOwned[series][msg.sender].sub(amount);
        callsExercised[series] = callsExercised[series].add(amount);
        _collectFee(msg.sender, feeSchedule.exerciseFee);
        _subDai(cost, msg.sender);
        _addEth(amount, msg.sender);
        emit ExerciseCall(msg.sender, amount, expiration, strike);
    }

    event AssignCall(address indexed user, uint amount, uint expiration, uint strike);
    event SettleCall(address indexed user, uint expiration, uint strike);

    function settleCall(uint expiration, uint strike, address writer) public {
        require(msg.sender == writer || isAuthorized(msg.sender, msg.sig), "Unauthorized");
        require(now > expiration, "Expired");
        bytes32 series = keccak256(expiration, strike);
        require(callsSold[series][writer] > 0);
        if (callsAssigned[series] < callsExercised[series]) {
            uint maximum = callsSold[series][writer];
            uint needed = callsExercised[series].sub(callsAssigned[series]);
            uint assignment = needed.min(maximum);
            totalEth[writer] = totalEth[writer].sub(assignment);
            callsAssigned[series] = callsAssigned[series].add(assignment);
            callsSold[series][writer] = callsSold[series][writer].sub(assignment);
            uint value = strike.mul(assignment).div(1 ether);
            _addDai(value, writer);
            emit AssignCall(msg.sender, assignment, expiration, strike);
        }
        _collectFee(writer, feeSchedule.settlementFee);
        eth[writer] = eth[writer].add(callsSold[series][writer]);
        callsSold[series][writer] = 0;
        emit SettleCall(writer, expiration, strike);
    }

    function putBtoWithSto(
        uint amount,
        uint expiration,
        bytes32 nonce,
        uint price,
        uint size,
        uint strike,
        uint validUntil,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public hasFee(amount) {
        bytes32 hash = keccak256(Action.SellPutToOpen, expiration, nonce, price, size, strike, validUntil, this);
        address maker = _getMaker(hash, v, r, s);
        _validateOrder(amount, expiration, hash, maker, price, validUntil, size, strike);
        _buyPutToOpen(amount, expiration, price, strike, msg.sender);
        _sellPutToOpen(amount, expiration, price, strike, maker);
    }

    function putBtoWithStc(
        uint amount,
        uint expiration,
        bytes32 nonce,
        uint price,
        uint size,
        uint strike,
        uint validUntil,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public hasFee(amount) {
        bytes32 hash = keccak256(Action.SellPutToClose, expiration, nonce, price, size, strike, validUntil, this);
        address maker = _getMaker(hash, v, r, s);
        _validateOrder(amount, expiration, hash, maker, price, validUntil, size, strike);
        _buyPutToOpen(amount, expiration, price, strike, msg.sender);
        _sellPutToClose(amount, expiration, price, strike, maker);
    }

    function putBtcWithSto(
        uint amount,
        uint expiration,
        bytes32 nonce,
        uint price,
        uint size,
        uint strike,
        uint validUntil,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public hasFee(amount) {
        bytes32 hash = keccak256(Action.SellPutToOpen, expiration, nonce, price, size, strike, validUntil, this);
        address maker = _getMaker(hash, v, r, s);
        _validateOrder(amount, expiration, hash, maker, price, validUntil, size, strike);
        _buyPutToClose(amount, expiration, price, strike, msg.sender);
        _sellPutToOpen(amount, expiration, price, strike, maker);
    }

    function putBtcWithStc(
        uint amount,
        uint expiration,
        bytes32 nonce,
        uint price,
        uint size,
        uint strike,
        uint validUntil,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public hasFee(amount) {
        bytes32 hash = keccak256(Action.SellPutToClose, expiration, nonce, price, size, strike, validUntil, this);
        address maker = _getMaker(hash, v, r, s);
        _validateOrder(amount, expiration, hash, maker, price, validUntil, size, strike);
        _buyPutToClose(amount, expiration, price, strike, msg.sender);
        _sellPutToClose(amount, expiration, price, strike, maker);
    }

    function putStoWithBto(
        uint amount,
        uint expiration,
        bytes32 nonce,
        uint price,
        uint size,
        uint strike,
        uint validUntil,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public hasFee(amount) {
        bytes32 hash = keccak256(Action.BuyPutToOpen, expiration, nonce, price, size, strike, validUntil, this);
        address maker = _getMaker(hash, v, r, s);
        _validateOrder(amount, expiration, hash, maker, price, validUntil, size, strike);
        _sellPutToOpen(amount, expiration, price, strike, msg.sender);
        _buyPutToOpen(amount, expiration, price, strike, maker);
    }

    function putStoWithBtc(
        uint amount,
        uint expiration,
        bytes32 nonce,
        uint price,
        uint size,
        uint strike,
        uint validUntil,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public hasFee(amount) {
        bytes32 hash = keccak256(Action.BuyPutToClose, expiration, nonce, price, size, strike, validUntil, this);
        address maker = _getMaker(hash, v, r, s);
        _validateOrder(amount, expiration, hash, maker, price, validUntil, size, strike);
        _sellPutToOpen(amount, expiration, price, strike, msg.sender);
        _buyPutToClose(amount, expiration, price, strike, maker);
    }

    function putStcWithBto(
        uint amount,
        uint expiration,
        bytes32 nonce,
        uint price,
        uint size,
        uint strike,
        uint validUntil,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public hasFee(amount) {
        bytes32 hash = keccak256(Action.BuyPutToOpen, expiration, nonce, price, size, strike, validUntil, this);
        address maker = _getMaker(hash, v, r, s);
        _validateOrder(amount, expiration, hash, maker, price, validUntil, size, strike);
        _sellPutToClose(amount, expiration, price, strike, msg.sender);
        _buyPutToOpen(amount, expiration, price, strike, maker);
    }

    function putStcWithBtc(
        uint amount,
        uint expiration,
        bytes32 nonce,
        uint price,
        uint size,
        uint strike,
        uint validUntil,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public hasFee(amount) {
        bytes32 hash = keccak256(Action.BuyPutToClose, expiration, nonce, price, size, strike, validUntil, this);
        address maker = _getMaker(hash, v, r, s);
        _validateOrder(amount, expiration, hash, maker, price, validUntil, size, strike);
        _sellPutToClose(amount, expiration, price, strike, msg.sender);
        _buyPutToClose(amount, expiration, price, strike, maker);
    }

    event BuyPutToOpen(address indexed user, uint amount, uint expiration, uint price, uint strike);
    event SellPutToOpen(address indexed user, uint amount, uint expiration, uint price, uint strike);
    event BuyPutToClose(address indexed user, uint amount, uint expiration, uint price, uint strike);
    event SellPutToClose(address indexed user, uint amount, uint expiration, uint price, uint strike);

    function _buyPutToOpen(uint amount, uint expiration, uint price, uint strike, address buyer) private {
        bytes32 series = keccak256(expiration, strike);
        uint premium = amount.mul(price).div(1 ether);
        _subDai(premium, buyer);
        putsOwned[series][buyer] = putsOwned[series][buyer].add(amount);
        emit BuyPutToOpen(buyer, amount, expiration, price, strike);
    }

    function _buyPutToClose(uint amount, uint expiration, uint price, uint strike, address buyer) private {
        bytes32 series = keccak256(expiration, strike);
        uint premium = amount.mul(price).div(1 ether);
        dai[buyer] = dai[buyer].add(strike.mul(amount).div(1 ether));
        _subDai(premium, buyer);
        putsSold[series][buyer] = putsSold[series][buyer].sub(amount);
        emit BuyPutToClose(buyer, amount, expiration, price, strike);
    }

    function _sellPutToOpen(uint amount, uint expiration, uint price, uint strike, address seller) private {
        bytes32 series = keccak256(expiration, strike);
        uint premium = amount.mul(price).div(1 ether);
        uint cost = strike.mul(amount).div(1 ether);
        _addDai(premium, seller);
        dai[seller] = dai[seller].sub(cost);
        putsSold[series][seller] = putsSold[series][seller].add(amount);
        emit SellPutToOpen(seller, amount, expiration, price, strike);
    }

    function _sellPutToClose(uint amount, uint expiration, uint price, uint strike, address seller) private {
        bytes32 series = keccak256(expiration, strike);
        uint premium = amount.mul(price).div(1 ether);
        _addDai(premium, seller);
        putsOwned[series][seller] = putsOwned[series][seller].sub(amount);
        emit SellPutToClose(seller, amount, expiration, price, strike);
    }

    event ExercisePut(address indexed user, uint amount, uint expiration, uint strike);

    function exercisePut(uint amount, uint expiration, uint strike) public {
        require(now < expiration, "Expired");
        require(amount % 1 finney == 0, feeSchedule.precisionError);
        uint yield = amount.mul(strike).div(1 ether);
        bytes32 series = keccak256(expiration, strike);
        require(putsOwned[series][msg.sender] > 0);
        putsOwned[series][msg.sender] = putsOwned[series][msg.sender].sub(amount);
        putsExercised[series] = putsExercised[series].add(amount);
        _subEth(amount, msg.sender);
        _addDai(yield, msg.sender);
        _collectFee(msg.sender, feeSchedule.exerciseFee);
        emit ExercisePut(msg.sender, amount, expiration, strike);
    }

    event AssignPut(address indexed user, uint amount, uint expiration, uint strike);
    event SettlePut(address indexed user, uint expiration, uint strike);

    function settlePut(uint expiration, uint strike, address writer) public {
        require(msg.sender == writer || isAuthorized(msg.sender, msg.sig), "Unauthorized");
        require(now > expiration, "Expired");
        bytes32 series = keccak256(expiration, strike);
        require(putsSold[series][writer] > 0);
        if (putsAssigned[series] < putsExercised[series]) {
            uint maximum = putsSold[series][writer];
            uint needed = putsExercised[series].sub(putsAssigned[series]);
            uint assignment = maximum.min(needed);
            totalDai[writer] = totalDai[writer].sub(assignment.mul(strike).div(1 ether));
            putsSold[series][writer] = putsSold[series][writer].sub(assignment);
            putsAssigned[series] = putsAssigned[series].add(assignment);
            _addEth(assignment, writer);
            emit AssignPut(writer, assignment, expiration, strike);
        }
        uint yield = putsSold[series][writer].mul(strike).div(1 ether);
        _collectFee(writer, feeSchedule.settlementFee);
        dai[writer] = dai[writer].add(yield);
        putsSold[series][writer] = 0;
        emit SettlePut(writer, expiration, strike);
    }

    function calculateFee(uint amount) public view returns (uint) {
        return amount.mul(feeSchedule.contractFee).div(1 ether).add(feeSchedule.flatFee);
    }

    function claimFeeRebate(uint amount, bytes32 nonce, bytes32 r, bytes32 s, uint8 v) public {
        bytes32 hash = keccak256(amount, nonce, msg.sender);
        hash = keccak256("\x19Ethereum Signed Message:\n32", hash);
        address signer = ecrecover(hash, v, r, s);
        require(amount <= 1000);
        require(isAuthorized(signer, msg.sig));
        require(claimedFeeRebate[nonce] == false);
        feeRebates[msg.sender] = feeRebates[msg.sender].add(amount);
        claimedFeeRebate[nonce] = true;
    }

    event TakeOrder(address indexed user, address maker, uint amount, bytes32 hash);

    function _validateOrder(
        uint amount,
        uint expiration,
        bytes32 hash,
        address maker,
        uint price,
        uint validUntil,
        uint size,
        uint strike
    ) private {
        require(strike % 1 ether == 0, feeSchedule.precisionError);
        require(amount % 1 finney == 0, feeSchedule.precisionError);
        require(price % 1 finney == 0, feeSchedule.precisionError);
        require(expiration % 86400 == 0, "Expiration");
        require(cancelled[maker][hash] == false, "Cancelled");
        require(amount <= size.sub(filled[maker][hash]), "Filled");
        require(now < validUntil, "OrderExpired");
        require(now < expiration, "Expired");
        filled[maker][hash] = filled[maker][hash].add(amount);
        emit TakeOrder(msg.sender, maker, amount, hash);
    }

    function _collectFee(address user, uint amount) private {
        if (feeRebates[msg.sender] > 0) {
            feeRebates[msg.sender] = feeRebates[msg.sender].sub(1);
        } else {
            _subDai(amount, user);
            feeSchedule.feesCollected = feeSchedule.feesCollected.add(amount);
        }
    }

    function _getMaker(bytes32 hash, uint8 v, bytes32 r, bytes32 s) public pure returns (address) {
        return ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s);
    }
}
```