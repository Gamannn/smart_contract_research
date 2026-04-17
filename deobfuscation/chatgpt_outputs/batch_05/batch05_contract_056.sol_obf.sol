pragma solidity ^0.4.18;

contract TokenContract {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Mined(address indexed miner, uint value);
    event WaitStarted(uint256 timestamp);
    event SwapStarted(uint256 timestamp);
    event MiningStart(uint256 startTime, uint256 endTime, uint256 extendedTime);
    event MiningExtended(uint256 startTime, uint256 endTime, uint256 extendedTime);

    string public symbol = "TokenContract";
    uint256 public totalSupply = 0;
    uint256 public minedSupply = 0;
    uint256 public submittedFees = 0;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;

    function () external payable {
        require(msg.sender != address(0) && miningStage != 5 && isWaiting == false && isSwapping == false);
        uint256 issuedTokens = issueTokens(msg.sender, msg.value);
        Transfer(this, msg.sender, issuedTokens);
    }

    function issueTokens(address to, uint256 value) internal returns (uint256) {
        uint256 newSupply = totalSupply + value;
        if (newSupply > maxSupply) {
            uint256 excess = newSupply - maxSupply - 1;
            value -= excess;
            burnTokens(excess);
        }
        minedSupply += value;
        totalSupply = newSupply - excess;
        uint256 issued = calculateIssuedTokens(value);
        balances[to] += issued;
        totalSupply += issued;
        return issued;
    }

    function calculateIssuedTokens(uint256 value) internal returns (uint256) {
        if (miningStage == 5) return 0;
        if (totalSupply > stageLimits[miningStage]) {
            uint256 remaining = totalSupply - stageLimits[miningStage];
            value -= remaining;
            uint256 issued = value * stageRates[miningStage];
            miningStage += 1;
            return issued + calculateIssuedTokens(remaining);
        } else {
            return value * stageRates[miningStage];
        }
    }

    function getMiningStage() public view returns (uint256) {
        if (miningStage == 5) {
            return 5;
        } else {
            return miningStage + 1;
        }
    }

    function getRemainingSupply() public view returns (uint256) {
        if (miningStage == 5) {
            return 0;
        } else {
            return stageLimits[miningStage] - totalSupply;
        }
    }

    function getTotalSupply() public view returns (uint256) {
        return totalSupply;
    }

    function getAvailableSupply() public view returns (uint256) {
        return maxSupply - (minedSupply + (stageLimits[miningStage] - totalSupply) * 530 / 10000);
    }

    function updateSupply() internal {
        submittedFees = (totalSupply - minedSupply) * 530 / 10000;
        uint256 issued = totalSupply - submittedFees;
        totalSupply = issued / tokenRate;
    }

    function checkMiningStage() internal {
        if (now >= miningStartTime) {
            if (!isWaiting && !isSwapping) {
                if (now >= swapEndTime) {
                    isSwapping = true;
                    miningStartTime = swapExtendedTime;
                    WaitStarted(miningStartTime);
                } else if (miningStage == 5) {
                    isSwapping = true;
                    miningStartTime = swapEndTime;
                    SwapStarted(miningStartTime);
                } else {
                    miningStartTime = miningExtendedTime;
                    isExtended = true;
                    MiningExtended(miningStartTime, swapEndTime, swapExtendedTime);
                }
            } else if (isSwapping) {
                isWaiting = true;
                isSwapping = false;
                if (isExtended) {
                    miningStartTime = miningExtendedTime;
                } else {
                    miningStartTime = swapExtendedTime;
                }
                SwapStarted(miningStartTime);
            }
        }
    }

    function burnTokens(uint256 value) internal {
        totalSupply -= value;
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balances[msg.sender] >= value);
        checkMiningStage();
        if (to == address(this)) {
            require(isWaiting);
            if (totalSupply == 0) {
                updateSupply();
            }
            uint256 payout = value * totalSupply;
            payout /= 1 ether;
            balances[msg.sender] -= value;
            Transfer(msg.sender, to, value);
            msg.sender.transfer(payout);
        } else {
            balances[msg.sender] -= value;
            balances[to] += value;
            Transfer(msg.sender, to, value);
        }
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        allowances[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowances[owner][spender];
    }

    address public foundationAddress = 0xE252765E4A71e3170b2215cf63C16E7553ec26bD;
    address public owner = 0xa4cdd9c17d87EcceF6a02AC43F677501cAb05d04;
    address public devAddress = 0x752607dc81e0336ea6ddccced509d8fd28610b54;

    function distributeFees() public {
        uint256 fees = minedSupply + submittedFees;
        minedSupply = 0;
        if (fees > 0) {
            foundationAddress.transfer(fees / 2);
            owner.transfer(fees / 4);
            devAddress.transfer(fees / 4);
        }
    }

    function setFoundationAddress(address newAddress) public {
        require(msg.sender == owner);
        foundationAddress = newAddress;
    }

    function setOwner(address newAddress) public {
        require(msg.sender == owner);
        owner = newAddress;
    }

    function setDevAddress(address newAddress) public {
        require(msg.sender == devAddress);
        devAddress = newAddress;
    }

    uint256 public miningStartTime;
    uint256 public swapEndTime;
    uint256 public swapExtendedTime;
    uint256 public miningExtendedTime;
    uint256 public maxSupply = 1500000 ether;
    uint256 public tokenRate = 1 ether;
    uint256 public miningStage = 0;
    bool public isWaiting = false;
    bool public isSwapping = false;
    bool public isExtended = false;

    uint256[] public stageLimits = [10000 ether, 20000 ether, 30000 ether, 40000 ether, 50000 ether];
    uint256[] public stageRates = [1, 2, 3, 4, 5];
}