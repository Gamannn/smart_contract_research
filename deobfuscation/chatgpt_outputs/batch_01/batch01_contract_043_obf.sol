```solidity
pragma solidity ^0.4.18;

contract FutereumX {
    uint256[] levels = [
        87719298245614000000,
        198955253301794000000,
        373500707847248000000,
        641147766670778000000,
        984004909527921000000,
        1484004909527920000000,
        2184004909527920000000,
        3084004909527920000000,
        4150671576194590000000,
        5000671576194550000000
    ];
    uint256[] ratios = [114, 89, 55, 34, 21, 13, 8, 5, 3, 2];

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mined(address indexed miner, uint256 value);
    event WaitStarted(uint256 endTime);
    event SwapStarted(uint256 endTime);
    event MiningStart(uint256 endTime, uint256 swapTime, uint256 swapEndTime);
    event MiningExtended(uint256 endTime, uint256 swapTime, uint256 swapEndTime);

    string public name = "Futereum X";
    string public symbol = "FUTX";

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    struct ContractState {
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

    ContractState state = ContractState(
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
        5000671576194550000000,
        2**256 - 1
    );

    function () external payable {
        require(msg.sender != address(0) && state.tier != 10 && !state.swap && !state.wait);
        uint256 issued = mint(msg.sender, msg.value);
        Mined(msg.sender, issued);
        Transfer(this, msg.sender, issued);
    }

    function FutereumX() public {
        _start();
    }

    function _start() internal {
        state.swap = false;
        state.wait = false;
        state.extended = false;
        state.endTime = now + 90 days;
        state.swapTime = state.endTime + 30 days;
        state.swapEndTime = state.swapTime + 5 days;
        state.endTimeExtended = now + 270 days;
        state.swapTimeExtended = state.endTimeExtended + 90 days;
        state.swapEndTimeExtended = state.swapTimeExtended + 5 days;
        state.submittedFeesPaid = 0;
        state.submitted = 0;
        state.reservedFees = 0;
        state.payRate = 0;
        state.tier = 0;
        MiningStart(state.endTime, state.swapTime, state.swapEndTime);
    }

    function restart() public {
        require(state.swap && now >= state.endTime);
        state.penalty = this.balance * 2000 / 10000;
        payFees();
        _start();
    }

    function totalSupply() public constant returns (uint) {
        return state.totalSupply;
    }

    function mint(address to, uint256 value) internal returns (uint256) {
        uint256 total = state.submitted + value;
        uint256 refund = 0;
        if (total > state.MAX_SUBMITTED) {
            refund = total - state.MAX_SUBMITTED - 1;
            value -= refund;
            to.transfer(refund);
        }
        state.submitted += value;
        total -= refund;
        uint256 tokens = calculateTokens(total, value);
        balances[to] += tokens;
        state.totalSupply += tokens;
        return tokens;
    }

    function calculateTokens(uint256 total, uint256 value) internal returns (uint256) {
        if (state.tier == 10) {
            return 74000000;
        }
        uint256 tokens = 0;
        if (total > levels[state.tier]) {
            uint256 remaining = total - levels[state.tier];
            value -= remaining;
            tokens = value * ratios[state.tier];
            state.tier += 1;
            tokens += calculateTokens(total, remaining);
        } else {
            tokens = value * ratios[state.tier];
        }
        return tokens;
    }

    function currentTier() public view returns (uint256) {
        if (state.tier == 10) {
            return 10;
        } else {
            return state.tier + 1;
        }
    }

    function leftInTier() public view returns (uint256) {
        if (state.tier == 10) {
            return 0;
        } else {
            return levels[state.tier] - state.submitted;
        }
    }

    function submitted() public view returns (uint256) {
        return state.submitted;
    }

    function balanceMinusFeesOutstanding() public view returns (uint256) {
        return this.balance - (state.penalty + (state.submitted - state.submittedFeesPaid) * 1530 / 10000);
    }

    function calculateRate() internal {
        state.reservedFees = state.penalty + (state.submitted - state.submittedFeesPaid) * 1530 / 10000;
        uint256 tokens = state.totalSupply / 1 ether;
        state.payRate = (this.balance - state.reservedFees) / tokens;
    }

    function _updateState() internal {
        if (now >= state.endTime) {
            if (!state.swap && !state.wait) {
                if (state.extended) {
                    state.wait = true;
                    state.endTime = state.swapTimeExtended;
                    WaitStarted(state.endTime);
                } else if (state.tier == 10) {
                    state.wait = true;
                    state.endTime = state.swapTime;
                    WaitStarted(state.endTime);
                } else {
                    state.endTime = state.endTimeExtended;
                    state.extended = true;
                    MiningExtended(state.endTime, state.swapTime, state.swapEndTime);
                }
            } else if (state.wait) {
                state.swap = true;
                state.wait = false;
                if (state.extended) {
                    state.endTime = state.swapEndTimeExtended;
                } else {
                    state.endTime = state.swapEndTime;
                }
                SwapStarted(state.endTime);
            }
        }
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balances[msg.sender] >= value);
        _updateState();
        if (to == address(this)) {
            require(state.swap);
            if (state.payRate == 0) {
                calculateRate();
            }
            uint256 amount = value * state.payRate / 1 ether;
            balances[msg.sender] -= value;
            state.totalSupply -= value;
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
        if (allowance < state.MAX_UINT256) {
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
        uint256 fees = state.penalty + (state.submitted - state.submittedFeesPaid) * 1530 / 10000;
        state.submittedFeesPaid = state.submitted;
        state.reservedFees = 0;
        state.penalty = 0;
        if (fees > 0) {
            state.foundation.transfer(fees / 3);
            state.owner.transfer(fees / 3);
            state.dev.transfer(fees / 3);
        }
    }

    function changeFoundation(address receiver) public {
        require(msg.sender == state.foundation);
        state.foundation = receiver;
    }

    function changeOwner(address receiver) public {
        require(msg.sender == state.owner);
        state.owner = receiver;
    }

    function changeDev(address receiver) public {
        require(msg.sender == state.dev);
        state.dev = receiver;
    }
}
```