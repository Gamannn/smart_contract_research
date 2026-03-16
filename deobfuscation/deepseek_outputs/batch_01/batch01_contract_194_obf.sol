pragma solidity ^0.4.25;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Owner {
    modifier onlyOwner() {
        require(msg.sender == config.owner);
        _;
    }

    function changeOwner(address newOwner) public onlyOwner returns (bool) {
        config.owner = newOwner;
        return true;
    }
}

contract EagleEvent {
    event onEventDeposit(address indexed user, uint256 indexed amountInEther);
    event onEventWithdraw(address indexed from, address indexed to, uint256 indexed amountInEther);
    event onEventWithdrawLost(address indexed lostUser, address indexed reporter, uint256 indexed amountInEther);
    event onEventReport(address indexed reportedUser, address indexed reporter);
    event onEventVerify(address indexed verifiedUser);
    event onEventReset(address indexed user);
    event onEventUnlock(address indexed user);
}

contract Eagle is Owner, EagleEvent {
    using SafeMath for uint256;

    enum State { Normal, Report, Verify, Lock }

    mapping(address => uint256) public balances;
    mapping(address => State) public states;
    mapping(address => uint) public verifyTimes;
    mapping(address => address) public reporters;
    mapping(address => bytes) public signatures;

    struct Config {
        uint256 reportLock;
        uint256 withdrawFeeLost;
        uint256 withdrawFee;
        address owner;
    }

    Config config = Config(
        100000000000000000,  // 0.1 ether
        10000000000000000,   // 0.01 ether
        600000000000000,     // 0.0006 ether
        address(0)
    );

    constructor() public {
        config.owner = msg.sender;
    }

    function getbalance(address user) public view returns (uint256) {
        return balances[user];
    }

    function getstate(address user) public view returns (State) {
        return states[user];
    }

    function getverifytime(address user) public view returns (uint) {
        return verifyTimes[user];
    }

    function () public payable {
        require(states[msg.sender] == State.Normal);
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        emit onEventDeposit(msg.sender, msg.value.div(100000000000000));
    }

    function withdraw(address to, uint256 amount) public {
        require(states[msg.sender] != State.Lock);
        require(balances[msg.sender] >= amount.add(config.withdrawFee));
        balances[msg.sender] = balances[msg.sender].sub(amount.add(config.withdrawFee));
        to.transfer(amount);
        config.owner.transfer(config.withdrawFee);
        emit onEventWithdraw(msg.sender, to, amount.div(100000000000000));
    }

    function withdrawloss(address lostUser, address reporter) public {
        require(reporter == msg.sender);
        require(reporters[lostUser] == reporter);
        require(states[lostUser] == State.Verify);
        require(states[reporter] == State.Normal);
        require(now >= verifyTimes[lostUser] + 5 days);
        require(balances[lostUser] >= config.withdrawFeeLost);

        emit onEventWithdrawLost(lostUser, reporter, balances[lostUser].div(100000000000000));

        config.owner.transfer(config.withdrawFeeLost);
        balances[reporter] = balances[reporter].add(balances[lostUser]).sub(config.withdrawFeeLost);
        balances[lostUser] = 0;
        states[lostUser] = State.Normal;
        verifyTimes[lostUser] = 0;
        reporters[lostUser] = address(0);
    }

    function report(address reportedUser, address reporter, bytes signature) public {
        require(reporter == msg.sender);
        require(states[reportedUser] == State.Normal);
        require(balances[reporter] >= config.reportLock);
        require(states[reporter] == State.Normal);

        signatures[reportedUser] = signature;
        reporters[reportedUser] = reporter;
        states[reportedUser] = State.Report;
        states[reporter] = State.Lock;

        emit onEventReport(reportedUser, reporter);
    }

    function verify(address user, bytes id) public {
        require(states[user] == State.Report);

        bytes memory signedstr = signatures[user];
        bytes32 hash = keccak256(id);
        hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));

        bytes32 r;
        bytes32 s;
        uint8 v;
        address addr;

        if (signedstr.length != 65) {
            addr = address(0);
        } else {
            assembly {
                r := mload(add(signedstr, 32))
                s := mload(add(signedstr, 64))
                v := and(mload(add(signedstr, 65)), 255)
            }
            if (v < 27) {
                v += 27;
            }
            if (v != 27 && v != 28) {
                addr = address(0);
            } else {
                addr = ecrecover(hash, v, r, s);
            }
        }

        require(addr == user);

        verifyTimes[user] = now;
        states[user] = State.Verify;
        states[reporters[user]] = State.Normal;

        emit onEventVerify(user);
    }

    function resetState(address user) public onlyOwner {
        require(states[user] == State.Report || states[user] == State.Lock);

        if (states[user] == State.Report) {
            states[user] = State.Normal;
            verifyTimes[user] = 0;
            reporters[user] = address(0);
            emit onEventReset(user);
        } else if (states[user] == State.Lock) {
            states[user] = State.Normal;
            balances[user] = balances[user].sub(config.reportLock);
            config.owner.transfer(config.reportLock);
            emit onEventUnlock(user);
        }
    }
}