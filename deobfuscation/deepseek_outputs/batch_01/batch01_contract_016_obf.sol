pragma solidity ^0.4.18;

contract FUTR {
    uint256[] public levels = [
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
    
    uint256[] public ratios = [114, 89, 55, 34, 21, 13, 8, 5, 3, 2];
    
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    event Mined(address indexed _miner, uint _value);
    event WaitStarted(uint256 endTime);
    event SwapStarted(uint256 endTime);
    event MiningStart(uint256 end_time, uint256 swap_time, uint256 swap_end_time);
    event MiningExtended(uint256 end_time, uint256 swap_time, uint256 swap_end_time);
    
    string public name = "Futereum Token";
    string public symbol = "FUTR";
    uint8 public decimals = 18;
    
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    
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
        uint256 tier;
        uint256 submitted;
        uint256 totalSupply;
        uint256 MAX_SUBMITTED;
        uint256 MAX_UINT256;
    }
    
    ContractState public state;
    
    function FUTR() public {
        _start();
    }
    
    function _start() internal {
        state.swap = false;
        state.wait = false;
        state.extended = false;
        state.endTime = now + 366 days;
        state.swapTime = state.endTime + 30 days;
        state.swapEndTime = state.swapTime + 5 days;
        state.endTimeExtended = now + 1096 days;
        state.swapTimeExtended = state.endTimeExtended + 30 days;
        state.swapEndTimeExtended = state.swapTimeExtended + 5 days;
        state.submittedFeesPaid = 0;
        state.submitted = 0;
        state.reservedFees = 0;
        state.payRate = 0;
        state.tier = 0;
        MiningStart(state.endTime, state.swapTime, state.swapEndTime);
    }
    
    function () external payable {
        require(msg.sender != address(0) && state.tier != 10 && state.swap == false && state.wait == false);
        uint256 issued = mint(msg.sender, msg.value);
        Mined(msg.sender, issued);
        Transfer(this, msg.sender, issued);
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
    
    function mint(address _to, uint256 _value) internal returns (uint256) {
        uint256 total = state.submitted + _value;
        uint256 refund = 0;
        
        if (total > state.MAX_SUBMITTED) {
            refund = total - state.MAX_SUBMITTED - 1;
            _value = _value - refund;
            _to.transfer(refund);
        }
        
        state.submitted += _value;
        total = state.submitted;
        
        uint256 tokens = calculateTokens(total, _value);
        balances[_to] += tokens;
        state.totalSupply += tokens;
        return tokens;
    }
    
    function calculateTokens(uint256 total, uint256 _value) internal returns (uint256) {
        if (state.tier == 10) {
            return 7400000000;
        }
        
        uint256 tokens = 0;
        
        if (total > levels[state.tier]) {
            uint256 remaining = total - levels[state.tier];
            _value -= remaining;
            tokens = _value * ratios[state.tier];
            state.tier += 1;
            tokens += calculateTokens(total, remaining);
        } else {
            tokens = _value * ratios[state.tier];
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
    
    function calulateRate() internal {
        state.reservedFees = state.penalty + (state.submitted - state.submittedFeesPaid) * 1530 / 10000;
        uint256 tokens = state.totalSupply / 1 ether;
        state.payRate = (this.balance - state.reservedFees);
        state.payRate = state.payRate / tokens;
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
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        _updateState();
        
        if (_to == address(this)) {
            require(state.swap);
            if (state.payRate == 0) {
                calulateRate();
            }
            uint256 amount = _value * state.payRate;
            amount /= 1 ether;
            balances[msg.sender] -= _value;
            state.totalSupply -= _value;
            Transfer(msg.sender, _to, _value);
            msg.sender.transfer(amount);
        } else {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
        }
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        
        balances[_to] += _value;
        balances[_from] -= _value;
        
        if (allowance < state.MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        
        Transfer(_from, _to, _value);
        return true;
    }
    
    function balanceOf(address _owner) view public returns (uint256 balance) {
        return balances[_owner];
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function payFees() public {
        _updateState();
        uint256 fees = state.penalty + (state.submitted - state.submittedFeesPaid) * 1530 / 10000;
        state.submittedFeesPaid = state.submitted;
        state.reservedFees = 0;
        state.penalty = 0;
        
        if (fees > 0) {
            state.foundation.transfer(fees / 2);
            state.owner.transfer(fees / 4);
            state.dev.transfer(fees / 4);
        }
    }
    
    function changeFoundation(address _receiver) public {
        require(msg.sender == state.foundation);
        state.foundation = _receiver;
    }
    
    function changeOwner(address _receiver) public {
        require(msg.sender == state.owner);
        state.owner = _receiver;
    }
    
    function changeDev(address _receiver) public {
        require(msg.sender == state.dev);
        state.dev = _receiver;
    }
    
    constructor() {
        state.dev = 0x5d2b9f5345e69e2390ce4c26ccc9c2910a097520;
        state.owner = 0x78BFCA5E20B0D710EbEF98249f68d9320eE423be;
        state.foundation = 0x950ec4ef693d90f8519c4213821e462426d30905;
        state.reservedFees = 0;
        state.penalty = 0;
        state.submittedFeesPaid = 0;
        state.payRate = 0;
        state.swapEndTimeExtended = 0;
        state.swapTimeExtended = 0;
        state.endTimeExtended = 0;
        state.swapEndTime = 0;
        state.swapTime = 0;
        state.endTime = 0;
        state.extended = false;
        state.wait = false;
        state.swap = false;
        state.tier = 0;
        state.submitted = 0;
        state.totalSupply = 0;
        state.MAX_SUBMITTED = 500067157619455000000000;
        state.MAX_UINT256 = 2**256 - 1;
    }
}