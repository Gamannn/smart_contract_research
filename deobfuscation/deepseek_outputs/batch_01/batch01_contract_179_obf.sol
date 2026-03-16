```solidity
pragma solidity ^0.4.19;

interface Token {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint);
    function transfer(address to, uint tokens) public returns (bool);
    function transferFrom(address from, address to, uint tokens) public returns (bool);
    function approve(address spender, uint tokens) public returns (bool);
    function allowance(address tokenOwner, address spender) public constant returns (uint);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract SafeMath {
    function safeMul(uint a, uint b) internal pure returns (uint256) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function safeDiv(uint a, uint b) internal pure returns (uint256) {
        uint c = a / b;
        return c;
    }
    
    function safeSub(uint a, uint b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function safeAdd(uint a, uint b) internal pure returns (uint256) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Exchange is SafeMath {
    mapping (address => mapping (address => uint256)) public balances;
    mapping (bytes32 => bool) public traded;
    mapping (bytes32 => uint256) public orderFills;
    mapping (address => bool) public admins;
    mapping (address => uint256) public lastActiveTransaction;
    mapping (bytes32 => bool) public withdrawn;
    mapping (address => uint256) public rewards;
    mapping (address => uint256) public tokenDiscounts;
    
    event Deposit(address token, address user, uint amount, uint balance);
    event Withdraw(address token, address user, uint amount, uint balance);
    event Trade(address tokenBuy, address tokenSell, uint amountBuy, uint amountSell, uint expires, address maker, address taker);
    event Cancel(address user, bytes32 orderHash, uint expires);
    event Claim(address user, uint amount);
    
    struct ExchangeData {
        bool stopped;
        address rewardToken;
        uint256 rewardPool;
        uint256 totalRewardPool;
        uint256 claimedRewards;
        uint256 availableRewards;
        address feeAccount;
        address owner;
    }
    
    ExchangeData public exchangeData = ExchangeData(
        false,
        address(0),
        600000000 * 1e18,
        600000000 * 1e18,
        0,
        300000000 * 1e18,
        address(0),
        address(0)
    );
    
    function Exchange(address feeAccount) public {
        exchangeData.owner = msg.sender;
        exchangeData.feeAccount = feeAccount;
    }
    
    function changeOwner(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            exchangeData.owner = newOwner;
        }
    }
    
    function changeFeeAccount(address newFeeAccount) public onlyOwner {
        exchangeData.feeAccount = newFeeAccount;
    }
    
    function addAdmin(address admin) public onlyOwner {
        admins[admin] = true;
    }
    
    function removeAdmin(address admin) public onlyOwner {
        admins[admin] = false;
    }
    
    function setRewardToken(address rewardToken) public onlyOwner {
        exchangeData.rewardToken = rewardToken;
    }
    
    function setTokenDiscount(address token, uint256 discount) public onlyOwner {
        tokenDiscounts[token] = discount;
    }
    
    function setStopped(bool stopped) public onlyOwner {
        exchangeData.stopped = stopped;
    }
    
    modifier onlyOwner() {
        require(msg.sender == exchangeData.owner);
        _;
    }
    
    modifier onlyAdmin() {
        require(admins[msg.sender]);
        _;
    }
    
    modifier notStopped() {
        require(!exchangeData.stopped);
        _;
    }
    
    function() external {
        revert();
    }
    
    function depositToken(address token, uint amount) public {
        balances[token][msg.sender] = safeAdd(balances[token][msg.sender], amount);
        require(Token(token).transferFrom(msg.sender, this, amount));
        Deposit(token, msg.sender, amount, balances[token][msg.sender]);
    }
    
    function deposit() public payable {
        balances[address(0)][msg.sender] = safeAdd(balances[address(0)][msg.sender], msg.value);
        Deposit(address(0), msg.sender, msg.value, balances[address(0)][msg.sender]);
    }
    
    function withdraw(address token, uint amount, uint expires, address user, uint8 v, bytes32 r, bytes32 s) public {
        require(balances[token][msg.sender] >= amount);
        require(admins[user]);
        
        bytes32 hash = keccak256(this, msg.sender, token, amount, expires);
        require(verify(user, hash, v, r, s));
        require(!withdrawn[hash]);
        
        withdrawn[hash] = true;
        balances[token][msg.sender] = safeSub(balances[token][msg.sender], amount);
        
        if (token == address(0)) {
            require(msg.sender.send(amount));
        } else {
            require(Token(token).transfer(msg.sender, amount));
        }
        
        Withdraw(token, msg.sender, amount, balances[token][msg.sender]);
    }
    
    function balanceOf(address token, address user) public view returns(uint) {
        return balances[token][user];
    }
    
    function setLastActiveTransaction(address user, uint256 timestamp) public onlyAdmin {
        require(timestamp > lastActiveTransaction[user]);
        lastActiveTransaction[user] = timestamp;
    }
    
    function getTokenDiscount(address token) public view returns(uint256) {
        uint256 discount = tokenDiscounts[token];
        
        if (exchangeData.rewardPool > 500000000e18) {
            return discount;
        } else if (exchangeData.rewardPool > 400000000e18 && exchangeData.rewardPool <= 500000000e18) {
            return discount * 9e17 / 1e18;
        } else if (exchangeData.rewardPool > 300000000e18 && exchangeData.rewardPool <= 400000000e18) {
            return discount * 8e17 / 1e18;
        } else if (exchangeData.rewardPool > 200000000e18 && exchangeData.rewardPool <= 300000000e18) {
            return discount * 7e17 / 1e18;
        } else if (exchangeData.rewardPool > 100000000e18 && exchangeData.rewardPool <= 200000000e18) {
            return discount * 6e17 / 1e18;
        } else if(exchangeData.rewardPool <= 100000000e18) {
            return discount * 5e17 / 1e18;
        }
    }
    
    function trade(
        address[5] addresses,
        uint[11] values,
        uint8[3] v,
        bytes32[6] rs
    ) public notStopped returns (bool) {
        require(admins[addresses[4]]);
        require(lastActiveTransaction[addresses[2]] < values[2]);
        require(lastActiveTransaction[addresses[3]] < values[5]);
        require(values[6] > 0 && values[7] > 0 && values[8] > 0);
        require(values[1] >= values[7] && values[4] >= values[7]);
        require(msg.sender == addresses[2] || msg.sender == addresses[3] || msg.sender == addresses[4]);
        
        bytes32 buyHash = keccak256(address(this), addresses[0], addresses[1], addresses[2], values[0], values[1], values[2]);
        bytes32 sellHash = keccak256(address(this), addresses[0], addresses[1], addresses[3], values[3], values[4], values[5]);
        
        require(verify(addresses[2], buyHash, v[0], rs[0], rs[1]));
        require(verify(addresses[3], sellHash, v[1], rs[2], rs[3]));
        
        bytes32 tradeHash = keccak256(this, buyHash, sellHash, addresses[4], values[6], values[7], values[8], values[9], values[10]);
        require(verify(addresses[4], tradeHash, v[2], rs[4], rs[5]));
        
        require(!traded[tradeHash]);
        traded[tradeHash] = true;
        
        require(safeAdd(orderFills[buyHash], values[6]) <= values[0]);
        require(safeAdd(orderFills[sellHash], values[6]) <= values[3]);
        require(balances[addresses[1]][addresses[2]] >= values[7]);
        
        balances[addresses[1]][addresses[2]] = safeSub(balances[addresses[1]][addresses[2]], values[7]);
        balances[addresses[0]][addresses[3]] = safeSub(balances[addresses[0]][addresses[3]], values[6]);
        
        balances[addresses[0]][addresses[2]] = safeAdd(balances[addresses[0]][addresses[2]], safeSub(values[6], safeMul(values[6], values[9]) / 1 ether));
        balances[addresses[1]][addresses[3]] = safeAdd(balances[addresses[1]][addresses[3]], safeSub(values[7], safeMul(values[7], values[10]) / 1 ether));
        
        balances[addresses[0]][exchangeData.feeAccount] = safeAdd(balances[addresses[0]][exchangeData.feeAccount], safeMul(values[6], values[9]) / 1 ether);
        balances[addresses[1]][exchangeData.feeAccount] = safeAdd(balances[addresses[1]][exchangeData.feeAccount], safeMul(values[7], values[10]) / 1 ether);
        
        orderFills[buyHash] = safeAdd(orderFills[buyHash], values[6]);
        orderFills[sellHash] = safeAdd(orderFills[sellHash], values[6]);
        
        Trade(addresses[0], addresses[1], values[6], values[7], values[8], addresses[2], addresses[3]);
        
        if(exchangeData.rewardPool > 0) {
            if(tokenDiscounts[addresses[1]] > 0) {
                uint256 rewardAmount = safeMul(safeMul(values[7], getTokenDiscount(addresses[1])), 2) / (1 ether);
                
                if(exchangeData.rewardPool > rewardAmount) {
                    rewards[addresses[2]] = safeAdd(rewards[addresses[2]], safeSub(rewardAmount, rewardAmount / 2));
                    rewards[addresses[3]] = safeAdd(rewards[addresses[3]], rewardAmount / 2);
                    exchangeData.rewardPool = safeSub(exchangeData.rewardPool, rewardAmount);
                } else {
                    rewards[addresses[2]] = safeAdd(rewards[addresses[2]], safeSub(exchangeData.rewardPool, exchangeData.rewardPool / 2));
                    rewards[addresses[3]] = safeAdd(rewards[addresses[3]], exchangeData.rewardPool / 2);
                    exchangeData.rewardPool = 0;
                }
            }
        }
        return true;
    }
    
    function claimReward() public returns(bool) {
        require(rewards[msg.sender] > 0);
        require(exchangeData.rewardToken != address(0));
        
        uint amount = rewards[msg.sender];
        rewards[msg.sender] = 0;
        
        require(Token(exchangeData.rewardToken).transfer(msg.sender, amount));
        Claim(msg.sender, amount);
        return true;
    }
    
    function claimOwnerReward() public onlyOwner returns(bool) {
        uint256 remainingRewards = safeSub(exchangeData.totalRewardPool, exchangeData.rewardPool);
        require(remainingRewards > 0);
        
        uint256 ownerReward = safeMul(exchangeData.availableRewards, remainingRewards) / exchangeData.totalRewardPool;
        uint256 amount = safeSub(ownerReward, exchangeData.claimedRewards);
        require(amount > 0);
        
        exchangeData.claimedRewards = ownerReward;
        require(Token(exchangeData.rewardToken).transfer(msg.sender, amount));
        Claim(msg.sender, amount);
        return true;
    }
    
    function cancelOrder(
        address tokenBuy,
        address tokenSell,
        address user,
        uint amountBuy,
        uint amountSell,
        uint expires,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public onlyAdmin returns(bool) {
        bytes32 hash = keccak256(this, tokenBuy, tokenSell, user, amountBuy, amountSell, expires);
        require(verify(user, hash, v, r, s));
        
        orderFills[hash] = amountBuy;
        Cancel(user, hash, expires);
        return true;
    }
    
    function verify(
        address signer,
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (bool) {
        return signer == ecrecover(
            keccak256("\x19Ethereum Signed Message:\n32", hash),
            v,
            r,
            s
        );
    }
}
```