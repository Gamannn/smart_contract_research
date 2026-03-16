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
    
    uint256 public feesWithdrawn;
    uint256 public feesCollected;
    uint256 public settlementFee;
    uint256 public exerciseFee;
    uint256 public contractFee;
    uint256 public flatFee;
    
    string public constant precisionError = "Precision";

    constructor(address daiAddress) public {
        require(daiAddress != 0x0);
        daiToken = ERC20(daiAddress);
        
        settlementFee = 20 ether;
        exerciseFee = 20 ether;
        contractFee = 1 ether;
        flatFee = 7 ether;
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
        require(daiToken.transfer(to, amount));
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

    function setFeeSchedule(
        uint _flatFee,
        uint _contractFee,
        uint _exerciseFee,
        uint _settlementFee
    ) public auth {
        flatFee = _flatFee;
        contractFee = _contractFee;
        exerciseFee = _exerciseFee;
        settlementFee = _settlementFee;
        
        require(contractFee < 5 ether);
        require(flatFee < 6.95 ether);
        require(exerciseFee < 20 ether);
        require(settlementFee < 20 ether);
    }

    function withdrawFees(address to) public auth {
        require(to != 0x0);
        uint amount = feesCollected.sub(feesWithdrawn);
        feesWithdrawn = feesCollected;
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

    event CancelOrder(address indexed user, bytes32 h);

    function cancelOrder(bytes32 h) public {
        cancelled[msg.sender][h] = true;
        emit CancelOrder(msg.sender, h);
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
        bytes32 h = keccak256(Action.SellCallToOpen, expiration, nonce, price, size, strike, validUntil, this);
        address maker = _getMaker(h, v, r, s);
        _validateOrder(amount, expiration, h, maker, price, validUntil, size, strike);
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
        bytes32 h = keccak256(Action.SellCallToClose, expiration, nonce, price, size, strike, validUntil, this);
        address maker = _getMaker(h, v, r, s);
        _validateOrder(amount, expiration, h, maker, price, validUntil, size, strike);
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
        bytes32 h = keccak256(Action.SellCallToOpen, expiration, nonce, price, size, strike, validUntil, this);
        address maker = _getMaker(h, v, r, s);
        _validateOrder(amount, expiration, h, maker, price, validUntil, size, strike);
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
        bytes32 h = keccak256(Action.SellCallToClose, expiration, nonce, price, size, strike, validUntil, this);
        address maker = _getMaker(h, v, r, s);
        _validateOrder(amount, expiration, h, maker, price, validUntil, size, strike);
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
        bytes32 h = keccak256(Action.BuyCallToOpen, expiration, nonce, price, size, strike, validUntil, this);
        address maker = _getMaker(h, v, r, s);
        _validateOrder(amount, expiration, h, maker, price, validUntil, size, strike);
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
        bytes32 h = keccak256(Action.BuyCallToClose, expiration, nonce, price, size, strike, validUntil, this);
        address maker = _getMaker(h, v, r, s);
        _validateOrder(amount, expiration, h, maker, price, validUntil, size, strike);
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
        bytes32 h = keccak256(Action.BuyCallToOpen, expiration, nonce, price, size, strike, validUntil, this);
        address maker = _getMaker(h, v, r, s);
        _validateOrder(amount, expiration, h, maker, price, validUntil, size, strike);
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
        bytes32 h = keccak256(Action.BuyCallToClose, expiration, nonce, price, size, strike, validUntil, this);
        address maker = _getMaker(h, v, r, s);
        _validateOrder(amount, expiration, h, maker, price, validUntil, size, strike);
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
        require(amount % 1 finney == 0, precisionError);
        uint cost = amount.mul(strike).div(1 ether);
        bytes32 series = keccak256(expiration, strike);
        require(callsOwned[series][msg.sender] > 0);
        callsOwned[series][msg.sender] = callsOwned[series][msg.sender].sub(amount);
        callsExercised[series] = callsExercised[series].add(amount);
        _collectFee(msg.sender, exerciseFee);
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
        
        _collectFee(writer, settlementFee);
        eth[writer] = eth[writer].add(calls