```solidity
pragma solidity ^0.4.15;

contract ERC20 {
    function balanceOf(address who) constant returns (uint);
    function allowance(address owner, address spender) constant returns (uint);
    function transfer(address to, uint value) returns (bool ok);
    function transferFrom(address from, address to, uint value) returns (bool ok);
    function approve(address spender, uint value) returns (bool ok);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract SafeMath {
    function safeAdd(uint256 a, uint256 b) constant internal returns (uint256 c) {
        assert((c = a + b) >= a);
    }
    
    function safeSub(uint256 a, uint256 b) constant internal returns (uint256 c) {
        assert((c = a - b) <= a);
    }
    
    function safeMul(uint256 a, uint256 b) constant internal returns (uint256 c) {
        assert((c = a * b) >= a);
    }
    
    function safeDiv(uint256 a, uint256 b) constant internal returns (uint256 c) {
        c = a / b;
    }
    
    function min(uint256 a, uint256 b) constant internal returns (uint256 c) {
        return a <= b ? a : b;
    }
    
    function max(uint256 a, uint256 b) constant internal returns (uint256 c) {
        return a >= b ? a : b;
    }
}

contract DateTime {
    struct DateTimeStruct {
        uint16 year;
        uint8 month;
        uint8 day;
        uint8 hour;
        uint8 minute;
        uint8 second;
        uint8 weekday;
    }
    
    function isLeapYear(uint16 year) constant returns (bool) {
        if (year % 4 != 0) {
            return false;
        }
        if (year % 100 != 0) {
            return true;
        }
        if (year % 400 != 0) {
            return false;
        }
        return true;
    }
    
    function leapYearsBefore(uint year) constant returns (uint) {
        year -= 1;
        return year / 4 - year / 100 + year / 400;
    }
    
    function getDaysInMonth(uint8 month, uint16 year) constant returns (uint8) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            return 31;
        } else if (month == 4 || month == 6 || month == 9 || month == 11) {
            return 30;
        } else if (isLeapYear(year)) {
            return 29;
        } else {
            return 28;
        }
    }
    
    function parseTimestamp(uint timestamp) internal returns (DateTimeStruct dt) {
        uint secondsAccountedFor = 0;
        uint buf;
        uint8 i;
        dt.year = getYear(timestamp);
        buf = leapYearsBefore(dt.year) - leapYearsBefore(1970);
        secondsAccountedFor += 31622400 * buf;
        secondsAccountedFor += 31536000 * (dt.year - 1970 - buf);
        uint secondsInMonth;
        for (i = 1; i <= 12; i++) {
            secondsInMonth = 86400 * getDaysInMonth(i, dt.year);
            if (secondsInMonth + secondsAccountedFor > timestamp) {
                dt.month = i;
                break;
            }
            secondsAccountedFor += secondsInMonth;
        }
        for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
            if (86400 + secondsAccountedFor > timestamp) {
                dt.day = i;
                break;
            }
            secondsAccountedFor += 86400;
        }
        dt.hour = getHour(timestamp);
    }
    
    function getYear(uint timestamp) constant returns (uint16) {
        uint secondsAccountedFor = 0;
        uint16 year;
        uint numLeapYears;
        year = uint16(1970 + timestamp / 31536000);
        numLeapYears = leapYearsBefore(year) - leapYearsBefore(1970);
        secondsAccountedFor += 31622400 * numLeapYears;
        secondsAccountedFor += 31536000 * (year - 1970 - numLeapYears);
        while (secondsAccountedFor > timestamp) {
            if (isLeapYear(uint16(year - 1))) {
                secondsAccountedFor -= 31622400;
            } else {
                secondsAccountedFor -= 31536000;
            }
            year -= 1;
        }
        return year;
    }
    
    function getMonth(uint timestamp) constant returns (uint8) {
        return parseTimestamp(timestamp).month;
    }
    
    function getDay(uint timestamp) constant returns (uint8) {
        return parseTimestamp(timestamp).day;
    }
    
    function getHour(uint timestamp) constant returns (uint8) {
        return uint8((timestamp / 60 / 60) % 24);
    }
}

contract ITGTokenBase is ERC20, SafeMath {
    mapping(address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    
    function balanceOf(address who) constant returns (uint balance) {
        return balances[who];
    }
    
    function approve(address spender, uint value) returns (bool success) {
        if ((value != 0) && (allowed[msg.sender][spender] != 0)) throw;
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }
    
    function allowance(address owner, address spender) constant returns (uint remaining) {
        return allowed[owner][spender];
    }
}

contract Authable {
    modifier onlyOwner() {
        require(msg.sender == config.owner);
        _;
    }
    
    modifier onlyAuth() {
        require(msg.sender == config.owner || msg.sender == config.executor);
        _;
    }
    
    function setOwner(address newOwner) {
        require(config.owner == 0x0 || config.owner == msg.sender);
        config.owner = newOwner;
    }
    
    function setExecutor(address exec) {
        require(config.executor == 0x0 || config.owner == msg.sender || config.executor == msg.sender);
        config.executor = exec;
    }
}

contract CrowdSale is SafeMath, Authable {
    struct SaleAttr {
        uint amountRaisedTotal;
        uint saleSupplyPre;
        uint saleSupply1;
        uint saleSupply2;
        uint saleSupply3;
        uint saleSupply4;
        uint amountRaisedPre;
        uint amountRaised1;
        uint amountRaised2;
        uint amountRaised3;
        uint amountRaised4;
        uint soldSupply2;
        uint soldSupply4;
    }
    
    SaleAttr public sale;
    
    mapping(address => uint) public participantsForPreSale;
    mapping(address => uint) public participantsFor1stSale;
    mapping(address => uint) public participantsFor3rdSale;
    
    event LogCustomSale(uint startTime, uint endTime, uint tokPerEth, uint supply);
    
    struct SaleTimeAttr {
        uint pstart;
        uint pdeadline;
        uint start;
        uint deadline1;
        uint deadline2;
        uint deadline3;
        uint deadline4;
    }
    
    SaleTimeAttr public time;
    
    struct CustomSaleAttr {
        uint start;
        uint end;
        uint tokenPerEth;
        uint saleSupply;
        uint soldSupply;
        uint amountRaised;
    }
    
    CustomSaleAttr public customSale;
    
    mapping(uint => mapping(address => uint)) public participantsForCustomSale;
    
    function setAttrs(
        uint supplyPre,
        uint supply1,
        uint supply2,
        uint supply3,
        uint supply4,
        uint preStart,
        uint preEnd,
        uint start,
        uint end1,
        uint end2,
        uint end3,
        uint end4
    ) onlyAuth {
        sale.saleSupplyPre = supplyPre;
        sale.saleSupply1 = supply1;
        sale.saleSupply2 = supply2;
        sale.saleSupply3 = supply3;
        sale.saleSupply4 = supply4;
        time.pstart = preStart;
        time.pdeadline = preEnd;
        time.start = start;
        time.deadline1 = end1;
        time.deadline2 = end2;
        time.deadline3 = end3;
        time.deadline4 = end4;
    }
    
    function setAttrCustom(uint startTime, uint endTime, uint tokPerEth, uint supply) onlyAuth {
        customSale.start = startTime;
        customSale.end = endTime;
        customSale.tokenPerEth = tokPerEth;
        customSale.saleSupply = supply;
        customSale.soldSupply = 0;
        customSale.amountRaised = 0;
        LogCustomSale(startTime, endTime, tokPerEth, supply);
    }
    
    function process(address sender, uint sendValue) onlyOwner returns (uint tokenAmount) {
        if (now > time.pstart && now <= time.pdeadline) {
            participantsForPreSale[sender] = safeAdd(participantsForPreSale[sender], sendValue);
            sale.amountRaisedPre = safeAdd(sale.amountRaisedPre, sendValue);
        } else if (now > time.start && now <= time.deadline1) {
            participantsFor1stSale[sender] = safeAdd(participantsFor1stSale[sender], sendValue);
            sale.amountRaised1 = safeAdd(sale.amountRaised1, sendValue);
        } else if (now > time.deadline1 && now <= time.deadline2 && sale.soldSupply2 < sale.saleSupply2) {
            tokenAmount = sendValue / (sale.amountRaised1 / sale.saleSupply1 * 120 / 100);
            sale.soldSupply2 = safeAdd(sale.soldSupply2, tokenAmount);
            sale.amountRaised2 = safeAdd(sale.amountRaised2, sendValue);
            require(sale.soldSupply2 < sale.saleSupply2 * 105 / 100);
        } else if (now > time.deadline2 && now <= time.deadline3) {
            participantsFor3rdSale[sender] = safeAdd(participantsFor3rdSale[sender], sendValue);
            sale.amountRaised3 = safeAdd(sale.amountRaised3, sendValue);
        } else if (now > time.deadline3 && now <= time.deadline4 && sale.soldSupply4 < sale.saleSupply4) {
            tokenAmount = sendValue / (sale.amountRaised3 / sale.saleSupply3 * 120 / 100);
            sale.soldSupply4 = safeAdd(sale.soldSupply4, tokenAmount);
            sale.amountRaised4 = safeAdd(sale.amountRaised4, sendValue);
            require(sale.soldSupply4 < sale.saleSupply4 * 105 / 100);
        } else if (now > customSale.start && now <= customSale.end && customSale.soldSupply < customSale.saleSupply) {
            if (customSale.tokenPerEth > 0) {
                tokenAmount = sendValue * customSale.tokenPerEth;
                customSale.soldSupply = safeAdd(customSale.soldSupply, tokenAmount);
                require(customSale.soldSupply < customSale.saleSupply * 105 / 100);
            } else {
                participantsForCustomSale[customSale.start][sender] = safeAdd(participantsForCustomSale[customSale.start][sender], sendValue);
                customSale.amountRaised = safeAdd(customSale.amountRaised, sendValue);
            }
        } else {
            throw;
        }
        sale.amountRaisedTotal = safeAdd(sale.amountRaisedTotal, sendValue);
    }
    
    function getToken(address sender) onlyOwner returns (uint tokenAmount) {
        if (now > time.pdeadline && participantsForPreSale[sender] != 0) {
            tokenAmount = safeAdd(tokenAmount, participantsForPreSale[sender] * sale.saleSupplyPre / sale.amountRaisedPre);
            participantsForPreSale[sender] = 0;
        }
        if (now > time.deadline1 && participantsFor1stSale[sender] != 0) {
            tokenAmount = safeAdd(tokenAmount, participantsFor1stSale[sender] * sale.saleSupply1 / sale.amountRaised1);
            participantsFor1stSale[sender] = 0;
        }
        if (now > time.deadline3 && participantsFor3rdSale[sender] != 0) {
            tokenAmount = safeAdd(tokenAmount, participantsFor3rdSale[sender] * sale.saleSupply3 / sale.amountRaised3);
            participantsFor3rdSale[sender] = 0;
        }
        if (now > customSale.end && participantsForCustomSale[customSale.start][sender] != 0) {
            tokenAmount = safeAdd(tokenAmount, participantsForCustomSale[customSale.start][sender] * customSale.saleSupply / customSale.amountRaised);
            participantsForCustomSale[customSale.start][sender] = 0;
        }
    }
}

contract Voting is SafeMath, Authable {
    mapping(uint => uint) public voteRewardPerUnit;
    mapping(uint => uint) public voteWeightUnit;
    mapping(uint => uint) public voteStart;
    mapping(uint => uint) public voteEnd;
    mapping(uint => uint) public maxCandidateId;
    mapping(uint => mapping(address => bool)) public voted;
    mapping(uint => mapping(uint => uint)) public results;
    
    event LogVoteInitiate(uint _voteId, uint _voteRewardPerUnit, uint _voteWeightUnit, uint _voteStart, uint _voteEnd, uint _maxCandidateId);
    event LogVote(address voter, uint weight, uint voteId, uint candidateId, uint candidateValue);
    
    function voteInitiate(
        uint _voteId,
        uint _voteRewardPerUnit,
        uint _voteWeightUnit,
        uint _voteStart,
        uint _voteEnd,
        uint _maxCandidateId
    ) onlyOwner {
        require(voteEnd[_voteId] == 0);
        require(_voteEnd != 0);
        voteRewardPerUnit[_voteId] = _voteRewardPerUnit;
        voteWeightUnit[_voteId] = _voteWeightUnit;
        voteStart[_voteId] = _voteStart;
        voteEnd[_voteId] = _voteEnd;
        maxCandidateId[_voteId] = _maxCandidateId;
        LogVoteInitiate(_voteId, _voteRewardPerUnit, _voteWeightUnit, _voteStart, _voteEnd, _maxCandidateId);
    }
    
    function vote(address sender, uint holding, uint voteId, uint candidateId) onlyOwner returns (uint tokenAmount, uint lockUntil) {
        require(now > voteStart[voteId] && now <= voteEnd[voteId]);
        require(maxCandidateId[voteId] >= candidateId);
        require(holding >= voteRewardPerUnit[voteId]);
        require(!voted[voteId][sender]);
        uint weight = holding / voteWeightUnit[voteId];
        results[voteId][candidateId] = safeAdd(results[voteId][candidateId], weight);
        voted[voteId][sender] = true;
        tokenAmount = weight * voteWeightUnit[voteId] * voteRewardPerUnit[voteId] / 100 / 100;
        lockUntil = voteEnd[voteId];
        LogVote(sender, weight, voteId, candidateId, results[voteId][candidateId]);
    }
}

contract Games is SafeMath, DateTime, Authable {
    enum GameTime { Hour, Month, Year, OutOfTime }
    enum GameType { Range, Point }
    
    struct Participant {
        address sender;
        uint value;
        uint currency;
    }
    
    struct DateAttr {
        uint currentYear;
        uint gameStart;
        uint gameEnd;
        uint prevGameEnd;
    }
    
    DateAttr public date;
    
    struct CommonAttr {
        GameTime currentGameTimeType;
        GameType gameType;
        uint hourlyAmountEth;
        uint monthlyAmountEth;
        uint yearlyAmountEth;
        uint charityAmountEth;
    }
    
    CommonAttr public common;
    
    struct FundAmountStatusAttr {
        uint hourlyStatusEth;
        uint monthlyStatusEth;
        uint yearlyStatusEth;
        uint hourlyStatusTok;
        uint monthlyStatusTok;
    }
    
    FundAmountStatusAttr public fundStatus;
    
    struct PriceAttr {
        uint bonusPerEth;
        uint inGameTokPricePerEth;
        uint inGameTokWinRatioMax;
        uint inGameTokWinRatioMin;
        uint currentInGameTokWinRatio;
        uint hourlyMinParticipateRatio;
        uint monthlyMinParticipateRatio;
        uint yearlyMinParticipateRatio;
        uint boostPrizeEth;
    }
    
    PriceAttr public price;
    
    struct RangeGameAttr {
        uint inTimeRange_H;
        uint inTimeRange_M;
        uint inTimeRange_Y;
    }
    
    RangeGameAttr public range;
    
    Participant[] public participants;
    mapping(uint256 => mapping(address => uint256)) public winners;
    mapping(uint256 => mapping(address => uint256)) public tokTakers;
    mapping(uint256 => uint256) public winPrizes;
    mapping(uint256 => uint256) public tokPrizes;
    
    event LogSelectWinner(uint rand, uint luckyNumber, address sender, uint reward, uint currency, uint amount);
    
    function setPriceAttr(
        GameType _gameType,
        uint _bonusPerEth,
        uint _inGameTokPricePerEth,
        uint _inGameTokWinRatioMax,
        uint _inGameTokWinRatioMin,
        uint _currentInGameTokWinRatio,
        uint _hourlyMinParticipateRatio,
        uint _monthlyMinParticipateRatio,
        uint _yearlyMinParticipateRatio,
        uint _boostPrizeEth
    ) onlyAuth {
        common.gameType = _gameType;
        price.bonusPerEth = _bonusPerEth;
        price.inGameTokPricePerEth = _inGameTokPricePerEth;
        price.inGameTokWinRatioMax = _inGameTokWinRatioMax;
        price.inGameTokWinRatioMin = _inGameTokWinRatioMin;
        price.currentInGameTokWinRatio = _currentIn