```solidity
pragma solidity ^0.4.18;

contract FUTX {
    uint256[] public levels = [
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
    
    uint256[] public ratios = [114, 89, 55, 34, 21, 13, 8, 5, 3, 2];
    
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    event Mined(address indexed _miner, uint _value);
    event WaitStarted(uint256 endTime);
    event SwapStarted(uint256 endTime);
    event MiningStart(uint256 end_time, uint256 swap_time, uint256 swap_end_time);
    event MiningExtended(uint256 end_time, uint256 swap_time, uint256 swap_end_time);
    
    string public name = "Futereum X";
    string public symbol = "FUTX";
    uint8 public decimals = 18;
    
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;
    
    address public owner = 0x78BFCA5E20B0D710EbEF98249f68d9320eE423be;
    address public dev = 0x5d2b9f5345e69e2390ce4c26ccc9c2910a097520;
    address public foundation = 0x950ec4ef693d90f8519c4213821e462426d30905;
    
    uint256 public _totalSupply;
    uint256 public _submitted;
    uint256 public submittedFeesPaid;
    uint256 public reservedFees;
    uint256 public penalty;
    uint256 public payRate;
    
    uint256 public endTime;
    uint256 public swapTime;
    uint256 public swapEndTime;
    uint256 public endTimeExtended;
    uint256 public swapTimeExtended;
    uint256 public swapEndTimeExtended;
    
    bool public extended;
    bool public wait;
    bool public swap;
    
    uint8 public tier;
    
    uint256 public constant MAX_SUBMITTED = 5000671576194550000000;
    uint256 public constant MAX_UINT256 = 2**256 - 1;
    
    function FUTX() public {
        _start();
    }
    
    function () external payable {
        require(
            msg.sender != address(0) && 
            tier != 10 && 
            swap == false && 
            wait == false
        );
        
        uint256 issued = mint(msg.sender, msg.value);
        Mined(msg.sender, issued);
        Transfer(this, msg.sender, issued);
    }
    
    function _start() internal {
        swap = false;
        wait = false;
        extended = false;
        
        endTime = now + 90 days;
        swapTime = endTime + 30 days;
        swapEndTime = swapTime + 5 days;
        
        endTimeExtended = now + 270 days;
        swapTimeExtended = endTimeExtended + 90 days;
        swapEndTimeExtended = swapTimeExtended + 5 days;
        
        submittedFeesPaid = 0;
        _submitted = 0;
        reservedFees = 0;
        payRate = 0;
        tier = 0;
        
        MiningStart(endTime, swapTime, swapEndTime);
    }
    
    function restart() public {
        require(swap && now >= endTime);
        
        penalty = this.balance * 2000 / 10000;
        payFees();
        _start();
    }
    
    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }
    
    function mint(address _to, uint256 _value) internal returns (uint256) {
        uint256 total = _submitted + _value;
        uint256 refund = 0;
        
        if (total > MAX_SUBMITTED) {
            refund = total - MAX_SUBMITTED - 1;
            _value = _value - refund;
            _to.transfer(refund);
        }
        
        _submitted += _value;
        total -= refund;
        
        uint256 tokens = calculateTokens(total, _value);
        balances[_to] += tokens;
        _totalSupply += tokens;
        
        return tokens;
    }
    
    function calculateTokens(uint256 total, uint256 _value) internal returns (uint256) {
        if (tier == 10) {
            return 74000000;
        }
        
        uint256 tokens = 0;
        
        if (total > levels[tier]) {
            uint256 remaining = total - levels[tier];
            _value -= remaining;
            tokens = _value * ratios[tier];
            tier += 1;
            tokens += calculateTokens(total, remaining);
        } else {
            tokens = _value * ratios[tier];
        }
        
        return tokens;
    }
    
    function currentTier() public view returns (uint256) {
        if (tier == 10) {
            return 10;
        } else {
            return tier + 1;
        }
    }
    
    function leftInTier() public view returns (uint256) {
        if (tier == 10) {
            return 0;
        } else {
            return levels[tier] - _submitted;
        }
    }
    
    function submitted() public view returns (uint256) {
        return _submitted;
    }
    
    function balanceMinusFeesOutstanding() public view returns (uint256) {
        return this.balance - (penalty + (_submitted - submittedFeesPaid) * 1530 / 10000);
    }
    
    function calulateRate() internal {
        reservedFees = penalty + (_submitted - submittedFeesPaid) * 1530 / 10000;
        uint256 tokens = _totalSupply / 1 ether;
        payRate = (this.balance - reservedFees) / tokens;
    }
    
    function _updateState() internal {
        if (now >= endTime) {
            if (!swap && !wait) {
                if (extended) {
                    wait = true;
                    endTime = swapTimeExtended;
                    WaitStarted(endTime);
                } else if (tier == 10) {
                    wait = true;
                    endTime = swapTime;
                    WaitStarted(endTime);
                } else {
                    endTime = endTimeExtended;
                    extended = true;
                    MiningExtended(endTime, swapTime, swapEndTime);
                }
            } else if (wait) {
                swap = true;
                wait = false;
                if (extended) {
                    endTime = swapEndTimeExtended;
                } else {
                    endTime = swapEndTime;
                }
                SwapStarted(endTime);
            }
        }
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        
        _updateState();
        
        if (_to == address(this)) {
            require(swap);
            
            if (payRate == 0) {
                calulateRate();
            }
            
            uint256 amount = _value * payRate / 1 ether;
            balances[msg.sender] -= _value;
            _totalSupply -= _value;
            
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
        
        if (allowance < MAX_UINT256) {
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
        
        uint256 fees = penalty + (_submitted - submittedFeesPaid) * 1530 / 10000;
        submittedFeesPaid = _submitted;
        reservedFees = 0;
        penalty = 0;
        
        if (fees > 0) {
            foundation.transfer(fees / 3);
            owner.transfer(fees / 3);
            dev.transfer(fees / 3);
        }
    }
    
    function changeFoundation(address _receiver) public {
        require(msg.sender == foundation);
        foundation = _receiver;
    }
    
    function changeOwner(address _receiver) public {
        require(msg.sender == owner);
        owner = _receiver;
    }
    
    function changeDev(address _receiver) public {
        require(msg.sender == dev);
        dev = _receiver;
    }
}
```