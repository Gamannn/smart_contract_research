pragma solidity ^0.4.25;

contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns(address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns(bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

contract ReentrancyGuard {
    uint256 private _guardCounter;

    constructor() internal {
        _guardCounter = 1;
    }

    modifier nonReentrant() {
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

contract MLM_FOMO_BANK is Ownable {
    using SafeMath for uint256;

    uint256 public fomo_period;
    uint256 public finish_time;
    address public winner;
    uint256 public balance;

    event Win(address indexed winner, uint256 amount);

    constructor(uint256 period) public {
        fomo_period = period;
        finish_time = now.add(period);
    }

    function AddToBank(address user) public payable {
        balance = balance.add(msg.value);
        winner = user;
        finish_time = now.add(fomo_period);
    }

    function CheckWinner() internal {
        if (now > finish_time && winner != address(0)) {
            emit Win(winner, balance);
            uint256 prev_balance = balance;
            balance = 0;
            winner.transfer(prev_balance);
            finish_time = now.add(fomo_period);
            winner = address(0);
        }
    }

    function GetInfo() public view returns (uint256, uint256, address) {
        return (balance, finish_time, winner);
    }
}

contract MLM is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;

    MLM_FOMO_BANK public fomoBank;

    struct UserStruct {
        address[] referrers;
        address[] referrals;
        uint256 next_payment;
        bool isRegistered;
        bytes32 ref_link;
    }

    mapping(address => UserStruct) public users;
    mapping(bytes32 => address) public ref_to_users;

    uint256 public min_payment = 100 finney;
    uint256 public min_time_to_add = 604800;
    uint256[] public reward_parts = [35, 25, 15, 15, 10];

    event RegisterEvent(address indexed user, address indexed referrer);
    event PayEvent(address indexed payer, uint256 amount, bool[3] levels);

    constructor(MLM_FOMO_BANK fomo) public {
        fomoBank = fomo;
    }

    function() public payable {
        require(!address(msg.sender).isContract());
        require(users[msg.sender].isRegistered);
        Pay(bytes32(0));
    }

    function Pay(bytes32 referrer_addr) public payable nonReentrant {
        require(!address(msg.sender).isContract());
        require(msg.value >= min_payment);

        if (!users[msg.sender].isRegistered) {
            _register(referrer_addr);
        }

        uint256 amount = msg.value;
        bool[3] memory levels = [false, false, false];

        for (uint i = 0; i < 3; i++) {
            address ref = users[msg.sender].referrers[i];
            if (users[ref].next_payment > now) {
                uint256 reward = amount.mul(reward_parts[i]).div(100);
                ref.transfer(reward);
                levels[i] = true;
            }
        }

        address fomo_user = msg.sender;
        if (users[msg.sender].referrers.length > 0 && users[users[msg.sender].referrers[0]].next_payment > now) {
            fomo_user = users[msg.sender].referrers[0];
        }

        fomoBank.AddToBank.value(amount.mul(reward_parts[3]).div(100)).gas(gasleft())(fomo_user);

        if (now > users[msg.sender].next_payment) {
            users[msg.sender].next_payment = now.add(amount.mul(min_time_to_add).div(min_payment));
        } else {
            users[msg.sender].next_payment = users[msg.sender].next_payment.add(amount.mul(min_time_to_add).div(min_payment));
        }

        emit PayEvent(msg.sender, amount, levels);
    }

    function _register(bytes32 referrer_addr) internal {
        require(!users[msg.sender].isRegistered);

        address referrer = ref_to_users[referrer_addr];
        require(referrer != address(0));

        if (referrer != address(0)) {
            _setReferrers(referrer, 0);
        }

        users[msg.sender].isRegistered = true;
        _getReferralLink(referrer);
        emit RegisterEvent(msg.sender, referrer);
    }

    function _getReferralLink(address referrer) internal {
        do {
            users[msg.sender].ref_link = keccak256(abi.encodePacked(uint256(msg.sender) ^ uint256(referrer) ^ now));
        } while (ref_to_users[users[msg.sender].ref_link] != address(0));
        ref_to_users[users[msg.sender].ref_link] = msg.sender;
    }

    function _setReferrers(address referrer, uint256 level) internal {
        if (users[referrer].next_payment > now) {
            users[msg.sender].referrers.push(referrer);
            if (level == 0) {
                users[referrer].referrals.push(msg.sender);
            }
            level++;
        }

        if (level < 3 && users[referrer].referrers.length > 0) {
            _setReferrers(users[referrer].referrers[0], level);
        }
    }

    function GetUser() public view returns(uint256, bool, bytes32) {
        return (
            users[msg.sender].next_payment,
            users[msg.sender].isRegistered,
            users[msg.sender].ref_link
        );
    }

    function GetReferrers() public view returns(address[] memory) {
        return users[msg.sender].referrers;
    }

    function GetReferrals() public view returns(address[] memory) {
        return users[msg.sender].referrals;
    }

    function withdraw(address to, uint256 amount) public onlyOwner {
        to.transfer(amount);
    }
}