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

contract Math {
    function safeAdd(uint256 a, uint256 b) constant internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function safeSub(uint256 a, uint256 b) constant internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeMul(uint256 a, uint256 b) constant internal returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) constant internal returns (uint256) {
        return a / b;
    }

    function min(uint256 a, uint256 b) constant internal returns (uint256) {
        return a <= b ? a : b;
    }

    function max(uint256 a, uint256 b) constant internal returns (uint256) {
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

contract ITGTokenBase is ERC20, Math {
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    function balanceOf(address owner) constant returns (uint balance) {
        return balances[owner];
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
        require(msg.sender == owner);
        _;
    }

    modifier onlyAuth() {
        require(msg.sender == owner || msg.sender == executor);
        _;
    }

    function setOwner(address newOwner) {
        require(owner == 0x0 || owner == msg.sender);
        owner = newOwner;
    }

    function setExecutor(address exec) {
        require(executor == 0x0 || owner == msg.sender || executor == msg.sender);
        executor = exec;
    }

    address public owner;
    address public executor;
}

contract CrowdSale is Math, Authable {
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

    SaleAttr public s;
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

    SaleTimeAttr public t;

    struct CustomSaleAttr {
        uint start;
        uint end;
        uint tokenPerEth;
        uint saleSupply;
        uint soldSupply;
        uint amountRaised;
    }

    CustomSaleAttr public cs;
    mapping(uint => mapping(address => uint)) public participantsForCustomSale;

    function setAttrs(uint supplyPre, uint supply1, uint supply2, uint supply3, uint supply4, uint preStart, uint preEnd, uint start, uint end1, uint end2, uint end3, uint end4) onlyAuth {
        s.saleSupplyPre = supplyPre;
        s.saleSupply1 = supply1;
        s.saleSupply2 = supply2;
        s.saleSupply3 = supply3;
        s.saleSupply4 = supply4;
        t.pstart = preStart;
        t.pdeadline = preEnd;
        t.start = start;
        t.deadline1 = end1;
        t.deadline2 = end2;
        t.deadline3 = end3;
        t.deadline4 = end4;
    }

    function setAttrCustom(uint startTime, uint endTime, uint tokPerEth, uint supply) onlyAuth {
        cs.start = startTime;
        cs.end = endTime;
        cs.tokenPerEth = tokPerEth;
        cs.saleSupply = supply;
        cs.soldSupply = 0;
        cs.amountRaised = 0;
        LogCustomSale(startTime, endTime, tokPerEth, supply);
    }

    function process(address sender, uint sendValue) onlyOwner returns (uint tokenAmount) {
        if (now > t.pstart && now <= t.pdeadline) {
            participantsForPreSale[sender] = safeAdd(participantsForPreSale[sender], sendValue);
            s.amountRaisedPre = safeAdd(s.amountRaisedPre, sendValue);
        } else if (now > t.start && now <= t.deadline1) {
            participantsFor1stSale[sender] = safeAdd(participantsFor1stSale[sender], sendValue);
            s.amountRaised1 = safeAdd(s.amountRaised1, sendValue);
        } else if (now > t.deadline1 && now <= t.deadline2 && s.soldSupply2 < s.saleSupply2) {
            tokenAmount = sendValue / (s.amountRaised1 / s.saleSupply1 * 120 / 100);
            s.soldSupply2 = safeAdd(s.soldSupply2, tokenAmount);
            s.amountRaised2 = safeAdd(s.amountRaised2, sendValue);
            require(s.soldSupply2 < s.saleSupply2 * 105 / 100);
        } else if (now > t.deadline2 && now <= t.deadline3) {
            participantsFor3rdSale[sender] = safeAdd(participantsFor3rdSale[sender], sendValue);
            s.amountRaised3 = safeAdd(s.amountRaised3, sendValue);
        } else if (now > t.deadline3 && now <= t.deadline4 && s.soldSupply4 < s.saleSupply4) {
            tokenAmount = sendValue / (s.amountRaised3 / s.saleSupply3 * 120 / 100);
            s.soldSupply4 = safeAdd(s.soldSupply4, tokenAmount);
            s.amountRaised4 = safeAdd(s.amountRaised4, sendValue);
            require(s.soldSupply4 < s.saleSupply4 * 105 / 100);
        } else if (now > cs.start && now <= cs.end && cs.soldSupply < cs.saleSupply) {
            if (cs.tokenPerEth > 0) {
                tokenAmount = sendValue * cs.tokenPerEth;
                cs.soldSupply = safeAdd(cs.soldSupply, tokenAmount);
                require(cs.soldSupply < cs.saleSupply * 105 / 100);
            } else {
                participantsForCustomSale[cs.start][sender] = safeAdd(participantsForCustomSale[cs.start][sender], sendValue);
                cs.amountRaised = safeAdd(cs.amountRaised, sendValue);
            }
        } else {
            throw;
        }
        s.amountRaisedTotal = safeAdd(s.amountRaisedTotal, sendValue);
    }

    function getToken(address sender) onlyOwner returns (uint tokenAmount) {
        if (now > t.pdeadline && participantsForPreSale[sender] != 0) {
            tokenAmount = safeAdd(tokenAmount, participantsForPreSale[sender] * s.saleSupplyPre / s.amountRaisedPre);
            participantsForPreSale[sender] = 0;
        }
        if (now > t.deadline1 && participantsFor1stSale[sender] != 0) {
            tokenAmount = safeAdd(tokenAmount, participantsFor1stSale[sender] * s.saleSupply1 / s.amountRaised1);
            participantsFor1stSale[sender] = 0;
        }
        if (now > t.deadline3 && participantsFor3rdSale[sender] != 0) {
            tokenAmount = safeAdd(tokenAmount, participantsFor3rdSale[sender] * s.saleSupply3 / s.amountRaised3);
            participantsFor3rdSale[sender] = 0;
        }
        if (now > cs.end && participantsForCustomSale[cs.start][sender] != 0) {
            tokenAmount = safeAdd(tokenAmount, participantsForCustomSale[cs.start][sender] * cs.saleSupply / cs.amountRaised);
            participantsForCustomSale[cs.start][sender] = 0;
        }
    }
}

contract Voting is Math, Authable {
    mapping(uint => uint) public voteRewardPerUnit;
    mapping(uint => uint) public voteWeightUnit;
    mapping(uint => uint) public voteStart;
    mapping(uint => uint) public voteEnd;
    mapping(uint => uint) public maxCandidateId;
    mapping(uint => mapping(address => bool)) public voted;
    mapping(uint => mapping(uint => uint)) public results;
    event LogVoteInitiate(uint voteId, uint voteRewardPerUnit, uint voteWeightUnit, uint voteStart, uint voteEnd, uint maxCandidateId);
    event LogVote(address voter, uint weight, uint voteId, uint candidateId, uint candidateValue);

    function voteInitiate(uint voteId, uint voteRewardPerUnit, uint voteWeightUnit, uint voteStart, uint voteEnd, uint maxCandidateId) onlyOwner {
        require(voteEnd[voteId] == 0);
        require(voteEnd != 0);
        voteRewardPerUnit[voteId] = voteRewardPerUnit;
        voteWeightUnit[voteId] = voteWeightUnit;
        voteStart[voteId] = voteStart;
        voteEnd[voteId] = voteEnd;
        maxCandidateId[voteId] = maxCandidateId;
        LogVoteInitiate(voteId, voteRewardPerUnit, voteWeightUnit, voteStart, voteEnd, maxCandidateId);
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

contract Games is Math, DateTime, Authable {
    enum GameTime { Hour, Month, Year, OutOfTime }
    enum GameType { Range, Point }

    struct Participant {
        address sender;
        uint amount;
        uint currency;
    }

    struct DateAttr {
        uint currentYear;
        uint gameStart;
        uint gameEnd;
        uint prevGameEnd;
    }

    DateAttr public d;

    struct CommonAttr {
        GameTime currentGameTimeType;
        GameType gameType;
        uint hourlyAmountEth;
        uint monthlyAmountEth;
        uint yearlyAmountEth;
        uint charityAmountEth;
    }

    CommonAttr public commonAttr;

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

    PriceAttr public priceAttr;

    struct RangeGameAttr {
        uint inTimeRange_H;
        uint inTimeRange_M;
        uint inTimeRange_Y;
    }

    RangeGameAttr public rangeGameAttr;

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
        commonAttr.gameType = _gameType;
        priceAttr.bonusPerEth = _bonusPerEth;
        priceAttr.inGameTokPricePerEth = _inGameTokPricePerEth;
        priceAttr.inGameTokWinRatioMax = _inGameTokWinRatioMax;
        priceAttr.inGameTokWinRatioMin = _inGameTokWinRatioMin;
        priceAttr.currentInGameTokWinRatio = _currentInGameTokWinRatio;
        priceAttr.hourlyMinParticipateRatio = _hourlyMinParticipateRatio;
        priceAttr.monthlyMinParticipateRatio = _monthlyMinParticipateRatio;
        priceAttr.yearlyMinParticipateRatio = _yearlyMinParticipateRatio;
        priceAttr.boostPrizeEth = _boostPrizeEth;
    }

    function setRangeGameAttr(uint _inTimeRange_H, uint _inTimeRange_M, uint _inTimeRange_Y) onlyAuth {
        rangeGameAttr.inTimeRange_H = _inTimeRange_H;
        rangeGameAttr.inTimeRange_M = _inTimeRange_M;
        rangeGameAttr.inTimeRange_Y = _inTimeRange_Y;
    }

    modifier beforeRangeGame() {
        require(now > d.gameStart && now <= d.gameEnd);
        _;
    }

    modifier beforePointGame() {
        refreshGameTime();
        _;
    }

    function process(address sender, uint sendValue) onlyOwner {
        if (commonAttr.gameType == GameType.Range) {
            RangeGameProcess(sender, sendValue);
        } else if (commonAttr.gameType == GameType.Point) {
            PointGameProcess(sender, sendValue);
        }
    }

    function processWithITG(address sender, uint tokenAmountToGame) onlyOwner {
        if (commonAttr.gameType == GameType.Range) {
            RangeGameWithITG(sender, tokenAmountToGame);
        } else if (commonAttr.gameType == GameType.Point) {
            PointGameWithITG(sender, tokenAmountToGame);
        }
    }

    function RangeGameProcess(address sender, uint sendValue) private beforeRangeGame {
        if (commonAttr.currentGameTimeType == GameTime.Year) {
            commonAttr.yearlyAmountEth = safeAdd(commonAttr.yearlyAmountEth, sendValue);
            fundStatus.yearlyStatusEth = safeAdd(fundStatus.yearlyStatusEth, sendValue);
        } else if (commonAttr.currentGameTimeType == GameTime.Month) {
            commonAttr.monthlyAmountEth = safeAdd(commonAttr.monthlyAmountEth, sendValue);
            fundStatus.monthlyStatusEth = safeAdd(fundStatus.monthlyStatusEth, sendValue);
        } else if (commonAttr.currentGameTimeType == GameTime.Hour) {
            commonAttr.hourlyAmountEth = safeAdd(commonAttr.hourlyAmountEth, sendValue);
            fundStatus.hourlyStatusEth = safeAdd(fundStatus.hourlyStatusEth, sendValue);
        }
        participants.push(Participant(sender, sendValue, 1));
        if (priceAttr.bonusPerEth != 0) {
            tokTakers[d.currentYear][sender] = safeAdd(tokTakers[d.currentYear][sender], sendValue * priceAttr.bonusPerEth);
            tokPrizes[d.currentYear] = safeAdd(tokPrizes[d.currentYear], sendValue * priceAttr.bonusPerEth);
        }
    }

    function RangeGameWithITG(address sender, uint tokenAmountToGame) private beforeRangeGame {
        require(commonAttr.currentGameTimeType != GameTime.Year);
        if (commonAttr.currentGameTimeType == GameTime.Month) {
            fundStatus.monthlyStatusTok = safeAdd(fundStatus.monthlyStatusTok, tokenAmountToGame);
        } else if (commonAttr.currentGameTimeType == GameTime.Hour) {
            fundStatus.hourlyStatusTok = safeAdd(fundStatus.hourlyStatusTok, tokenAmountToGame);
        }
        participants.push(Participant(sender, tokenAmountToGame, 2));
    }

    function getTimeRangeInfo() private returns (GameTime, uint, uint, uint) {
        uint nextTimeStamp;
        uint nextYear;
        uint nextMonth;
        uint basis;
        if (commonAttr.gameType == GameType.Range) {
            nextTimeStamp = now + rangeGameAttr.inTimeRange_Y * 1 minutes + 1 hours;
            nextYear = getYear(nextTimeStamp);
            if (getYear(now - rangeGameAttr.inTimeRange_Y * 1 minutes + 1 hours) != nextYear) {
                basis = nextTimeStamp - (nextTimeStamp % 1 days);
                return (GameTime.Year, nextYear, basis - rangeGameAttr.inTimeRange_Y * 1 minutes, basis + rangeGameAttr.inTimeRange_Y * 1 minutes);
            }
            nextTimeStamp = now + rangeGameAttr.inTimeRange_M * 1 minutes + 1 hours;
            nextMonth = getMonth(nextTimeStamp);
            if (getMonth(now - rangeGameAttr.inTimeRange_M * 1 minutes + 1 hours) != nextMonth) {
                basis = nextTimeStamp - (nextTimeStamp % 1 days);
                return (GameTime.Month, nextYear, basis - rangeGameAttr.inTimeRange_M * 1 minutes, basis + rangeGameAttr.inTimeRange_M * 1 minutes);
            }
            nextTimeStamp = now + rangeGameAttr.inTimeRange_H * 1 minutes + 1 hours;
            basis = nextTimeStamp - (nextTimeStamp % 1 hours);
            return (GameTime.Hour, nextYear, basis - rangeGameAttr.inTimeRange_H * 1 minutes, basis + rangeGameAttr.inTimeRange_H * 1 minutes);
        } else if (commonAttr.gameType == GameType.Point) {
            nextTimeStamp = now - (now % 1 hours) + 1 hours;
            nextYear = getYear(nextTimeStamp);
            if (getYear(now) != nextYear) {
                return (GameTime.Year, nextYear, 0, nextTimeStamp);
            }
            nextMonth = getMonth(nextTimeStamp);
            if (getMonth(now) != nextMonth) {
                return (GameTime.Month, nextYear, 0, nextTimeStamp);
            }
            return (GameTime.Hour, nextYear, 0, nextTimeStamp);
        }
    }

    function refreshGameTime() private {
        (commonAttr.currentGameTimeType, d.currentYear, d.gameStart, d.gameEnd) = getTimeRangeInfo();
    }

    function gcFundAmount() private {
        fundStatus.hourlyStatusEth = 0;
        fundStatus.monthlyStatusEth = 0;
        fundStatus.yearlyStatusEth = 0;
        fundStatus.hourlyStatusTok = 0;
        fundStatus.monthlyStatusTok = 0;
    }

    function selectWinner(uint rand) onlyOwner {
        uint luckyNumber = participants.length * rand / 100000000;
        uint rewardDiv100 = 0;
        uint participateRatio = participants.length;
        if (participateRatio != 0) {
            if (commonAttr.currentGameTimeType == GameTime.Year) {
                participateRatio = participateRatio > priceAttr.yearlyMinParticipateRatio ? participateRatio : priceAttr.yearlyMinParticipateRatio;
            } else if (commonAttr.currentGameTimeType == GameTime.Month) {
                participateRatio = participateRatio > priceAttr.monthlyMinParticipateRatio ? participateRatio : priceAttr.monthlyMinParticipateRatio;
            } else if (commonAttr.currentGameTimeType == GameTime.Hour) {
                participateRatio = participateRatio > priceAttr.hourlyMinParticipateRatio ? participateRatio : priceAttr.hourlyMinParticipateRatio;
            }
            if (participants[luckyNumber].currency == 1) {
                rewardDiv100 = participants[luckyNumber].amount * participateRatio * priceAttr.boostPrizeEth / 100 / 100;
                if (priceAttr.currentInGameTokWinRatio < priceAttr.inGameTokWinRatioMax) {
                    priceAttr.currentInGameTokWinRatio++;
                }
            } else if (participants[luckyNumber].currency == 2) {
                rewardDiv100 = (participants[luckyNumber].amount / priceAttr.inGameTokPricePerEth * priceAttr.currentInGameTokWinRatio / 100) * participateRatio / 100;
                if (priceAttr.currentInGameTokWinRatio > priceAttr.inGameTokWinRatioMin) {
                    priceAttr.currentInGameTokWinRatio--;
                }
            }
            if (commonAttr.currentGameTimeType == GameTime.Year) {
                if (commonAttr.yearlyAmountEth >= rewardDiv100 * 104) {
                    commonAttr.yearlyAmountEth = safeSub(commonAttr.yearlyAmountEth, rewardDiv100 * 104);
                } else {
                    rewardDiv100 = commonAttr.yearlyAmountEth / 104;
                    commonAttr.yearlyAmountEth = 0;
                }
            } else if (commonAttr.currentGameTimeType == GameTime.Month) {
                if (commonAttr.monthlyAmountEth >= rewardDiv100 * 107) {
                    commonAttr.monthlyAmountEth = safeSub(commonAttr.monthlyAmountEth, rewardDiv100 * 107);
                } else {
                    rewardDiv100 = commonAttr.monthlyAmountEth / 107;
                    commonAttr.monthlyAmountEth = 0;
                }
                commonAttr.yearlyAmountEth = safeAdd(commonAttr.yearlyAmountEth, rewardDiv100 * 3);
            } else if (commonAttr.currentGameTimeType == GameTime.Hour) {
                if (commonAttr.hourlyAmountEth >= rewardDiv100 * 110) {
                    commonAttr.hourlyAmountEth = safeSub(commonAttr.hourlyAmountEth, rewardDiv100 * 110);
                } else {
                    rewardDiv100 = commonAttr.hourlyAmountEth / 110;
                    commonAttr.hourlyAmountEth = 0;
                }
                commonAttr.monthlyAmountEth = safeAdd(commonAttr.monthlyAmountEth, rewardDiv100 * 3);
                commonAttr.yearlyAmountEth = safeAdd(commonAttr.yearlyAmountEth, rewardDiv100 * 3);
            }
            commonAttr.charityAmountEth = safeAdd(commonAttr.charityAmountEth, rewardDiv100 * 4);
            winners[d.currentYear][participants[luckyNumber].sender] = safeAdd(winners[d.currentYear][participants[luckyNumber].sender], rewardDiv100 * 100);
            winPrizes[d.currentYear] = safeAdd(winPrizes[d.currentYear], rewardDiv100 * 100);
            LogSelectWinner(rand, luckyNumber, participants[luckyNumber].sender, rewardDiv100 * 100, participants[luckyNumber].currency, participants[luckyNumber].amount);
            participants.length = 0;
        }
        if (commonAttr.gameType == GameType.Range) {
            refreshGameTime();
        }
        gcFundAmount();
    }

    function getPrize(address sender) onlyOwner returns (uint ethPrize, uint tokPrize) {
        ethPrize = safeAdd(winners[d.currentYear][sender], winners[d.currentYear - 1][sender]);
        tokPrize = safeAdd(tokTakers[d.currentYear][sender], tokTakers[d.currentYear - 1][sender]);
        winPrizes[d.currentYear] = safeSub(winPrizes[d.currentYear], winners[d.currentYear][sender]);
        tokPrizes[d.currentYear] = safeSub(tokPrizes[d.currentYear], tokTakers[d.currentYear][sender]);
        winners[d.currentYear][sender] = 0;
        tokTakers[d.currentYear][sender] = 0;
        winPrizes[d.currentYear - 1] = safeSub(winPrizes[d.currentYear - 1], winners[d.currentYear - 1][sender]);
        tokPrizes[d.currentYear - 1] = safeSub(tokPrizes[d.currentYear - 1], tokTakers[d.currentYear - 1][sender]);
        winners[d.currentYear - 1][sender] = 0;
        tokTakers[d.currentYear - 1][sender] = 0;
    }

    function PointGameProcess(address sender, uint sendValue) private beforePointGame {
        if (commonAttr.currentGameTimeType == GameTime.Year) {
            commonAttr.yearlyAmountEth = safeAdd(commonAttr.yearlyAmountEth, sendValue);
            fundStatus.yearlyStatusEth = safeAdd(fundStatus.yearlyStatusEth, sendValue);
        } else if (commonAttr.currentGameTimeType == GameTime.Month) {
            commonAttr.monthlyAmountEth = safeAdd(commonAttr.monthlyAmountEth, sendValue);
            fundStatus.monthlyStatusEth = safeAdd(fundStatus.monthlyStatusEth, sendValue);
        } else if (commonAttr.currentGameTimeType == GameTime.Hour) {
            commonAttr.hourlyAmountEth = safeAdd(commonAttr.hourlyAmountEth, sendValue);
            fundStatus.hourlyStatusEth = safeAdd(fundStatus.hourlyStatusEth, sendValue);
        }
        PointGameParticipate(sender, sendValue, 1);
        if (priceAttr.bonusPerEth != 0) {
            tokTakers[d.currentYear][sender] = safeAdd(tokTakers[d.currentYear][sender], sendValue * priceAttr.bonusPerEth);
            tokPrizes[d.currentYear] = safeAdd(tokPrizes[d.currentYear], sendValue * priceAttr.bonusPerEth);
        }
    }

    function PointGameWithITG(address sender, uint tokenAmountToGame) private beforePointGame {
        require(commonAttr.currentGameTimeType != GameTime.Year);
        if (commonAttr.currentGameTimeType == GameTime.Month) {
            fundStatus.monthlyStatusTok = safeAdd(fundStatus.monthlyStatusTok, tokenAmountToGame);
        } else if (commonAttr.currentGameTimeType == GameTime.Hour) {
            fundStatus.hourlyStatusTok = safeAdd(fundStatus.hourlyStatusTok, tokenAmountToGame);
        }
        PointGameParticipate(sender, tokenAmountToGame, 2);
    }

    function PointGameParticipate(address sender, uint sendValue, uint currency) private {
        if (d.prevGameEnd != d.gameEnd) {
            selectWinner(1);
        }
        participants.length = 0;
        participants.push(Participant(sender, sendValue, currency));
        d.prevGameEnd = d.gameEnd;
    }

    function lossToCharity(uint year) onlyOwner returns (uint amt) {
        require(year < d.currentYear - 1);
        amt = winPrizes[year];
        tokPrizes[year] = 0;
        winPrizes[year] = 0;
    }

    function charityAmtToCharity() onlyOwner returns (uint amt) {
        amt = commonAttr.charityAmountEth;
        commonAttr.charityAmountEth = 0;
    }

    function distributeTokenSale(uint hour, uint month, uint year, uint charity) onlyOwner {
        commonAttr.hourlyAmountEth = safeAdd(commonAttr.hourlyAmountEth, hour);
        commonAttr.monthlyAmountEth = safeAdd(commonAttr.monthlyAmountEth, month);
        commonAttr.yearlyAmountEth = safeAdd(commonAttr.yearlyAmountEth, year);
        commonAttr.charityAmountEth = safeAdd(commonAttr.charityAmountEth, charity);
    }
}

contract ITGToken is ITGTokenBase, Authable {
    bytes32 public name = "ITG";
    bytes32 public symbol = "ITG";
    enum Status { CrowdSale, Game, Pause }
    Status public status;
    CrowdSale crowdSale;
    Games games;
    Voting voting;
    mapping(address => uint) public withdrawRestriction;
    event LogFundTransfer(address sender, address to, uint amount, uint8 currency);

    modifier beforeTransfer() {
        require(withdrawRestriction[msg.sender] < now);
        _;
    }

    function transfer(address to, uint value) beforeTransfer returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], value);
        balances[to] = safeAdd(balances[to], value);
        Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) beforeTransfer returns (bool success) {
        uint _allowance = allowed[from][msg.sender];
        balances[to] = safeAdd(balances[to], value);
        balances[from] = safeSub(balances[from], value);
        allowed[from][msg.sender] = safeSub(_allowance, value);
        Transfer(from, to, value);
        return true;
    }

    function ITGToken() {
        owner = msg.sender;
        totalSupply = 100000000 * 1 ether;
        balances[msg.sender] = totalSupply;
        status = Status.Pause;
    }

    function () payable {
        if (msg.value < minEtherParticipate) {
            throw;
        }
        if (status == Status.CrowdSale) {
            LogFundTransfer(msg.sender, 0x0, msg.value, 1);
            itgTokenTransfer(crowdSale.process(msg.sender, msg.value), true);
        } else if (status == Status.Game) {
            LogFundTransfer(msg.sender, 0x0, msg.value, 1);
            games.process(msg.sender, msg.value);
        } else if (status == Status.Pause) {
            throw;
        }
    }

    function setAttrs(address csAddr, address gmAddr, address vtAddr, Status _status, uint amtEth, uint amtTok) onlyAuth {
        crowdSale = CrowdSale(csAddr);
        games = Games(gmAddr);
        voting = Voting(vtAddr);
        status = _status;
        minEtherParticipate = amtEth;
        minTokParticipate = amtTok;
    }

    function USER_GET_CROWDSALE_TOKEN() {
        itgTokenTransfer(crowdSale.getToken(msg.sender), true);
    }

    function USER_VOTE(uint voteId, uint candidateId) {
        uint addedToken;
        uint lockUntil;
        (addedToken, lockUntil) = voting.vote(msg.sender, balances[msg.sender], voteId, candidateId);
        itgTokenTransfer(addedToken, true);
        if (withdrawRestriction[msg.sender] < lockUntil) {
            withdrawRestriction[msg.sender] = lockUntil;
        }
    }

    function voteInitiate(uint voteId, uint voteRewardPerUnit, uint voteWeightUnit, uint voteStart, uint voteEnd, uint maxCandidateId) onlyAuth {
        voting.voteInitiate(voteId, voteRewardPerUnit, voteWeightUnit, voteStart, voteEnd, maxCandidateId);
    }

    function itgTokenTransfer(uint amt, bool fromOwner) private {
        if (amt > 0) {
            if (fromOwner) {
                balances[owner] = safeSub(balances[owner], amt);
                balances[msg.sender] = safeAdd(balances[msg.sender], amt);
                Transfer(owner, msg.sender, amt);
                LogFundTransfer(owner, msg.sender, amt, 2);
            } else {
                balances[owner] = safeAdd(balances[owner], amt);
                balances[msg.sender] = safeSub(balances[msg.sender], amt);
                Transfer(msg.sender, owner, amt);
                LogFundTransfer(msg.sender, owner, amt, 2);
            }
        }
    }

    function ethTransfer(address target, uint amt) private {
        if (amt > 0) {
            target.transfer(amt);
            LogFundTransfer(0x0, target, amt, 1);
        }
    }

    function USER_GAME_WITH_TOKEN(uint tokenAmountToGame) {
        require(status == Status.Game);
        require(balances[msg.sender] >= tokenAmountToGame * 1 ether);
        require(tokenAmountToGame * 1 ether >= minTokParticipate);
        itgTokenTransfer(tokenAmountToGame * 1 ether, false);
        games.processWithITG(msg.sender, tokenAmountToGame * 1 ether);
    }

    function USER_GET_PRIZE() {
        uint ethPrize;
        uint tokPrize;
        (ethPrize, tokPrize) = games.getPrize(msg.sender);
        itgTokenTransfer(tokPrize, true);
        ethTransfer(msg.sender, ethPrize);
    }

    function selectWinner(uint rand) onlyAuth {
        games.selectWinner(rand);
    }

    function burn(uint amt) onlyOwner {
        balances[msg.sender] = safeSub(balances[msg.sender], amt);
        totalSupply = safeSub(totalSupply, amt);
    }

    function mint(uint amt) onlyOwner {
        balances[msg.sender] = safeAdd(balances[msg.sender], amt);
        totalSupply = safeAdd(totalSupply, amt);
    }

    function lossToCharity(uint year, address charityAccount) onlyAuth {
        ethTransfer(charityAccount, games.lossToCharity(year));
    }

    function charityAmtToCharity(address charityAccount) onlyOwner {
        ethTransfer(charityAccount, games.charityAmtToCharity());
    }

    function distributeTokenSale(uint hour, uint month, uint year, uint charity) onlyAuth {
        games.distributeTokenSale(hour, month, year, charity);
    }

    uint256 public minTokParticipate;
    uint256 public minEtherParticipate;
    uint256 public totalSupply;
}