pragma solidity ^0.4.25;

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
        return a / b;
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

contract Owner {
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function changeOwner(address newOwner) public onlyOwner returns (bool) {
        owner = newOwner;
        return true;
    }

    address public owner;
}

contract EagleEvent {
    event onEventDeposit(address indexed user, uint256 indexed amount);
    event onEventWithdraw(address indexed user, address indexed to, uint256 indexed amount);
    event onEventWithdrawLost(address indexed from, address indexed to, uint256 indexed amount);
    event onEventReport(address indexed from, address indexed to);
    event onEventVerify(address indexed user);
    event onEventReset(address indexed user);
    event onEventUnlock(address indexed user);
}

contract Eagle is Owner, EagleEvent {
    using SafeMath for uint256;

    enum State {Normal, Report, Verify, Lock}

    mapping(address => uint256) public balances;
    mapping(address => State) public states;
    mapping(address => uint) public verifyTimes;
    mapping(address => address) public tos;
    mapping(address => bytes) public signs;

    struct Config {
        uint256 reportLock;
        uint256 withdrawFeeLost;
        uint256 withdrawFee;
        address owner;
    }

    Config public config;

    constructor() public {
        config = Config({
            reportLock: 100000000000000000,
            withdrawFeeLost: 10000000000000000,
            withdrawFee: 600000000000000,
            owner: msg.sender
        });
        owner = msg.sender;
    }

    function getBalance(address user) public view returns (uint256) {
        return balances[user];
    }

    function getState(address user) public view returns (State) {
        return states[user];
    }

    function getVerifyTime(address user) public view returns (uint) {
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

    function withdrawLoss(address from, address to) public {
        require(to == msg.sender);
        require(tos[from] == to);
        require(states[from] == State.Verify);
        require(states[to] == State.Normal);
        require(now >= verifyTimes[from] + 5 days);
        require(balances[from] >= config.withdrawFeeLost);
        emit onEventWithdrawLost(from, to, balances[from].div(100000000000000));
        config.owner.transfer(config.withdrawFeeLost);
        balances[to] = balances[to].add(balances[from]).sub(config.withdrawFeeLost);
        balances[from] = 0;
        states[from] = State.Normal;
        verifyTimes[from] = 0;
        tos[from] = address(0);
    }

    function report(address from, address to, bytes _sign) public {
        require(to == msg.sender);
        require(states[from] == State.Normal);
        require(balances[to] >= config.reportLock);
        require(states[to] == State.Normal);
        signs[from] = _sign;
        tos[from] = to;
        states[from] = State.Report;
        states[to] = State.Lock;
        emit onEventReport(from, to);
    }

    function verify(address user, bytes _id) public {
        require(states[user] == State.Report);
        bytes memory signedStr = signs[user];
        bytes32 hash = keccak256(_id);
        hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        bytes32 r;
        bytes32 s;
        uint8 v;
        address addr;
        if (signedStr.length != 65) {
            addr = address(0);
        } else {
            assembly {
                r := mload(add(signedStr, 32))
                s := mload(add(signedStr, 64))
                v := and(mload(add(signedStr, 65)), 255)
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
        states[tos[user]] = State.Normal;
        emit onEventVerify(user);
    }

    function resetState(address user) public onlyOwner {
        require(states[user] == State.Report || states[user] == State.Lock);
        if (states[user] == State.Report) {
            states[user] = State.Normal;
            verifyTimes[user] = 0;
            tos[user] = address(0);
            emit onEventReset(user);
        } else if (states[user] == State.Lock) {
            states[user] = State.Normal;
            balances[user] = balances[user].sub(config.reportLock);
            config.owner.transfer(config.reportLock);
            emit onEventUnlock(user);
        }
    }
}