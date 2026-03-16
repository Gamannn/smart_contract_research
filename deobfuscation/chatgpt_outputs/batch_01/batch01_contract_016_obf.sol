pragma solidity ^0.4.18;

contract FutereumToken {
    uint256[] levels = [
        8771929824561400000000,
        19895525330179400000000,
        37350070784724800000000,
        64114776667077800000000,
        98400490952792100000000,
        148400490952792000000000,
        218400490952792000000000,
        308400490952792000000000,
        415067157619459000000000,
        500067157619455000000000
    ];
    uint256[] ratios = [114, 89, 55, 34, 21, 13, 8, 5, 3, 2];

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mined(address indexed miner, uint256 value);
    event WaitStarted(uint256 endTime);
    event SwapStarted(uint256 endTime);
    event MiningStart(uint256 endTime, uint256 swapTime, uint256 swapEndTime);
    event MiningExtended(uint256 endTime, uint256 swapTime, uint256 swapEndTime);

    string public name = "Futereum Token";
    string public symbol = "FUTR";

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    struct State {
        address dev;
        address owner;
        address foundation;
        uint256 reservedFees;
        uint256 penalty;
        uint256 submittedFeesPaid;
        uint256 payRate;
        uint256 swapEndTimeExtended;
        uint256 swapTimeExtended;
        uint256 endTimeExtended;
        uint256 swapEndTime;
        uint256 swapTime;
        uint256 endTime;
        bool extended;
        bool wait;
        bool swap;
        uint8 decimals;
        uint256 tier;
        uint256 submitted;
        uint256 totalSupply;
        uint256 MAX_SUBMITTED;
        uint256 MAX_UINT256;
    }

    State s2c = State(
        0x5d2b9f5345e69e2390ce4c26ccc9c2910a097520,
        0x78BFCA5E20B0D710EbEF98249f68d9320eE423be,
        0x950ec4ef693d90f8519c4213821e462426d30905,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        false,
        false,
        false,
        18,
        0,
        0,
        0,
        500067157619455000000000,
        2**256 - 1
    );

    function () external payable {
        require(msg.sender != address(0) && s2c.tier != 10 && !s2c.swap && !s2c.wait);
        uint256 issued = mint(msg.sender, msg.value);
        Mined(msg.sender, issued);
        Transfer(this, msg.sender, issued);
    }

    function FutereumToken() public {
        _start();
    }

    function _start() internal {
        s2c.swap = false;
        s2c.wait = false;
        s2c.extended = false;
        s2c.endTime = now + 366 days;
        s2c.swapTime = s2c.endTime + 30 days;
        s2c.swapEndTime = s2c.swapTime + 5 days;
        s2c.endTimeExtended = now + 1096 days;
        s2c.swapTimeExtended = s2c.endTimeExtended + 30 days;
        s2c.swapEndTimeExtended = s2c.swapTimeExtended + 5 days;
        s2c.submittedFeesPaid = 0;
        s2c.submitted = 0;
        s2c.reservedFees = 0;
        s2c.payRate = 0;
        s2c.tier = 0;
        MiningStart(s2c.endTime, s2c.swapTime, s2c.swapEndTime);
    }

    function restart() public {
        require(s2c.swap && now >= s2c.endTime);
        s2c.penalty = this.balance * 2000 / 10000;
        payFees();
        _start();
    }

    function totalSupply() public constant returns (uint256) {
        return s2c.totalSupply;
    }

    function mint(address to, uint256 value) internal returns (uint256) {
        uint256 total = s2c.submitted + value;
        uint256 refund = 0;
        if (total > s2c.MAX_SUBMITTED) {
            refund = total - s2c.MAX_SUBMITTED - 1;
            value -= refund;
            to.transfer(refund);
        }
        s2c.submitted += value;
        total -= refund;
        uint256 tokens = calculateTokens(total, value);
        balances[to] += tokens;
        s2c.totalSupply += tokens;
        return tokens;
    }

    function calculateTokens(uint256 total, uint256 value) internal returns (uint256) {
        if (s2c.tier == 10) {
            return 7400000000;
        }
        uint256 tokens = 0;
        if (total > levels[s2c.tier]) {
            uint256 remaining = total - levels[s2c.tier];
            value -= remaining;
            tokens = value * ratios[s2c.tier];
            s2c.tier += 1;
            tokens += calculateTokens(total, remaining);
        } else {
            tokens = value * ratios[s2c.tier];
        }
        return tokens;
    }

    function currentTier() public view returns (uint256) {
        if (s2c.tier == 10) {
            return 10;
        } else {
            return s2c.tier + 1;
        }
    }

    function leftInTier() public view returns (uint256) {
        if (s2c.tier == 10) {
            return 0;
        } else {
            return levels[s2c.tier] - s2c.submitted;
        }
    }

    function submitted() public view returns (uint256) {
        return s2c.submitted;
    }

    function balanceMinusFeesOutstanding() public view returns (uint256) {
        return this.balance - (s2c.penalty + (s2c.submitted - s2c.submittedFeesPaid) * 1530 / 10000);
    }

    function calculateRate() internal {
        s2c.reservedFees = s2c.penalty + (s2c.submitted - s2c.submittedFeesPaid) * 1530 / 10000;
        uint256 tokens = s2c.totalSupply / 1 ether;
        s2c.payRate = (this.balance - s2c.reservedFees) / tokens;
    }

    function _updateState() internal {
        if (now >= s2c.endTime) {
            if (!s2c.swap && !s2c.wait) {
                if (s2c.extended) {
                    s2c.wait = true;
                    s2c.endTime = s2c.swapTimeExtended;
                    WaitStarted(s2c.endTime);
                } else if (s2c.tier == 10) {
                    s2c.wait = true;
                    s2c.endTime = s2c.swapTime;
                    WaitStarted(s2c.endTime);
                } else {
                    s2c.endTime = s2c.endTimeExtended;
                    s2c.extended = true;
                    MiningExtended(s2c.endTime, s2c.swapTime, s2c.swapEndTime);
                }
            } else if (s2c.wait) {
                s2c.swap = true;
                s2c.wait = false;
                if (s2c.extended) {
                    s2c.endTime = s2c.swapEndTimeExtended;
                } else {
                    s2c.endTime = s2c.swapEndTime;
                }
                SwapStarted(s2c.endTime);
            }
        }
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balances[msg.sender] >= value);
        _updateState();
        if (to == address(this)) {
            require(s2c.swap);
            if (s2c.payRate == 0) {
                calculateRate();
            }
            uint256 amount = value * s2c.payRate / 1 ether;
            balances[msg.sender] -= value;
            s2c.totalSupply -= value;
            Transfer(msg.sender, to, value);
            msg.sender.transfer(amount);
        } else {
            balances[msg.sender] -= value;
            balances[to] += value;
            Transfer(msg.sender, to, value);
        }
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        uint256 allowance = allowed[from][msg.sender];
        require(balances[from] >= value && allowance >= value);
        balances[to] += value;
        balances[from] -= value;
        if (allowance < s2c.MAX_UINT256) {
            allowed[from][msg.sender] -= value;
        }
        Transfer(from, to, value);
        return true;
    }

    function balanceOf(address owner) view public returns (uint256 balance) {
        return balances[owner];
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) view public returns (uint256 remaining) {
        return allowed[owner][spender];
    }

    function payFees() public {
        _updateState();
        uint256 fees = s2c.penalty + (s2c.submitted - s2c.submittedFeesPaid) * 1530 / 10000;
        s2c.submittedFeesPaid = s2c.submitted;
        s2c.reservedFees = 0;
        s2c.penalty = 0;
        if (fees > 0) {
            s2c.foundation.transfer(fees / 2);
            s2c.owner.transfer(fees / 4);
            s2c.dev.transfer(fees / 4);
        }
    }

    function changeFoundation(address receiver) public {
        require(msg.sender == s2c.foundation);
        s2c.foundation = receiver;
    }

    function changeOwner(address receiver) public {
        require(msg.sender == s2c.owner);
        s2c.owner = receiver;
    }

    function changeDev(address receiver) public {
        require(msg.sender == s2c.dev);
        s2c.dev = receiver;
    }
}