pragma solidity ^0.4.18;

contract Ox9e33a1d0cc24090bb555d2d489f8497c7a53e23b {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    event WaitStarted(uint256 waitStart);
    event SwapStarted(uint256 swapStart);
    event MiningStart(uint256 miningStart, uint256 swapTime, uint256 swapTimeExtended);
    event MiningExtended(uint256 miningStart, uint256 swapTime, uint256 swapTimeExtended);

    string public symbol = "Ox9e33a1d0cc24090bb555d2d489f8497c7a53e23b";
    uint256 public totalSupply = 0;
    uint256 public totalFees = 0;
    uint256 public totalPenalty = 0;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    address public foundation = 0xE252765E4A71e3170b2215cf63C16E7553ec26bD;
    address public owner = 0xa4cdd9c17d87EcceF6a02AC43F677501cAb05d04;
    address public dev = 0x752607dc81e0336ea6ddccced509d8fd28610b54;

    uint256 public miningStart;
    uint256 public swapTime;
    uint256 public swapTimeExtended;
    uint256 public swapEndTime;
    uint256 public waitStart;
    uint256 public waitEnd;
    uint256 public penaltyStart;
    uint256 public penaltyEnd;

    bool public isWaiting = false;
    bool public isSwapping = false;
    bool public isExtended = false;

    uint8 public currentTier = 0;
    uint256 public totalSubmitted = 0;
    uint256 public totalReserved = 0;
    uint256 public exchangeRate = 0;

    uint256 constant public MAX_SUBMITTED = 1500000 ether;
    uint256 constant public MAX_UINT256 = 2**256 - 1;

    uint256[5] public tierLimits = [3000000000000000000, 6000000000000000000, 15000000000000000000, 10000000000000000000, 0];
    uint256[5] public tierRates = [146, 133, 110, 100, 0];

    function () external payable {
        require(msg.sender != address(0) && currentTier != 5 && isSwapping == false && isWaiting == false);
        uint256 amount = msg.value;
        require(amount > 0);
        uint256 tokens = _addTokens(msg.sender, amount);
        totalSubmitted += amount;
        Transfer(address(this), msg.sender, tokens);
        _updateState();
    }

    function totalSupply() public view returns (uint) {
        return totalReserved;
    }

    function _addTokens(address beneficiary, uint amount) internal returns (uint256) {
        uint256 newTotal = totalSubmitted + amount;
        if (newTotal > MAX_SUBMITTED) {
            uint256 refund = newTotal - MAX_SUBMITTED - 1;
            amount = amount - refund;
            beneficiary.transfer(refund);
        }
        totalSubmitted += amount;
        uint256 tokens = _calculateTokens(totalSubmitted, amount);
        balanceOf[beneficiary] += tokens;
        totalReserved += tokens;
        return tokens;
    }

    function _calculateTokens(uint256 total, uint256 amount) internal returns (uint256) {
        if (currentTier == 5) return 0;
        uint256 tokens = 0;
        if (total > tierLimits[currentTier]) {
            uint256 remaining = total - tierLimits[currentTier];
            amount -= remaining;
            tokens = (amount) * tierRates[currentTier];
            currentTier += 1;
            tokens += _calculateTokens(total, remaining);
        } else {
            tokens = amount * tierRates[currentTier];
        }
        return tokens;
    }

    function getCurrentTier() public view returns (uint256) {
        if (currentTier == 5) {
            return 5;
        } else {
            return currentTier + 1;
        }
    }

    function getTierRemaining() public view returns (uint256) {
        if (currentTier == 5) {
            return 0;
        } else {
            return tierLimits[currentTier] - totalSubmitted;
        }
    }

    function getTotalPenalty() public view returns (uint256) {
        return totalPenalty;
    }

    function getAvailableBalance() public view returns (uint256) {
        return this.balance - (totalFees + (totalSubmitted - totalPenalty) * 530 / 10000);
    }

    function _calculateExchangeRate() internal {
        totalPenalty = (totalSubmitted - totalPenalty) * 530 / 10000;
        uint256 tokens = totalReserved;
        exchangeRate = (this.balance - totalPenalty);
        exchangeRate = exchangeRate / tokens;
    }

    function _updateState() internal {
        if (now >= miningStart) {
            if(!isSwapping && !isWaiting) {
                if (now < swapTime) {
                    isWaiting = true;
                    waitStart = now;
                    WaitStarted(waitStart);
                } else if (currentTier == 5) {
                    isWaiting = true;
                    waitStart = penaltyStart;
                    WaitStarted(waitStart);
                } else {
                    miningStart = penaltyEnd;
                    isExtended = true;
                    MiningExtended(miningStart, swapTime, swapTimeExtended);
                }
            }
        } else if (isWaiting) {
            isSwapping = true;
            isWaiting = false;
            if (isExtended) {
                waitStart = penaltyStart;
            } else {
                waitStart = swapTimeExtended;
            }
            SwapStarted(waitStart);
        }
    }

    function transfer(address to, uint value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);
        _updateState();
        if (to == address(this)) {
            require(isSwapping);
            if (exchangeRate == 0) {
                _calculateExchangeRate();
            }
            uint256 etherAmount = value * exchangeRate;
            etherAmount /= 1 ether;
            balanceOf[msg.sender] -= value;
            totalReserved -= value;
            Transfer(msg.sender, to, value);
            msg.sender.transfer(etherAmount);
        } else {
            balanceOf[msg.sender] -= value;
            balanceOf[to] += value;
            Transfer(msg.sender, to, value);
        }
        return true;
    }

    function transferFrom(address from, address to, uint value) public returns (bool success) {
        uint256 allowed = allowance[from][msg.sender];
        require(balanceOf[from] >= value && allowed >= value);
        balanceOf[to] += value;
        balanceOf[from] -= value;
        if (allowed < MAX_UINT256) {
            allowance[from][msg.sender] -= value;
        }
        Approval(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint value) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

    function distributeFees() public {
        uint256 remaining = totalFees + (totalSubmitted - totalPenalty) * 530 / 10000;
        uint256 devShare = remaining / 4;
        totalFees = 0;
        if (remaining > 0) {
            foundation.transfer(remaining / 2);
            owner.transfer(remaining / 4);
            dev.transfer(remaining / 4);
        }
    }

    function setFoundation(address newFoundation) public {
        require(msg.sender == foundation);
        foundation = newFoundation;
    }

    function setOwner(address newOwner) public {
        require(msg.sender == owner);
        owner = newOwner;
    }

    function setDev(address newDev) public {
        require(msg.sender == dev);
        dev = newDev;
    }
}